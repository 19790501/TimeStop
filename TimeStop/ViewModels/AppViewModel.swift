import Foundation
import SwiftUI
import Combine
import AVFoundation
import UserNotifications
import AudioToolbox
import BackgroundTasks

class AppViewModel: ObservableObject {
    // 共享实例，可用于AppDelegate中访问
    static let shared = AppViewModel()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var tasks: [Task] = []
    @Published var activeTask: Task?
    @Published var timeRemaining: Int = 0
    @Published var timerIsRunning: Bool = false
    @Published var statistics: Statistics = Statistics()
    
    // 倒计时设置相关状态
    @Published var selectedTaskType: TaskType = .work
    @Published var selectedTimeMode: TimeMode = .minutes
    @Published var selectedMinutes: Int = 30 // 分钟滑块值（0-59）
    @Published var selectedHours: Int = 0    // 小时滑块值（0-12）
    
    // 声音设置
    @Published var soundEnabled: Bool = true // 默认开启按钮音效
    
    // 振动设置
    @Published var vibrationEnabled: Bool = true // 默认开启振动
    
    // MARK: - 倒计时设置持久化
    
    // 保存倒计时设置
    func saveTimerSettings() {
        let settings = TimerSettings(
            taskType: selectedTaskType, 
            timeMode: selectedTimeMode,
            minutes: selectedMinutes,
            hours: selectedHours
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(settings)
            UserDefaults.standard.set(data, forKey: "timerSettings")
        } catch {
            print("Failed to save timer settings: \(error.localizedDescription)")
        }
    }
    
    // 加载倒计时设置
    private func loadTimerSettings() {
        if let data = UserDefaults.standard.data(forKey: "timerSettings") {
            do {
                let decoder = JSONDecoder()
                let settings = try decoder.decode(TimerSettings.self, from: data)
                
                // 更新状态
                selectedTaskType = settings.taskType
                selectedTimeMode = settings.timeMode
                selectedMinutes = settings.minutes
                selectedHours = settings.hours
            } catch {
                print("Failed to load timer settings: \(error.localizedDescription)")
            }
        }
    }
    
    // 倒计时设置结构
    struct TimerSettings: Codable {
        var taskType: TaskType
        var timeMode: TimeMode
        var minutes: Int
        var hours: Int
    }
    
    // 验证任务相关
    @Published var isVerifying: Bool = false
    @Published var verificationComplete: Bool = false
    @Published var verificationDrawingPrompt: String = ""
    @Published var verificationReadingWords: [String] = []
    
    // 声音和震动
    private var audioPlayer: AVAudioPlayer?
    private var backgroundAudioPlayer: AVAudioPlayer? // 用于后台播放的无声音频
    private var verificationTimer: Timer?
    private var alarmStartTime: Date? // 记录警报开始时间
    
    // 绘画提示列表
    private let drawingPrompts = [
        "树", "鸡蛋", "苹果", "房子", "太阳", 
        "花", "鱼", "汽车", "笑脸", "星星"
    ]
    
    // 英文单词列表
    private let readingWords = [
        ("Apple", "A-P-P-L-E"),
        ("Book", "B-O-O-K"),
        ("Cat", "C-A-T"),
        ("Door", "D-O-O-R"),
        ("Eye", "E-Y-E"),
        ("Food", "F-O-O-D"),
        ("Game", "G-A-M-E"),
        ("House", "H-O-O-S-E"),
        ("Ice", "I-C-E"),
        ("Jump", "J-U-M-P")
    ]
    
    var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTaskRefreshTimer: Timer? // 用于定期延长后台任务时间
    private var lastBackgroundDate: Date?
    
    // 后台任务标识符
    private let backgroundTaskIdentifier = "com.timestop.focustimer.backgroundtask"
    private var isBackgroundTaskRegistered = false
    
    // Statistics structure
    struct Statistics {
        var todayFocusTime: Int = 0 // in minutes
        var weeklyFocusTime: Int = 0 // in minutes
        var completionRate: Double = 0 // percentage
        var tasksByType: [Task.FocusType: Int] = [:]
        var averageFocusTime: Int = 0 // in minutes
    }
    
    @Published var selectedVerificationMethod: VerificationMethod = .drawing
    @Published var verificationSongPrompt: String = "请唱一首你喜欢的歌"
    @Published var verificationWordPrompt: String = "请朗读以下文字：\n\n" + "这是一段示例文字，用于朗读验证。请清晰地读出每个字，保持适当的语速和语调。"
    
    // Navigation manager
    private var navigationManager: NavigationManager?
    
    // 备用警报声音播放方法
    private var fallbackSoundTimer: Timer?
    
    // 用于防止任务完成界面过早消失
    @Published var taskCompletionInProgress: Bool = false
    
    // MARK: - 常量定义
    private enum Constants {
        // 时间相关常量
        static let taskCompletionCooldown: TimeInterval = 6.0
        static let vibrationInterval: TimeInterval = 0.15
        static let vibrationRepeatInterval: TimeInterval = 1.0
        static let fallbackSoundInterval: TimeInterval = 1.0 // 降低备用声音间隔为1秒，使铃声提示更频繁
        static let backgroundTaskRefreshInterval: TimeInterval = 60.0 // 每分钟刷新一次后台任务
        static let minimumAlarmDuration: TimeInterval = 30.0 // 锁屏状态下铃声最短持续时间(秒)
        
        // 音频相关常量
        static let audioSampleRate: Int = 44100
        static let audioChannels: Int = 1
        
        // 成就和经验相关常量
        static let experiencePerDuration: Int = 5     // 每分钟获得的经验值
        static let levelUpExperienceMultiplier: Int = 100 // 升级所需经验值乘数
        static let achievementExpReward: Int = 50     // 成就解锁基础经验奖励
        
        // 系统音效ID
        static let buttonSound: SystemSoundID = 1104
        static let successSound: SystemSoundID = 1057
        static let errorSound: SystemSoundID = 1073
        static let achievementSound: SystemSoundID = 1025
        static let alertSound: SystemSoundID = 1005
        
