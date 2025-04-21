import SwiftUI

struct AchievementView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var achievementManager = AchievementManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 成就总览卡片
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总成就进度")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("\(Int(achievementManager.totalCompletionPercentage * 100))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.primary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(themeManager.colors.secondaryBackground, lineWidth: 8)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(achievementManager.totalCompletionPercentage))
                                .stroke(themeManager.colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: achievementManager.totalCompletionPercentage)
                            
                            Text("\(achievementManager.unlockedAchievementsCount)/\(AchievementType.allCases.count)")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.text)
                        }
                    }
                    
                    // 显示各类别的成就概览
                    categorySummary
                }
                .padding()
                .background(themeManager.colors.secondaryBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top)
                
                // 成就收集视图
                AchievementCollectionView(achievementManager: achievementManager)
                    .padding(.top, 8)
            }
            .background(themeManager.colors.background)
            .navigationTitle("成就收集")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 类别概览
    private var categorySummary: some View {
        VStack(spacing: 12) {
            Text("成就类别")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(themeManager.colors.text)
            
            // 类别卡片网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AchievementCategory.allCases) { category in
                    categoryCard(for: category)
                }
            }
        }
    }
    
    // 单个类别卡片
    private func categoryCard(for category: AchievementCategory) -> some View {
        // 获取该类别下已解锁的成就数量和总数
        let achievements = achievementManager.achievements(in: category)
        let unlockedCount = achievements.filter { $0.level > 0 }.count
        let totalCount = achievements.count
        
        return VStack(spacing: 8) {
            // 类别图标
            Image(systemName: category.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(category.color)
                )
                .padding(.top, 8)
            
            // 类别名称
            Text(category.rawValue)
                .font(.subheadline)
                .foregroundColor(themeManager.colors.text)
                .lineLimit(1)
            
            // 进度指示
            Text("\(unlockedCount)/\(totalCount)")
                .font(.caption)
                .foregroundColor(themeManager.colors.secondaryText)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(themeManager.colors.cardBackground)
        .cornerRadius(12)
    }
}

// 预览
struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        let themeManager = ThemeManager()
        
        return AchievementView()
            .environmentObject(themeManager)
    }
} 