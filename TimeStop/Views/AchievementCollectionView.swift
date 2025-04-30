import SwiftUI

struct AchievementCollectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var achievementManager: AchievementManager
    @State private var selectedCategory: AchievementCategory? = nil
    
    // 默认初始化方法，使用shared实例
    init() {
        self.achievementManager = AchievementManager.shared
    }
    
    // 参数化初始化方法
    init(achievementManager: AchievementManager) {
        self.achievementManager = achievementManager
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部空白区域 - 往下移动30点
            Spacer()
                .frame(height: 30)
            
            // 成就总览 - 改进设计（固定不滚动）
            achievementOverview
                .padding(.horizontal, 20)
            
            // 类别选择器 - 改进设计（固定不滚动）
            categorySelector
                .padding(.horizontal, 20)
            
            // 只有成就列表部分可滚动
            ScrollView {
                achievementsList
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
            }
        }
        .padding(.top)
        .background(themeManager.colors.background.edgesIgnoringSafeArea(.all))
    }
    
    // 成就总览统计 - Apple Design风格
    private var achievementOverview: some View {
        // 使用圆角矩形和精致的内部布局
        VStack(spacing: 16) {
            // 标题和状态栏
            HStack(alignment: .center) {
                Text("成就总览")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.colors.primary.opacity(0.8))
                    
                    Text("\(achievementManager.unlockedAchievementsCount)个成就")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(themeManager.colors.secondaryBackground)
                )
            }
            
            // 进度指示器
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(achievementManager.totalCompletionPercentage * 100))% 完成")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
            }
                
                // 精致的进度条
                ZStack(alignment: .leading) {
                    // 背景层
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.colors.secondaryBackground)
                        .frame(height: 8)
                    
                    // 进度层
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [themeManager.colors.primary, themeManager.colors.primary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, UIScreen.main.bounds.width * 0.85 * achievementManager.totalCompletionPercentage), height: 8)
                }
                .shadow(color: themeManager.colors.primary.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // 类别选择器 - Apple Design风格
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择类别")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(themeManager.colors.secondaryText)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 全部类别按钮
                    categoryButton(nil, name: "全部")
                    
                    // 仅显示与主页一致的8种任务按钮
                    let mainPageCategories: [AchievementCategory] = [
                        .work, .meeting, .thinking, .reading, .exercise, .sleep, .life, .relax
                    ]
                    
                    // 显示筛选后的类别按钮
                    ForEach(mainPageCategories) { category in
                        categoryButton(category, name: category.rawValue)
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }
    
    // 类别选择按钮 - 强化立体胶囊质感
    private func categoryButton(_ category: AchievementCategory?, name: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            Text(name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(isSelected(category) ? .semibold : .medium)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    // 增强立体胶囊效果
                    ZStack {
                        if isSelected(category) {
                            // 选中状态 - 彩色立体胶囊
                            Capsule()
                                .fill(
                                    // 为"全部"按钮使用墨绿色，其他按钮保持原样
                                    category == nil ? 
                                        (themeManager.currentTheme == .classic ? Color(red: 0.05, green: 0.3, blue: 0.15) : themeManager.colors.primary) : 
                                        (category?.color ?? themeManager.colors.primary)
                                )
                                // 内部阴影增强立体感
                                .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1.5)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2),
                                                    Color.clear
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        } else {
                            // 未选中状态 - 深灰色立体胶囊
                            Capsule()
                                .fill(
                                    Color(white: 0.2) // 深灰色底色
                                )
                                // 内部阴影增强立体感
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1.5)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.15),
                                                    Color.clear
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        }
                        
                        // 顶部高光增强3D质感
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 10)
                            .padding(.horizontal, 1)
                            .padding(.top, 1)
                            .mask(
                                Capsule()
                                    .padding(.bottom, 14)
                            )
                    }
                )
        }
        .buttonStyle(EnhancedCapsuleButtonStyle()) // 使用增强立体按钮样式
    }
    
    // 增强立体胶囊按钮样式
    struct EnhancedCapsuleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.93 : 1)
                // 按下时模拟下沉效果
                .offset(y: configuration.isPressed ? 1 : 0)
                // 按下时降低高光强度
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(.spring(response: 0.16, dampingFraction: 0.5), value: configuration.isPressed)
        }
    }
    
    // 判断类别是否被选中
    private func isSelected(_ category: AchievementCategory?) -> Bool {
        return selectedCategory == category
    }
    
    // 展示成就列表 - 采用左右两列网格布局
    private var achievementsList: some View {
        // 获取当前筛选后的成就
        let filteredAchievements = getFilteredAchievements()
        
        if filteredAchievements.isEmpty {
            return AnyView(emptyStateView)
        } else {
            // 使用LazyVGrid实现两列正方形布局
            return AnyView(
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            )
        }
    }
    
    // 空状态显示 - Apple Design风格
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 空状态图标
            ZStack {
                Circle()
                    .fill(themeManager.colors.secondaryBackground)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "star.slash")
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.colors.secondaryText.opacity(0.7))
            }
            .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("暂无成就")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.colors.text)
                
                Text("继续努力记录和管理时间，解锁更多成就")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.cardBackground.opacity(0.6))
        )
    }
    
    // 根据选择的类别筛选成就
    private func getFilteredAchievements() -> [AchievementProgress] {
        if let category = selectedCategory {
            return achievementManager.achievements(in: category)
        } else {
            return achievementManager.achievements
        }
    }
}

// 单个成就卡片 - 小型正方形设计
struct AchievementCard: View {
    var achievement: AchievementProgress
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        // 使用VStack创建正方形卡片布局
        VStack(alignment: .center, spacing: 5) {
            // 顶部：图标和等级
            ZStack {
                // 成就图标背景
                Circle()
                    .fill(
                        achievement.level > 0 ? 
                        LinearGradient(
                            gradient: Gradient(colors: [
                                achievement.type.levelColor(achievement.level),
                                achievement.type.levelColor(achievement.level).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: achievement.level > 0 ? achievement.type.levelColor(achievement.level).opacity(0.2) : Color.clear, radius: 2, x: 0, y: 1)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.top, 6)
            
            // 成就标题
            Text(achievement.type.name)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(themeManager.colors.text)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // 成就级别
            Text(achievement.levelDescription)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(achievement.level > 0 ? 
                                 achievement.type.levelColor(achievement.level) : 
                                 themeManager.colors.secondaryText)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // 分隔线
            Rectangle()
                .fill(themeManager.colors.secondaryBackground)
                .frame(height: 0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
            
            // 进度指示器
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(themeManager.colors.secondaryBackground, lineWidth: 2)
                    .frame(width: 34, height: 34)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: achievement.progressPercentage)
                    .stroke(
                        achievement.type.levelColor(achievement.level),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 34, height: 34)
                    .rotationEffect(.degrees(-90))
                
                // 等级数字
                Text("\(achievement.level)")
                    .font(.system(.footnote, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.text)
            }
            
            // 进度文字
            if let nextThreshold = achievement.type.nextLevelThreshold(current: achievement.value) {
                Text("\(achievement.value)/\(nextThreshold)")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.secondaryText)
            } else {
                Text("\(achievement.value) (满级)")
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.colors.secondaryText)
            }
        }
        .aspectRatio(1, contentMode: .fill) // 强制1:1比例
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeManager.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        )
        // 添加边框增强轮廓
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.black.opacity(0.03), lineWidth: 0.5)
        )
    }
}
