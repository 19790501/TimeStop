import Foundation
import SwiftUI

// 成就进度数据模型
struct AchievementProgress: Identifiable, Codable {
    var id = UUID()
    var type: AchievementType
    var value: Int = 0
    var lastUpdated: Date = Date()
    
    // 新增字段: 用于跟踪连续打卡等统计性成就
    var streakCount: Int = 0
    var lastStreakDate: Date?
    var metadata: [String: String] = [:]
    
    var level: Int {
        return type.achievementLevel(for: value)
    }
    
    var lastInteractionDate: Date {
        return lastUpdated
    }
    
    var valueToNextLevel: Int {
        return type.valueToNextLevel(current: value)
    }
    
    var progressPercentage: Double {
        return type.progressPercentage(for: value)
    }
    
    var levelDescription: String {
        return type.levelDescription(level)
    }
    
    var achievementDescription: String {
        return type.achievementDescription(for: level)
    }
    
    var suggestion: String {
        return type.achievementSuggestion(for: level)
    }
    
    var color: Color {
        return type.color
    }
    
    var levelColor: Color {
        return type.levelColor(level)
    }
    
    var icon: String {
        return type.icon
    }
    
    // 更新成就数据
    mutating func updateValue(newValue: Int) {
        // 旧有类型直接累加分钟数
        if [.meeting, .thinking, .work, .life, .exercise, .reading, .sleep, .relax].contains(type) {
            self.value += newValue
        } else {
            // 新类型根据不同逻辑更新
            updateBasedOnType(newValue: newValue)
        }
        self.lastUpdated = Date()
    }
    
    // 基于不同成就类型的更新逻辑
    private mutating func updateBasedOnType(newValue: Int) {
        switch type {
        // 连续打卡类成就处理
        case .dailyStreak, .weeklyStreak, .monthlyStreak:
            updateStreakCount(newValue: newValue)
            
        // 任务完成相关
        case .taskCompletion:
            self.value += newValue // 直接累加完成的任务数
            
        // 专注时间里程碑
        case .focusMilestone:
            self.value += newValue // 直接累加专注分钟数
            
        // 其他新增类型
        default:
            // 基于特定条件的更新，暂时直接更新传入值
            self.value = newValue
        }
    }
    
    // 更新连续打卡计数
    private mutating func updateStreakCount(newValue: Int) {
        let calendar = Calendar.current
        let today = Date()
        
        guard let lastDate = lastStreakDate else {
            // 首次记录
            self.streakCount = 1
            self.value = 1
            self.lastStreakDate = today
            return
        }
        
        switch type {
        case .dailyStreak:
            // 如果最后打卡是昨天，连续+1
            if calendar.isDateInYesterday(lastDate) {
                self.streakCount += 1
                self.value = self.streakCount
            } 
            // 如果是今天，保持不变
            else if calendar.isDateInToday(lastDate) {
                // 不变
            } 
            // 如果间隔超过1天，重置为1
            else {
                self.streakCount = 1
                self.value = 1
            }
            
        case .weeklyStreak:
            let lastWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastDate)
            let thisWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            
            // 如果是上周，连续+1
            if lastWeekComponents.yearForWeekOfYear == thisWeekComponents.yearForWeekOfYear && 
               lastWeekComponents.weekOfYear == thisWeekComponents.weekOfYear! - 1 {
                self.streakCount += 1
                self.value = self.streakCount
            }
            // 如果是本周，保持不变
            else if lastWeekComponents.yearForWeekOfYear == thisWeekComponents.yearForWeekOfYear && 
                    lastWeekComponents.weekOfYear == thisWeekComponents.weekOfYear {
                // 不变
            }
            // 否则重置
            else {
                self.streakCount = 1
                self.value = 1
            }
            
        case .monthlyStreak:
            let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastDate)
            let thisMonthComponents = calendar.dateComponents([.year, .month], from: today)
            
            // 如果是上月，连续+1
            if lastMonthComponents.year == thisMonthComponents.year && 
               lastMonthComponents.month == thisMonthComponents.month! - 1 {
                self.streakCount += 1
                self.value = self.streakCount
            }
            // 如果是本月，保持不变
            else if lastMonthComponents.year == thisMonthComponents.year && 
                    lastMonthComponents.month == thisMonthComponents.month {
                // 不变
            }
            // 否则重置
            else {
                self.streakCount = 1
                self.value = 1
            }
            
        default:
            // 默认情况，直接更新值
            self.value = newValue
        }
        
        self.lastStreakDate = today
    }
    
    // 存储额外元数据
    mutating func storeMetadata(key: String, value: String) {
        metadata[key] = value
    }
    
    // 获取元数据
    func getMetadata(key: String) -> String? {
        return metadata[key]
    }
    
    // 兼容旧有API
    var minutes: Int {
        return value
    }
    
    mutating func addMinutes(_ minutes: Int) {
        updateValue(newValue: minutes)
    }
} 
