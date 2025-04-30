import Foundation
import AVFoundation
import AudioToolbox
import UIKit
import MediaPlayer

/// 音频服务类 - 用于处理应用中的声音和震动
class AudioService {
    static let shared = AudioService()
    
    // MARK: - 属性
    private var audioSession: AVAudioSession
    private var audioPlayer: AVAudioPlayer?
    private var soundTimer: Timer?
    
    // 添加锁确保线程安全
    private let lock = NSLock()
    
    // 标记音频是否正在播放
    private var isPlayingAudio = false
    private var isVibrating = false
    
    // 音频会话配置选项
    enum AudioSessionOptions {
        case background    // 后台运行用的静音播放
        case alarm         // 闹钟模式，绕过静音开关
        case recording     // 录音模式
    }
    
    // 设备静音状态
    enum DeviceSoundSettings {
        case normal        // 正常模式 - 声音和震动都正常
        case silentWithVibration // 静音但允许震动
        case silentNoVibration  // 静音且禁止震动
    }
    
    // MARK: - 初始化
    private init() {
        audioSession = AVAudioSession.sharedInstance()
        setupAudioSession(option: .background)
        setupNotifications()
    }
    
    // 设置通知监听
    private func setupNotifications() {
        // 监听音频会话中断
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // 监听音频会话路由改变
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用即将终止
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    // 处理音频会话中断
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            // 音频会话被中断（如来电），停止所有音频
            stopAudioPlayback()
            stopRepeatingAlarm()
        } else if type == .ended {
            // 中断结束
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // 如果应该恢复播放，可以在这里处理
                    // 但针对闹钟类应用，通常不会自动恢复，而是由用户重新触发
                }
            }
        }
    }
    
    // 处理音频路由改变
    @objc private func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        // 当音频路由发生变化时（如拔出耳机），确保音频配置仍然正确
        if reason == .oldDeviceUnavailable {
            // 旧设备不可用（如耳机被拔出）
            if isPlayingAudio {
                // 重新配置音频会话以确保音频继续播放
                setupAudioSession(option: .alarm)
            }
        }
    }
    
    // 处理应用进入后台
    @objc private func handleAppDidEnterBackground(notification: Notification) {
        // 应用进入后台时，如果不需要继续播放音频，可以释放音频资源
        if !isPlayingAudio && !isVibrating {
            prepareForBackground()
        }
    }
    
    // 处理应用即将终止
    @objc private func handleAppWillTerminate(notification: Notification) {
        // 应用即将终止时，执行紧急清理
        emergencyCleanup()
    }
    
    // MARK: - 音频会话配置
    /// 配置音频会话
    /// - Parameter option: 音频会话配置选项
    func setupAudioSession(option: AudioSessionOptions) {
        lock.lock()
        defer { lock.unlock() }
        
        do {
            switch option {
            case .background:
                // 后台播放模式 - 允许混音，但会降低其他音频音量
                try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            case .alarm:
                // 闹钟模式 - 即使在静音模式下也会播放
                try audioSession.setCategory(.playback, mode: .default, options: [])
            case .recording:
                // 录音模式 - 允许录音和播放
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            }
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("配置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    // 为后台做准备
    func prepareForBackground() {
        lock.lock()
        defer { lock.unlock() }
        
        // 如果没有活动的音频或振动，可以释放音频会话
        if !isPlayingAudio && !isVibrating {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("停用音频会话失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 紧急清理
    /// 紧急清理所有音频和振动资源
    /// 在应用崩溃、异常退出或需要立即停止所有声音时调用
    func emergencyCleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        print("执行紧急音频清理...")
        
        // 标记状态
        isPlayingAudio = false
        isVibrating = false
        
        // 停止计时器
        soundTimer?.invalidate()
        soundTimer = nil
        
        // 停止音频播放
        if let player = audioPlayer {
            player.stop()
            audioPlayer = nil
        }
        
        // 停止系统声音
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
        
        // 尝试停用音频会话
        do {
            try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
            
            // 短暂延迟后重新激活会话以重置状态
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                do {
                    try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("重新激活音频会话失败: \(error)")
                }
            }
        } catch {
            print("紧急停用音频会话失败: \(error)")
            
            // 如果常规方法失败，尝试更激进的方法
            // 使用系统声音服务清理
            AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate)
            
            // 尝试强制停止所有声音播放
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                try audioSession.setCategory(.ambient, mode: .default)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("紧急音频重置失败: \(error)")
            }
        }
    }
    
    // MARK: - 音频播放控制
    /// 播放铃声 - 即使在静音模式下也会播放
    /// - Parameters:
    ///   - soundID: 系统声音ID
    ///   - vibrate: 是否同时震动
    func playAlarmSound(soundID: SystemSoundID, vibrate: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        // 检测设备当前的声音和震动设置
        let deviceSoundSettings = detectDeviceSoundSettings()
        
        // 配置为闹钟模式
        setupAudioSession(option: .alarm)
        
        // 根据设备设置和用户需求确定是否播放声音
        switch deviceSoundSettings {
        case .normal:
            // 正常模式 - 播放声音，根据需要震动
            isPlayingAudio = true
            AudioServicesPlaySystemSound(soundID)
            if vibrate {
                isVibrating = true
                vibrateDevice()
            }
            
        case .silentWithVibration:
            // 静音但允许震动 - 尝试播放声音（因为是闹钟类应用），同时触发震动
            isPlayingAudio = true
            AudioServicesPlaySystemSound(soundID)
            isVibrating = true
            vibrateDevice() // 总是震动，即使用户未要求
            
        case .silentNoVibration:
            // 静音且禁止震动 - 不播放声音，但仍然震动（要求倒计时必须有提醒）
            isVibrating = true
            vibrateDevice() // 即使设置禁止震动，也尝试触发震动
        }
    }
    
    /// 开始播放循环铃声 - 用于闹钟，每隔指定时间播放一次
    /// - Parameters:
    ///   - soundID: 系统声音ID
    ///   - interval: 重复间隔（秒）
    ///   - vibrate: 是否同时震动
    func startRepeatingAlarm(soundID: SystemSoundID, interval: TimeInterval, vibrate: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        // 停止之前可能存在的计时器
        stopRepeatingAlarm()
        
        // 确保以闹钟模式激活音频会话
        setupAudioSession(option: .alarm)
        
        // 检测设备当前的声音和震动设置
        let deviceSoundSettings = detectDeviceSoundSettings()
        
        // 根据设备设置决定行为
        var shouldPlaySound = true
        var shouldVibrate = vibrate
        
        switch deviceSoundSettings {
        case .normal:
            // 正常模式 - 使用用户设置
            shouldPlaySound = true
            shouldVibrate = vibrate
            
        case .silentWithVibration:
            // 静音但允许震动 - 尝试播放声音（闹钟类应用），总是震动
            shouldPlaySound = true
            shouldVibrate = true
            
        case .silentNoVibration:
            // 静音且禁止震动 - 不播放声音，但仍然尝试震动
            shouldPlaySound = false
            shouldVibrate = true
        }
        
        // 更新状态标记
        isPlayingAudio = shouldPlaySound
        isVibrating = shouldVibrate
        
        // 立即执行一次
        if shouldPlaySound {
            AudioServicesPlaySystemSound(soundID)
        }
        
        if shouldVibrate {
            vibrateDevice()
        }
        
        // 设置循环计时器
        soundTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if shouldPlaySound {
                AudioServicesPlaySystemSound(soundID)
            }
            
            if shouldVibrate {
                self.vibrateDevice()
            }
        }
        
        // 确保计时器被添加到主运行循环
        if let timer = soundTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    /// 停止循环铃声
    func stopRepeatingAlarm() {
        lock.lock()
        defer { lock.unlock() }
        
        // 更新状态标记
        isPlayingAudio = false
        isVibrating = false
        
        soundTimer?.invalidate()
        soundTimer = nil
        
        // 重置音频会话
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // 短暂延迟后重新激活会话以正常工作
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
                do {
                    try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("重新激活音频会话失败: \(error)")
                }
            }
        } catch {
            print("停用音频会话失败: \(error.localizedDescription)")
        }
    }
    
    /// 播放音频文件（循环播放）
    /// - Parameters:
    ///   - fileURL: 音频文件URL
    ///   - looping: 是否循环播放
    ///   - vibrate: 是否同时震动
    func playAudioFile(fileURL: URL, looping: Bool = false, vibrate: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        
        // 检测设备当前的声音和震动设置
        let deviceSoundSettings = detectDeviceSoundSettings()
        
        // 配置为闹钟模式
        setupAudioSession(option: .alarm)
        
        // 根据设备设置决定行为
        var shouldPlaySound = true
        var shouldVibrate = vibrate
        
        switch deviceSoundSettings {
        case .normal:
            // 正常模式 - 使用用户设置
            shouldPlaySound = true
            shouldVibrate = vibrate
            
        case .silentWithVibration:
            // 静音但允许震动 - 尝试播放声音（闹钟类应用），总是震动
            shouldPlaySound = true
            shouldVibrate = true
            
        case .silentNoVibration:
            // 静音且禁止震动 - 不播放声音，但仍然尝试震动
            shouldPlaySound = false
            shouldVibrate = true
        }
        
        // 更新状态标记
        isPlayingAudio = shouldPlaySound
        isVibrating = shouldVibrate
        
        if shouldPlaySound {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.numberOfLoops = looping ? -1 : 0
                audioPlayer?.volume = 1.0
                audioPlayer?.play()
            } catch {
                print("播放音频文件失败: \(error.localizedDescription)")
                isPlayingAudio = false
            }
        }
        
        if shouldVibrate {
            vibrateDevice()
        }
    }
    
    /// 停止音频播放
    func stopAudioPlayback() {
        lock.lock()
        defer { lock.unlock() }
        
        // 更新状态标记
        isPlayingAudio = false
        
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - 震动控制
    /// 触发设备震动 - 即使在静音+禁止震动模式下也会尝试震动
    func vibrateDevice() {
        // 使用AudioServicesPlaySystemSound触发系统震动 - 即使在设置中禁用了震动也能工作
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // 使用更现代的震动API提供更好的触觉反馈
        let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
        heavyGenerator.impactOccurred()
        
        // 延迟短暂时间后使用中等强度震动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            mediumGenerator.impactOccurred()
        }
        
        // 使用通知类型震动提供错误反馈
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - 设备状态检测
    /// 检测设备当前的声音和震动设置
    /// - Returns: 设备声音设置状态
    func detectDeviceSoundSettings() -> DeviceSoundSettings {
        // 获取当前系统音量
        let currentVolume = AVAudioSession.sharedInstance().outputVolume
        
        // 判断设备是否可能处于静音状态
        // 由于iOS不提供直接API检测静音开关状态，这里使用音量作为间接判断
        // 这不是100%准确的方法，但是在大多数情况下可以工作
        
        if currentVolume < 0.05 {
            // 音量非常低，可能处于静音状态
            // 尝试检测震动状态 - 但iOS也没有提供直接API检测震动开关
            // 在这里我们假设如果设备是iPhone且处于静音模式，默认允许震动
            // 这是符合大多数用户习惯的假设
            
            // 检查是否是iPad - iPad没有震动硬件
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            
            if isIPad {
                return .silentNoVibration
            } else {
                // 假设iPhone默认允许震动，除非明确指示禁用
                // 由于没有直接API检测，我们随时准备尝试震动
                return .silentWithVibration
            }
        } else {
            // 音量正常，假设设备处于正常模式
            return .normal
        }
    }
} 