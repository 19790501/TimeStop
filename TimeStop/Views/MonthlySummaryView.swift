import SwiftUI
import Charts

struct MonthlySummaryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeFrame = 0
    @State private var animateCharts = false
    
    var summary: TimeAnalysisSummary
    
    // 示例数据 - 真实应用中应从summary中获取
    private let days = Array(1...30)
    private let timeData = [62, 48, 75, 30, 45, 0, 20, 15, 55, 72, 68, 40, 35, 0, 45, 
                            65, 70, 80, 75, 65, 60, 0, 15, 37, 48, 55, 67, 72, 85, 90]
    private let categories = ["工作", "学习", "休闲", "家务", "运动", "社交"]
    private let categoryColors: [Color] = [.blue, .green, .orange, .purple, .red, .yellow]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // 顶部统计卡片
                topStatsCard
                
                // 时间段选择器
                timeFrameSelector
                
                // 时间趋势图
                trendsChartCard
                
                // 时间分配图
                timeAllocationCard
                
                // 详细统计
                summaryDetailsSection
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("月度总结")
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
    
    // 顶部统计卡片
    var topStatsCard: some View {
        HStack(spacing: 15) {
            // 左侧总时间
            VStack(alignment: .leading, spacing: 8) {
                Text("总时间")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(summary.totalTime)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("分钟")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(formatMinutes(summary.totalTime))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
            // 右侧任务数
            VStack(alignment: .leading, spacing: 8) {
                Text("任务数")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(summary.taskCount)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("个")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("平均 \(summary.avgDuration) 分钟/任务")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    // 时间段选择器
    var timeFrameSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeFrame = index
                    }
                }) {
                    Text(["本月", "上月"][index])
                        .font(.system(size: 15, weight: selectedTimeFrame == index ? .semibold : .regular))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTimeFrame == index ? themeManager.colors.primary : .secondary)
                }
                .background(
                    ZStack {
                        if selectedTimeFrame == index {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.colors.primary.opacity(0.1))
                                .matchedGeometryEffect(id: "TAB", in: namespace)
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }
    
    @Namespace private var namespace
    
    // 时间趋势图
    var trendsChartCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("每日时间趋势")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("平均: \(Int(timeData.reduce(0, +)) / timeData.count)分钟/天")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // 趋势图
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(timeData.enumerated()), id: \.offset) { index, value in
                        if value > 0 {
                            LineMark(
                                x: .value("日期", days[index]),
                                y: .value("分钟", animateCharts ? value : 0)
                            )
                            .foregroundStyle(themeManager.colors.primary.gradient)
                            .symbol {
                                Circle()
                                    .fill(themeManager.colors.primary)
                                    .frame(width: 6, height: 6)
                            }
                            
                            AreaMark(
                                x: .value("日期", days[index]),
                                y: .value("分钟", animateCharts ? value : 0)
                            )
                            .foregroundStyle(themeManager.colors.primary.opacity(0.1).gradient)
                        }
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(preset: .automatic) { value in
                        if let day = value.as(Int.self), day % 5 == 0 {
                            AxisValueLabel {
                                Text("\(day)日")
                                    .font(.system(size: 11))
                            }
                            AxisGridLine()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let yValue = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(yValue)分")
                                    .font(.system(size: 11))
                            }
                            AxisGridLine()
                        }
                    }
                }
            } else {
                // iOS 16以下的后备方案
                Text("暂无图表数据")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 时间分配图
    var timeAllocationCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("时间分配")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            // 分配图表
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                        // 使用BarMark代替SectorMark以兼容iOS 16
                        BarMark(
                            x: .value("分类", ""),
                            y: .value("时间", animateCharts ? Double(index * 15 + 10) : 0)
                        )
                        .foregroundStyle(categoryColors[index])
                        .position(by: .value("分类", category))
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 220)
            } else {
                // iOS 16以下的后备方案
                Text("暂无图表数据")
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // 分类图例
            VStack(spacing: 10) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    HStack {
                        Circle()
                            .fill(categoryColors[index])
                            .frame(width: 12, height: 12)
                        
                        Text(category)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(index * 15 + 10)分钟 · \(Int(Double(index * 15 + 10) / Double(summary.totalTime) * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if index < categories.count - 1 {
                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 详细统计部分
    var summaryDetailsSection: some View {
        VStack(spacing: 15) {
            // 时间分配情况
            summaryGroupCard(title: "过度分配时间", items: summary.overAllocatedTypes.map { "\($0.0): \(formatMinutes($0.1))" }, color: .orange)
            
            summaryGroupCard(title: "分配不足时间", items: summary.underAllocatedTypes.map { "\($0.0): \(formatMinutes($0.1))" }, color: .blue)
            
            // 趋势情况
            if !summary.trendingUpTypes.isEmpty {
                summaryGroupCard(title: "上升趋势", items: summary.trendingUpTypes.map { "\($0.0): +\(String(format: "%.1f", $0.1))%" }, color: .green)
            }
            
            if !summary.trendingDownTypes.isEmpty {
                summaryGroupCard(title: "下降趋势", items: summary.trendingDownTypes.map { "\($0.0): -\(String(format: "%.1f", $0.1))%" }, color: .red)
            }
        }
    }
    
    // 分组统计卡片
    private func summaryGroupCard(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 4, height: 16)
                    .cornerRadius(2)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            if items.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.leading, 10)
            } else {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(color.opacity(0.8))
                        
                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                    }
                    .padding(.leading, 10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // 格式化分钟为小时分钟格式
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
            totalTime: 325,
            taskCount: 18,
            avgDuration: 18,
            overAllocatedTypes: [("工作", 120), ("学习", 80)],
            underAllocatedTypes: [("休闲", 45), ("社交", 30)],
            trendingUpTypes: [("工作", 15.2), ("运动", 8.5)],
            trendingDownTypes: [("社交", 12.3)]
        )
        
        return MonthlySummaryView(summary: summary)
            .environmentObject(ThemeManager())
    }
} 