import SwiftUI
import UserNotifications

class AchievementNotificationManager: ObservableObject {
    static let shared = AchievementNotificationManager()
    
    @Published var showNotification = false
    @Published var currentAchievement: (type: AchievementType, level: Int)? = nil
    
    private init() {
        requestNotificationPermission()
    }
    
    // 请求通知权限
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限已授权")
            } else if let error = error {
                print("通知权限请求错误: \(error.localizedDescription)")
            }
        }
    }
    
    // 显示成就解锁通知
    func showAchievementUnlocked(type: AchievementType, level: Int) {
        // 更新当前成就
        currentAchievement = (type, level)
        
        // 显示应用内通知
        showNotification = true
        
        // 发送系统通知
        let content = UNMutableNotificationContent()
        content.title = "成就解锁！"
        content.body = "恭喜你解锁了\(type.name)的\(type.levelDescription(level))成就"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 成就解锁通知视图
    struct AchievementUnlockView: View {
        @ObservedObject var manager = AchievementNotificationManager.shared
        @EnvironmentObject var themeManager: ThemeManager
        
        var body: some View {
            if let achievement = manager.currentAchievement {
                VStack(spacing: 15) {
                    // 成就图标
                    ZStack {
                        Circle()
                            .fill(themeManager.colors.primary)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: achievement.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    // 成就信息
                    VStack(spacing: 5) {
                        Text("成就解锁！")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("\(achievement.type.name) - \(achievement.type.levelDescription(achievement.level))")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                .padding()
                .background(themeManager.colors.cardBackground)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: manager.showNotification)
            }
        }
    }
} 