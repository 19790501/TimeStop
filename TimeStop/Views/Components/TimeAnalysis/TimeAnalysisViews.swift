import SwiftUI
import Foundation

// 详细建议视图
struct DetailedSuggestionView: View {
    let taskType: String
    let suggestion: (title: String, objectiveReasons: [String], subjectiveReasons: [String], suggestions: [String])
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题部分
                    Text(suggestion.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.text)
                        .padding(.bottom, 5)
                    
                    // 客观原因部分
                    if !suggestion.objectiveReasons.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("客观因素")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .padding(.bottom, 4)
                            
                            ForEach(suggestion.objectiveReasons, id: \.self) { reason in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.7))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    Text(reason)
                                        .font(.body)
                                        .foregroundColor(themeManager.colors.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // 主观原因部分
                    if !suggestion.subjectiveReasons.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("主观因素")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .padding(.bottom, 4)
                            
                            ForEach(suggestion.subjectiveReasons, id: \.self) { reason in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.7))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    
                                    Text(reason)
                                        .font(.body)
                                        .foregroundColor(themeManager.colors.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // 建议部分
                    if !suggestion.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("改进建议")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .padding(.bottom, 4)
                            
                            ForEach(suggestion.suggestions, id: \.self) { suggestionItem in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Color.yellow)
                                        .font(.system(size: 14))
                                        .padding(.top, 2)
                                    
                                    Text(suggestionItem)
                                        .font(.body)
                                        .foregroundColor(themeManager.colors.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(themeManager.colors.background)
            }
            .navigationBarTitle("关于\(taskType)的建议", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    isPresented = false
                }) {
                    Text("关闭")
                        .foregroundColor(themeManager.colors.primary)
                }
            )
        }
    }
}

// 周总结视图
struct WeeklySummaryView: View {
    let summary: TimeAnalysisSummary
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部标题和基本数据
                    VStack(alignment: .leading, spacing: 10) {
                        Text("本周时间分析")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.text)
                        
