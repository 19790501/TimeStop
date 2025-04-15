import SwiftUI
import Foundation

// 任务类型统计
struct TaskTypeStat: Identifiable {
    let id = UUID()
    let type: String
    var count: Int
    var minutes: Int
    var originalMinutes: Int
    var adjustmentMinutes: Int
    var terminatedCount: Int = 0
    var reducedMinutes: Int = 0
    var color: Color = .gray
    
    // 格式化时间为小时和分钟
    var formattedTime: String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
        } else {
            return "\(mins)分钟"
        }
    }
}

// 时间分析摘要数据结构
struct TimeAnalysisSummary {
    // 基本分析数据
    var totalTime: Int = 0
    var taskCount: Int = 0
    var avgDuration: Int = 0
    
    // 时间过多/过少分析
    var overAllocatedTypes: [(type: String, minutes: Int)] = []
    var underAllocatedTypes: [(type: String, minutes: Int)] = []
    
    // 调整/终止分析
    var frequentlyAdjustedTypes: [(type: String, adjustmentCount: Int, adjustmentPercentage: Double)] = []
    var frequentlyTerminatedTypes: [(type: String, terminatedCount: Int, terminationPercentage: Double)] = []
    
    // 模式分析
    var mostProductiveTimeOfDay: String = ""
    var leastProductiveTimeOfDay: String = ""
    var bestCombinations: [(first: String, second: String, synergy: String)] = []
    
    // 趋势分析 (仅月总结使用)
    var trendingUpTypes: [(type: String, increasePercentage: Double)] = []
    var trendingDownTypes: [(type: String, decreasePercentage: Double)] = []
    var mostConsistentType: String = ""
    var leastConsistentType: String = ""
}

// 角色标准数据结构
struct RoleStandard {
    let type: String // "创业者", "高管", "白领"
    let standards: [String: TimeStandard]
    let description: String
    
    // 通过任务类型获取时间标准
    func getStandard(for taskType: String) -> TimeStandard? {
        return standards[taskType]
    }
}

// 时间标准数据结构
struct TimeStandard {
    let lowerBound: Double // 小时
    let upperBound: Double // 小时
    let priorityCoefficient: Int // 1-5
    
    // 判断时间是否在基准范围内
    func isWithinStandard(_ hours: Double) -> DeviationType {
        if hours < lowerBound {
            return .deficient
        } else if hours > upperBound {
            return .excess
        } else {
            return .balanced
        }
    }
    
    // 计算偏差百分比
    func deviationPercentage(_ hours: Double) -> Double {
        if hours < lowerBound {
            return (lowerBound - hours) / lowerBound * 100
        } else if hours > upperBound {
            return (hours - upperBound) / upperBound * 100
        } else {
            return 0
        }
    }
}

// 偏差类型枚举
enum DeviationType {
    case excess // 过多
    case deficient // 过少
    case balanced // 正常
}

// 因素类型枚举
enum FactorType {
    case objective // 客观因素
    case subjective // 主观因素
}

// 时间影响因素结构
struct TimeInfluenceFactor {
    let factorType: FactorType
    let description: String
    let impactLevel: Int // 1-5影响程度
}

// 健康状态枚举
enum HealthStatus {
    case good           // 良好
    case needsAttention // 需注意
    case poor           // 严重问题
    
    var icon: String {
        switch self {
        case .good: return "✓"
        case .needsAttention: return "⚠️"
        case .poor: return "❗"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return Color.green
        case .needsAttention: return Color.orange
        case .poor: return Color.red
        }
    }
}

// 任务类型指标
struct TaskTypeMetric: Identifiable {
    let id = UUID()
    let type: String           // 任务类型名称
    let percentage: Double     // 当前占比
    let minutes: Int           // 实际分钟数
    let idealRange: ClosedRange<Double> // 理想范围
    let adjustmentFrequency: Int // 调整次数
    let averageAdjustmentPercent: Double // 平均调整幅度
    let interruptionCount: Int  // 中断次数
    
    // 计算健康状态
    var healthStatus: HealthStatus {
        if idealRange.contains(percentage) {
            return .good
        } else if abs(percentage - idealRange.lowerBound) <= 5 || 
                  abs(percentage - idealRange.upperBound) <= 5 {
            return .needsAttention
        } else {
            return .poor
        }
    }
    
    // 生成进度条填充比例
    var progressFillRatio: Double {
        min(1.0, percentage / 100.0)
    }
    
    // 生成状态描述
    var statusDescription: String {
        switch healthStatus {
        case .good:
            return "✓"
        case .needsAttention:
            return percentage < idealRange.lowerBound ? "不足" : "过多"
        case .poor:
            return percentage < idealRange.lowerBound ? "严重不足" : "严重过多"
        }
    }
    
    // 生成调整建议
    var adjustmentSuggestion: String? {
        if adjustmentFrequency > 5 {
            return "频繁调整(\(adjustmentFrequency)次)，建议更准确估计时间"
        }
        if interruptionCount > 5 {
            return "经常中断(\(interruptionCount)次)，建议减少环境干扰"
        }
        if averageAdjustmentPercent > 20 {
            return "调整幅度大(+\(Int(averageAdjustmentPercent))%)，建议预留缓冲时间"
        }
        if healthStatus == .poor && percentage < idealRange.lowerBound {
            return "时间严重不足，建议优先安排"
        }
        return nil
    }
}

// 总体健康指标
struct TimeHealthDashboard {
    var taskMetrics: [TaskTypeMetric]
    
    // 计算总体健康分数 (0-100)
    var healthScore: Int {
        // 基础分80分
        var score = 80
        
        // 根据各指标加减分
        for metric in taskMetrics {
            switch metric.healthStatus {
            case .good:
                score += 3
            case .needsAttention:
                score -= 3
            case .poor:
                score -= 8
            }
            
            // 调整次数过多扣分
            if metric.adjustmentFrequency > 5 {
                score -= min(10, metric.adjustmentFrequency)
            }
            
            // 中断次数过多扣分
            if metric.interruptionCount > 5 {
                score -= min(10, metric.interruptionCount)
            }
        }
        
        // 控制分数范围
        return min(100, max(0, score))
    }
    
