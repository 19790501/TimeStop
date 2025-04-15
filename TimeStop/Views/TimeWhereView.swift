import SwiftUI
import Foundation

// 时间健康仪表盘视图
struct TimeWhereView_Dashboard: View {
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
    
    // 时间健康状态枚举
    enum TimeHealthStatus {
        case normal      // 正常
        case warning     // 警告
        case critical    // 严重不足
        
        var icon: String {
            switch self {
            case .normal: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
    
    @State private var selectedRange: TimeRange = .today
    @State private var selectedRole: String = "创业者"
    @State private var showTaskDetail: Bool = false
    @State private var selectedTaskType: String?
    @State private var showAlert: Bool = false
    @State private var showDetailedSuggestion = false
    @State private var currentTaskType = ""
    @State private var detailedSuggestion = (title: "", objectiveReasons: [String](), subjectiveReasons: [String](), suggestions: [String]())
    @State private var showWeeklySummary: Bool = false
    @State private var showMonthlySummary: Bool = false
    
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
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .edgesIgnoringSafeArea(.all)
                
                if tasksForSelectedRange.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .onAppear {
                print("时间健康仪表盘加载: 任务总数 \(appViewModel.tasks.count)")
            }
            .sheet(isPresented: $showDetailedSuggestion) {
                DetailedSuggestionView(
                    taskType: currentTaskType,
                    suggestion: detailedSuggestion,
                    isPresented: $showDetailedSuggestion
                )
                .environmentObject(themeManager)
            }
        }
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

// 偏差类型枚举
enum DeviationType {
    case excess // 过多
    case deficient // 过少
    case balanced // 正常
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

// 预览
struct TimeWhereView_Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        TimeWhereView_Dashboard()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
            .environmentObject(AppViewModel())
    }
}

// MARK: - 数据处理

// 任务类型统计结构
extension TimeWhereView_Dashboard {
    struct TaskTypeStat: Equatable {
        let type: String
        let count: Int
        let minutes: Int
        let originalMinutes: Int
        let adjustmentMinutes: Int
        
        // 新增：终止任务相关数据
        var terminatedCount: Int = 0      // 被终止的任务数量
        var reducedMinutes: Int = 0       // 因终止而减少的分钟数
        
        // 实现Equatable协议的静态方法
        static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
            return lhs.type == rhs.type
        }
    }
    
