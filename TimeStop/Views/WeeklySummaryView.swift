import SwiftUI
import Charts

struct WeeklySummaryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animateCharts = false
    
    var summary: TimeAnalysisSummary
    
    // 示例数据 - 真实应用中应从summary中获取
    private let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
    private let timeData = [45, 72, 60, 80, 55, 90, 65].map { Double($0) }
    private let categories = ["工作", "学习", "休闲", "运动", "社交"]
    private let categoryValues = [120, 90, 60, 45, 30]
    private let categoryColors: [Color] = [.blue, .green, .orange, .purple, .red]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 顶部卡片 - 总览信息
                weeklyOverviewCard
                
                // 每日时间分布
                dailyDistributionCard
                
                // 类别占比
                categoryDistributionCard
                
                // 详细统计
                detailsSection
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("周统计")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // 加载时添加动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateCharts = true
                }
            }
        }
    }
    
    // 每周总览卡片
    var weeklyOverviewCard: some View {
        VStack(spacing: 20) {
            // 总体数据
            HStack(spacing: 20) {
                // 总时间
                statItem(title: "本周总时间", value: formatMinutes(summary.totalTime), icon: "clock.fill", color: .blue)
                
                // 任务数
                statItem(title: "任务总数", value: "\(summary.taskCount)个", icon: "checklist", color: .green)
            }
            
            HStack(spacing: 20) {
                // 平均时间
                statItem(title: "平均任务时长", value: "\(summary.avgDuration)分钟", icon: "timer", color: .orange)
                
                // 专注天数
                statItem(title: "专注天数", value: "5天", icon: "calendar", color: .purple)
            }
        }
    }
    
    // 统计项
    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 每日时间分布卡片
    var dailyDistributionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("每日时间分布")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Text("平均: \(Int(timeData.reduce(0, +) / Double(timeData.count)))分钟/天")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(timeData.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("天", weekdays[index]),
                            y: .value("分钟", animateCharts ? value : 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(8)
                    }
                    
                    RuleMark(y: .value("平均值", timeData.reduce(0, +) / Double(timeData.count)))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(Color.red)
                        .annotation(position: .trailing) {
                            Text("平均")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                }
                .frame(height: 220)
                .padding(.horizontal)
            } else {
                // iOS 16以下的后备实现
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(timeData.enumerated()), id: \.offset) { index, value in
                        VStack {
                            // 柱状图
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [themeManager.currentTheme.primaryColor, themeManager.currentTheme.primaryColor.opacity(0.7)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: animateCharts ? CGFloat(value * 1.5) : 0)
                                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateCharts)
                            
                            // 标签
                            Text(weekdays[index])
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 类别占比卡片
    var categoryDistributionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("类别占比")
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal)
            
            if #available(iOS 16.0, *) {
                // iOS 16 和以上使用 Charts 框架
                VStack {
                    Chart {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            BarMark(
                                x: .value("Category", category),
                                y: .value("Value", categoryValues[index])
                            )
                            .foregroundStyle(categoryColors[index])
                            .cornerRadius(6)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 220)
                    .padding(.horizontal)
                    
                    // 图例
                    HStack {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(categoryColors[index])
                                    .frame(width: 8, height: 8)
                                
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if index < categories.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                // iOS 16 以下使用替代方案
                Text("图表需要iOS 16或更高版本")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                
                // 计算总和
                let totalValue = categoryValues.reduce(0, +)
                
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    let percentage = Double(categoryValues[index]) / Double(totalValue)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(categoryColors[index].opacity(0.2))
                                    .frame(width: 28, height: 28)
                                
                                Circle()
                                    .fill(categoryColors[index])
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(category)
                                .font(.system(size: 15, weight: .medium))
                            
                            Spacer()
                            
                            Text("\(categoryValues[index])分钟")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("(\(Int(percentage * 100))%)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(categoryColors[index])
                        }
                        
                        // 进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [categoryColors[index], categoryColors[index].opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: animateCharts ? CGFloat(percentage) * (UIScreen.main.bounds.width - 60) : 0, height: 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 详细统计部分
    var detailsSection: some View {
        VStack(spacing: 15) {
            // 时间分配情况
            if !summary.overAllocatedTypes.isEmpty {
                detailCard(
                    title: "过度分配时间",
                    items: summary.overAllocatedTypes.map { "\($0.0): \(formatMinutes($0.1))" },
                    color: .orange,
                    icon: "arrow.up.right.circle.fill"
                )
            }
            
            if !summary.underAllocatedTypes.isEmpty {
                detailCard(
                    title: "分配不足时间",
                    items: summary.underAllocatedTypes.map { "\($0.0): \(formatMinutes($0.1))" },
                    color: .blue,
                    icon: "arrow.down.right.circle.fill"
                )
            }
            
            // 周建议
            detailCard(
                title: "本周建议",
                items: [
                    "增加「休闲」类别的时间，缓解压力",
                    "减少工作日的任务数量，提高完成率",
                    "优化「学习」时段分布，避免过度集中"
                ],
                color: .green,
                icon: "lightbulb.fill"
            )
        }
    }
    
    // 详细卡片
    private func detailCard(title: String, items: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    
                    Text(item)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    // 格式化分钟
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
        } else {
            return "\(mins)分钟"
        }
    }
}

#Preview {
    NavigationView {
        // 创建示例数据
        let summary = TimeAnalysisSummary(
            totalTime: 385,
            taskCount: 15,
            avgDuration: 25,
            overAllocatedTypes: [("工作", 135), ("学习", 95)],
            underAllocatedTypes: [("休闲", 55), ("社交", 35)],
            trendingUpTypes: [],
            trendingDownTypes: []
        )
        
        return WeeklySummaryView(summary: summary)
            .environmentObject(ThemeManager())
    }
} 