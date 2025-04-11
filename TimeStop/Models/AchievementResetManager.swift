import Foundation
import SwiftUI

class AchievementResetManager {
    static let shared = AchievementResetManager()
    
    private let lastResetKey = "lastAchievementResetDate"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // 检查是否需要重置，如果需要则执行重置并返回true
    func checkAndResetIfNeeded() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取上次重置日期
        if let lastResetDate = userDefaults.object(forKey: lastResetKey) as? Date {
            // 检查是否到了新的一周
            let lastWeek = calendar.component(.weekOfYear, from: lastResetDate)
            let currentWeek = calendar.component(.weekOfYear, from: now)
            
            let lastYear = calendar.component(.year, from: lastResetDate)
            let currentYear = calendar.component(.year, from: now)
            
            // 如果周数或年份变化，需要重置
            if lastWeek != currentWeek || lastYear != currentYear {
                resetAchievements()
                updateLastResetDate()
                return true
            }
            return false
        } else {
            // 首次运行，记录当前日期
            updateLastResetDate()
            return false
        }
    }
    
    // 重置所有成就的累计时间
    private func resetAchievements() {
        // 获取所有成就类型
        for achievementType in AchievementType.allCases {
            // 重置该类型成就的累计时间
            let key = "achievement_\(achievementType.rawValue)"
            userDefaults.removeObject(forKey: key)
        }
        
        // 记录重置事件
        NotificationCenter.default.post(name: NSNotification.Name("AchievementsResetNotification"), object: nil)
        
        // 保存更改
        userDefaults.synchronize()
    }
    
    // 更新上次重置日期
    private func updateLastResetDate() {
        userDefaults.set(Date(), forKey: lastResetKey)
        userDefaults.synchronize()
    }
    
    // 强制重置所有成就
    func forceReset() {
        resetAchievements()
        updateLastResetDate()
    }
    
    // 获取下一次重置日期
    func calculateNextResetDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取当前周的开始日期（周一）
        let weekday = calendar.component(.weekday, from: now)
        let daysToAdd = (2 - weekday + 7) % 7 // 2 是周一在 Calendar 中的值
        let nextMonday = calendar.date(byAdding: .day, value: daysToAdd, to: now)!
        
        // 设置时间为午夜
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: nextMonday)!
    }
    
    // 获取距离下次重置的剩余天数
    func getDaysUntilNextReset() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let nextReset = calculateNextResetDate()
        
        let components = calendar.dateComponents([.day], from: now, to: nextReset)
        return components.day ?? 0
    }
    
    // 检查是否需要重置
    func shouldResetAchievements() -> Bool {
        let nextResetDate = calculateNextResetDate()
        return Date() >= nextResetDate
    }
    
    // 重置成就
    func resetAchievements(for userModel: UserModel) {
        for type in AchievementType.allCases {
            userModel.achievementProgress[type] = 0
        }
        userModel.save()
    }
}
