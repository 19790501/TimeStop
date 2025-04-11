import Foundation
import SwiftUI

class AchievementProgress: ObservableObject {
    @Published private(set) var progress: [AchievementType: Int] = [:]
    @Published var lastUpdateDate: Date = Date()
    @Published var lastResetDate: Date = Date()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "achievement_progress"
    private let lastUpdateKey = "lastUpdateDate"
    private let lastResetKey = "lastResetDate"
    private var lastLevels: [AchievementType: Int] = [:]
    
    init() {
        loadProgress()
        // 初始化上次等级记录
        for type in AchievementType.allCases {
            lastLevels[type] = currentLevel(for: type)
        }
        // 检查是否需要周重置
        checkAndResetIfNeeded()
    }
    
    // 检查是否需要周重置
    private func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取上次重置的周数
        let lastResetWeek = calendar.component(.weekOfYear, from: lastResetDate)
        let currentWeek = calendar.component(.weekOfYear, from: now)
        
        // 如果不在同一周，需要重置
        if lastResetWeek != currentWeek {
            resetWeeklyProgress()
            lastResetDate = now
            userDefaults.set(lastResetDate, forKey: lastResetKey)
        }
    }
    
    // 重置周进度
    private func resetWeeklyProgress() {
        // 保留最高等级记录
        let maxLevels = lastLevels
        // 重置当前进度
        progress.removeAll()
        saveProgress()
        // 恢复最高等级记录
        lastLevels = maxLevels
    }
    
    // 加载进度
    private func loadProgress() {
        if let data = userDefaults.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([AchievementType: Int].self, from: data) {
            progress = decoded
        }
        
        if let date = userDefaults.object(forKey: lastUpdateKey) as? Date {
            lastUpdateDate = date
        }
        
        if let resetDate = userDefaults.object(forKey: lastResetKey) as? Date {
            lastResetDate = resetDate
        }
    }
    
    // 保存进度
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            userDefaults.set(encoded, forKey: progressKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    // 更新进度并检查成就解锁
    func updateProgress(for type: AchievementType, minutes: Int) {
        // 先检查是否需要重置
        checkAndResetIfNeeded()
        
        let currentMinutes = progress[type] ?? 0
        progress[type] = currentMinutes + minutes
        saveProgress()
        
        // 检查是否解锁新等级
        let newLevel = currentLevel(for: type)
        let oldLevel = lastLevels[type] ?? 0
        
        if newLevel > oldLevel {
            // 解锁新成就
            AchievementNotificationManager.shared.showAchievementUnlocked(type: type, level: newLevel)
            // 更新等级记录
            lastLevels[type] = newLevel
        }
    }
    
    // 获取当前等级
    func currentLevel(for type: AchievementType) -> Int {
        let minutes = progress[type] ?? 0
        return type.achievementLevel(for: minutes)
    }
    
    // 获取进度百分比
    func progressPercentage(for type: AchievementType) -> Double {
        let minutes = progress[type] ?? 0
        return type.progressPercentage(for: minutes)
    }
    
    // 获取距离下一级所需时间
    func minutesToNextLevel(for type: AchievementType) -> Int {
        let minutes = progress[type] ?? 0
        return type.minutesToNextLevel(for: minutes)
    }
    
    // 获取总完成度百分比
    var totalCompletionPercentage: Double {
        let totalLevels = AchievementType.allCases.count * 6 // 6个等级
        var completedLevels = 0
        
        for type in AchievementType.allCases {
            completedLevels += currentLevel(for: type)
        }
        
        return Double(completedLevels) / Double(totalLevels)
    }
    
    // 获取已解锁成就数量
    var unlockedAchievementsCount: Int {
        var count = 0
        for type in AchievementType.allCases {
            if currentLevel(for: type) > 0 {
                count += 1
            }
        }
        return count
    }
    
    // 重置所有进度
    func resetAllProgress() {
        progress.removeAll()
        lastLevels.removeAll()
        saveProgress()
    }
} 