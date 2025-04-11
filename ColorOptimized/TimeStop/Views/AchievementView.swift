import SwiftUI

struct AchievementView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    
    // 计算总成就进度
    var totalProgressPercentage: Double {
        // 总共8种类型，每种最多6级 = 48个级别
        let totalLevels = AchievementType.allCases.count * 6
        let achievedLevels = userModel.achievements.count
        return min(Double(achievedLevels) / Double(totalLevels), 1.0)
    }
    
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
                            
                            Text("\(Int(totalProgressPercentage * 100))%")
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
                                .trim(from: 0, to: CGFloat(totalProgressPercentage))
                                .stroke(themeManager.colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: totalProgressPercentage)
                            
                            Text("\(userModel.achievements.count)/\(AchievementType.allCases.count * 6)")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.text)
                        }
                    }
                    
                    // 显示8个核心类型的高亮指示器
                    HStack(spacing: 8) {
                        ForEach(AchievementType.allCases, id: \.self) { type in
                            let level = userModel.highestLevel(for: type)
                            
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(level > 0 ? type.levelColor(level) : Color.gray.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: type.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                                
                                Text("\(level)")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.colors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(themeManager.colors.secondaryBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top)
                
                // 成就收集视图
                AchievementCollectionView()
                    .padding(.top, 8)
            }
            .background(themeManager.colors.background)
            .navigationTitle("成就收集")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        let userModel = UserModel()
        // 添加一些测试数据
        userModel.generateTestData()
        
        return AchievementView()
            .environmentObject(ThemeManager())
            .environmentObject(userModel)
    }
} 