    // 获取健康状态图标
    var healthIcon: String {
        if healthScore >= 80 {
            return "✓"
        } else if healthScore >= 60 {
            return "⚠️"
        } else {
            return "❗"
        }
    }
    
    // 获取健康状态颜色
    var healthColor: Color {
        if healthScore >= 80 {
            return Color.green
        } else if healthScore >= 60 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    // 获取需要关注的任务类型
    var tasksNeedingAttention: [TaskTypeMetric] {
        return taskMetrics.filter { 
            $0.healthStatus != .good || 
            $0.adjustmentFrequency > 5 || 
            $0.interruptionCount > 5 
        }
    }
}

// 确保可以访问ThemeManager中定义的AppColors
struct TimeWhereView_test: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appViewModel: AppViewModel
    
    // 定义时间范围枚举
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "今日"
        case week = "本周"
        case month = "本月"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedRange: TimeRange = .today
    @State private var selectedRole: String = "创业者" // 默认选择创业者角色
    @State private var showTaskDetail: Bool = false
    @State private var selectedTaskType: String?
    @State private var showAlert: Bool = false
    @State private var showDetailedSuggestion = false
    @State private var currentTaskType = ""
    @State private var detailedSuggestion = (title: "", objectiveReasons: [String](), subjectiveReasons: [String](), suggestions: [String]())
    @State private var showWeeklySummary: Bool = false
    @State private var showMonthlySummary: Bool = false
    @State private var isInitialLoad: Bool = true // 添加初始加载状态
    
    // 缺失的计算属性
    private var tasks: [Task] {
        return tasksForSelectedRange
    }
    
    private var weeklySummary: TimeAnalysisSummary? {
        return getSampleWeeklySummary()
    }
    
    private var monthlySummary: TimeAnalysisSummary? {
        return getSampleMonthlySummary()
    }
    
    private var taskTypeStats: [TaskTypeStat] {
        let tasks = getWeekTasks()
        return getTaskTypeStatsForTasks(tasks)
    }
    
    // 获取当前选择范围内的任务
    private var tasksForSelectedRange: [Task] {
        switch selectedRange {
        case .today:
            return appViewModel.getTodayTasks()
        case .week:
            return appViewModel.getWeeklyTasks()
        case .month:
            return appViewModel.getMonthlyTasks()
        }
    }
    