    // 获取所选时间范围的任务
    var tasksForSelectedRange: [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        let completedTasks = appViewModel.tasks.filter { $0.isCompleted }
        
        switch selectedRange {
        case .today:
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: now)
                }
                return false
            }
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return completedAt >= startOfWeek && completedAt < endOfWeek
                }
                return false
            }
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return completedAt >= startOfMonth && completedAt < nextMonth
                }
                return false
            }
        }
    }
    
    // 获取任务类型统计数据
    func getTaskTypesStats() -> [TaskTypeStat] {
        // 定义任务类型（8类）
        let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        var stats: [TaskTypeStat] = []
        
        for type in taskTypes {
            let tasksOfThisType = tasksForSelectedRange.filter { task in task.title == type }
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
    
    // 所选时间范围内的总时长
    var totalTimeForSelectedRange: Int {
        tasksForSelectedRange.reduce(0) { $0 + $1.duration }
    }
    
    // 平均每个任务的时长
    var averageTimePerTask: Int {
        if tasksForSelectedRange.isEmpty { return 0 }
        return totalTimeForSelectedRange / tasksForSelectedRange.count
    }
    
    // 计算时间健康度评分 (0-100)
    func calculateTimeHealthScore() -> Int {
        let stats = getTaskTypesStats()
        if stats.isEmpty { return 0 }
        
        var totalScore = 0
        var totalWeight = 0
        
        for stat in stats {
            let hours = Double(stat.minutes) / 60.0
            if let standard = currentRoleStandard.getStandard(for: stat.type) {
                let deviationType = standard.isWithinStandard(hours)
                let weight = standard.priorityCoefficient
                totalWeight += weight
                
                // 计算每个任务类型的分数
                var score = 0
                switch deviationType {
                case .balanced:
                    score = 100 // 完美平衡
                case .deficient:
                    let deficitPercentage = (standard.lowerBound - hours) / standard.lowerBound * 100
                    if deficitPercentage <= 20 {
                        score = 80 // 轻微不足
                    } else if deficitPercentage <= 50 {
                        score = 60 // 中度不足
                    } else {
                        score = 40 // 严重不足
                    }
                case .excess:
                    let excessPercentage = (hours - standard.upperBound) / standard.upperBound * 100
                    if excessPercentage <= 20 {
                        score = 80 // 轻微过多
                    } else if excessPercentage <= 50 {
                        score = 60 // 中度过多
                    } else {
                        score = 40 // 严重过多
                    }
                }
                
                // 根据任务调整和终止情况调整分数
                let adjustmentPercentage = stat.originalMinutes > 0 ? 
                    Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100 : 0
                let terminationPercentage = stat.count > 0 ? 
                    Double(stat.terminatedCount) / Double(stat.count) * 100 : 0
                
                if adjustmentPercentage > 30 || terminationPercentage > 30 {
                    score = max(score - 20, 0) // 频繁调整或终止会降低分数
                }
                
                totalScore += score * weight
            }
        }
        
        return totalWeight > 0 ? totalScore / totalWeight : 0
    }
    
    // 获取任务健康状态
    func getHealthStatus(for taskType: String, minutes: Int) -> TimeHealthStatus {
        let hours = Double(minutes) / 60.0
        if let standard = currentRoleStandard.getStandard(for: taskType) {
            let deviationType = standard.isWithinStandard(hours)
            let deviationPercentage = standard.deviationPercentage(hours)
            
            switch deviationType {
            case .balanced:
                return .normal
            case .deficient:
                return deviationPercentage > 30 ? .critical : .warning
            case .excess:
                return deviationPercentage > 30 ? .critical : .warning
            }
        }
        return .normal
    }
    
    // 获取每种任务类型的标准范围描述
    func getStandardRangeText(for taskType: String) -> String {
        if let standard = currentRoleStandard.getStandard(for: taskType) {
            return "\(String(format: "%.1f", standard.lowerBound))-\(String(format: "%.1f", standard.upperBound))小时"
        }
        return "无标准"
    }
}

// MARK: - 辅助函数
extension TimeWhereView_Dashboard {
    // 获取任务类型图标
    func getIconForTaskType(_ type: String) -> String {
        switch type {
        case "会议": return "person.3.fill"
        case "思考": return "brain"
        case "工作": return "briefcase.fill"
        case "阅读": return "book.fill"
        case "生活": return "house.fill"
        case "运动": return "figure.run"
        case "摸鱼": return "fish.fill"
        case "睡觉": return "bed.double.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    // 获取任务类型颜色
    func getColorForTaskType(_ type: String) -> Color {
        switch type {
        case "会议": return Color.orange.opacity(0.7)
        case "思考": return Color.purple.opacity(0.7)
        case "工作": return Color.blue.opacity(0.7)
        case "阅读": return Color.yellow.opacity(0.7)
        case "生活": return Color.pink.opacity(0.7)
        case "运动": return Color.green.opacity(0.7)
        case "摸鱼": return Color.cyan.opacity(0.7)
        case "睡觉": return Color.indigo.opacity(0.7)
        default: return Color.gray.opacity(0.7)
        }
    }
    
    // 获取角色对应的颜色
    func getRoleColor(_ role: String) -> Color {
        switch role {
        case "创业者":
            return Color(hex: "FF6B00") // 活力橙色
        case "高管":
            return Color(hex: "005CAF") // 深蓝色
        case "白领":
            return Color(hex: "00896C") // 深绿色
        default:
            return Color.blue
        }
    }
    
    // 格式化分钟为易读时间
    func formatMinutes(_ minutes: Int) -> String {
        return "\(minutes)分钟"
    }
    
    // 格式化小时
    func formatHours(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    // 格式化时间调整
    func formatAdjustment(_ minutes: Int) -> String {
        if minutes > 0 {
            return "+\(formatMinutes(minutes))"
        } else {
            return "-\(formatMinutes(abs(minutes)))"
        }
    }
    
    // 格式化百分比
    func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.1f%%", percentage)
    }
    
    // 获取任务类型
    func getTaskTypes() -> [String] {
        let stats = getTaskTypesStats()
        return stats.map { stat in stat.type }
    }
    
    // 获取每类任务的完成次数
    func getTaskCountByType(_ type: String) -> Int {
        return tasksForSelectedRange.filter { task in task.title == type }.count
    }
}

// MARK: - UI组件
extension TimeWhereView_Dashboard {
    // 顶部标题和测试数据按钮
    private var headerView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("时间去哪了")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                Button(action: {
                    generateRandomTestData()
                    showAlert = true
                }) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(themeManager.colors.secondaryBackground)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            themeManager.currentTheme == .elegantPurple ?
                                                Color(hex: "483D8B").opacity(0.4) :
                                                Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 24) // 增加水平边距
            .padding(.top, 25)
            .padding(.bottom, 10)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("测试数据已生成"),
                    message: Text("已生成随机任务数据用于测试"),
                    dismissButton: .default(Text("确定"))
                )
            }
            
            // 角色选择器
            roleSelector
                .padding(.horizontal, 24)
                .padding(.bottom, 6)
        }
    }
    
    // 角色选择器
    private var roleSelector: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(roleStandards, id: \.type) { role in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRole = role.type
                        }
                    }) {
                        Text(role.type)
                            .font(.system(size: 14, weight: selectedRole == role.type ? .semibold : .regular))
                            .foregroundColor(selectedRole == role.type ? .white : themeManager.colors.secondaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                ZStack {
                                    if selectedRole == role.type {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(getRoleColor(role.type))
                                            .shadow(color: getRoleColor(role.type).opacity(0.3), radius: 4, x: 0, y: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(themeManager.colors.secondaryText.opacity(0.2), lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(themeManager.colors.secondaryBackground.opacity(0.5))
                                            )
                                    }
                                }
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            
            // 角色描述
            Text(currentRoleStandard.description)
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }
    
    // 时间范围选择器
    private var timeRangeSelector: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedRange = range
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 15, weight: selectedRange == range ? .semibold : .medium))
                            .foregroundColor(selectedRange == range ? .white : themeManager.colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    if selectedRange == range {
                                        // 选中状态的按钮设计 - 根据主题选择颜色
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.currentTheme == .elegantPurple ? 
                                                  Color(hex: "8A2BE2") : // 知性紫主题使用深紫色
                                                  Color(hex: "0C4A45")) // 默认主题使用翡翠墨绿色
                                            .shadow(color: themeManager.currentTheme == .elegantPurple ? 
                                                    Color(hex: "8A2BE2").opacity(0.4) : 
                                                    Color(hex: "0C4A45").opacity(0.4), 
                                                    radius: 5, x: 0, y: 2)
                                    } else {
                                        // 未选中状态的按钮设计
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeManager.colors.secondaryText.opacity(0.2), lineWidth: 1.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(themeManager.colors.secondaryBackground.opacity(0.5))
                                            )
                                    }
                                }
                            )
                            .scaleEffect(selectedRange == range ? 1.05 : 1.0)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24) // 增加水平边距
        }
        .background(themeManager.colors.background)
    }
    
    // 按钮缩放效果
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.colors.secondaryText)
                
                Text("暂无\(selectedRange.rawValue)数据")
                    .font(.title3)
                    .foregroundColor(themeManager.colors.text)
                
                Text("点击页面右上角闪电⚡按钮生成测试数据")
                    .font(.callout)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
    
    // 主要内容视图
    private var mainContentView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("时间分配")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                // 添加分析报告按钮
                Button(action: {
                    generateAnalysisReport()
                    showDetailedSuggestion = true
                }) {
                    HStack(spacing: 4) {
                        Text("分析报告")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .stroke(themeManager.colors.secondaryText.opacity(0.3), lineWidth: 1)
                            .background(
                                Capsule()
                                    .fill(themeManager.colors.secondaryBackground.opacity(0.8))
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 健康度仪表盘
                    timeHealthDashboardCard
                        .padding(.horizontal, 24)
                    
                    // 时间分配详情
                    timeAllocationDetailsCard
                        .padding(.horizontal, 24)
                    
                    // 任务调整分析
                    taskAdjustmentAnalysisCard
                        .padding(.horizontal, 24)
                    
                    // 添加报告查看按钮，仅在查看非今天的数据时显示
                    if selectedRange != .today {
                        summaryReportButton
                            .padding(.horizontal, 24)
                            .padding(.top, 6)
                            .padding(.bottom, 10)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .background(themeManager.colors.background)
        .sheet(isPresented: $showWeeklySummary) {
            WeeklySummaryView(summary: currentWeeklySummary)
        }
        .sheet(isPresented: $showMonthlySummary) {
            MonthlySummaryView(summary: currentMonthlySummary)
        }
    }
    
    // 摘要报告按钮
    private var summaryReportButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                if selectedRange == .week {
                    showWeeklySummary = true
                } else if selectedRange == .month {
                    showMonthlySummary = true
                }
            }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("查看\(selectedRange.rawValue)报告")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.colors.secondaryBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                )
            }
        }
    }
}

