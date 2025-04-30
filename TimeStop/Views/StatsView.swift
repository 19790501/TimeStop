import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var animateCharts = false
    
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
    
    // 格式化时间
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        } else {
            return "\(mins)分钟"
        }
    }
    
    var body: some View {
            ScrollView {
            VStack(spacing: 22) {
                // 顶部卡片
                topOverviewCard
                    
                // 分段控制器
                segmentedControl
                
                // 根据选择的选项卡显示不同内容
                if selectedTab == 0 {
                    achievementProgressView
                } else if selectedTab == 1 {
                    categoryDistributionView
                } else {
                    weeklyTrendsView
                }
                    
                    // 详细统计卡片
                detailedStatsView
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 30)
            }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("活动分析")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateCharts = true
                }
            }
        }
    }
    
    // 顶部总览卡片 - 现代风格
    var topOverviewCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 20) {
                // 左侧统计
                statCard(
                    title: "总专注时间",
                    value: "\(totalFocusTime)",
                    unit: "分钟",
                    subtitle: "约\(totalFocusTime / 60)小时\(totalFocusTime % 60)分钟",
                    color: themeManager.currentTheme.primaryColor
                )
                
                // 右侧统计
                statCard(
                    title: "已解锁成就",
                    value: "\(unlockedAchievements)",
                    unit: "个",
                    subtitle: "继续加油!",
                    color: themeManager.currentTheme.primaryColor
                )
                }
        }
    }
    
    // 统计卡片复用组件
    private func statCard(title: String, value: String, unit: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    
                Text(unit)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color.opacity(0.7))
            }
            
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 分段控制器
    var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(["成就进度", "分类分布", "每周趋势"][index])
                        .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == index ? themeManager.currentTheme.primaryColor : .secondary)
                }
                .background(
                    ZStack {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.currentTheme.primaryColor.opacity(0.1))
                                .matchedGeometryEffect(id: "TAB", in: namespace)
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
    }
    
    @Namespace private var namespace
    
    // 成就进度视图
    var achievementProgressView: some View {
        VStack(spacing: 20) {
            ForEach(AchievementType.allCases.prefix(5), id: \.self) { type in
                let minutes = userModel.achievementProgress[type] ?? 0
                let level = type.achievementLevel(for: minutes)
                let progress = type.progressPercentage(for: minutes)
                let nextLevelMinutes = calculateNextLevelMinutes(type: type, currentMinutes: minutes)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                    Image(systemName: type.icon)
                            .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(type.levelColor(level))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(type.levelColor(level).opacity(0.15))
                            )
                    
                    Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Lv.\(level)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(type.levelColor(level).opacity(0.15))
                            )
                        .foregroundColor(type.levelColor(level))
                }
                
                    VStack(alignment: .leading, spacing: 8) {
                        // 进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [type.levelColor(level), type.levelColor(level).opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: animateCharts ? (UIScreen.main.bounds.width - 76) * progress : 0, height: 10)
                        }
                        
                        // 当前进度和下一级所需
                        HStack {
                            Text("\(minutes)分钟")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("下一级需要: \(nextLevelMinutes)分钟")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                )
            }
            
            NavigationLink(destination: AchievementCollectionView(achievementManager: AchievementManager.shared)) {
                Text("查看全部成就")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.currentTheme.primaryColor)
                            .shadow(color: themeManager.currentTheme.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
            }
            .padding(.top, 5)
        }
    }
    
    // 计算下一级所需的分钟数
    private func calculateNextLevelMinutes(type: AchievementType, currentMinutes: Int) -> Int {
        let currentLevel = type.achievementLevel(for: currentMinutes)
        // 根据当前级别计算下一级所需分钟数
        // 这里使用简单公式，实际应根据AchievementType的具体实现调整
        let nextLevelThreshold = (currentLevel + 1) * 100
        return max(0, nextLevelThreshold - currentMinutes)
    }
    
    // 分类分布视图
    var categoryDistributionView: some View {
        VStack(spacing: 15) {
            // 生成分类数据
            let chartData = AchievementType.allCases.map { type -> (String, Double) in
                let minutes = Double(userModel.achievementProgress[type] ?? 0)
                return (type.rawValue, minutes)
            }.sorted { $0.1 > $1.1 }
            
            let total = chartData.reduce(0) { $0 + $1.1 }
            
            // 饼图和总时长
            ZStack {
                // iOS 16+ 使用新的Charts API
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(chartData.indices, id: \.self) { index in
                            let item = chartData[index]
                            let type = AchievementType.allCases.first { $0.rawValue == item.0 }!
                            
                            // 使用在iOS 16中可用的图表元素代替SectorMark
                            BarMark(
                                x: .value("分类", ""),
                                y: .value("时间", animateCharts ? item.1 : 0)
                            )
                            .foregroundStyle(type.levelColor(type.achievementLevel(for: Int(item.1))))
                            .position(by: .value("分类", item.0))
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 250)
                    .padding(.horizontal, 8)
                } else {
                    // iOS 16以下的兼容实现
                    VStack {
                        Text("分类分布图")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(height: 250)
                    }
                }
                
                // 中心显示总时长
                VStack(spacing: 4) {
                    Text("总时长")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(total))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("分钟")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 3)
                )
            }
            .padding(.bottom, 10)
            
            // 分类列表
            VStack(spacing: 0) {
                ForEach(chartData.indices, id: \.self) { index in
                    let item = chartData[index]
                    let type = AchievementType.allCases.first { $0.rawValue == item.0 }!
                    let percentage = total > 0 ? (item.1 / total * 100) : 0
                    
                    HStack {
                        // 图标和颜色指示
                        ZStack {
                            Circle()
                                .fill(type.levelColor(type.achievementLevel(for: Int(item.1))).opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: type.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(type.levelColor(type.achievementLevel(for: Int(item.1))))
                        }
                        
                        // 分类名称
                        Text(item.0)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 百分比和时间
                        Text("\(Int(percentage))% · \(Int(item.1))分钟")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    
                    if index < chartData.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // 每周趋势视图 
    var weeklyTrendsView: some View {
        VStack(spacing: 15) {
            // 生成示例数据 (实际应用中应来自用户模型)
            let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
            let data = [45, 30, 60, 80, 50, 90, 35].map { Double($0) }
            
            // 趋势图
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("专注时间趋势")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("平均：\(Int(data.reduce(0, +) / Double(data.count)))分钟/天")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                            LineMark(
                                x: .value("日期", weekdays[index]),
                                y: .value("分钟", animateCharts ? value : 0)
                            )
                            .foregroundStyle(themeManager.currentTheme.primaryColor.gradient)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .symbol {
                                Circle()
                                    .fill(themeManager.currentTheme.primaryColor)
                                    .frame(width: 8, height: 8)
                            }
                            
                            AreaMark(
                                x: .value("日期", weekdays[index]),
                                y: .value("分钟", animateCharts ? value : 0)
                            )
                            .foregroundStyle(themeManager.currentTheme.primaryColor.opacity(0.1).gradient)
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(preset: .aligned) { _ in
                            AxisValueLabel()
                                .font(.system(size: 12, weight: .regular))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel()
                                .font(.system(size: 12, weight: .regular))
                        }
                    }
                } else {
                    // iOS 16以下的兼容实现
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.7)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 30, height: animateCharts ? CGFloat(value) * 1.8 : 0)
                                
                                Text(weekdays[index])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 220)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
            
            // 统计摘要
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    statisticItem(title: "本周总时间", value: "390分钟", icon: "clock.fill", color: .blue)
                    statisticItem(title: "日均时间", value: "55.7分钟", icon: "chart.bar.fill", color: .orange)
                }
                
                HStack(spacing: 15) {
                    statisticItem(title: "最活跃的日子", value: "周六", icon: "star.fill", color: .yellow)
                    statisticItem(title: "完成任务数", value: "18个", icon: "checkmark.circle.fill", color: .green)
                }
            }
        }
    }
    
    // 统计数据项
    private func statisticItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
                            }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 详细统计视图
    var detailedStatsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("类别详情")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 5)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(AchievementType.allCases, id: \.self) { type in
                    let minutes = userModel.achievementProgress[type] ?? 0
                    
                    categoryCard(
                        title: type.rawValue,
                        minutes: minutes,
                        icon: type.icon,
                        color: type.levelColor(type.achievementLevel(for: minutes))
                    )
                }
            }
        }
    }
    
    // 分类卡片
    private func categoryCard(title: String, minutes: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标和标题
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // 时间
            Text("\(minutes)分钟")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 级别
            let level = AchievementType.allCases.first(where: { $0.rawValue == title })?.achievementLevel(for: minutes) ?? 0
            Text("Lv.\(level)")
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                )
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationView {
    StatsView()
        .environmentObject(UserModel())
        .environmentObject(ThemeManager())
    }
} 
