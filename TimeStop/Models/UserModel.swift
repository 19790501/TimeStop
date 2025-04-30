import Foundation
import SwiftUI
import Combine

struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var phoneNumber: String
    var password: String
    var achievements: [Achievement]
    var totalFocusTime: Int // in minutes
    var completedTasks: Int
    var level: Int
    var experience: Int
    
    init(id: UUID = UUID(), username: String, phoneNumber: String, password: String) {
        self.id = id
        self.username = username
        self.phoneNumber = phoneNumber
        self.password = password
        self.achievements = []
        self.totalFocusTime = 0
        self.completedTasks = 0
        self.level = 1
        self.experience = 0
    }
}

struct Achievement: Identifiable, Codable {
    var id: UUID = UUID()
    var typeIdentifier: String // 成就类型标识符，对应 AchievementType 的 rawValue
    var minutes: Int // 该类型积累的时间（分钟）
    var unlockedLevels: [Int] = [] // 已解锁的等级
    var earnedAt: Date = Date() // 第一次获得该类型成就的时间
}

class UserModel: ObservableObject {
    static let shared = UserModel()
    
    @Published var achievementProgress: [AchievementType: Int] = [:]
    @Published var achievements: [AchievementBadge] = []
    @Published var errorMessage: String?
    @Published var hasError: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let achievementProgressKey = "achievementProgress"
    private let achievementsKey = "achievements"
    
    // Custom error types
    enum UserModelError: Error {
        case dataDecodingFailed(String)
        case dataEncodingFailed(String)
        case dataSavingFailed(String)
        case dataLoadingFailed(String)
    }
    
    init() {
        loadAchievementData()
    }
    
    func addMinutes(_ minutes: Int, for type: AchievementType) {
        let currentMinutes = achievementProgress[type] ?? 0
        achievementProgress[type] = currentMinutes + minutes
        do {
            try save()
        } catch {
            handleError(error)
        }
    }
    
    func hasAchievement(type: AchievementType, level: Int) -> Bool {
        return achievements.contains { $0.type == type && $0.level == level }
    }
    
    func addAchievement(_ badge: AchievementBadge) {
        if !hasAchievement(type: badge.type, level: badge.level) {
            achievements.append(badge)
            do {
                try save()
            } catch {
                handleError(error)
            }
        }
    }
    
    private func loadAchievementData() {
        do {
            // Load achievement progress
            if let progressData = userDefaults.data(forKey: achievementProgressKey) {
                do {
                    achievementProgress = try JSONDecoder().decode([AchievementType: Int].self, from: progressData)
                } catch {
                    throw UserModelError.dataDecodingFailed("Failed to decode achievement progress: \(error.localizedDescription)")
                }
            }
            
            // Load achievements
            if let achievementsData = userDefaults.data(forKey: achievementsKey) {
                do {
                    achievements = try JSONDecoder().decode([AchievementBadge].self, from: achievementsData)
                } catch {
                    throw UserModelError.dataDecodingFailed("Failed to decode achievements: \(error.localizedDescription)")
                }
            }
        } catch {
            handleError(error)
            // Reset to default values on error
            achievementProgress = [:]
            achievements = []
        }
    }
    
    func save() throws {
        do {
            // Save achievement progress
            let progressData = try JSONEncoder().encode(achievementProgress)
            userDefaults.set(progressData, forKey: achievementProgressKey)
            
            // Save achievements
            let achievementsData = try JSONEncoder().encode(achievements)
            userDefaults.set(achievementsData, forKey: achievementsKey)
            
            // Verify data was saved correctly
            if userDefaults.data(forKey: achievementProgressKey) == nil || 
               userDefaults.data(forKey: achievementsKey) == nil {
                throw UserModelError.dataSavingFailed("Failed to verify data was saved correctly")
            }
            
            // Force UserDefaults to save to disk
            userDefaults.synchronize()
            
            // Clear any previous errors
            hasError = false
            errorMessage = nil
        } catch {
            throw UserModelError.dataSavingFailed("Failed to save user data: \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async(execute: DispatchWorkItem {
            self.hasError = true
            self.errorMessage = error.localizedDescription
            
            // Log the error
            print("UserModel Error: \(error.localizedDescription)")
            
            // Post notification about the error
            NotificationCenter.default.post(
                name: NSNotification.Name("UserModelError"),
                object: nil,
                userInfo: ["error": error]
            )
        })
    }
    