    // 头部视图
    private var headerView: some View {
        HStack {
            Text("时间分析")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                // 生成测试数据
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // 角色选择器
    private var roleSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["创业者", "高管", "白领"], id: \.self) { role in
                    Button(action: {
                        selectedRole = role
                    }) {
                        Text(role)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedRole == role ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedRole == role ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 时间范围选择器
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedRange == range ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedRange == range ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("暂无任务数据")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("完成的任务将在这里显示分析")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // 时间分配视图
    private var timeAllocationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分配")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(taskTypeStats) { stat in
                HStack {
                    Circle()
                        .fill(stat.color)
                        .frame(width: 14, height: 14)
                    
                    Text(stat.type)
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text(stat.formattedTime)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                roleSelector
                
                timeRangeSelector
                
                if selectedRole != nil && !isInitialLoad {
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        // 添加时间健康仪表盘
                        TimeHealthDashboardView(
                            healthScore: calculateHealthScore(),
                            taskMetrics: getTaskMetrics(),
                            themeColor: Color.blue
                        )
                        .padding(.horizontal)
                        
                        // 保留原有的图表如果需要
                        if !taskTypeStats.isEmpty {
                            timeAllocationView
                        }
                    }
                } else {
                    // 选择角色提示
                    Text("请选择一个角色以查看时间分配分析")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showWeeklySummary) {
            if let summary = weeklySummary {
                WeeklySummaryView(summary: summary)
            }
        }
        .sheet(isPresented: $showMonthlySummary) {
            if let summary = monthlySummary {
                MonthlySummaryView(summary: summary)
            }
        }
    }
    
    // 计算健康分数
    private func calculateHealthScore() -> Int {
        let dashboard = generateTimeHealthDashboard()
        return dashboard.healthScore
    }
    
    // 获取任务指标数据
    private func getTaskMetrics() -> [TaskTypeMetric] {
            let stats = getTaskTypesStats()
            
        return stats.map { stat -> TaskTypeMetric in
            let idealRange = getIdealRangeForTaskType(stat.type)
            let percentage = totalTimeForSelectedRange > 0 ? Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100 : 0
            
            return TaskTypeMetric(
                id: UUID(),
                type: stat.type,
                percentage: percentage,
                minutes: stat.minutes,
                idealRange: idealRange,
                adjustmentFrequency: stat.count > 0 ? Int(Double(stat.adjustmentMinutes) / Double(stat.originalMinutes) * 10) : 0,
                averageAdjustmentPercent: stat.originalMinutes > 0 ? Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100 : 0,
                interruptionCount: stat.terminatedCount
            )
        }
        .sorted { $0.percentage > $1.percentage }
    }
    
    // MARK: - 时间健康仪表盘相关方法
    
    // 获取任务类型的理想范围
    private func getIdealRangeForTaskType(_ type: String) -> ClosedRange<Double> {
        if let standard = currentRoleStandard.getStandard(for: type) {
            // 将小时转换为百分比范围
            let totalHours = currentRoleStandard.standards.values.reduce(0.0) { 
                result, standard in 
                return result + (standard.lowerBound + standard.upperBound) / 2
            }
            
            // 计算理想百分比范围
            let lowerPercent = (standard.lowerBound / totalHours) * 100
            let upperPercent = (standard.upperBound / totalHours) * 100
            
            return max(1, lowerPercent)...max(upperPercent, lowerPercent + 5)
        }
        
        // 如果没有找到标准，提供默认范围
        switch type {
        case "工作": return 30...40
        case "会议": return 10...15
        case "思考": return 15...20
        case "阅读": return 10...15
        case "运动": return 8...12
        case "睡觉": return 30...35
        case "生活": return 10...15
        case "摸鱼": return 3...5
        default: return 5...10
        }
    }
    
    // 生成时间健康仪表盘数据
    func generateTimeHealthDashboard() -> TimeHealthDashboard {
        let tasks = tasksForSelectedRange
        
        // 1. 按任务类型分组
        let tasksByType = Dictionary(grouping: tasks) { $0.title }
        
        // 2. 计算总时间
        let totalMinutes = tasks.reduce(0) { $0 + $1.duration }
        
        // 3. 为每种任务类型创建指标
        var metrics: [TaskTypeMetric] = []
        
        // 定义所有可能的任务类型，确保即使没有数据也显示
        let allTaskTypes = ["工作", "会议", "思考", "阅读", "运动", "睡觉", "生活", "摸鱼"]
        
        for type in allTaskTypes {
            let tasksOfType = tasksByType[type] ?? []
            
            // 计算占比
            let minutes = tasksOfType.reduce(0) { $0 + $1.duration }
            let percentage = totalMinutes > 0 ? (Double(minutes) / Double(totalMinutes) * 100) : 0
            
            // 计算调整指标
            let adjustments = tasksOfType.reduce(0) { $0 + ($1.timeAdjustments.isEmpty ? 0 : 1) }
            let adjustmentMinutes = tasksOfType.reduce(0) { $0 + $1.totalTimeAdjustment() }
            let originalMinutes = tasksOfType.reduce(0) { $0 + $1.originalDuration() }
            let adjustmentPercent = originalMinutes > 0 ? (Double(abs(adjustmentMinutes)) / Double(originalMinutes) * 100) : 0
            
            // 计算中断次数
            let interruptions = tasksOfType.filter { $0.isTerminated }.count
            
            // 获取理想范围
            let idealRange = getIdealRangeForTaskType(type)
            
            // 创建指标
            let metric = TaskTypeMetric(
                    type: type,
                percentage: percentage,
                    minutes: minutes,
                idealRange: idealRange,
                adjustmentFrequency: adjustments,
                averageAdjustmentPercent: adjustmentPercent,
                interruptionCount: interruptions
            )
            
            metrics.append(metric)
        }
        
        // 4. 按百分比排序
        metrics.sort { $0.percentage > $1.percentage }
        
        // 5. 创建仪表盘
        return TimeHealthDashboard(taskMetrics: metrics)
    }
}

// 详细建议视图
struct DetailedSuggestionView: View {
    let taskType: String
    let suggestion: (title: String, objectiveReasons: [String], subjectiveReasons: [String], suggestions: [String])
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 标题
                        Text(suggestion.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                            .padding(.top, 10)
                        
                        // 客观因素
                        VStack(alignment: .leading, spacing: 12) {
                            Text("客观因素")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.colors.text)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(suggestion.objectiveReasons, id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(themeManager.colors.secondaryText)
                                            .padding(.top, 6)
                                        
                                        Text(reason)
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.colors.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.colors.secondaryBackground)
                        )
                        
                        // 主观因素
                        VStack(alignment: .leading, spacing: 12) {
                            Text("主观因素")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.colors.text)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(suggestion.subjectiveReasons, id: \.self) { reason in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(themeManager.colors.secondaryText)
                                            .padding(.top, 6)
                                        
                                        Text(reason)
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.colors.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.colors.secondaryBackground)
                        )
                        
                        // 建议
                        VStack(alignment: .leading, spacing: 12) {
                            Text("改进建议")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.colors.text)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(suggestion.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.yellow)
                                            .padding(.top, 3)
                                        
                                        Text(suggestion)
                                            .font(.system(size: 16))
                                            .foregroundColor(themeManager.colors.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.colors.secondaryBackground)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("\(taskType)类活动分析", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                isPresented = false
            })
        }
    }
}

// MARK: - Summary Structures
// Using TimeAnalysisSummary for both weekly and monthly summaries

// 修改为使用TimeAnalysisSummary
extension TimeWhereView_test {
    // 定义为方法而非属性，避免重复声明
    func getSampleWeeklySummary() -> TimeAnalysisSummary {
        var summary = TimeAnalysisSummary()
        
        // 基本统计数据
        summary.totalTime = 1950 // 32.5小时 = 1950分钟
        summary.taskCount = 47   // 5种类型的任务总数
        summary.avgDuration = 41 // 平均每次约41分钟
        
        // 时间过多/过少分析
        summary.overAllocatedTypes = [
            ("工作", 720),   // 12小时
            ("睡觉", 480),  // 8小时
            ("运动", 360),  // 6小时
            ("阅读", 240),  // 4小时
            ("思考", 180),  // 3小时
            ("生活", 120),  // 2小时
            ("会议", 90),   // 1.5小时
            ("摸鱼", 60)    // 1小时
        ]
        
        summary.underAllocatedTypes = [
            ("工作", 120),  // 2小时
            ("睡觉", 180),  // 3小时
            ("运动", 240),  // 4小时
            ("阅读", 300),  // 5小时
            ("思考", 360),  // 6小时
            ("生活", 420),  // 7小时
            ("会议", 480),  // 8小时
            ("摸鱼", 540)   // 9小时
        ]
        
        summary.frequentlyAdjustedTypes = [
            ("工作", 15, 30.0),
            ("学习", 10, 20.0),
            ("阅读", 5, 10.0)
        ]
        
        summary.frequentlyTerminatedTypes = [
            ("工作", 8, 16.0),
            ("学习", 5, 10.0),
            ("娱乐", 12, 24.0)
        ]
        
        summary.mostProductiveTimeOfDay = "上午9点-11点"
        summary.leastProductiveTimeOfDay = "下午3点-4点"
        
        summary.bestCombinations = [
            ("运动", "工作", "运动后工作效率提升20%"),
            ("阅读", "思考", "阅读后思考质量提升15%"),
            ("工作", "休息", "短暂休息后工作专注度提升18%")
        ]
        
        summary.mostConsistentType = "工作"
        summary.leastConsistentType = "娱乐"
        
        summary.trendingUpTypes = [
            ("工作", 15.0),
            ("阅读", 10.0)
        ]
        
        summary.trendingDownTypes = [
            ("娱乐", 8.0),
            ("摸鱼", 12.0)
        ]
        
        return summary
    }
    
