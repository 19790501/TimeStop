import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // 计算总专注时间
    var totalFocusTime: Int {
        var total = 0
        for type in AchievementType.allCases {
            total += userModel.achievementProgress[type] ?? 0
        }
        return total
    }
    
    // 计算解锁的成就数量
    var unlockedAchievements: Int {
        return userModel.achievements.count
    }
    
    // 视觉风格常量
    private struct DesignConstants {
        static let darkText = Color.black.opacity(0.85)
        static let mediumText = Color.black.opacity(0.7)
        static let lightText = Color.black.opacity(0.5)
        static let highlightColor = Color(red: 0.4, green: 0.75, blue: 1.0)
        static let cardShadow = Color.black.opacity(0.08)
        static let cornerRadius: CGFloat = 16
        static let progressHeight: CGFloat = 8
        static let badgeSize: CGFloat = 50
        static let greenBackgroundHeight: CGFloat = 240
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 概览卡片
                    overviewCard
                    
                    // 成就进度卡片
                    achievementProgressCard
                    
                    // 详细统计卡片
                    detailedStatsCard
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("统计")
        }
    }
    
    // 概览卡片
    var overviewCard: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("总专注时间")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("\(totalFocusTime) 分钟")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("解锁成就")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("\(unlockedAchievements)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // 成就进度卡片
    var achievementProgressCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("成就进度")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            ForEach(AchievementType.allCases.prefix(5), id: \.self) { type in
                let minutes = userModel.achievementProgress[type] ?? 0
                let level = type.achievementLevel(for: minutes)
                let progress = type.progressPercentage(for: minutes)
                
                HStack {
                    Image(systemName: type.icon)
                        .foregroundColor(type.levelColor(level))
                    
                    Text(type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    Text("Lv.\(level)")
                        .font(.caption)
                        .foregroundColor(type.levelColor(level))
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: type.levelColor(level)))
                    .frame(height: 6)
            }
            
            NavigationLink(destination: AchievementCollectionView()) {
                Text("查看全部")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // 详细统计卡片
    var detailedStatsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("详细统计")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            ForEach(Array(AchievementType.allCases.enumerated()), id: \.element) { index, type in
                if index % 3 == 0 {
                    HStack(spacing: 12) {
                        ForEach(0..<min(3, AchievementType.allCases.count - index), id: \.self) { offset in
                            let currentType = AchievementType.allCases[index + offset]
                            let minutes = userModel.achievementProgress[currentType] ?? 0
                            
                            VStack(spacing: 5) {
                                Image(systemName: currentType.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                
                                Text(currentType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                    .lineLimit(1)
                                
                                Text("\(minutes)分钟")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

#Preview {
    StatsView()
        .environmentObject(UserModel())
        .environmentObject(ThemeManager())
} 