// MARK: - 仪表盘卡片
extension TimeWhereView_Dashboard {
    // 时间健康仪表盘卡片
    private var timeHealthDashboardCard: some View {
        let healthScore = calculateTimeHealthScore()
        
        return VStack(alignment: .leading, spacing: 16) {
            // 标题和评分
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("时间分配健康度")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("基于\(selectedRange.rawValue)数据，\(selectedRole)角色标准")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                
                Spacer()
                
                // 健康评分
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.red, Color.orange, Color.yellow, Color.green
                                ]),
                                center: .center
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .fill(themeManager.colors.secondaryBackground)
                        .frame(width: 40, height: 40)
                    
                    Text("\(healthScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(
                            healthScore >= 80 ? Color.green :
                            healthScore >= 60 ? Color.yellow :
                            Color.red
                        )
                }
            }
            
            // 总计时间信息
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总时长")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text(formatHours(totalTimeForSelectedRange))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务数")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text("\(tasksForSelectedRange.count)个")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均时长")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text("\(averageTimePerTask)分钟")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 时间分配详情卡片
    private var timeAllocationDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分配详情")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.colors.text)
            
            VStack(spacing: 18) {
                let stats = getTaskTypesStats()
                let totalMinutes = totalTimeForSelectedRange
                
                ForEach(stats, id: \.type) { stat in
                    let percentage = totalMinutes > 0 ? Double(stat.minutes) / Double(totalMinutes) * 100 : 0
                    let healthStatus = getHealthStatus(for: stat.type, minutes: stat.minutes)
                    let standard = currentRoleStandard.getStandard(for: stat.type)
                    let hours = Double(stat.minutes) / 60.0
                    let idealRange = "\(String(format: "%.1f", standard?.lowerBound ?? 0))-\(String(format: "%.1f", standard?.upperBound ?? 0))小时"
                    
                    VStack(spacing: 6) {
                        // 标题和指标
                        HStack {
                            HStack(spacing: 8) {
                                // 图标
                                Image(systemName: getIconForTaskType(stat.type))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(getColorForTaskType(stat.type))
                                    )
                                
                                Text(stat.type)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeManager.colors.text)
                            }
                            
                            Spacer()
                            
                            // 比例和健康状态指示器
                            HStack(spacing: 2) {
                                Text(formatPercentage(percentage))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(themeManager.colors.text)
                                
                                Image(systemName: healthStatus.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(healthStatus.color)
                            }
                        }
                        
                        // 进度条和标准范围指示
                        VStack(alignment: .leading, spacing: 2) {
                            ZStack(alignment: .leading) {
                                // 背景进度条
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                // 实际时间进度条
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getColorForTaskType(stat.type))
                                    .frame(width: min(CGFloat(percentage) / 100 * UIScreen.main.bounds.width * 0.8, UIScreen.main.bounds.width * 0.8), height: 8)
                                
                                // 理想范围指示器 (如果有标准的话)
                                if let standardRange = standard, totalMinutes > 0 {
                                    let lowerBoundPercentage = standardRange.lowerBound * 60 / Double(totalMinutes) * 100
                                    let upperBoundPercentage = standardRange.upperBound * 60 / Double(totalMinutes) * 100
                                    
                                    // 下限指示器
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 2, height: 8)
                                        .offset(x: CGFloat(lowerBoundPercentage) / 100 * UIScreen.main.bounds.width * 0.8 - 1)
                                    
                                    // 上限指示器
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 2, height: 8)
                                        .offset(x: CGFloat(upperBoundPercentage) / 100 * UIScreen.main.bounds.width * 0.8 - 1)
                                }
                            }
                            
                            // 详细信息
                            HStack {
                                Text("\(formatHours(stat.minutes)) (\(stat.count)次)")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                
                                Spacer()
                                
                                Text("理想：\(idealRange)")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.colors.secondaryText)
                            }
                        }
                        
                        // 调整和终止信息
                        if stat.adjustmentMinutes != 0 || stat.terminatedCount > 0 {
                            HStack {
                                if stat.adjustmentMinutes != 0 {
                                    let adjustmentPercentage = stat.originalMinutes > 0 ? 
                                        Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100 : 0
                                    
                                    Text(stat.adjustmentMinutes > 0 ? 
                                         "调整: \(formatAdjustment(stat.adjustmentMinutes)) (\(formatPercentage(adjustmentPercentage)))" : 
                                         "调整: \(formatAdjustment(stat.adjustmentMinutes)) (\(formatPercentage(adjustmentPercentage)))")
                                        .font(.system(size: 11))
                                        .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(
                                            Capsule()
                                                .fill(stat.adjustmentMinutes > 0 ? 
                                                      Color.green.opacity(0.1) : 
                                                      Color.red.opacity(0.1))
                                        )
                                }
                                
                                if stat.terminatedCount > 0 {
                                    let terminationPercentage = Double(stat.terminatedCount) / Double(stat.count) * 100
                                    
                                    Text("终止: \(stat.terminatedCount)次 (\(formatPercentage(terminationPercentage)))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange.opacity(0.1))
                                        )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.colors.background)
                    )
                    .onTapGesture {
                        currentTaskType = stat.type
                        generateDetailedSuggestion(for: stat)
                        showDetailedSuggestion = true
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 任务调整分析卡片
    private var taskAdjustmentAnalysisCard: some View {
        let stats = getTaskTypesStats()
        let frequentlyAdjustedTypes = stats.filter { stat in
            let adjustmentPercentage = stat.originalMinutes > 0 ? 
                Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100 : 0
            return adjustmentPercentage > 20
        }
        
        let frequentlyTerminatedTypes = stats.filter { stat in
            let terminationPercentage = stat.count > 0 ? 
                Double(stat.terminatedCount) / Double(stat.count) * 100 : 0
            return terminationPercentage > 25
        }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("任务调整分析")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.colors.text)
            
            if frequentlyAdjustedTypes.isEmpty && frequentlyTerminatedTypes.isEmpty {
                Text("暂无明显需要调整的任务")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .padding(.top, 2)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if !frequentlyAdjustedTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ 频繁调整的任务")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.colors.text)
                            
                            ForEach(frequentlyAdjustedTypes, id: \.type) { stat in
                                let adjustmentPercentage = stat.originalMinutes > 0 ? 
                                    Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100 : 0
                                
                                HStack {
                                    Text("• \(stat.type):")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.colors.secondaryText)
                                    
                                    if stat.adjustmentMinutes > 0 {
                                        Text("时间常被延长 (\(formatPercentage(adjustmentPercentage)))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.green)
                                        
                                        Spacer()
                                        
                                        Text("建议预留缓冲时间")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.colors.secondaryText)
                                    } else {
                                        Text("时间常被缩短 (\(formatPercentage(adjustmentPercentage)))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.red)
                                        
                                        Spacer()
                                        
                                        Text("建议减少初始时间")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeManager.colors.secondaryText)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !frequentlyTerminatedTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ 频繁终止的任务")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.colors.text)
                            
                            ForEach(frequentlyTerminatedTypes, id: \.type) { stat in
                                let terminationPercentage = Double(stat.terminatedCount) / Double(stat.count) * 100
                                
                                HStack {
                                    Text("• \(stat.type):")
                                        .font(.system(size: 13))
                                        .foregroundColor(themeManager.colors.secondaryText)
                                    
                                    Text("终止率 \(formatPercentage(terminationPercentage))")
                                        .font(.system(size: 13))
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text("建议减少中断和干扰")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
} 