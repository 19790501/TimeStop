import Foundation
import SwiftUI
import Combine

class AchievementViewModel: ObservableObject {
    @Published var userModel: UserModel
    @Published var selectedType: AchievementType?
    @Published var showingDetail = false
    @Published var showingUnlockAnimation = false
    @Published var unlockedAchievement: AchievementBadge?
    
    private var cancellables = Set<AnyCancellable>()
    private let resetManager = AchievementResetManager.shared
    
    init(userModel: UserModel) {
        self.userModel = userModel
        
        // 检查是否需要重置成就
        if resetManager.shouldResetAchievements() {
            resetManager.resetAchievements(for: userModel)
        }
        
        // 监听成就解锁
        userModel.$achievementProgress
            .sink { [weak self] _ in
                self?.checkAchievementUnlocks()
            }
            .store(in: &cancellables)
    }
    
    private func checkAchievementUnlocks() {
        for type in AchievementType.allCases {
            let minutes = userModel.achievementProgress[type] ?? 0
            let level = type.achievementLevel(for: minutes)
            
            // 检查是否解锁了新等级
            if level > 0 && !userModel.hasAchievement(type: type, level: level) {
                let badge = AchievementBadge(type: type, level: level)
                userModel.addAchievement(badge)
                unlockedAchievement = badge
                showingUnlockAnimation = true
            }
        }
    }
    
    func selectType(_ type: AchievementType) {
        selectedType = type
        showingDetail = true
    }
    
    @Published var unlockedAchievementsCount: Int = 0
    @Published var achievementCompletionPercentage: Double = 0.0
    
    private let userDefaults = UserDefaults.standard
    
    // 加载成就数据并更新统计
    func loadAchievementData() {
        updateStatistics()
    }
    
    // 获取指定类型成就的累计时间
    func getAchievementMinutes(for type: AchievementType) -> Int {
        let key = "achievement_\(type.rawValue)"
        return userDefaults.integer(forKey: key)
    }
    
    // 获取指定类型成就的等级
    func achievementLevel(for type: AchievementType) -> Int {
        let minutes = getAchievementMinutes(for: type)
        return type.achievementLevel(for: minutes)
    }
    
    // 更新指定类型成就的累计时间
    func updateAchievementMinutes(for type: AchievementType, minutes: Int) {
        let key = "achievement_\(type.rawValue)"
        let currentMinutes = userDefaults.integer(forKey: key)
        userDefaults.set(currentMinutes + minutes, forKey: key)
        userDefaults.synchronize()
        
        // 更新统计数据
        updateStatistics()
    }
    
    // 更新统计数据
    private func updateStatistics() {
        var unlockedCount = 0
        var totalPercentage = 0.0
        
        for type in AchievementType.allCases {
            let minutes = getAchievementMinutes(for: type)
            let level = type.achievementLevel(for: minutes)
            
            if level > 0 {
                unlockedCount += 1
            }
            
            // 计算该类型的完成百分比
            totalPercentage += type.progressPercentage(for: minutes)
        }
        
        // 更新已解锁数量
        unlockedAchievementsCount = unlockedCount
        
        // 计算总完成度百分比（所有类型的平均值）
        achievementCompletionPercentage = totalPercentage / Double(AchievementType.allCases.count) * 100.0
    }
    
    // 重置所有成就
    func resetAllAchievements() {
        AchievementResetManager.shared.forceReset()
        updateStatistics()
    }
}
