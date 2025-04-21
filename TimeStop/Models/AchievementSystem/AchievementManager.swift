import Foundation
import SwiftUI
import Combine

// 成就系统管理器
class AchievementManager: ObservableObject {
    @Published private(set) var achievements: [AchievementProgress] = []
    @Published var lastUpdateDate: Date = Date()
    @Published var lastResetDate: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "user_achievements"
    private let lastUpdateKey = "achievement_last_update"
    private let lastResetKey = "achievement_last_reset"
    
    // 单例模式
    static let shared = AchievementManager()
    
    private init() {
        loadAchievements()
        checkAndResetIfNeeded()
        
        // 如果是首次启动，初始化默认成就
        if achievements.isEmpty {
            initializeDefaultAchievements()
        }
    }
    
    // 初始化默认成就跟踪
    private func initializeDefaultAchievements() {
        // 初始化传统成就类型
        for type in AchievementType.legacyTypes {
            let achievement = AchievementProgress(type: type)
            achievements.append(achievement)
        }
        
        // 初始化新成就类型
        for type in AchievementType.allCases where !AchievementType.legacyTypes.contains(type) {
            let achievement = AchievementProgress(type: type)
            achievements.append(achievement)
        }
        
        saveAchievements()
    }
    
    // 检查是否需要重置周期性成就
    private func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取上次重置的日期信息
        let lastResetWeek = calendar.component(.weekOfYear, from: lastResetDate)
        let currentWeek = calendar.component(.weekOfYear, from: now)
        
        // 检查是否需要周重置
        if lastResetWeek != currentWeek {
            resetWeeklyAchievements()
            lastResetDate = now
            userDefaults.set(lastResetDate, forKey: lastResetKey)
        }
    }
    
    // 重置周期性成就
    private func resetWeeklyAchievements() {
        // 筛选出需要每周重置的成就类型
        let weeklyResetTypes: [AchievementType] = [
            .balanceMaster, 
            .focusEfficiency, // 替换focusStreak
            .taskEfficiency   // 添加taskEfficiency
        ]
        
        // 移除这些类型的成就记录，让他们重新开始
        achievements.removeAll { progress in
            weeklyResetTypes.contains(progress.type)
        }
        
        // 重新添加这些类型，值重置为0
        for type in weeklyResetTypes {
            let newProgress = AchievementProgress(type: type)
            achievements.append(newProgress)
        }
        
        saveAchievements()
    }
    
    // 加载成就数据
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([AchievementProgress].self, from: data) {
            achievements = decoded
        }
        
        if let date = userDefaults.object(forKey: lastUpdateKey) as? Date {
            lastUpdateDate = date
        }
        
        if let resetDate = userDefaults.object(forKey: lastResetKey) as? Date {
            lastResetDate = resetDate
        }
    }
    
    // 保存成就数据
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
            lastUpdateDate = Date()
            userDefaults.set(lastUpdateDate, forKey: lastUpdateKey)
        }
    }
    
    // 获取特定类型的成就进度
    func achievement(for type: AchievementType) -> AchievementProgress? {
        return achievements.first { $0.type == type }
    }
    
    // 获取特定类别的所有成就
    func achievements(in category: AchievementCategory) -> [AchievementProgress] {
        return achievements.filter { $0.type.category.rawValue == category.rawValue }
    }
    
    // 更新成就进度
    func updateProgress(for type: AchievementType, value: Int) {
        if let index = achievements.firstIndex(where: { $0.type == type }) {
            var achievement = achievements[index]
            
            // 记录旧等级
            let oldLevel = achievement.level
            
            // 更新进度
            achievement.updateValue(newValue: value)
            achievements[index] = achievement
            
            // 检查是否解锁新等级
            if achievement.level > oldLevel {
                // 触发成就解锁通知
                AchievementNotificationManager.shared.showAchievementUnlocked(
                    type: type, 
                    level: achievement.level
                )
            }
            
            saveAchievements()
        } else {
            // 成就类型不存在，创建新记录
            var newAchievement = AchievementProgress(type: type)
            newAchievement.updateValue(newValue: value)
            achievements.append(newAchievement)
            saveAchievements()
        }
    }
    
    // 更新特定成就的元数据
    func updateMetadata(for type: AchievementType, key: String, value: String) {
        if let index = achievements.firstIndex(where: { $0.type == type }) {
            var achievement = achievements[index]
            achievement.storeMetadata(key: key, value: value)
            achievements[index] = achievement
            saveAchievements()
        }
    }
    
    // 兼容旧版API: 添加分钟数
    func addMinutes(for type: AchievementType, minutes: Int) {
        updateProgress(for: type, value: minutes)
    }
    
    // 获取总完成度百分比
    var totalCompletionPercentage: Double {
        let totalPossibleLevels = AchievementType.allCases.count * 5 // 假设每个成就有5级
        var totalAchievedLevels = 0
        
        for achievement in achievements {
            totalAchievedLevels += achievement.level
        }
        
        return Double(totalAchievedLevels) / Double(totalPossibleLevels)
    }
    
    // 获取已解锁成就数量
    var unlockedAchievementsCount: Int {
        return achievements.filter { $0.level > 0 }.count
    }
    
    // 重置所有成就
    func resetAllAchievements() {
        achievements.removeAll()
        initializeDefaultAchievements()
        saveAchievements()
    }
} 