        // 倒计时结束铃声选项
        static let timerRingtones: [Ringtone] = [
            Ringtone(id: "default", name: "默认铃声", systemSoundID: 1005),
            Ringtone(id: "bell", name: "清脆铃声", systemSoundID: 1013),
            Ringtone(id: "glass", name: "水晶提示", systemSoundID: 1314),
            Ringtone(id: "horn", name: "喇叭提醒", systemSoundID: 1033),
            Ringtone(id: "notes", name: "音符旋律", systemSoundID: 1022)
        ]
    }
    
    // 铃声模型
    struct Ringtone: Identifiable, Equatable {
        let id: String
        let name: String
        let systemSoundID: SystemSoundID
        
        static func == (lhs: Ringtone, rhs: Ringtone) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // 添加铃声选择属性
    @Published var selectedRingtoneID: String = "default" // 默认铃声ID
    
    // 添加一个属性来跟踪铃声定时器
    private var alarmTimer: Timer?
    
    // MARK: - 缓存管理
    
    // 缓存类型枚举
    enum CacheType {
        case all         // 所有缓存
        case audio       // 音频缓存
        case tempFiles   // 临时文件
        case recordings  // 录音文件
        case metal       // Metal渲染缓存
    }
    
    // 缓存清理状态
    struct CacheStatus {
        var totalSizeMB: Double = 0
        var lastCleanDate: Date?
    }
    
    // 添加一个发布属性来跟踪缓存状态
    @Published var cacheStatus: CacheStatus = CacheStatus()
        
    // 计算缓存大小
    func calculateCacheSize(completion: @escaping (Double) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            var totalSize: UInt64 = 0
            
            // 添加要检查的目录
            var directories: [URL] = []
            
            // 1. 文档目录
            if let documentDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                directories.append(documentDir)
        }
        
            // 2. 缓存目录
            if let cacheDir = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                directories.append(cacheDir)
            }
            
            // 3. 临时目录
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            directories.append(tempDir)
        
