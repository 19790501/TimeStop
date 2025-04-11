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
    
    private let userDefaults = UserDefaults.standard
    private let achievementProgressKey = "achievementProgress"
    private let achievementsKey = "achievements"
    
    init() {
        loadAchievementData()
    }
    
    func addMinutes(_ minutes: Int, for type: AchievementType) {
        let currentMinutes = achievementProgress[type] ?? 0
        achievementProgress[type] = currentMinutes + minutes
        save()
    }
    
    func hasAchievement(type: AchievementType, level: Int) -> Bool {
        return achievements.contains { $0.type == type && $0.level == level }
    }
    
    func addAchievement(_ badge: AchievementBadge) {
        if !hasAchievement(type: badge.type, level: badge.level) {
            achievements.append(badge)
            save()
        }
    }
    
    private func loadAchievementData() {
        if let progressData = userDefaults.data(forKey: achievementProgressKey),
           let progress = try? JSONDecoder().decode([AchievementType: Int].self, from: progressData) {
            achievementProgress = progress
        }
        
        if let achievementsData = userDefaults.data(forKey: achievementsKey),
           let badges = try? JSONDecoder().decode([AchievementBadge].self, from: achievementsData) {
            achievements = badges
        }
    }
    
    func save() {
        if let progressData = try? JSONEncoder().encode(achievementProgress) {
            userDefaults.set(progressData, forKey: achievementProgressKey)
        }
        
        if let achievementsData = try? JSONEncoder().encode(achievements) {
            userDefaults.set(achievementsData, forKey: achievementsKey)
        }
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
        save()
        
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
        
        save()
        print("已生成所有成就类型的完整等级测试数据")
    }
    
    func highestLevel(for type: AchievementType) -> Int {
        let badges = achievements.filter { $0.type == type }
        return badges.map { $0.level }.max() ?? 0
    }
} 