    func getSampleMonthlySummary() -> TimeAnalysisSummary {
        var summary = TimeAnalysisSummary()
        
        // 基本统计数据
        summary.totalTime = 8800  // 146.7小时 = 8800分钟
        summary.taskCount = 194   // 月度任务总量
        summary.avgDuration = 45  // 平均每次约45分钟
        
        // 时间过多/过少分析，月度数据量更大
        summary.overAllocatedTypes = [
            ("工作", 3200),  // 53.3小时
            ("睡觉", 2000),  // 33.3小时
            ("运动", 1500),  // 25小时
            ("阅读", 1200),  // 20小时
            ("思考", 900)    // 15小时
        ]
        
        summary.underAllocatedTypes = [
            ("生活", 600),   // 10小时
            ("会议", 450),   // 7.5小时
            ("摸鱼", 300)    // 5小时
        ]
        
        // 频繁调整类型
        summary.frequentlyAdjustedTypes = [
            ("工作", 30, 25.0),
            ("会议", 15, 30.0),
            ("思考", 10, 15.0)
        ]
        
        // 频繁终止类型
        summary.frequentlyTerminatedTypes = [
            ("工作", 20, 20.0),
            ("学习", 12, 25.0),
            ("思考", 8, 15.0)
        ]
        
        summary.mostProductiveTimeOfDay = "上午10点-12点"
        summary.leastProductiveTimeOfDay = "下午2点-4点"
        
        // 月度更注重长期模式
        summary.bestCombinations = [
            ("运动", "工作", "运动后工作效率提升25%"),
            ("阅读", "思考", "阅读后思考质量提升20%"),
            ("休息", "会议", "休息后会议专注度提高15%"),
            ("冥想", "学习", "冥想后学习吸收率提高18%")
        ]
        
        summary.mostConsistentType = "工作"
        summary.leastConsistentType = "思考"
        
        // 月度趋势分析
        summary.trendingUpTypes = [
            ("工作", 15.0),
            ("学习", 10.0),
            ("阅读", 8.0)
        ]
        
        summary.trendingDownTypes = [
            ("休闲", 12.0),
            ("娱乐", 8.0),
            ("社交", 5.0)
        ]
        
        return summary
    }
}

