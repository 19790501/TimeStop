import Foundation
import SwiftUI
import Combine
import AVFoundation
import UserNotifications
import AudioToolbox

class AppViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var tasks: [Task] = []
    @Published var activeTask: Task?
    @Published var timeRemaining: Int = 0
    @Published var timerIsRunning: Bool = false
    @Published var statistics: Statistics = Statistics()
    
    // 声音设置
    @Published var soundEnabled: Bool = true // 默认开启按钮音效
    
    // 振动设置
    @Published var vibrationEnabled: Bool = true // 默认开启振动
    
    // 验证任务相关
    @Published var isVerifying: Bool = false
    @Published var verificationComplete: Bool = false
    @Published var verificationDrawingPrompt: String = ""
    @Published var verificationReadingWords: [String] = []
    
    // 声音和震动
    private var audioPlayer: AVAudioPlayer?
    private var verificationTimer: Timer?
    
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
        static let fallbackSoundInterval: TimeInterval = 2.0
        
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
    }
    
    init() {
        // Load user data from storage
        loadUserData()
        
        // 添加测试数据用于展示统计功能
        if tasks.isEmpty {
            addDemoTasks()
        }
        
        // Setup publishers
        setupPublishers()
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
        
        // Set up notification categories and actions
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
    
    func setNavigationManager(_ manager: NavigationManager) {
        self.navigationManager = manager
    }
    
    private func setupPublishers() {
        // Monitor changes to tasks and update statistics
        $tasks
            .sink { [weak self] tasks in
                self?.updateStatistics(with: tasks)
                self?.saveUserData()
            }
            .store(in: &cancellables)
    }
    
    func loadUserData() {
        // Create a centralized error logger
        let logError = { (error: Error, operation: String) in
            print("I/O Error: \(operation) - \(error.localizedDescription)")
            
            // In a production app, we might want to log this to an analytics service
            // analyticsService.logError(error, context: operation)
            
            // Optionally notify the user about the error
            NotificationCenter.default.post(
                name: NSNotification.Name("DataOperationError"),
                object: nil,
                userInfo: ["error": error, "operation": operation]
            )
        }
        
        // Simulate loading user data from UserDefaults or other storage
        do {
        if let savedUser = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let decoder = JSONDecoder()
                currentUser = try decoder.decode(User.self, from: savedUser)
                isAuthenticated = currentUser != nil
            } catch {
                    logError(error, "decoding user data")
                    
                    // Attempt data recovery
                    if let backupPath = getBackupPath(for: "currentUser"),
                       let backupData = try? Data(contentsOf: backupPath) {
                        do {
                            currentUser = try JSONDecoder().decode(User.self, from: backupData)
                            isAuthenticated = currentUser != nil
                            print("Successfully recovered user data from backup")
                        } catch {
                            logError(error, "recovering user data from backup")
                        }
                    }
            }
        }
        
        // Load tasks
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks") {
            do {
                let decoder = JSONDecoder()
                tasks = try decoder.decode([Task].self, from: savedTasks)
            } catch {
                    logError(error, "decoding tasks data")
                    
                    // Attempt data recovery
                    if let backupPath = getBackupPath(for: "tasks"),
                       let backupData = try? Data(contentsOf: backupPath) {
                        do {
                            tasks = try JSONDecoder().decode([Task].self, from: backupData)
                            print("Successfully recovered tasks data from backup")
                        } catch {
                            logError(error, "recovering tasks data from backup")
                        }
                    }
            }
        }
        
            // Load sound settings with validation
            if let soundEnabledValue = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool {
                soundEnabled = soundEnabledValue
            } else {
                // Set default and log the issue
                soundEnabled = true
                print("Sound setting not found, using default value")
            }
        
            // Load vibration settings with validation
            if let vibrationEnabledValue = UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool {
                vibrationEnabled = vibrationEnabledValue
            } else {
                // Set default and log the issue
                vibrationEnabled = true
                print("Vibration setting not found, using default value")
            }
        } catch {
            logError(error, "general data loading")
        }
        
        updateStatistics(with: tasks)
    }
    
    func saveUserData() {
        // Create a centralized error logger
        let logError = { (error: Error, operation: String) in
            print("I/O Error: \(operation) - \(error.localizedDescription)")
            
            // In a production app, we might want to log this to an analytics service
            // analyticsService.logError(error, context: operation)
            
            // Optionally notify the user about the error
            NotificationCenter.default.post(
                name: NSNotification.Name("DataOperationError"),
                object: nil,
                userInfo: ["error": error, "operation": operation]
            )
        }
        
        // Save user data
        if let currentUser = currentUser {
            do {
                let encoder = JSONEncoder()
                let userData = try encoder.encode(currentUser)
                
                // Create backup of current data before overwriting
                if let existingData = UserDefaults.standard.data(forKey: "currentUser") {
                    createBackup(data: existingData, for: "currentUser")
                }
                
                UserDefaults.standard.set(userData, forKey: "currentUser")
                
                // Verify the data was saved correctly
                if UserDefaults.standard.data(forKey: "currentUser") == nil {
                    throw NSError(domain: "com.timestop.usersaving", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to verify user data was saved"])
                }
            } catch {
                logError(error, "encoding and saving user data")
            }
        }
        
        // Save tasks
        do {
            let encoder = JSONEncoder()
            let tasksData = try encoder.encode(tasks)
            
            // Create backup of current data before overwriting
            if let existingData = UserDefaults.standard.data(forKey: "tasks") {
                createBackup(data: existingData, for: "tasks")
            }
            
            UserDefaults.standard.set(tasksData, forKey: "tasks")
            
            // Verify the data was saved correctly
            if UserDefaults.standard.data(forKey: "tasks") == nil {
                throw NSError(domain: "com.timestop.taskssaving", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to verify tasks data was saved"])
            }
        } catch {
            logError(error, "encoding and saving tasks data")
        }
        
        // Force UserDefaults to save to disk
        UserDefaults.standard.synchronize()
    }
    
    // Helper function to create backup of data
    private func createBackup(data: Data, for key: String) {
        do {
            let backupPath = getBackupPath(for: key)
            try data.write(to: backupPath)
        } catch {
            print("Failed to create backup for \(key): \(error)")
        }
    }
    
    // Helper function to get backup file path
    private func getBackupPath(for key: String) -> URL? {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectory.appendingPathComponent("\(key)_backup.json")
        } catch {
            print("Failed to get backup path for \(key): \(error)")
            return nil
        }
    }
    
    // MARK: - Authentication
    
    func signIn(username: String, password: String) {
        // 模拟登录成功
        let user = User(username: username, phoneNumber: "", password: password)
        currentUser = user
        isAuthenticated = true
        saveUserData()
        
        // 发送登录成功通知
        NotificationCenter.default.post(name: NSNotification.Name("UserDidSignIn"), object: nil)
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        saveUserData()
        
        // 发送用户登出通知
        NotificationCenter.default.post(name: NSNotification.Name("UserDidSignOut"), object: nil)
    }
    
    // MARK: - Task Management
    
    func createTask(title: String, duration: Int, focusType: Task.FocusType) {
        let newTask = Task(title: title, focusType: focusType, duration: duration, completedAt: nil)
        tasks.append(newTask)
        saveUserData()
    }
    
    // 新增支持随机验证方式的任务创建方法
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
    
    func startTask(_ task: Task) {
        activeTask = task
        timeRemaining = task.duration * 60 // Convert to seconds
        startTimer()
    }
    
    func completeTask() {
        guard let task = activeTask else { return }
        
        // 更新任务状态
        var completedTask = task
        completedTask.completedAt = Date()
        tasks.append(completedTask)
        
        // 更新用户数据
        if var user = currentUser {
            user.completedTasks += 1
            user.totalFocusTime += task.duration
            user.experience += task.duration / 5
            
            // 检查是否需要升级
            if user.experience >= user.level * 100 {
                user.level += 1
                // 显示升级提示或动画
            }
            
            currentUser = user
        }
        
        // 停止计时器
        stopTimer()
        
        // 清除当前任务
        activeTask = nil
        
        // 保存数据
        saveUserData()
        
        // 发送任务完成通知
        NotificationCenter.default.post(name: NSNotification.Name("TaskDidComplete"), object: task)
    }
    
    func cancelTask() {
        stopTimer()
        activeTask = nil
        timeRemaining = 0
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        timerIsRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.timeRemaining > 0 else {
                // 时间结束，开始发出声音和震动
                self?.startVerification()
                self?.stopTimer()
                return
            }
            
            self.timeRemaining -= 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerIsRunning = false
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
        
        // 如果任务存在，更新其持续时间
        if var task = activeTask {
            task.duration = max(0, task.duration + minutes)
            activeTask = task
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
        
        isVerifying = true
        verificationComplete = false
        
        // 启动提示声音和震动
        startVerificationAlert()
        
        // 根据验证方法准备相应的内容
        switch method {
        case .drawing:
            // 随机选择一个绘画提示
            verificationDrawingPrompt = drawingPrompts.randomElement() ?? "树"
            
        case .reading:
            // 随机选择两个单词
            let selectedWords = Array(readingWords.shuffled().prefix(2))
            verificationReadingWords = selectedWords.map { $0.0 }
            
        case .singing:
            // 唱歌模式不需要特殊准备
            break
        }
    }
    
    // 验证任务完成
    func completeVerification() {
        // 立即停止所有警报声音和震动 - 这是最高优先级的操作
        stopVerificationAlert()
        
        // 批量更新状态，避免多次触发UI更新
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 立即更新状态标志
            self.verificationComplete = true
            self.isVerifying = false
            
            // 使用高优先级后台队列处理任务完成逻辑
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // 在后台准备任务完成所需的数据
                
                // 返回主线程更新UI
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
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
        }
    }
    
    // 取消验证
    func cancelVerification() {
        isVerifying = false
        verificationComplete = false
        verificationDrawingPrompt = ""
        verificationReadingWords = []
    }
    
    // 重置验证状态
    func resetVerificationState() {
        verificationComplete = false
        verificationDrawingPrompt = ""
        verificationReadingWords = []
    }
    
    // 启动声音和振动提醒
    private func startVerificationAlert() {
        // 播放提示音（如果声音已启用）
        if soundEnabled {
            playIntenseAlertSound()
        }
        
        // 设置振动定时器（如果振动已启用）
        if vibrationEnabled {
            verificationTimer = Timer.scheduledTimer(withTimeInterval: Constants.vibrationRepeatInterval, repeats: true) { [weak self] _ in
                self?.vibrateIntensely()
            }
            
            // 立即振动一次
            vibrateIntensely()
        }
        
        // 如果既没有声音也没有振动，至少显示一个视觉提示
        if !soundEnabled && !vibrationEnabled {
            // 在UI上显示一个明显的提示（这部分需要在UI层实现）
            isVerifying = true // 确保验证状态被标记为活跃，这样UI可以显示相应的提示
        }
    }
    
    // 停止声音和振动提醒 - 优化性能
    func stopVerificationAlert() {
        // 为了确保这个函数立即执行，我们使用最高优先级
        
        // 停止音频播放
        if let player = audioPlayer {
            player.stop()
            audioPlayer = nil
        }
        
        // 停止振动定时器
        if let timer = verificationTimer {
            timer.invalidate()
            verificationTimer = nil
        }
        
        // 停止备用声音计时器
        if let timer = fallbackSoundTimer {
            timer.invalidate()
            fallbackSoundTimer = nil
        }
        
        // 停止可能存在的系统声音计时器
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // 在后台处理可能耗时的音频会话操作
        DispatchQueue.global(qos: .userInitiated).async {
            // 中断所有可能的声音播放
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Could not reset audio session: \(error)")
            }
        }
    }
    
    // 播放更激烈的声音
    private func playIntenseAlertSound() {
        // 在soundEnabled为false时，仅执行振动而不播放声音
        if !soundEnabled {
            // 还是需要振动提醒，但不播放声音
            return
        }
        
        guard let soundURL = Bundle.main.url(forResource: "intense_alert", withExtension: "mp3") else {
            // 如果找不到指定的声音文件，尝试使用系统声音
            let systemSoundID: SystemSoundID = 1005 // 系统警报声音
            AudioServicesPlaySystemSound(systemSoundID)
            
            // 使用备用方法播放连续声音
            playFallbackAlertSound()
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // 循环播放
            audioPlayer?.volume = 1.0 // 最大音量
            audioPlayer?.play()
        } catch {
            print("Could not play sound file: \(error)")
            // 如果播放失败，使用备用方法
            playFallbackAlertSound()
        }
    }
    
    // 备用警报声音播放方法
    private func playFallbackAlertSound() {
        // 在soundEnabled为false时不播放声音
        if !soundEnabled {
            return
        }
        
        // 确保之前的计时器被停止
        fallbackSoundTimer?.invalidate()
        
        // 创建计时器，每2秒播放一次系统声音
        fallbackSoundTimer = Timer.scheduledTimer(withTimeInterval: Constants.fallbackSoundInterval, repeats: true) { [weak self] timer in
            // 检查音效设置可能在播放期间发生变化
            guard let self = self, self.soundEnabled else {
                timer.invalidate()
                return
            }
            
            AudioServicesPlaySystemSound(Constants.alertSound) // 系统警报声音
        }
    }
    
    // 触发更强烈的振动
    private func vibrateIntensely() {
        // 检查振动设置是否开启
        guard vibrationEnabled else { return }
        
        // 使用更强烈的震动模式
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyGenerator.impactOccurred()
        
        // 连续震动以增强效果
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.vibrationInterval) { [weak self] in
            guard self != nil else { return }
            let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            mediumGenerator.impactOccurred()
        }
        
        // 使用通知反馈类型
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error) // 使用错误类型的震动
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
    
    // 重置并添加测试数据
    func resetWithTestData() {
        // 清除当前任务数据
        tasks.removeAll()
        
        // 添加测试数据
        addDemoTasks()
        
        // 更新统计信息
        updateStatistics(with: tasks)
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
        var typeToUpdate: AchievementType
        
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

// MARK: - 成就系统测试扩展
extension AppViewModel {
    // 用于测试的成就更新方法
    func updateAchievementForTest(type: AchievementType, minutes: Int) {
        guard var user = currentUser else { return }
        
        // 查找是否已存在此类成就
        if let index = user.achievements.firstIndex(where: { $0.typeIdentifier == type.rawValue }) {
            // 更新已有成就的分钟数
            user.achievements[index].minutes = minutes
            
            // 计算解锁的等级
            let level = type.achievementLevel(for: minutes)
            let unlockedLevels = Array(1...level)
            user.achievements[index].unlockedLevels = unlockedLevels
        } else {
            // 创建新成就
            let level = type.achievementLevel(for: minutes)
            let newAchievement = Achievement(
                typeIdentifier: type.rawValue,
                minutes: minutes,
                unlockedLevels: Array(1...max(1, level))
            )
            user.achievements.append(newAchievement)
        }
        
        currentUser = user
        isAuthenticated = true
        saveUserData()
    }
    
    // 获取特定类型成就的累计分钟数
    func achievementMinutes(for type: AchievementType) -> Int {
        guard let user = currentUser else { return 0 }
        
        if let achievement = user.achievements.first(where: { $0.typeIdentifier == type.rawValue }) {
            return achievement.minutes
        }
        
        return 0
    }
} 