                        HStack {
                            StatisticCard(title: "总时长", value: formatHours(summary.totalTime))
                            StatisticCard(title: "任务数", value: "\(summary.taskCount)个")
                            StatisticCard(title: "平均时长", value: "\(summary.avgDuration)分钟")
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // 过度分配的时间
                    if !summary.overAllocatedTypes.isEmpty {
                        SummarySection(
                            title: "过度分配的时间",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange
                        ) {
                            ForEach(summary.overAllocatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("花费了过多时间 (\(formatHours(item.minutes)))")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 不足分配的时间
                    if !summary.underAllocatedTypes.isEmpty {
                        SummarySection(
                            title: "不足分配的时间",
                            icon: "arrow.down.circle.fill",
                            iconColor: .red
                        ) {
                            ForEach(summary.underAllocatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("时间不足 (\(formatHours(item.minutes)))")
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 频繁调整的任务
                    if !summary.frequentlyAdjustedTypes.isEmpty {
                        SummarySection(
                            title: "频繁调整的任务",
                            icon: "slider.horizontal.3",
                            iconColor: .blue
                        ) {
                            ForEach(summary.frequentlyAdjustedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("\(item.adjustmentCount)次调整 (\(formatPercentage(item.adjustmentPercentage)))")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 频繁终止的任务
                    if !summary.frequentlyTerminatedTypes.isEmpty {
                        SummarySection(
                            title: "频繁终止的任务",
                            icon: "xmark.circle.fill",
                            iconColor: .red
                        ) {
                            ForEach(summary.frequentlyTerminatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("\(item.terminatedCount)次终止 (\(formatPercentage(item.terminationPercentage)))")
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 时间模式分析
                    SummarySection(
                        title: "时间模式分析",
                        icon: "chart.bar.fill",
                        iconColor: .purple
                    ) {
                        if !summary.mostProductiveTimeOfDay.isEmpty {
                            InfoRow(label: "最高效时段", value: summary.mostProductiveTimeOfDay, valueColor: .green)
                        }
                        
                        if !summary.leastProductiveTimeOfDay.isEmpty {
                            InfoRow(label: "效率较低时段", value: summary.leastProductiveTimeOfDay, valueColor: .orange)
                        }
                        
                        ForEach(summary.bestCombinations.indices, id: \.self) { index in
                            let combination = summary.bestCombinations[index]
                            InfoRow(
                                label: "高效组合 \(index + 1)",
                                value: "\(combination.first) + \(combination.second): \(combination.synergy)",
                                valueColor: .blue
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("周总结", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("关闭")
                        .foregroundColor(themeManager.colors.primary)
                }
            )
            .background(themeManager.colors.background)
        }
    }
    
    // 格式化小时
    private func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    // 格式化百分比
    private func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.1f%%", percentage)
    }
}

// 月总结视图
struct MonthlySummaryView: View {
    let summary: TimeAnalysisSummary
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部标题和基本数据
                    VStack(alignment: .leading, spacing: 10) {
                        Text("本月时间分析")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.text)
                        
                        HStack {
                            StatisticCard(title: "总时长", value: formatHours(summary.totalTime))
                            StatisticCard(title: "任务数", value: "\(summary.taskCount)个")
                            StatisticCard(title: "平均时长", value: "\(summary.avgDuration)分钟")
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // 过度分配的时间
                    if !summary.overAllocatedTypes.isEmpty {
                        SummarySection(
                            title: "过度分配的时间",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange
                        ) {
                            ForEach(summary.overAllocatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("花费了过多时间 (\(formatHours(item.minutes)))")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 不足分配的时间
                    if !summary.underAllocatedTypes.isEmpty {
                        SummarySection(
                            title: "不足分配的时间",
                            icon: "arrow.down.circle.fill",
                            iconColor: .red
                        ) {
                            ForEach(summary.underAllocatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("时间不足 (\(formatHours(item.minutes)))")
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 趋势变化
                    SummarySection(
                        title: "本月趋势",
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .blue
                    ) {
                        if !summary.trendingUpTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("增长趋势")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.text)
                                
                                ForEach(summary.trendingUpTypes, id: \.type) { item in
                                    HStack {
                                        Text("• \(item.type):")
                                            .foregroundColor(themeManager.colors.text)
                                        
                                        Text("上升 \(formatPercentage(item.increasePercentage))")
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(.bottom, 6)
                        }
                        
                        if !summary.trendingDownTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("下降趋势")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.text)
                                
                                ForEach(summary.trendingDownTypes, id: \.type) { item in
                                    HStack {
                                        Text("• \(item.type):")
                                            .foregroundColor(themeManager.colors.text)
                                        
                                        Text("下降 \(formatPercentage(item.decreasePercentage))")
                                            .foregroundColor(.red)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding(.bottom, 6)
                        }
                        
                        if !summary.mostConsistentType.isEmpty {
                            InfoRow(label: "最稳定任务类型", value: summary.mostConsistentType, valueColor: .blue)
                        }
                        
                        if !summary.leastConsistentType.isEmpty {
                            InfoRow(label: "最不稳定任务类型", value: summary.leastConsistentType, valueColor: .orange)
                        }
                    }
                    
                    // 频繁调整的任务
                    if !summary.frequentlyAdjustedTypes.isEmpty {
                        SummarySection(
                            title: "频繁调整的任务",
                            icon: "slider.horizontal.3",
                            iconColor: .blue
                        ) {
                            ForEach(summary.frequentlyAdjustedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("\(item.adjustmentCount)次调整 (\(formatPercentage(item.adjustmentPercentage)))")
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // 频繁终止的任务
                    if !summary.frequentlyTerminatedTypes.isEmpty {
                        SummarySection(
                            title: "频繁终止的任务",
                            icon: "xmark.circle.fill",
                            iconColor: .red
                        ) {
                            ForEach(summary.frequentlyTerminatedTypes, id: \.type) { item in
                                HStack {
                                    Text("• \(item.type):")
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("\(item.terminatedCount)次终止 (\(formatPercentage(item.terminationPercentage)))")
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("月总结", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("关闭")
                        .foregroundColor(themeManager.colors.primary)
                }
            )
            .background(themeManager.colors.background)
        }
    }
    
    // 格式化小时
    private func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    // 格式化百分比
    private func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.1f%%", percentage)
    }
}

// 辅助组件 - 统计卡片
struct StatisticCard: View {
    let title: String
    let value: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.colors.secondaryText)
            
            Text(value)
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(10)
    }
}

// 辅助组件 - 摘要分组
struct SummarySection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.text)
            }
            
            content
                .padding(.leading, 4)
        }
        .padding(15)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// 辅助组件 - 信息行
struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(themeManager.colors.text)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 2)
    }
}

// 创建视图的AnyView扩展，用于类型擦除
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
} 