// MARK: - Weekly Summary View
struct WeeklySummaryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var summary: TimeAnalysisSummary
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题
                Text("本周时间总结")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top)
                
                // 总体时间概览
                VStack(alignment: .leading, spacing: 16) {
                    Text("总体概览")
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    HStack(spacing: 12) {
                        statBox(title: "专注总时长", value: "\(String(format: "%.1f", Double(summary.totalTime) / 60.0))小时")
                        statBox(title: "平均每次", value: "\(summary.avgDuration)分钟")
                    }
                    
                    // 使用任务类型统计
                    let taskTypeStats = getTaskTypesStatsForSummary()
                    taskCountsView(taskCounts: taskTypeStats)
                }
                
                // 时间分配问题
                timeAllocationIssuesSection
                
                // 最佳组合分析
                if !summary.bestCombinations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("任务组合分析")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        VStack(spacing: 12) {
                            ForEach(summary.bestCombinations, id: \.first) { combo in
                                patternRow(pattern: "\(combo.first) + \(combo.second)", description: combo.synergy)
                            }
                        }
                    }
                }
                
                // 生产力时段分析
                if !summary.mostProductiveTimeOfDay.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("生产力时段分析")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        HStack(spacing: 12) {
                            productivityTimeBox(title: "高效时段", time: summary.mostProductiveTimeOfDay, isPositive: true)
                            productivityTimeBox(title: "低效时段", time: summary.leastProductiveTimeOfDay, isPositive: false)
                        }
                    }
                }
                
                // 建议
                suggestionSection
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(themeManager.colors.background)
    }
    
    // 获取任务类型统计，用于显示
    private func getTaskTypesStatsForSummary() -> [String: Int] {
        var result: [String: Int] = [:]
        
        // 从overAllocatedTypes和underAllocatedTypes中提取任务类型数量
        for item in summary.overAllocatedTypes {
            result[item.type] = item.minutes / 30  // 假设平均每个任务30分钟
        }
        
        for item in summary.underAllocatedTypes {
            if result[item.type] == nil {
                result[item.type] = item.minutes / 30
            }
        }
        
        return result
    }
    
    private var timeAllocationIssuesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分配问题")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            if !summary.overAllocatedTypes.isEmpty {
                Text("过度分配")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.text.opacity(0.8))
                
                VStack(spacing: 8) {
                    ForEach(summary.overAllocatedTypes, id: \.type) { item in
                        issueBox(type: item.type, message: "占用过多:\(item.minutes)分钟", isOverAllocation: true)
                    }
                }
            }
            
            if !summary.underAllocatedTypes.isEmpty {
                Text("分配不足")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.text.opacity(0.8))
                    .padding(.top, 8)
                
                VStack(spacing: 8) {
                    ForEach(summary.underAllocatedTypes, id: \.type) { item in
                        issueBox(type: item.type, message: "仅用时:\(item.minutes)分钟", isOverAllocation: false)
                    }
                }
            }
        }
    }
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("改进建议")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            // 生成一些建议
            let suggestions = generateSuggestions()
            
            VStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    actionSuggestion(suggestion: suggestion)
                }
            }
        }
    }
    
    // 根据summary数据生成建议
    private func generateSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // 从超时分配中生成建议
        if !summary.overAllocatedTypes.isEmpty {
            let type = summary.overAllocatedTypes[0].type
            suggestions.append("考虑减少「\(type)」时间，适当分配给其他任务类型")
        }
        
        // 从不足分配中生成建议
        if !summary.underAllocatedTypes.isEmpty {
            let type = summary.underAllocatedTypes[0].type
            suggestions.append("建议增加「\(type)」时间，提升整体平衡性")
        }
        
        // 从频繁调整中生成建议
        if !summary.frequentlyAdjustedTypes.isEmpty {
            let item = summary.frequentlyAdjustedTypes[0]
            suggestions.append("「\(item.type)」任务频繁调整时间(占比\(Int(item.adjustmentPercentage))%)，建议提高时间预估准确性")
        }
        
        // 从频繁终止中生成建议
        if !summary.frequentlyTerminatedTypes.isEmpty {
            let item = summary.frequentlyTerminatedTypes[0]
            suggestions.append("「\(item.type)」任务频繁终止(占比\(Int(item.terminationPercentage))%)，建议检视任务设置的合理性")
        }
        
        // 如果建议太少，添加一些通用建议
        if suggestions.count < 2 {
            suggestions.append("尝试在高效时段(\(summary.mostProductiveTimeOfDay))安排重要任务")
            suggestions.append("为每天安排至少30分钟的专注思考时间")
        }
        
        return suggestions
    }
    
    private func productivityTimeBox(title: String, time: String, isPositive: Bool) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
            
            Text(time)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isPositive ? .green : .orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.colors.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func taskCountsView(taskCounts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("任务类型统计")
                .font(.subheadline)
                .foregroundColor(themeManager.colors.text.opacity(0.8))
            
            VStack(spacing: 8) {
                ForEach(taskCounts.sorted(by: { item1, item2 in item1.value > item2.value }), id: \.key) { type, count in
                    HStack {
                        Text(type)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.text)
                        
                        Spacer()
                        
                        Text("\(count)次")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeManager.colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func issueBox(type: String, message: String, isOverAllocation: Bool) -> some View {
        HStack {
            Image(systemName: isOverAllocation ? "exclamationmark.triangle" : "arrow.down.circle")
                .foregroundColor(isOverAllocation ? .orange : .blue)
            
            Text(type)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.colors.text)
            
            Spacer()
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(isOverAllocation ? .orange : .blue)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            (isOverAllocation ? Color.orange : Color.blue)
                .opacity(0.1)
        )
        .cornerRadius(8)
    }
    
    private func patternRow(pattern: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pattern)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.colors.text)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(10)
    }
    
    private func actionSuggestion(suggestion: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            
            Text(suggestion)
                .font(.system(size: 15))
                .foregroundColor(themeManager.colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Monthly Summary View
struct MonthlySummaryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var summary: TimeAnalysisSummary
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 标题
                Text("本月时间总结")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top)
                
                // 总体时间概览
                VStack(alignment: .leading, spacing: 16) {
                    Text("总体概览")
                        .font(.headline)
                        .foregroundColor(themeManager.colors.text)
                    
                    HStack(spacing: 12) {
                        statBox(title: "专注总时长", value: "\(String(format: "%.1f", Double(summary.totalTime) / 60.0))小时")
                        statBox(title: "平均每次", value: "\(summary.avgDuration)分钟")
                    }
                    
                    // 使用任务类型统计
                    let taskTypeStats = getTaskTypesStatsForSummary()
                    taskCountsView(taskCounts: taskTypeStats)
                }
                
                // 时间分配问题
                timeAllocationIssuesSection
                
                // 趋势分析 - 仅月度分析显示
                if !summary.trendingUpTypes.isEmpty || !summary.trendingDownTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("月度趋势分析")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        HStack(spacing: 12) {
                            trendBox(title: "上升趋势", trends: summary.trendingUpTypes, isPositive: true)
                            trendBox(title: "下降趋势", trends: adaptTrendingDownTypes(summary.trendingDownTypes), isPositive: false)
                        }
                    }
                }
                
                // 行为模式分析 - 使用最佳组合替代
                if !summary.bestCombinations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("月度任务组合分析")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        VStack(spacing: 12) {
                            ForEach(summary.bestCombinations, id: \.first) { combo in
                                patternRow(pattern: "\(combo.first) + \(combo.second)", description: combo.synergy)
                            }
                        }
                    }
                }
                
                // 一致性分析
                if !summary.mostConsistentType.isEmpty || !summary.leastConsistentType.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("任务一致性分析")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        HStack(spacing: 12) {
                            consistencyBox(title: "最稳定任务", type: summary.mostConsistentType, isPositive: true)
                            consistencyBox(title: "最不稳定任务", type: summary.leastConsistentType, isPositive: false)
                        }
                    }
                }
                
                // 建议
                suggestionSection
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(themeManager.colors.background)
    }
    
    // 获取任务类型统计，用于显示
    private func getTaskTypesStatsForSummary() -> [String: Int] {
        var result: [String: Int] = [:]
        
        // 从overAllocatedTypes和underAllocatedTypes中提取任务类型数量
        for item in summary.overAllocatedTypes {
            result[item.type] = item.minutes / 30  // 假设平均每个任务30分钟
        }
        
        for item in summary.underAllocatedTypes {
            if result[item.type] == nil {
                result[item.type] = item.minutes / 30
            }
        }
        
        return result
    }
    
    private var timeAllocationIssuesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("月度时间分配问题")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            if !summary.overAllocatedTypes.isEmpty {
                Text("过度分配")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.text.opacity(0.8))
                
                VStack(spacing: 8) {
                    ForEach(summary.overAllocatedTypes, id: \.type) { item in
                        issueBox(type: item.type, message: "占用过多:\(item.minutes)分钟", isOverAllocation: true)
                    }
                }
            }
            
            if !summary.underAllocatedTypes.isEmpty {
                Text("分配不足")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.text.opacity(0.8))
                    .padding(.top, 8)
                
                VStack(spacing: 8) {
                    ForEach(summary.underAllocatedTypes, id: \.type) { item in
                        issueBox(type: item.type, message: "仅用时:\(item.minutes)分钟", isOverAllocation: false)
                    }
                }
            }
        }
    }
    
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("月度改进建议")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            // 生成一些建议
            let suggestions = generateSuggestions()
            
            VStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    actionSuggestion(suggestion: suggestion)
                }
            }
        }
    }
    
    // 根据summary数据生成建议
    private func generateSuggestions() -> [String] {
        var suggestions: [String] = []
        
        // 从超时分配中生成建议
        if !summary.overAllocatedTypes.isEmpty {
            let type = summary.overAllocatedTypes[0].type
            suggestions.append("考虑减少「\(type)」时间，本月该类型任务占比过高")
        }
        
        // 从不足分配中生成建议
        if !summary.underAllocatedTypes.isEmpty {
            let type = summary.underAllocatedTypes[0].type
            suggestions.append("建议增加「\(type)」时间，提升月度时间分配平衡性")
        }
        
        // 从趋势中生成建议
        if !summary.trendingUpTypes.isEmpty {
            let item = summary.trendingUpTypes[0]
            suggestions.append("「\(item.type)」时间呈上升趋势(+\(String(format: "%.1f", item.increasePercentage))%)，关注是否符合预期")
        }
        
        if !summary.trendingDownTypes.isEmpty {
            let item = summary.trendingDownTypes[0]
            suggestions.append("「\(item.type)」时间呈下降趋势(\(String(format: "%.1f", item.decreasePercentage))%)，注意是否需要调整")
        }
        
        // 从一致性中生成建议
        if !summary.leastConsistentType.isEmpty {
            suggestions.append("「\(summary.leastConsistentType)」任务时间分配不稳定，尝试建立更规律的习惯")
        }
        
        // 如果建议太少，添加一些通用建议
        if suggestions.count < 2 {
            suggestions.append("尝试定期回顾月度时间分配，识别并优化低效模式")
            suggestions.append("为下月制定合理的时间预算，提高时间利用率")
        }
        
        return suggestions
    }
    
    private func trendBox(title: String, trends: [(type: String, increasePercentage: Double)], isPositive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
            
            ForEach(trends.prefix(2), id: \.type) { trend in
                HStack {
                    Text(trend.type)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", abs(trend.increasePercentage)))%")
                        .font(.system(size: 14))
                        .foregroundColor(isPositive ? .green : .red)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func consistencyBox(title: String, type: String, isPositive: Bool) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
            
            Text(type)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isPositive ? .green : .orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func statBox(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.colors.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
    
    private func taskCountsView(taskCounts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月度任务统计")
                .font(.subheadline)
                .foregroundColor(themeManager.colors.text.opacity(0.8))
            
            VStack(spacing: 8) {
                ForEach(taskCounts.sorted(by: { item1, item2 in item1.value > item2.value }), id: \.key) { type, count in
                    HStack {
                        Text(type)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.text)
                        
                        Spacer()
                        
                        Text("\(count)次")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeManager.colors.secondaryBackground.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func issueBox(type: String, message: String, isOverAllocation: Bool) -> some View {
        HStack {
            Image(systemName: isOverAllocation ? "exclamationmark.triangle" : "arrow.down.circle")
                .foregroundColor(isOverAllocation ? .orange : .blue)
            
            Text(type)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.colors.text)
            
            Spacer()
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(isOverAllocation ? .orange : .blue)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            (isOverAllocation ? Color.orange : Color.blue)
                .opacity(0.1)
        )
        .cornerRadius(8)
    }
    
    private func patternRow(pattern: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pattern)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.colors.text)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.text.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(10)
    }
    
    private func actionSuggestion(suggestion: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 16))
            
            Text(suggestion)
                .font(.system(size: 15))
                .foregroundColor(themeManager.colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(10)
    }

    // 适配器方法，将trendingDownTypes转换为与trendingUpTypes相同的格式
    private func adaptTrendingDownTypes(_ trends: [(type: String, decreasePercentage: Double)]) -> [(type: String, increasePercentage: Double)] {
        return trends.map { trend in (type: trend.type, increasePercentage: trend.decreasePercentage) }
    }
}

// MARK: - View Extensions
extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

// MARK: - 高级UI组件

// 高级设计的进度条
struct GlassmorphicProgressBar: View {
    var progress: Double
    var height: CGFloat = 8
    var color: Color
    var backgroundColor: Color = Color(.systemGray6)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .opacity(0.3)
                
                // 进度
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.7), color]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geometry.size.width, geometry.size.width * progress)))
                    .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
            }
        }
        .frame(height: height)
    }
}

