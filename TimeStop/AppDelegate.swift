import UIKit
import BackgroundTasks
import UserNotifications
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // 添加应用状态跟踪
    private var isHandlingNotification = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 检查是否异常退出并执行清理
        checkForAbnormalTermination()
        
        // 配置音频会话
        configureAudioSession()
        
        // 在应用启动时注册后台任务
        registerBackgroundTasks()
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 标记应用启动正常
        UserDefaults.standard.set(true, forKey: "appIsRunning")
        
        // 设置崩溃检测心跳
        startHeartbeatTimer()
        
        return true
    }
    
    // 检查应用是否异常退出
    private func checkForAbnormalTermination() {
        if UserDefaults.standard.bool(forKey: "appIsRunning") {
            // 应用之前未正常退出
            print("检测到应用异常退出，执行清理...")
            
            // 立即清理所有音频和震动
            AudioService.shared.emergencyCleanup()
            
            // 重置任何需要的状态
            AppViewModel.shared.resetState()
        }
    }
    
    // 设置心跳计时器用于检测崩溃
    private func startHeartbeatTimer() {
        // 每15秒更新一次心跳时间戳
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            UserDefaults.standard.set(Date(), forKey: "lastHeartbeat")
        }
    }
    
    // 配置音频会话
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 设置音频会话类别
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            
            // 激活音频会话
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // 添加中断监听
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )
        } catch {
            print("配置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 中断开始，停止所有音频
            AudioService.shared.emergencyCleanup()
        case .ended:
            // 中断结束，尝试恢复音频会话
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("恢复音频会话失败: \(error.localizedDescription)")
            }
        @unknown default:
            break
        }
    }
    
    // 注册后台任务
    private func registerBackgroundTasks() {
        // 确保后台任务已经注册
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.timestop.apprefresh",
            using: nil
        ) { task in
            self.handleBackgroundTask(task)
        }
    }
    
    // 处理后台任务
    private func handleBackgroundTask(_ task: BGTask) {
        // 确保在任务到期前尽可能完成任务
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // 根据不同类型的任务执行不同的操作
        if let appRefreshTask = task as? BGAppRefreshTask {
            // 执行应用刷新任务
            performAppRefresh {
                appRefreshTask.setTaskCompleted(success: true)
            }
        } else if let processingTask = task as? BGProcessingTask {
            // 执行处理任务
            performBackgroundProcessing {
                processingTask.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: false)
        }
    }
    
    // 执行应用刷新任务
    private func performAppRefresh(completion: @escaping () -> Void) {
        // 执行轻量级的后台刷新任务
        DispatchQueue.global().async {
            // 执行任何需要的后台更新
            completion()
        }
    }
    
    // 执行后台处理任务
    private func performBackgroundProcessing(completion: @escaping () -> Void) {
        // 执行更密集的后台处理任务
        DispatchQueue.global().async {
            // 执行任何需要的密集型处理
            completion()
        }
    }
    
    // 应用进入前台时调用
    func applicationWillEnterForeground(_ application: UIApplication) {
        // 重置通知处理标志
        isHandlingNotification = false
        
        // 检查是否需要恢复任务
        if AppViewModel.shared.isVerifying {
            // 重置验证状态
            AppViewModel.shared.resetState()
            AppViewModel.shared.isVerifying = true
            
            // 发送验证通知
            NotificationCenter.default.post(name: NSNotification.Name("VerificationNeeded"), object: nil)
        } else if AppViewModel.shared.timerIsRunning {
            // 重置计时器状态
            AppViewModel.shared.resetState()
            AppViewModel.shared.timerIsRunning = true
            
            // 发送任务恢复通知
            NotificationCenter.default.post(name: NSNotification.Name("TaskRestored"), object: nil)
        }
    }
    
    // 应用进入后台时调用
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 保存当前应用状态
        AppViewModel.shared.saveActiveTaskState()
        
        // 应用进入后台时的处理
        scheduleBackgroundTasks()
    }
    
    // 应用即将终止时调用
    func applicationWillTerminate(_ application: UIApplication) {
        // 标记应用正常退出
        UserDefaults.standard.set(false, forKey: "appIsRunning")
        
        // 尝试最后一次保存任务状态
        AppViewModel.shared.saveActiveTaskState()
        
        // 清理所有音频资源
        AudioService.shared.emergencyCleanup()
    }
    
    // 调度后台任务
    private func scheduleBackgroundTasks() {
        // 调度应用刷新任务
        let appRefreshRequest = BGAppRefreshTaskRequest(identifier: "com.timestop.apprefresh")
        appRefreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分钟后执行
        
        do {
            try BGTaskScheduler.shared.submit(appRefreshRequest)
        } catch {
            print("无法调度应用刷新任务: \(error)")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 处理前台通知展示
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 处理通知响应（包括从锁屏或通知中心点击通知）
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // 防止重复处理
        if isHandlingNotification {
            completionHandler()
            return
        }
        
        isHandlingNotification = true
        
        // 立即停止所有声音和震动
        AudioService.shared.emergencyCleanup()
        
        // 使用 DispatchGroup 确保所有操作完成后才调用 completionHandler
        let group = DispatchGroup()
        
        let identifier = response.notification.request.identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        if identifier == "timerCompletion" || identifier == "immediateCompletion" {
            group.enter()
            
            // 确保在主线程执行UI操作
            DispatchQueue.main.async {
                // 重置所有状态
                AppViewModel.shared.resetState()
                
                // 准备导航
                NotificationCenter.default.post(name: NSNotification.Name("PrepareForTaskNavigation"), object: nil)
                
                // 延迟执行以确保UI更新完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 发送任务完成通知
                    NotificationCenter.default.post(name: NSNotification.Name("TaskCompleted"), object: nil)
                    
                    // 标记任务完成
                    AppViewModel.shared.taskCompletionInProgress = true
                    
                    group.leave()
                }
            }
        } else if categoryIdentifier == "TASK_REMINDER" {
            group.enter()
            
            if response.actionIdentifier == "COMPLETE_TASK" {
                // 用户选择"完成任务"操作
                NotificationCenter.default.post(name: NSNotification.Name("CompleteTaskFromNotification"), object: nil)
            } else if response.actionIdentifier == "CANCEL_TASK" {
                // 用户选择"取消任务"操作
                NotificationCenter.default.post(name: NSNotification.Name("CancelTaskFromNotification"), object: nil)
            } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                // 用户直接点击通知（默认操作）
                NotificationCenter.default.post(name: NSNotification.Name("ReturnToActiveTask"), object: nil)
            }
            
            group.leave()
        }
        
        // 设置超时保护
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if self.isHandlingNotification {
                self.isHandlingNotification = false
                completionHandler()
            }
        }
        
        // 等待所有操作完成
        group.notify(queue: .main) {
            self.isHandlingNotification = false
            completionHandler()
        }
    }
} 