    func generateTestData() {
        // 清除现有数据
        achievementProgress.removeAll()
        achievements.removeAll()
        
        // 为8种核心类型生成不同的累计时间，符合新的等级门槛
        // 会议
        achievementProgress[.meeting] = 410    // 解锁2级 (超过210分钟)
        // 思考
        achievementProgress[.thinking] = 500   // 解锁3级 (超过280分钟)
        // 工作
        achievementProgress[.work] = 1100      // 解锁3级 (超过900分钟)
        // 生活
        achievementProgress[.life] = 210       // 解锁4级 (超过180分钟)
        // 运动
        achievementProgress[.exercise] = 220   // 解锁4级 (超过210分钟)
        // 阅读
        achievementProgress[.reading] = 220    // 解锁3级 (超过180分钟)
        // 睡眠
        achievementProgress[.sleep] = 1200     // 解锁2级 (超过1120分钟)
        // 摸鱼
        achievementProgress[.relax] = 530      // 解锁2级 (超过210分钟)
        
        // 生成对应的成就徽章
        // 会议
        addAchievement(AchievementBadge(type: .meeting, level: 1))
        addAchievement(AchievementBadge(type: .meeting, level: 2))
        
        // 思考
        addAchievement(AchievementBadge(type: .thinking, level: 1))
        addAchievement(AchievementBadge(type: .thinking, level: 2))
        addAchievement(AchievementBadge(type: .thinking, level: 3))
        
        // 工作
        addAchievement(AchievementBadge(type: .work, level: 1))
        addAchievement(AchievementBadge(type: .work, level: 2))
        addAchievement(AchievementBadge(type: .work, level: 3))
        
        // 生活
        addAchievement(AchievementBadge(type: .life, level: 1))
        addAchievement(AchievementBadge(type: .life, level: 2))
        addAchievement(AchievementBadge(type: .life, level: 3))
        addAchievement(AchievementBadge(type: .life, level: 4))
        
        // 运动
        addAchievement(AchievementBadge(type: .exercise, level: 1))
        addAchievement(AchievementBadge(type: .exercise, level: 2))
        addAchievement(AchievementBadge(type: .exercise, level: 3))
        addAchievement(AchievementBadge(type: .exercise, level: 4))
        
        // 阅读
        addAchievement(AchievementBadge(type: .reading, level: 1))
        addAchievement(AchievementBadge(type: .reading, level: 2))
        addAchievement(AchievementBadge(type: .reading, level: 3))
        
        // 睡眠
        addAchievement(AchievementBadge(type: .sleep, level: 1))
        addAchievement(AchievementBadge(type: .sleep, level: 2))
        
        // 摸鱼
        addAchievement(AchievementBadge(type: .relax, level: 1))
        addAchievement(AchievementBadge(type: .relax, level: 2))
        
        // 保存测试数据
        do {
            try save()
        } catch {
            handleError(error)
        }
        
        print("成就系统测试数据已生成")
    }
    
    // 生成所有等级的完整测试数据
    func generateAllLevelsTestData() {
        // 清除现有数据
        achievementProgress.removeAll()
        achievements.removeAll()
        
        // 为每种成就类型生成最高等级的数据
        for type in AchievementType.allCases {
            // 设置足够高的分钟数以达到最高等级
            let highestThreshold = type.levelThresholds.last ?? 3000
            achievementProgress[type] = highestThreshold + 1
            
            // 为每个等级添加成就徽章
            for level in 1...6 {
                addAchievement(AchievementBadge(type: type, level: level))
            }
        }
        
        do {
            try save()
        } catch {
            handleError(error)
        }
        print("已生成所有成就类型的完整等级测试数据")
    }
    
    func highestLevel(for type: AchievementType) -> Int {
        let badges = achievements.filter { $0.type == type }
        return badges.map { $0.level }.max() ?? 0
    }
} 