// 玻璃拟态卡片
struct GlassmorphicCard<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = 24
    var shadowRadius: CGFloat = 10
    var backgroundColor: Color
    
    init(backgroundColor: Color = Color(.systemBackground), cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor.opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundColor.opacity(0.7))
                            .blur(radius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
    }
}

// 任务类型指标卡片
struct TaskMetricCard: View {
    let metric: TaskTypeMetric
    let themeColor: Color
    
    private var statusColor: Color {
        switch metric.healthStatus {
        case .good:
            return .green
        case .needsAttention:
            return .orange
        case .poor:
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题和时间
            HStack {
                // 任务类型名称
                Text(metric.type)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                // 时间和百分比
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatMinutes(metric.minutes))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.label))
                    
                    Text("\(Int(metric.percentage))% 的时间")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            // 状态标签
            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Text(metric.statusDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor)
                    
                    Text(metric.healthStatus.icon)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.1))
                )
            }
            
            // 进度条和理想范围
            GeometryReader { geometry in
                VStack(spacing: 6) {
                    // 进度条
                    GlassmorphicProgressBar(
                        progress: metric.progressFillRatio,
                        height: 10,
                        color: themeColor
                    )
                    
                    // 理想范围指示器
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * (metric.idealRange.lowerBound / 100))
                        
                        Rectangle()
                            .fill(Color.green.opacity(0.2))
                            .frame(
                                width: geometry.size.width * ((metric.idealRange.upperBound - metric.idealRange.lowerBound) / 100),
                                height: 4
                            )
                        
                        Spacer()
                    }
                    .frame(height: 4)
                    
                    // 理想范围标签
                    HStack {
                        Text("理想: \(Int(metric.idealRange.lowerBound))% - \(Int(metric.idealRange.upperBound))%")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 50)
            .padding(.top, 4)
            
            // 调整建议（如果有）
            if let suggestion = metric.adjustmentSuggestion {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text(suggestion)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground).opacity(0.8))
                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
        } else {
            return "\(mins)分钟"
        }
    }
}