            // 计算所有目录的总大小
            for directory in directories {
                let resourceKeys = Set<URLResourceKey>([.totalFileAllocatedSizeKey, .isDirectoryKey])
                
                if let directoryEnumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles) {
                    for case let fileURL as URL in directoryEnumerator {
                        guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                            continue
                        }
                        
                        // 如果是文件，加上它的大小
                        if resourceValues.isDirectory != true, let size = resourceValues.totalFileAllocatedSize {
                            totalSize += UInt64(size)
                        }
                    }
                }
            }
            
            // 将结果转换为MB
            let sizeMB = Double(totalSize) / (1024 * 1024)
            
            // 主线程返回结果
            DispatchQueue.main.async {
                self.cacheStatus.totalSizeMB = sizeMB
                completion(sizeMB)
            }
        }
    }
    
    // 清理指定类型的缓存
    func clearCache(type: CacheType = .all, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            do {
                let fileManager = FileManager.default
                
                // 获取各种目录
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let cacheDir = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                
                // 根据类型选择要清理的内容
                switch type {
                case .audio:
                    // 清理音频相关文件和文件夹
                    let audioDir = documentDir.appendingPathComponent("Audio", isDirectory: true)
                    if fileManager.fileExists(atPath: audioDir.path) {
                        try fileManager.removeItem(at: audioDir)
                        try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
                    }
                    
                case .recordings:
                    // 清理录音文件夹
                    let recordingsDir = documentDir.appendingPathComponent("Recordings", isDirectory: true)
                    if fileManager.fileExists(atPath: recordingsDir.path) {
                        try fileManager.removeItem(at: recordingsDir)
                        try fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
                    }
                    
                case .tempFiles:
                    // 清理临时文件目录
                    let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                    for item in contents {
                        try fileManager.removeItem(at: item)
                    }
                    
                case .metal:
                    // 清理Metal渲染缓存
                    let metalCacheDir = cacheDir.appendingPathComponent("Metal", isDirectory: true)
                    if fileManager.fileExists(atPath: metalCacheDir.path) {
                        try fileManager.removeItem(at: metalCacheDir)
                    }
                    
                    // 清理其它渲染相关缓存
                    let renderCacheDir = cacheDir.appendingPathComponent("RenderCache", isDirectory: true)
                    if fileManager.fileExists(atPath: renderCacheDir.path) {
                        try fileManager.removeItem(at: renderCacheDir)
                    }
                    
                case .all:
                    // 清理录音目录
                    let recordingsDir = documentDir.appendingPathComponent("Recordings", isDirectory: true)
                    if fileManager.fileExists(atPath: recordingsDir.path) {
                        try fileManager.removeItem(at: recordingsDir)
                        try fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
                    }
                    
                    // 清理缓存目录内容
                    let cacheContents = try fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
                    for item in cacheContents {
                        try fileManager.removeItem(at: item)
                    }
                    
                    // 清理临时目录
                    let tempContents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                    for item in tempContents {
                        try fileManager.removeItem(at: item)
        }
    }
    
                // 更新清理时间
                DispatchQueue.main.async {
                    // 更新最后清理时间
                    self.cacheStatus.lastCleanDate = Date()
                    
                    // 更新缓存大小
                    self.calculateCacheSize { _ in
                        // 重置音频会话，避免潜在的问题
                        do {
            let audioSession = AVAudioSession.sharedInstance()
                            try audioSession.setActive(false)
                            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                        } catch {
                            print("重置音频会话时出错: \(error.localizedDescription)")
            }
            
                        // 模拟完成回调
                        completion(true, nil)
                    }
                }
        } catch {
                DispatchQueue.main.async {
                    print("清理缓存时出错: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }
    
    // 加载缓存信息
    func loadCacheInfo() {
        // 从UserDefaults加载上次清理时间
        if let lastCleanDate = UserDefaults.standard.object(forKey: "lastCacheCleanDate") as? Date {
            cacheStatus.lastCleanDate = lastCleanDate
        }
        
        // 计算当前缓存大小
        calculateCacheSize { _ in }
    }
    
    // 保存缓存信息
    private func saveCacheInfo() {
        if let lastCleanDate = cacheStatus.lastCleanDate {
            UserDefaults.standard.set(lastCleanDate, forKey: "lastCacheCleanDate")
        }
    }
    
    init() {
        // Load user data from storage
        loadUserData()
        
        // 加载倒计时设置
        loadTimerSettings()
        
        // 添加测试数据用于展示统计功能
        if tasks.isEmpty {
            addDemoTasks()
        }
        
        // 加载声音设置
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
            
        // 加载振动设置
        vibrationEnabled = UserDefaults.standard.bool(forKey: "vibrationEnabled")
        
        // 加载选择的铃声ID
        if let savedRingtoneID = UserDefaults.standard.string(forKey: "selectedRingtoneID") {
            selectedRingtoneID = savedRingtoneID
        }
        
        // 加载缓存信息
        loadCacheInfo()
        
        // Setup publishers
        setupPublishers()
        
        // 请求必要的权限
        requestPermissions()
        
        // 初始化无声音频文件用于后台播放
        prepareBackgroundAudio()
        
        // 注册后台任务处理器
        // 注释掉以避免潜在的BGTaskScheduler崩溃问题
        // registerBackgroundTasks()
    }
    
    // 请求必要的权限
    private func requestPermissions() {
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
        }
        
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
                // 设置通知类别
                self.setupNotificationCategories()
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
            }
        }
        
    // 设置通知类别
    private func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "完成任务",
            options: .foreground
        )
        
        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_TASK",
            title: "取消任务",
            options: .destructive
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, cancelAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // 准备后台音频
    private func prepareBackgroundAudio() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            
            do {
                // 配置音频会话
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
            } catch {
                print("Failed to prepare audio session: \(error.localizedDescription)")
            }
        }
    }
    
    // 开始后台音频播放
    private func startBackgroundAudio() {
        guard timerIsRunning else { return }
        
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            
            do {
                // 确保音频会话处于活跃状态
                try AVAudioSession.sharedInstance().setActive(true)
        
                // 使用系统声音
                AudioServicesPlaySystemSound(1104)
            } catch {
                print("Failed to start background audio: \(error.localizedDescription)")
            }
        }
    }
    
    // 停止后台音频播放
    private func stopBackgroundAudio() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            
            do {
                // 停用音频会话
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Failed to stop background audio: \(error.localizedDescription)")
            }
        }
    }
    
    // 清理音频资源
    private func cleanupAudioResources() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
            
            // 停止并清理所有音频播放器
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
            self?.backgroundAudioPlayer?.stop()
            self?.backgroundAudioPlayer = nil
            
            // 停止所有音频会话
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
    }
    
    // 注册后台任务
    func registerBackgroundTasks() {
        // 暂时禁用，避免崩溃
        print("Background task registration is currently disabled to prevent crashes")
        /* 原始代码注释掉
        guard !isBackgroundTaskRegistered else { return }
        
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 注册后台任务
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: self.backgroundTaskIdentifier,
                using: nil
            ) { [weak self] task in
                guard let self = self else { return }
                self.handleBackgroundTask(task as! BGProcessingTask)
            }
            
            // 注册成功
            self.isBackgroundTaskRegistered = true
            print("Background task registered successfully")
            
            // 安排第一个后台任务
            self.scheduleBackgroundTask()
        }
        */
    }
    
    // 处理后台任务
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        // 暂时禁用，避免崩溃
        print("Background task handling is currently disabled to prevent crashes")
        task.setTaskCompleted(success: true)
        
        /* 原始代码注释掉
        // 设置任务到期处理程序
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // 如果计时器正在运行，更新剩余时间
        if timerIsRunning {
            guard let lastDate = lastBackgroundDate else {
                task.setTaskCompleted(success: true)
                return
            }
        
        // 计算后台经过的时间
        let elapsedTime = Int(Date().timeIntervalSince(lastDate))
        
        // 更新剩余时间
        timeRemaining = max(0, timeRemaining - elapsedTime)
            lastBackgroundDate = Date()
        
        // 如果时间到了，触发验证
        if timeRemaining == 0 {
                // 发送本地通知提醒用户返回应用
                sendCompletionNotification()
                
                // 可以在这里处理任务完成逻辑
            stopTimer()
        }
        }
        
        // 安排下一个后台任务
        scheduleBackgroundTask()
        
        task.setTaskCompleted(success: true)
        */
    }
    
    // 调度后台任务
    private func scheduleBackgroundTask() {
        // 暂时禁用，避免崩溃
        print("Background task scheduling is currently disabled to prevent crashes")
        
        /* 原始代码注释掉
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分钟后执行
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled successfully")
        } catch {
            print("Failed to schedule background task: \(error.localizedDescription)")
            
            // 如果是权限错误，尝试重新请求权限
            if let bgError = error as? BGTaskScheduler.Error,
               bgError.code == .notPermitted {
                print("Requesting background task permission...")
                registerBackgroundTasks()
            } else {
                // 其他错误，延迟重试
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.scheduleBackgroundTask()
                }
            }
        }
        */
    }
    
    // 注册后台任务 - 简化版，支持init调用
    private func registerBackgroundTask() {
        // 暂时禁用
        print("Background task registration is currently disabled to prevent crashes")
    }
    
    // 发送完成通知
    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "专注时间已完成"
        content.body = "请返回应用完成任务验证"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "TASK_REMINDER"
        
        // 立即触发通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediateCompletion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 停止后台任务刷新定时器
    private func stopBackgroundTaskRefreshTimer() {
        backgroundTaskRefreshTimer?.invalidate()
        backgroundTaskRefreshTimer = nil
    }
    
    // 添加处理异常退出的方法
    func resetAbnormalState() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("检测到应用异常退出，执行清理...")
            
            // 清理音频资源
            print("执行紧急音频清理...")
            self.cleanupAudioResources()
            
            // 停止所有计时器
            self.timer?.invalidate()
            self.timer = nil
            self.verificationTimer?.invalidate()
            self.verificationTimer = nil
            self.fallbackSoundTimer?.invalidate()
            self.fallbackSoundTimer = nil
            self.backgroundTaskRefreshTimer?.invalidate()
            self.backgroundTaskRefreshTimer = nil
            
            // 结束后台任务
            if self.backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = .invalid
            }
            
            // 重置所有状态
            self.timeRemaining = 0
            self.timerIsRunning = false
            self.isVerifying = false
            self.verificationComplete = false
            self.taskCompletionInProgress = false
            
            // 清除保存的状态
            UserDefaults.standard.removeObject(forKey: "activeTask")
            UserDefaults.standard.removeObject(forKey: "timeRemaining")
            UserDefaults.standard.removeObject(forKey: "lastBackgroundDate")
            UserDefaults.standard.removeObject(forKey: "isVerifying")
            UserDefaults.standard.removeObject(forKey: "verificationComplete")
            
            // 重置活动任务
            self.activeTask = nil
            
            // 重置成就相关状态
            self.verificationDrawingPrompt = ""
            self.verificationReadingWords = []
            self.verificationSongPrompt = "请唱一首你喜欢的歌"
            self.verificationWordPrompt = "请朗读以下文字：\n\n" + "这是一段示例文字，用于朗读验证。请清晰地读出每个字，保持适当的语速和语调。"
        }
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timerIsRunning = true
        
        // 首先确保之前的计时器被停止
            self.timer?.invalidate()
        
        // 使用Timer.scheduledTimer
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    
                    // 每10秒保存一次任务状态
                    if self.timeRemaining % 10 == 0 {
                        self.saveActiveTaskState()
                    }
                    
                    if self.timeRemaining == 0 {
                        // 停止计时器
                        self.stopTimer()
                        
                        // 开始验证流程
                        self.startVerification()
                        
                        // 发送通知，通知UI更新到验证界面
                        NotificationCenter.default.post(name: NSNotification.Name("VerificationNeeded"), object: nil)
                }
            }
        }
        
            // 将计时器添加到 RunLoop 的 common 模式
            if let timer = self.timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // 记录当前时间，用于后台恢复
            self.lastBackgroundDate = Date()
        
        // 保存活动任务状态
            self.saveActiveTaskState()
        }
    }
    
    private func stopTimer() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 停止计时器
            self.timer?.invalidate()
            self.timer = nil
            self.timerIsRunning = false
        
        // 停止后台音频播放
            self.stopBackgroundAudio()
        
        // 停止后台任务刷新定时器
            self.stopBackgroundTaskRefreshTimer()
        
        // 结束后台任务
            self.endBackgroundTask()
        
        // 清除保存的任务状态
        UserDefaults.standard.removeObject(forKey: "activeTask")
        UserDefaults.standard.removeObject(forKey: "timeRemaining")
        UserDefaults.standard.removeObject(forKey: "lastBackgroundDate")
        }
    }
    
    func pauseTimer() {
        stopTimer()
    }
    
    func resumeTimer() {
        startTimer()
    }
    
    // 更新任务时间
    func updateTaskTime(by minutes: Int) {
        timeRemaining = max(0, timeRemaining + (minutes * 60))
        
        // 如果任务存在，更新其持续时间并记录时间调整
        if var task = activeTask {
            // 更新持续时间
            task.duration = max(0, task.duration + minutes)
            
            // 记录时间调整，仅当调整值不为0时
            if minutes != 0 {
                task.timeAdjustments.append(minutes)
                
                // 可以在这里添加日志，便于调试
                print("任务时间调整: \(minutes)分钟，原始时间: \(task.originalDuration())分钟，当前时间: \(task.duration)分钟")
            }
            
            // 更新活动任务
            activeTask = task
            
            // 保存更改
            saveUserData()
            
            // 保存活动任务状态
            if timerIsRunning {
                saveActiveTaskState()
            }
        }
    }
    
    // MARK: - Statistics
    
    private func updateStatistics(with tasks: [Task]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // Calculate today's focus time
        let todayTasks = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: now)
        }
        statistics.todayFocusTime = todayTasks.reduce(0) { $0 + $1.duration }
        
        // Calculate weekly focus time
        let weekTasks = tasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= startOfWeek && completedAt < now
        }
        statistics.weeklyFocusTime = weekTasks.reduce(0) { $0 + $1.duration }
        
        // Calculate completion rate
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        statistics.completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) * 100 : 0
        
        // Calculate tasks by type
        var tasksByType: [Task.FocusType: Int] = [:]
        for type in Task.FocusType.allCases {
            tasksByType[type] = tasks.filter { $0.focusType == type }.count
        }
        statistics.tasksByType = tasksByType
        
        // Calculate average focus time
        if completedTasks > 0 {
            let totalFocusTime = tasks.filter { $0.isCompleted }.reduce(0) { $0 + $1.duration }
            statistics.averageFocusTime = totalFocusTime / completedTasks
        } else {
            statistics.averageFocusTime = 0
        }
    }
    
    // MARK: - Task Verification
    
    // 开始验证任务
    func startVerification() {
        guard let task = activeTask, let method = task.verificationMethod else { return }
        
        // 确保在主线程更新UI状态
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新状态
            self.isVerifying = true
            self.verificationComplete = false
        
        // 启动提示声音和震动
            self.startVerificationAlert()
        
        // 根据验证方法准备相应的内容
        switch method {
        case .drawing:
            // 随机选择一个绘画提示
                self.verificationDrawingPrompt = self.drawingPrompts.randomElement() ?? "树"
            
        case .reading:
            // 随机选择两个单词
                let selectedWords = Array(self.readingWords.shuffled().prefix(2))
                self.verificationReadingWords = selectedWords.map { $0.0 }
            
        case .singing:
            // 唱歌模式不需要特殊准备
            break
        }
            
            // 发送通知，通知UI更新到验证界面
            NotificationCenter.default.post(name: NSNotification.Name("VerificationNeeded"), object: nil)
        }
    }
    
    // 开始验证警报
    private func startVerificationAlert() {
        // 首先停止任何现有的铃声
        stopVerificationAlert()
        
        // 初始化警报开始时间
        alarmStartTime = Date()
        
        // 获取当前选择的铃声
        let ringtoneID = selectedRingtoneID
        let ringtone = Constants.timerRingtones.first { $0.id == ringtoneID } ?? Constants.timerRingtones[0]
        
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否在锁屏状态
            let isLocked = UIApplication.shared.applicationState == .background
            
            // 设置铃声持续时间：锁屏30秒，正常使用10秒
            let duration: TimeInterval = isLocked ? Constants.minimumAlarmDuration : 10.0
            
            // 配置音频会话
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to setup audio session: \(error.localizedDescription)")
                    }
                    
            // 创建定时器来重复播放铃声
            self.alarmTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
    }
    
                // 检查是否应该停止
                if let startTime = self.alarmStartTime,
                   Date().timeIntervalSince(startTime) >= duration {
                    self.stopVerificationAlert()
                    return
                }
                
                // 播放铃声
                AudioServicesPlaySystemSound(ringtone.systemSoundID)
                
                // 如果启用了震动
                if self.vibrationEnabled {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
            
            // 将定时器添加到 RunLoop
            if let timer = self.alarmTimer {
                RunLoop.current.add(timer, forMode: .common)
            }
            
            // 立即播放第一次铃声
            AudioServicesPlaySystemSound(ringtone.systemSoundID)
            if self.vibrationEnabled {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
    
    // 停止验证提醒
    public func stopVerificationAlert() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                
            // 停止并清理定时器
            self.alarmTimer?.invalidate()
            self.alarmTimer = nil
            
            // 重置警报开始时间
            self.alarmStartTime = nil
            
            // 停止所有音频播放
            self.stopBackgroundAudio()
            
            // 停止震动
            if self.vibrationEnabled {
                AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
            }
            
            // 停用音频会话
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
                }
                
            // 发送通知更新UI
            NotificationCenter.default.post(name: .alarmStopped, object: nil)
            }
        }
        
    // 修改完成验证方法
    func completeVerification() {
        // 停止铃声
        stopVerificationAlert()
        
        // 批量更新状态，避免多次触发UI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 立即更新状态标志
            self.verificationComplete = true
            self.isVerifying = false
            
            // 完成任务
            if self.activeTask != nil {
                self.completeTask()
            }
            
            // 确保任务不会立即被清除，避免界面提前消失
            self.taskCompletionInProgress = true
            
            // 在足够长的时间后，才完全清理状态
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.taskCompletionCooldown) { [weak self] in
                guard let self = self else { return }
                self.taskCompletionInProgress = false
                }
            }
        }
        
    // 修改取消验证方法
    func cancelVerification() {
        // 停止铃声
        stopVerificationAlert()
        
        // 确保在主线程更新UI状态
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isVerifying = false
            self.verificationComplete = false
            self.verificationDrawingPrompt = ""
            self.verificationReadingWords = []
            
            // 重置任务状态
            self.activeTask = nil
            self.timeRemaining = 0
            self.timerIsRunning = false
            
            // 清除保存的状态
            UserDefaults.standard.removeObject(forKey: "activeTask")
            UserDefaults.standard.removeObject(forKey: "timeRemaining")
            UserDefaults.standard.removeObject(forKey: "lastBackgroundDate")
            UserDefaults.standard.removeObject(forKey: "isVerifying")
            UserDefaults.standard.removeObject(forKey: "verificationComplete")
        }
    }
    
    // 添加用于演示的测试数据
    private func addDemoTasks() {
        let calendar = Calendar.current
        let today = Date()
        
        // 今天的任务 - 专注于工作和生产力
        addTasksForDate(
            baseDate: today,
            taskInfos: [
                ("项目会议", 45, Task.FocusType.productivity),
                ("代码开发", 120, Task.FocusType.productivity),
                ("写作计划", 60, Task.FocusType.writing),
                ("阅读文档", 30, Task.FocusType.writing),
                ("午休放松", 20, Task.FocusType.audio)
            ]
        )
        
        // 昨天的任务 - 专注于健康和生活
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            addTasksForDate(
                baseDate: yesterday,
                taskInfos: [
                    ("晨间运动", 30, Task.FocusType.success),
                    ("瑜伽课程", 60, Task.FocusType.success),
                    ("冥想放松", 20, Task.FocusType.audio),
                    ("阅读小说", 45, Task.FocusType.writing)
                ]
            )
        }
        
        // 前天的任务 - 混合类型
        if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today) {
            addTasksForDate(
                baseDate: dayBeforeYesterday,
                taskInfos: [
                    ("团队会议", 60, Task.FocusType.productivity),
                    ("健身训练", 45, Task.FocusType.success),
                    ("午间小憩", 15, Task.FocusType.audio),
                    ("读书笔记", 30, Task.FocusType.writing)
                ]
            )
        }
        
        // 上周的任务 - 专注于学习和成长
        if let lastWeekDate = calendar.date(byAdding: .day, value: -7, to: today) {
            addTasksForDate(
                baseDate: lastWeekDate,
                taskInfos: [
                    ("技术学习", 90, Task.FocusType.productivity),
                    ("写博客", 60, Task.FocusType.writing),
                    ("晚间运动", 45, Task.FocusType.success),
                    ("音乐放松", 30, Task.FocusType.audio)
                ]
            )
        }
        
        // 上周中间的任务 - 重点关注工作效率
        if let lastWeekMiddle = calendar.date(byAdding: .day, value: -9, to: today) {
            addTasksForDate(
                baseDate: lastWeekMiddle,
                taskInfos: [
                    ("项目规划", 120, Task.FocusType.productivity),
                    ("文档编写", 90, Task.FocusType.writing),
                    ("午间运动", 30, Task.FocusType.success),
                    ("休息时间", 20, Task.FocusType.audio)
                ]
            )
        }
        
        // 保存添加的测试数据
        saveUserData()
    }
    
    // 用于添加指定日期的多个任务
    private func addTasksForDate(baseDate: Date, taskInfos: [(String, Int, Task.FocusType)]) {
        for (index, taskInfo) in taskInfos.enumerated() {
            let (title, duration, focusType) = taskInfo
            
            // 添加时间的偏移量，使得任务不会有完全相同的完成时间
            let timeOffset = TimeInterval(index * 3600) // 每个任务间隔1小时
            let completionTime = baseDate.addingTimeInterval(timeOffset)
            
            let task = Task(
                title: title,
                focusType: focusType,
                duration: duration,
                completedAt: completionTime
            )
            
            self.tasks.append(task)
        }
    }
    
    // MARK: - Sound Management
    
    /// 切换音效开关状态
    func toggleSoundEnabled() {
        soundEnabled.toggle()
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
    }
    
    /// 切换振动开关状态
    func toggleVibrationEnabled() {
        vibrationEnabled.toggle()
        UserDefaults.standard.set(vibrationEnabled, forKey: "vibrationEnabled")
    }
    
    /// 播放按钮点击音效
    func playButtonSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(Constants.buttonSound)
    }
    
    /// 播放成功操作音效
    func playSuccessSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(Constants.successSound)
    }
    
    /// 播放取消操作音效
    func playCancelSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(Constants.buttonSound)
    }
    
    /// 播放错误操作音效
    func playErrorSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(Constants.errorSound)
    }
    
    /// 播放成就解锁音效
    func playAchievementSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(Constants.achievementSound)
    }
    
    // MARK: - Achievement System
    
    // 获取特定成就类型的等级
    func achievementLevel(for type: AchievementType) -> Int {
        let minutes = getAchievementMinutes(for: type)
        return type.achievementLevel(for: minutes)
    }
    
    // 获取特定成就类型的累计时间
    func getAchievementMinutes(for type: AchievementType) -> Int {
        let user = currentUser
        
        // 从用户数据中获取累计时间，如果不存在则返回0
        return user?.achievements
            .first(where: { $0.typeIdentifier == type.rawValue })?
            .minutes ?? 0
    }
    
    // 更新成就进度
    func updateAchievements(for task: Task) {
        guard currentUser != nil else { return }
        
        // 确定要更新的成就类型
        let typeToUpdate: AchievementType
        
        switch task.focusType {
        case .productivity:
            // 随机选择工作相关成就
            let workTypes: [AchievementType] = [.meeting, .thinking, .work]
            typeToUpdate = workTypes.randomElement() ?? .work
            
        case .writing:
            // 随机选择阅读和生活相关成就
            let lifeTypes: [AchievementType] = [.reading, .life]
            typeToUpdate = lifeTypes.randomElement() ?? .reading
            
        case .success:
            typeToUpdate = .exercise
            
        case .audio:
            // 随机选择休闲和睡眠相关成就
            let relaxTypes: [AchievementType] = [.relax, .sleep]
            typeToUpdate = relaxTypes.randomElement() ?? .relax
            
        case .general:
            // 随机选择一种成就类型
            typeToUpdate = AchievementType.allCases.randomElement() ?? .work
        }
        
        // 更新成就时间
        updateAchievement(type: typeToUpdate, minutes: task.duration)
    }
    
    // 更新特定类型的成就时间
    private func updateAchievement(type: AchievementType, minutes: Int) {
        guard var user = currentUser else { return }
        
        // 查找是否已存在此类成就
        if let index = user.achievements.firstIndex(where: { $0.typeIdentifier == type.rawValue }) {
            // 获取当前等级
            let currentMinutes = user.achievements[index].minutes
            let currentLevel = type.achievementLevel(for: currentMinutes)
            
            // 更新时间
            user.achievements[index].minutes += minutes
            
            // 检查是否升级
            let newMinutes = user.achievements[index].minutes
            let newLevel = type.achievementLevel(for: newMinutes)
            
            if newLevel > currentLevel {
                // 触发成就解锁通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("AchievementUnlocked"),
                    object: nil,
                    userInfo: [
                        "type": type,
                        "level": newLevel
                    ]
                )
                
                // 添加成就解锁记录
                user.achievements[index].unlockedLevels.append(newLevel)
                
                // 获取用户体验值奖励
                let expGain = 50 * newLevel
                user.experience += expGain
                
                // 检查是否升级
                checkLevelUp(for: &user)
            }
        } else {
            // 创建新的成就记录
            let newAchievement = Achievement(
                typeIdentifier: type.rawValue,
                minutes: minutes,
                unlockedLevels: minutes > 0 ? [1] : []
            )
            user.achievements.append(newAchievement)
            
            // 如果直接解锁了第一级，触发通知
            if minutes > 0 {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AchievementUnlocked"),
                    object: nil,
                    userInfo: [
                        "type": type,
                        "level": 1
                    ]
                )
                
                // 获取用户体验值奖励
                user.experience += 50
                
                // 检查是否升级
                checkLevelUp(for: &user)
            }
        }
        
        // 更新用户数据
        currentUser = user
        isAuthenticated = true
        saveUserData()
    }
    
    // 检查用户升级
    private func checkLevelUp(for user: inout User) {
        let nextLevelExp = user.level * Constants.levelUpExperienceMultiplier
        
        if user.experience >= nextLevelExp {
            user.level += 1
            // 通知用户升级
            NotificationCenter.default.post(
                name: NSNotification.Name("UserLevelUp"),
                object: nil,
                userInfo: ["level": user.level]
            )
        }
    }
    
    // 解锁所有成就 (用于测试)
    func unlockAllAchievements() {
        guard var user = currentUser else { return }
        
        for type in AchievementType.allCases {
            let minutes = type == .sleep ? 540 : 500 // 解锁最高等级
            
            if let index = user.achievements.firstIndex(where: { $0.typeIdentifier == type.rawValue }) {
                user.achievements[index].minutes = minutes
            } else {
                let newAchievement = Achievement(
                    typeIdentifier: type.rawValue,
                    minutes: minutes,
                    unlockedLevels: Array(1...(type == .sleep ? 8 : 6))
                )
                user.achievements.append(newAchievement)
            }
        }
        
        currentUser = user
        isAuthenticated = true
        saveUserData()
    }
    
    // 重置所有成就 (用于测试)
    func resetAllAchievements() {
        guard var user = currentUser else { return }
        user.achievements = []
        currentUser = user
        isAuthenticated = true
        saveUserData()
    }
    
    // 获取当前选择的铃声
    var currentRingtone: Ringtone {
        return Constants.timerRingtones.first { $0.id == selectedRingtoneID } ?? Constants.timerRingtones[0]
    }
    
    // 获取所有铃声选项
    var availableRingtones: [Ringtone] {
        return Constants.timerRingtones
    }
    
    // 选择并保存新铃声
    func selectRingtone(id: String) {
        selectedRingtoneID = id
        UserDefaults.standard.set(id, forKey: "selectedRingtoneID")
    }
    
    // 试听铃声
    func playRingtoneSample(id: String) {
        if let ringtone = Constants.timerRingtones.first(where: { $0.id == id }) {
            AudioServicesPlaySystemSound(ringtone.systemSoundID)
        }
    }
    
    // MARK: - Data Persistence
    
    // 从UserDefaults加载用户数据
    private func loadUserData() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(User.self, from: userData)
                currentUser = user
                isAuthenticated = true
            } catch {
                print("Failed to decode user data: \(error.localizedDescription)")
                // 创建一个新用户
                createNewUser()
            }
        } else {
            // 如果没有用户数据，创建一个新用户
            createNewUser()
        }
        
        // 加载任务数据
        if let tasksData = UserDefaults.standard.data(forKey: "userTasks") {
            do {
                let decoder = JSONDecoder()
                tasks = try decoder.decode([Task].self, from: tasksData)
                updateStatistics(with: tasks)
            } catch {
                print("Failed to decode tasks data: \(error.localizedDescription)")
                tasks = []
            }
        }
    }
    
    // 保存用户数据到UserDefaults
    private func saveUserData() {
        if let user = currentUser {
            do {
                let encoder = JSONEncoder()
                let userData = try encoder.encode(user)
                UserDefaults.standard.set(userData, forKey: "currentUser")
            } catch {
                print("Failed to encode user data: \(error.localizedDescription)")
            }
        }
        
        // 保存任务数据
        do {
            let encoder = JSONEncoder()
            let tasksData = try encoder.encode(tasks)
            UserDefaults.standard.set(tasksData, forKey: "userTasks")
        } catch {
            print("Failed to encode tasks data: \(error.localizedDescription)")
        }
    }
    
    // 创建新用户
    private func createNewUser() {
        let newUser = User(
            id: UUID(),
            username: "User",
            phoneNumber: "",
            password: ""
        )
        currentUser = newUser
        isAuthenticated = true
        saveUserData()
    }
    
    // 设置发布者和订阅
    private func setupPublishers() {
        // 监听任务变化以更新统计信息
        $tasks
            .sink { [weak self] tasks in
                self?.updateStatistics(with: tasks)
            }
            .store(in: &cancellables)
    }
    
    // 任务完成功能
    func completeTask() {
        guard let task = activeTask else { return }
        
        // 将任务标记为完成
        var completedTask = task
        completedTask.completedAt = Date()  // Setting completedAt is enough to mark as completed
        
        // 添加到任务列表
        tasks.append(completedTask)
        
        // 更新成就进度
        updateAchievements(for: completedTask)
        
        // 重置活动任务
        activeTask = nil
        timeRemaining = 0
        
        // 播放成功音效
        playSuccessSound()
        
        // 保存更改
        saveUserData()
    }
    
    // MARK: - Task Management
    
    // 创建新任务
    func createTask(title: String, duration: Int, focusType: Task.FocusType) {
        let newTask = Task(title: title, focusType: focusType, duration: duration, completedAt: nil)
        tasks.append(newTask)
        saveUserData()
    }
    
    // 创建带验证方式的新任务
    func createTaskWithVerification(title: String, duration: Int, focusType: Task.FocusType) {
        let randomVerification = VerificationMethod.random()
        let newTask = Task(
            title: title, 
            focusType: focusType,
            duration: duration, 
            completedAt: nil, 
            verificationMethod: randomVerification
        )
        tasks.append(newTask)
        saveUserData()
    }
    
    // 开始任务
    func startTask(_ task: Task) {
        activeTask = task
        timeRemaining = task.duration * 60 // Convert to seconds
        startTimer()
    }
    
    // 取消任务
    func cancelTask() {
        // 如果当前有活动任务
        if var task = activeTask {
            // 标记任务为已终止
            task.isTerminated = true
            
            // 计算已完成的时间
            let elapsedSeconds = (task.duration * 60) - timeRemaining
            let elapsedMinutes = max(1, Int(ceil(Double(elapsedSeconds) / 60.0)))
            
            // 如果已经完成了一定时间，记录为已完成的任务
            if elapsedMinutes >= 1 {
                task.duration = elapsedMinutes
                task.completedAt = Date()
                tasks.append(task)
                
                // 更新成就进度 - 即使任务被终止，已完成的时间也应该计入成就
                updateAchievements(for: task)
            }
            
            // 重置活动任务和时间
            activeTask = nil
            timeRemaining = 0
            stopTimer()
            
            // 保存更改
            saveUserData()
        } else {
            // 如果没有活动任务，只停止计时器
            stopTimer()
        }
    }
    
    // MARK: - Authentication
    
    // 用户登录
    func signIn(username: String, password: String) {
        // 创建用户对象
        let user = User(
            id: UUID(),
            username: username,
            phoneNumber: "",
            password: password
        )
        
        // 更新用户状态
        currentUser = user
        isAuthenticated = true
        
        // 保存用户数据
        saveUserData()
        
        // 播放成功音效
        playSuccessSound()
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
    }
    
    // 用户登出
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        saveUserData()
        
        // 发送用户登出通知
        NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
    }
    
    // MARK: - 任务状态保存与恢复
    
    // 保存当前运行的任务状态
    func saveActiveTaskState() {
        guard let task = activeTask else { return }
        
        // 保存任务状态
        let taskData = try? JSONEncoder().encode(task)
            UserDefaults.standard.set(taskData, forKey: "activeTask")
            
        // 保存计时器状态
        UserDefaults.standard.set(timeRemaining, forKey: "timeRemaining")
        UserDefaults.standard.set(timerIsRunning, forKey: "timerIsRunning")
            UserDefaults.standard.set(isVerifying, forKey: "isVerifying")
    }
    
    // 尝试恢复之前运行的任务状态
    private func restoreActiveTaskState() {
        // 检查是否有保存的任务
        guard let taskData = UserDefaults.standard.data(forKey: "activeTask"),
              let savedTimeRemaining = UserDefaults.standard.object(forKey: "timeRemaining") as? Int,
              let lastSavedDate = UserDefaults.standard.object(forKey: "lastBackgroundDate") as? Date else {
            return
        }
        
        do {
            // 解码任务数据
            let decoder = JSONDecoder()
            let savedTask = try decoder.decode(Task.self, from: taskData)
            
            // 计算经过的时间并更新剩余时间
            let elapsedTime = Int(Date().timeIntervalSince(lastSavedDate))
            let updatedTimeRemaining = max(0, savedTimeRemaining - elapsedTime)
            
            // 恢复验证状态
            let wasVerifying = UserDefaults.standard.bool(forKey: "isVerifying")
            
            // 如果正在验证或时间已结束需要验证
            if wasVerifying || updatedTimeRemaining == 0 {
                activeTask = savedTask
                timeRemaining = 0
                isVerifying = true
                verificationComplete = UserDefaults.standard.bool(forKey: "verificationComplete")
                
                // 如果没有开始验证，则开始验证
                if !verificationComplete {
                    startVerification()
                }
                
                // 发送通知，通知UI更新到验证界面
                NotificationCenter.default.post(name: NSNotification.Name("VerificationNeeded"), object: nil)
            }
            // 如果还有剩余时间，恢复任务
            else if updatedTimeRemaining > 0 {
                activeTask = savedTask
                timeRemaining = updatedTimeRemaining
                startTimer()
                
                // 发送通知，通知UI更新
                NotificationCenter.default.post(name: NSNotification.Name("TaskRestored"), object: nil)
            }
            
            // 清除保存的状态
            UserDefaults.standard.removeObject(forKey: "activeTask")
            UserDefaults.standard.removeObject(forKey: "timeRemaining")
            UserDefaults.standard.removeObject(forKey: "lastBackgroundDate")
            UserDefaults.standard.removeObject(forKey: "isVerifying")
            UserDefaults.standard.removeObject(forKey: "verificationComplete")
        } catch {
            print("Failed to restore active task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 状态管理
    func resetState() {
        // 停止所有计时器
        timer?.invalidate()
        timer = nil
        verificationTimer?.invalidate()
        verificationTimer = nil
        fallbackSoundTimer?.invalidate()
        fallbackSoundTimer = nil
        backgroundTaskRefreshTimer?.invalidate()
        backgroundTaskRefreshTimer = nil
        
        // 重置所有状态
            timeRemaining = 0
        timerIsRunning = false
            isVerifying = false
            verificationComplete = false
        taskCompletionInProgress = false
        
        // 清理音频资源
        audioPlayer?.stop()
        audioPlayer = nil
        backgroundAudioPlayer?.stop()
        backgroundAudioPlayer = nil
        
        // 重置后台任务
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // 重置活动任务
        if let task = activeTask {
            // 将任务添加到已完成任务列表
            let completedTask = Task(
                title: task.title,
                focusType: task.focusType,
                duration: task.duration,
                completedAt: Date(),
                verificationMethod: task.verificationMethod
            )
            tasks.append(completedTask)
            activeTask = nil
        }
        
        // 重置成就相关状态
        verificationDrawingPrompt = ""
        verificationReadingWords = []
        verificationSongPrompt = "请唱一首你喜欢的歌"
        verificationWordPrompt = "请朗读以下文字：\n\n" + "这是一段示例文字，用于朗读验证。请清晰地读出每个字，保持适当的语速和语调。"
    }
    
    // 结束后台任务
    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

// MARK: - 成就系统扩展
extension AppViewModel {
    // 已解锁的成就总数
    var unlockedAchievementsCount: Int {
        var count = 0
        for type in AchievementType.allCases {
            if achievementLevel(for: type) > 0 {
                count += 1
            }
        }
        return count
    }
    
    // 成就总数
    var totalAchievements: Int {
        return AchievementType.allCases.count * 6
    }
    
    // 成就完成百分比
    var achievementCompletionPercentage: Double {
        var totalPercentage: Double = 0
        
        for type in AchievementType.allCases {
            let level = achievementLevel(for: type)
            let maxLevel = 6 // 最高为6级
            
            // 当前等级占总等级的比例
            let levelPercentage = Double(level) / Double(maxLevel)
            totalPercentage += levelPercentage
        }
        
        // 平均百分比
        return totalPercentage / Double(AchievementType.allCases.count) * 100
    }
    
    // 获取特定类型已解锁的成就数量
    func unlockedAchievements(for type: AchievementType) -> Int {
        return achievementLevel(for: type)
    }
    
    // 获取特定类型的成就完成百分比
    func achievementCompletion(for type: AchievementType) -> Double {
        let level = achievementLevel(for: type)
        let maxLevel = 6 // 最高为6级
        
        return Double(level) / Double(maxLevel) * 100
    }
    
    // 最近解锁的成就
    var recentAchievements: [RecentAchievement] {
        // 模拟数据 - 实际应用中应从数据源获取
        var achievements: [RecentAchievement] = []
        
        // 生成一些随机的最近成就
        let types = AchievementType.allCases.shuffled().prefix(3)
        let today = Date()
        let calendar = Calendar.current
        
        for (index, type) in types.enumerated() {
            if let date = calendar.date(byAdding: .day, value: -index, to: today) {
                let level = Int.random(in: 1...5)
                achievements.append(RecentAchievement(type: type, level: level, date: date))
            }
        }
        
        return achievements
    }
}

// 最近解锁的成就模型
struct RecentAchievement: Hashable {
    let type: AchievementType
    let level: Int
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(level)
        hasher.combine(date)
    }
    
    static func == (lhs: RecentAchievement, rhs: RecentAchievement) -> Bool {
        return lhs.type == rhs.type && lhs.level == rhs.level && lhs.date == rhs.date
    }
} 

// MARK: - Notification Names
extension NSNotification.Name {
    static let alarmStopped = NSNotification.Name("AlarmStopped")
    static let verificationNeeded = NSNotification.Name("VerificationNeeded")
    static let taskRestored = NSNotification.Name("TaskRestored")
    static let achievementUnlocked = NSNotification.Name("AchievementUnlocked")
    static let userLevelUp = NSNotification.Name("UserLevelUp")
    static let userDidSignIn = NSNotification.Name("UserDidSignIn")
    static let userDidSignOut = NSNotification.Name("UserDidSignOut")
} 