// 健康分数圆形指示器
struct HealthScoreIndicator: View {
    var score: Int
    var size: CGFloat = 110
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var trackColor: Color {
        scoreColor.opacity(0.2)
    }
    
    var body: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(trackColor, lineWidth: 10)
                .frame(width: size, height: size)
            
            // 进度圈
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [scoreColor.opacity(0.7), scoreColor]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * Double(score) / 100)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .shadow(color: scoreColor.opacity(0.5), radius: 5, x: 0, y: 0)
            
            // 分数文本
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text("分")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

// MARK: - 时间健康仪表盘视图
struct TimeHealthDashboardView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    let taskMetrics: [TaskTypeMetric]
    let healthScore: Int
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // 健康分数圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(healthScore) / 100.0, 1.0)))
                    .stroke(
                        healthScore > 70 ? Color.green : 
                        healthScore > 40 ? themeManager.accentColor : 
                        Color.red,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(healthScore))")
                        .font(.system(size: 40, weight: .bold))
                    
                    Text("健康分数")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 10)
            
            // 任务类型健康状态列表
            VStack(spacing: 12) {
                ForEach(taskMetrics) { metric in
                    taskMetricRow(metric: metric)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
    
    private func taskMetricRow(metric: TaskTypeMetric) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.type)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("\(metric.minutes)分钟")
                        .font(.subheadline)
                    
                    Text("(\(Int(metric.percentage))%)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // 理想范围区域
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.green.opacity(0.3))
                        .frame(
                            width: geometry.size.width * CGFloat(metric.idealRange.upperBound - metric.idealRange.lowerBound) / 100,
                            height: 6
                        )
                        .offset(x: geometry.size.width * CGFloat(metric.idealRange.lowerBound) / 100)
                    
                    // 实际进度
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            metric.healthStatus == .good ? Color.green :
                            metric.healthStatus == .needsAttention ? Color.yellow :
                            Color.red
                        )
                        .frame(width: geometry.size.width * CGFloat(metric.progressFillRatio), height: 6)
                }
            }
            .frame(height: 6)
            
            if let suggestion = metric.adjustmentSuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(
                        metric.healthStatus == .good ? .green :
                        metric.healthStatus == .needsAttention ? .orange :
                        .red
                    )
            }
        }
    }
    
    private func getTaskMetrics() -> [TaskTypeMetric] {
        let taskStats = [
            ("工作", 240, 32.0, 25...40, "经常加班可能影响工作效率"),
            ("学习", 180, 24.0, 20...30, nil),
            ("运动", 60, 8.0, 5...15, nil),
            ("娱乐", 120, 16.0, 10...20, nil),
            ("睡眠", 150, 20.0, 25...35, "睡眠时间偏短，考虑增加休息时间")
        ]
        
        return taskStats.map { stats in
            let (type, minutes, percentage, idealRange, suggestion) = stats
            
            // 计算健康状态
            let healthStatus: HealthStatus
            if percentage < idealRange.lowerBound {
                healthStatus = .needsAttention
            } else if percentage > idealRange.upperBound {
                healthStatus = .needsAttention
            } else {
                healthStatus = .good
            }
            
            // 计算填充比例
            let progressFillRatio = min(1.0, percentage / 100.0)
            
            // 构建状态描述
            let statusDescription: String
            if percentage < idealRange.lowerBound {
                statusDescription = "偏少"
            } else if percentage > idealRange.upperBound {
                statusDescription = "偏多"
            } else {
                statusDescription = "适中"
            }
            
            // 构建调整建议
            let adjustmentSuggestion = suggestion
            
            return TaskTypeMetric(
                type: type,
                minutes: minutes,
                percentage: percentage,
                idealRange: idealRange.lowerBound...idealRange.upperBound,
                healthStatus: healthStatus,
                progressFillRatio: progressFillRatio,
                statusDescription: statusDescription,
                adjustmentSuggestion: adjustmentSuggestion
            )
        }
    }
}

// 获取任务类型的理想范围
private func getMetricForType(_ type: String) -> ClosedRange<Double> {
    switch type {
    case "工作", "学习":
        return 30...45
    case "会议":
        return 5...15
    case "思考":
        return 10...20
    case "阅读":
        return 5...15
    case "生活":
        return 10...20
    case "运动":
        return 5...10
    case "摸鱼":
        return 0...5
    case "睡觉":
        return 25...35
    default:
        return 0...10
    }
}

// 计算健康状态
private func calculateHealthStatus(percentage: Double, idealRange: ClosedRange<Double>) -> HealthStatus {
    if percentage >= idealRange.lowerBound && percentage <= idealRange.upperBound {
        return .good
    } else if percentage < idealRange.lowerBound * 0.5 || percentage > idealRange.upperBound * 1.5 {
        return .poor
    } else {
        return .needsAttention
    }
}

// 生成建议
private func generateSuggestion(type: String, percentage: Double, idealRange: ClosedRange<Double>) -> String? {
    if percentage >= idealRange.lowerBound && percentage <= idealRange.upperBound {
        return nil // 理想状态不需要建议
    } else if percentage < idealRange.lowerBound {
        return "建议增加\(type)的时间投入"
    } else {
        return "建议适当减少\(type)的时间"
    }
}

// 获取任务类型统计
private func getTaskTypesStats() -> [(type: String, minutes: Int, percentage: Double, count: Int, adjustmentMinutes: Int, originalMinutes: Int, terminatedCount: Int)] {
    let tasks = tasksForSelectedRange
    let completedTasks = tasks.filter { $0.isCompleted }
    
    if completedTasks.isEmpty {
        return []
    }
    
    // 按类型分组
    let tasksByType = Dictionary(grouping: completedTasks) { $0.title }
    let totalMinutes = completedTasks.reduce(0) { $0 + $1.duration }
    
    var stats: [(type: String, minutes: Int, percentage: Double, count: Int, adjustmentMinutes: Int, originalMinutes: Int, terminatedCount: Int)] = []
    
    for (type, tasks) in tasksByType {
        let minutes = tasks.reduce(0) { $0 + $1.duration }
        let percentage = Double(minutes) / Double(totalMinutes) * 100
        let count = tasks.count
        let adjustedTasks = tasks.filter { !$0.timeAdjustments.isEmpty }
        let adjustmentMinutes = tasks.reduce(0) { $0 + $1.totalTimeAdjustment() }
        let originalMinutes = tasks.reduce(0) { $0 + $1.originalDuration() }
        let terminatedCount = tasks.filter { $0.isTerminated }.count
        
        stats.append((
            type: type,
            minutes: minutes,
            percentage: percentage,
            count: count,
            adjustmentMinutes: adjustmentMinutes,
            originalMinutes: originalMinutes,
            terminatedCount: terminatedCount
        ))
    }
    
    // 按时间降序排序
    return stats.sorted { $0.minutes > $1.minutes }
}

// 角色定义
let roleStandards: [RoleStandard] = [
    RoleStandard(
        type: "创业者",
        standards: [
            "睡觉": TimeStandard(lowerBound: 6, upperBound: 7.5, priorityCoefficient: 5),
            "工作": TimeStandard(lowerBound: 10, upperBound: 14, priorityCoefficient: 5),
            "会议": TimeStandard(lowerBound: 1, upperBound: 3, priorityCoefficient: 3),
            "思考": TimeStandard(lowerBound: 1, upperBound: 2, priorityCoefficient: 4),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 2),
            "运动": TimeStandard(lowerBound: 0.25, upperBound: 0.75, priorityCoefficient: 4),
            "阅读": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 3),
            "生活": TimeStandard(lowerBound: 0.5, upperBound: 1.5, priorityCoefficient: 2)
        ],
        description: "创业者通常面临繁重的工作压力，需要在有限的时间内高效工作，同时需要保持充足的思考时间。"
    ),
    RoleStandard(
        type: "高管",
        standards: [
            "睡觉": TimeStandard(lowerBound: 7, upperBound: 8, priorityCoefficient: 5),
            "工作": TimeStandard(lowerBound: 8, upperBound: 10, priorityCoefficient: 4),
            "会议": TimeStandard(lowerBound: 3, upperBound: 6, priorityCoefficient: 4),
            "思考": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 4),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 1),
            "运动": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 3),
            "阅读": TimeStandard(lowerBound: 1, upperBound: 2, priorityCoefficient: 3),
            "生活": TimeStandard(lowerBound: 2, upperBound: 3, priorityCoefficient: 3)
        ],
        description: "高管需要处理较多会议，在领导和管理中取得平衡，同时保持健康的生活方式。"
    ),
    RoleStandard(
        type: "白领",
        standards: [
            "睡觉": TimeStandard(lowerBound: 7, upperBound: 8, priorityCoefficient: 4),
            "工作": TimeStandard(lowerBound: 6, upperBound: 8, priorityCoefficient: 4),
            "会议": TimeStandard(lowerBound: 1, upperBound: 2, priorityCoefficient: 2),
            "思考": TimeStandard(lowerBound: 0.25, upperBound: 0.5, priorityCoefficient: 3),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1.5, priorityCoefficient: 1),
            "运动": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 4),
            "阅读": TimeStandard(lowerBound: 0.5, upperBound: 1, priorityCoefficient: 2),
            "生活": TimeStandard(lowerBound: 3, upperBound: 4, priorityCoefficient: 4)
        ],
        description: "白领工作时间相对固定，应保持工作与生活的平衡，注重个人发展和健康。"
    )
]

// 获取当前选择的角色标准
var currentRoleStandard: RoleStandard {
    roleStandards.first { $0.type == selectedRole } ?? roleStandards[0]
}

// 辅助方法：获取周任务
private func getWeekTasks() -> [Task] {
    let calendar = Calendar.current
    let now = Date()
    let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
    
    return appViewModel.tasks.filter { task in
        if let completedAt = task.completedAt, task.isCompleted {
            return completedAt >= startOfWeek && completedAt < endOfWeek
        }
        return false
    }
}

// 辅助方法：获取月任务
private func getMonthTasks() -> [Task] {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.year, .month], from: now)
    let startOfMonth = calendar.date(from: components)!
    let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
    
    return appViewModel.tasks.filter { task in
        if let completedAt = task.completedAt, task.isCompleted {
            return completedAt >= startOfMonth && completedAt < nextMonth
        }
        return false
    }
}

// 辅助方法：从任务列表生成统计数据
private func getTaskTypeStatsForTasks(_ tasks: [Task]) -> [TaskTypeStat] {
    // 定义任务类型（8类）
    let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
    var stats: [TaskTypeStat] = []
    
    for type in taskTypes {
        let tasksOfThisType = tasks.filter { $0.title == type }
        let count = tasksOfThisType.count
        if count > 0 {
            let minutes = tasksOfThisType.reduce(0) { result, task in result + task.duration }
            let originalMinutes = tasksOfThisType.reduce(0) { result, task in result + task.originalDuration() }
            let adjustmentMinutes = minutes - originalMinutes
            
            // 统计终止的任务
            let terminatedTasks = tasksOfThisType.filter { task in task.isTerminated }
            let terminatedCount = terminatedTasks.count
            let reducedMinutes = terminatedTasks.reduce(0) { result, task in 
                result + abs(task.timeAdjustments.filter { adjustment in adjustment < 0 }.reduce(0, +)) 
            }
            
            var stat = TaskTypeStat(
                type: type,
                count: count,
                minutes: minutes,
                originalMinutes: originalMinutes,
                adjustmentMinutes: adjustmentMinutes
            )
            
            // 更新终止任务数据
            stat.terminatedCount = terminatedCount
            stat.reducedMinutes = reducedMinutes
            
            stats.append(stat)
        }
    }
    
    // 按时间降序排序
    return stats.sorted { $0.minutes > $1.minutes }
}
