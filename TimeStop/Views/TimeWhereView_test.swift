import SwiftUI
import Foundation

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
    
    // 健康指数 (方案E需要的字段)
    var balanceIndex: Double = 0.75 // 时间平衡指数 (0-1)
    var efficiencyIndex: Double = 0.68 // 效率指数 (0-1)
    var focusIndex: Double = 0.82 // 专注程度 (0-1)
    var totalMinutes: Int = 0 // 总分钟数
    
    // 任务类型统计 (方案E需要的字段)
    var taskTypeStats: [TaskTypeStat2] = [] // 使用TaskTypeStat2避免和现有TaskTypeStat冲突
}

// 方案E的任务类型统计
struct TaskTypeStat2: Identifiable {
    var id: String { taskType }
    let taskType: String
    let count: Int
    let minutes: Int
    let status: String // "最佳", "不足", "过多"
    let idealPercentage: Double
    let suggestion: String
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

// 定义时间状态枚举
enum TimeStatus: String {
    case overTime, normal, underTime
    
    var localizedDescription: String {
        switch self {
        case .overTime:
            return "时间超出"
        case .normal:
            return "时间合理"
        case .underTime:
            return "时间不足"
        }
    }
    
    var color: Color {
        switch self {
        case .overTime:
            return Color.red
        case .normal:
            return Color.green
        case .underTime:
            return Color.orange
        }
    }
}

// 任务类型统计结构
struct TaskTypeStat: Equatable {
    let type: String
    let count: Int
    let minutes: Int
    let originalMinutes: Int
    let adjustmentMinutes: Int
    
    // 终止任务相关数据
    var terminatedCount: Int = 0      // 被终止的任务数量
    var reducedMinutes: Int = 0       // 因终止而减少的分钟数
    
    // 计算百分比
    var percentage: Double {
        // 防止除以0
        guard minutes > 0 else { return 0 }
        return Double(minutes)
    }
    
    // 计算状态
    var status: TaskTypeStatus {
        // 这里简化处理，实际应基于比例、标准等
        if minutes > 180 {
            return .critical
        } else if minutes > 120 {
            return .warning
        } else {
            return .healthy
        }
    }
    
    // 实现Equatable协议的静态方法
    static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
        return lhs.type == rhs.type
    }
}

// 时间健康状态枚举
enum TaskTypeStatus: String {
    case healthy = "健康"
    case warning = "警告"
    case critical = "严重"
    case normal = "正常"
    case underAllocated = "时间偏少"
    case severelyUnderAllocated = "时间严重不足"
    case overAllocated = "时间偏多"
    case highlyOverAllocated = "时间过多"
    
    // 获取状态颜色
    var color: Color {
        switch self {
        case .healthy, .normal:
            return Color.green
        case .warning, .underAllocated, .overAllocated:
            return Color.orange
        case .critical, .severelyUnderAllocated, .highlyOverAllocated:
            return Color.red
        }
    }
}

// 确保可以访问ThemeManager中定义的AppColors
struct TimeWhereView_test: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appViewModel: AppViewModel
    @ObservedObject var themeManager = ThemeManager.shared
    @EnvironmentObject var storeReview: StoreReviewHelper
    
    @State private var selectedTimeRange: TimeRange = .thisWeek
    @State private var selectedRole: String = "创业者" // 默认选择创业者角色
    @State private var selectedTaskType: String?
    @State private var showAlert: Bool = false
    @State private var showDetailedSuggestion = false
    @State private var currentTaskType: String? = nil
    
    // Navigation bar trailing button
    private var trailingNavBarButton: some View {
        Button(action: {
            // Add functionality for the button here
            // For example, show settings or help
        }) {
            Image(systemName: "gearshape")
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
    
    // 定义时间范围枚举
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "今日"
        case week = "本周"
        case month = "本月"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedRange: TimeRange = .today
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
    
    // 周总结计算属性
    var currentWeeklySummary: TimeAnalysisSummary {
        let weekTasks = getWeekTasks()
        var summary = TimeAnalysisSummary()
        
        // 基本统计
        summary.totalTime = weekTasks.reduce(0) { $0 + $1.duration }
        summary.taskCount = weekTasks.count
        summary.avgDuration = weekTasks.isEmpty ? 0 : summary.totalTime / weekTasks.count
        
        // 时间分配分析
        let taskTypesStats = getTaskTypeStatsForTasks(weekTasks)
        let totalTimeInMinutes = taskTypesStats.reduce(0) { $0 + $1.minutes }
        
        // 判断时间过多/过少
        for stat in taskTypesStats {
            let percentage = Double(stat.minutes) / Double(totalTimeInMinutes) * 100
            
            // 根据任务类型设置阈值
            var upperThreshold: Double = 30
            var lowerThreshold: Double = 5
            
            switch stat.type {
            case "工作":
                upperThreshold = 50
                lowerThreshold = 20
            case "睡觉":
                upperThreshold = 40
                lowerThreshold = 25
            case "摸鱼":
                upperThreshold = 20
                lowerThreshold = 5
            case "运动":
                upperThreshold = 15
                lowerThreshold = 5
            default:
                break
            }
            
            if percentage > upperThreshold {
                summary.overAllocatedTypes.append((stat.type, stat.minutes))
            } else if percentage < lowerThreshold && stat.minutes > 0 {
                summary.underAllocatedTypes.append((stat.type, stat.minutes))
            }
        }
        
        // 分析调整频率
        for stat in taskTypesStats {
            if stat.count == 0 { continue }
            
            let tasksOfType = weekTasks.filter { $0.title == stat.type }
            let adjustedTasks = tasksOfType.filter { !$0.timeAdjustments.isEmpty }
            let adjustmentPercentage = Double(adjustedTasks.count) / Double(tasksOfType.count) * 100
            
            if adjustmentPercentage > 30 {
                summary.frequentlyAdjustedTypes.append((stat.type, adjustedTasks.count, adjustmentPercentage))
            }
            
            // 分析终止频率
            let terminatedTasks = tasksOfType.filter { $0.isTerminated }
            let terminationPercentage = Double(terminatedTasks.count) / Double(tasksOfType.count) * 100
            
            if terminationPercentage > 20 {
                summary.frequentlyTerminatedTypes.append((stat.type, terminatedTasks.count, terminationPercentage))
            }
        }
        
        // 模拟最佳组合分析（实际应用中这应该基于更复杂的算法）
        summary.bestCombinations = [
            ("运动", "工作", "运动后工作效率提升20%"),
            ("阅读", "思考", "阅读后思考质量提升15%"),
            ("工作", "休息", "短暂休息后工作专注度提升18%")
        ]
        
        // 模拟最佳/最差时段识别
        summary.mostProductiveTimeOfDay = "上午9点-11点"
        summary.leastProductiveTimeOfDay = "下午3点-4点"
        
        return summary
    }
    
    // 月总结计算属性
    var currentMonthlySummary: TimeAnalysisSummary {
        let monthTasks = getMonthTasks()
        var summary = TimeAnalysisSummary()
        
        // 复用周总结的基本分析
        summary.totalTime = monthTasks.reduce(0) { $0 + $1.duration }
        summary.taskCount = monthTasks.count
        summary.avgDuration = monthTasks.isEmpty ? 0 : summary.totalTime / monthTasks.count
        
        // 获取本月数据
        let taskTypesStats = getTaskTypeStatsForTasks(monthTasks)
        
        // 模拟趋势分析（真实实现需要比较多周数据）
        summary.trendingUpTypes = [
            ("阅读", 15.5),
            ("运动", 8.2)
        ]
        
        summary.trendingDownTypes = [
            ("摸鱼", -12.3),
            ("会议", -5.7)
        ]
        
        summary.mostConsistentType = "工作"
        summary.leastConsistentType = "思考"
        
        // 时间分配分析（复用周分析逻辑，但使用不同阈值）
        let totalTimeInMinutes = taskTypesStats.reduce(0) { $0 + $1.minutes }
        
        for stat in taskTypesStats {
            let percentage = Double(stat.minutes) / Double(totalTimeInMinutes) * 100
            
            // 月度阈值可能与周阈值不同
            var upperThreshold: Double = 35
            var lowerThreshold: Double = 3
            
            switch stat.type {
            case "工作":
                upperThreshold = 45
                lowerThreshold = 15
            case "睡觉":
                upperThreshold = 35
                lowerThreshold = 20
            case "摸鱼":
                upperThreshold = 15
                lowerThreshold = 3
            case "运动":
                upperThreshold = 12
                lowerThreshold = 3
            default:
                break
            }
            
            if percentage > upperThreshold {
                summary.overAllocatedTypes.append((stat.type, stat.minutes))
            } else if percentage < lowerThreshold && stat.minutes > 0 {
                summary.underAllocatedTypes.append((stat.type, stat.minutes))
            }
        }
        
        // 复用周分析的其他逻辑...
        
        return summary
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
    
    // 所选时间范围内的总时长
    var totalTimeForSelectedRange: Int {
        tasksForSelectedRange.reduce(0) { $0 + $1.duration }
    }
    
    // 获取不同任务类型
    private func getTaskTypes() -> [String] {
        let tasks = tasksForSelectedRange
        if tasks.isEmpty {
            return []
        }
        
        var taskTypes = Set<String>()
        for task in tasks {
            taskTypes.insert(task.title)
        }
        
        return Array(taskTypes).sorted()
    }
    
    // 获取唯一的任务类型列表
    private func getUniqueTaskTypes() -> [String] {
        let tasks = tasksForSelectedRange
        if tasks.isEmpty {
            return []
        }
        
        var taskTypes = Set<String>()
        for task in tasks {
            taskTypes.insert(task.title)
        }
        
        return Array(taskTypes).sorted()
    }
    
    // 获取特定类型的任务数量
    private func getTaskCountByType(_ type: String) -> Int {
        return tasksForSelectedRange.filter { $0.title == type }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView()
                        
                        if showRoleSelector {
                            roleSelectionView()
                                .padding(.horizontal)
                        }
                        
                        timeRangeSelectionView()
                            .padding(.horizontal)
                        
                        if taskDataIsEmpty {
                            emptyStateView()
                        } else {
                            VStack(spacing: 16) {
                                taskSummaryCard()
                                timeDistributionCard
                                mostProductiveTimesCard()
                                lessProductiveTimesCard()
                                topCombinationsCard()
                                trendingTaskTypesCard()
                                consistentActivitiesCard()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitle("时间分析", displayMode: .inline)
            .navigationBarItems(trailing: trailingNavBarButton)
            .sheet(isPresented: $showDetailedSuggestion) {
                if let taskType = currentTaskType {
                    detailedSuggestionView(for: taskType)
                }
            }
        }
    }
    
    // MARK: - 子视图拆分
    
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
            // 移除 "选择您的职业角色" 文字
            
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
    
    // 获取角色对应的颜色
    private func getRoleColor(_ role: String) -> Color {
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
            dateRangeSelector
                .padding(.bottom, 6)
            
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(getTaskTypes(), id: \.self) { taskType in
                        taskTypeCard(taskType: taskType)
                            .padding(.horizontal, 24) // 增加水平边距
                    }
                    
                    // 添加报告查看按钮，仅在查看非今天的数据时显示
                    if selectedRange != .today {
                        summaryReportButton
                            .padding(.horizontal, 24) // 增加水平边距
                            .padding(.top, 6)
                            .padding(.bottom, 10)
                    }
                }
                .padding(.top, 6)
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
    
    // 任务总数卡片
    private var taskSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和总数部分，与任务类型图标并排
            HStack(alignment: .center, spacing: 16) {
                // 左侧：任务总数信息
                VStack(alignment: .leading, spacing: 4) {
                    Text("任务总数")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("\(tasksForSelectedRange.count)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeManager.colors.text)
                }
                
                Spacer()
                
                // 右侧：任务类型图标水平滚动
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        let uniqueTaskTypes = getUniqueTaskTypes()
                        ForEach(uniqueTaskTypes, id: \.self) { taskType in
                            VStack(spacing: 2) {
                                // 任务类型图标
                                Image(systemName: getIconForTaskType(taskType))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .fill(Color.black)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                                
                                // 任务次数
                                HStack(spacing: 3) {
                                    Text("\(getTaskCountByType(taskType))")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(themeManager.colors.text)
                                        
                                    Text("次")
                                        .font(.system(size: 8))
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 220)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 时间分配卡片 - 优化为方案E样式
    private var timeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 标题区域
            HStack {
                Text("时间分配")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // 显示总时间
                if let minutes = timeMinutesForSelectedRange(), minutes > 0 {
                    Text("总计: \(formatTime(minutes))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 15)
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 10)
            
            if taskTypesForTimeRange().isEmpty {
                // 无数据显示
                VStack(spacing: 15) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("没有记录的任务数据")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text("开始记录你的第一个任务吧")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // 时间健康仪表盘 - 方案E实现
                VStack(spacing: 20) {
                    // 时间分配健康评分
                    timeHealthScoreView()
                    
                    // 任务类型列表
                    VStack(spacing: 18) {
                        ForEach(uniqueTaskTypes(for: selectedTimeRange), id: \.self) { taskType in
                            if let percentage = calculatePercentage(for: taskType, in: selectedTimeRange) {
                                taskTimeHealthRow(taskType: taskType, percentage: percentage)
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 15)
        .padding(.bottom, 15)
    }
    
    // 时间健康评分视图
    private func timeHealthScoreView() -> some View {
        VStack(spacing: 12) {
            // 健康评分标题
            Text("时间分配健康评分")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
            
            // 健康评分指示器
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Image(systemName: index < calculateOverallHealthScore() ? "star.fill" : "star")
                        .foregroundColor(index < calculateOverallHealthScore() ? .yellow : .gray.opacity(0.3))
                        .font(.system(size: 20))
                }
            }
            
            // 健康评分描述
            Text(getHealthScoreDescription())
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal, 15)
    }
    
    // 计算总体健康评分 (1-5 星)
    private func calculateOverallHealthScore() -> Int {
        guard let roleStandard = getRoleStandard(for: selectedRole) else { return 3 }
        
        var score = 3 // 默认中等评分
        var deviationSum = 0.0
        var totalTypes = 0
        
        for taskType in uniqueTaskTypes(for: selectedTimeRange) {
            if let percentage = calculatePercentage(for: taskType, in: selectedTimeRange),
               let standard = roleStandard.timeStandards.first(where: { $0.taskType == taskType }) {
                
                let idealPercentage = Double(standard.idealPercentage)
                let deviation = abs(percentage - idealPercentage)
                
                deviationSum += deviation
                totalTypes += 1
            }
        }
        
        if totalTypes > 0 {
            let averageDeviation = deviationSum / Double(totalTypes)
            
            if averageDeviation < 5 {
                score = 5 // 极佳
            } else if averageDeviation < 10 {
                score = 4 // 良好
            } else if averageDeviation < 15 {
                score = 3 // 一般
            } else if averageDeviation < 20 {
                score = 2 // 需要注意
            } else {
                score = 1 // 需要调整
            }
        }
        
        return score
    }
    
    // 获取健康评分描述
    private func getHealthScoreDescription() -> String {
        let score = calculateOverallHealthScore()
        
        switch score {
        case 5:
            return "您的时间分配极为理想，完美平衡各项活动。"
        case 4:
            return "时间分配良好，小部分活动可以进一步优化。"
        case 3:
            return "时间分配总体合理，但有些活动需要调整。"
        case 2:
            return "时间分配需要关注，多项活动偏离理想范围。"
        case 1:
            return "时间分配严重失衡，建议根据建议进行调整。"
        default:
            return "请记录更多任务来获取时间分配健康评分。"
        }
    }
    
    // 任务类型时间健康行
    private func taskTimeHealthRow(taskType: String, percentage: Double) -> some View {
        let status = getTaskTimeStatus(for: taskType, percentage: percentage)
        let suggestions = getSuggestionsForTaskType(taskType, status: status)
        let trend = getTrendForTaskType(taskType)
        
        return VStack(alignment: .leading, spacing: 8) {
            // 任务类型标题行
            HStack {
                // 任务类型图标与名称
                HStack(spacing: 6) {
                    Image(systemName: TaskType(rawValue: taskType)?.icon ?? "circle.fill")
                        .foregroundColor(TaskType(rawValue: taskType)?.color ?? .gray)
                        .font(.system(size: 16))
                    
                    Text(taskType)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // 状态标签
                HStack(spacing: 4) {
                    Image(systemName: status.icon)
                        .font(.system(size: 12))
                        .foregroundColor(status.color)
                    
                    Text(status.statusText)
                        .font(.system(size: 13))
                        .foregroundColor(status.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 时间百分比进度条和数值
            HStack(spacing: 10) {
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景条
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getTimeBarColor(for: taskType, percentage: percentage))
                            .frame(width: geometry.size.width * CGFloat(min(percentage, 100)) / 100, height: 8)
                        
                        // 理想范围指示器
                        if let ideal = getIdealPercentage(for: taskType) {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 2, height: 12)
                                .offset(x: geometry.size.width * CGFloat(ideal) / 100 - 1)
                        }
                    }
                }
                .frame(height: 8)
                
                // 百分比数值
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 50, alignment: .trailing)
            }
            
            // 趋势和建议
            VStack(alignment: .leading, spacing: 6) {
                // 趋势信息
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.increasing ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(trend.increasing ? .red : .green)
                        
                        Text("\(trend.increasing ? "增加" : "减少") \(trend.percentChange)%")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                // 主要建议
                if !suggestions.isEmpty {
                    Text(suggestions.first ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.9))
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // 获取进度条颜色
    private func getTimeBarColor(for taskType: String, percentage: Double) -> Color {
        let status = getTaskTimeStatus(for: taskType, percentage: percentage)
        
        switch status.statusText {
        case "理想":
            return .green
        case "过多":
            return .red
        case "不足":
            return .orange
        case "额外":
            return .blue
        default:
            return .gray
        }
    }
    
    // 获取理想百分比
    private func getIdealPercentage(for taskType: String) -> Double? {
        guard let roleStandard = getRoleStandard(for: selectedRole) else { return nil }
        
        if let standard = roleStandard.timeStandards.first(where: { $0.taskType == taskType }) {
            return Double(standard.idealPercentage)
        }
        
        return nil
    }
    
    // 计算工作相关百分比
    private func calculateWorkRelatedPercentage() -> Double {
        let workTypes = ["工作", "会议", "思考"]
        let workStats = taskTypeStats.filter { workTypes.contains($0.type) }
        let workMinutes = workStats.reduce(0) { $0 + $1.minutes }
        
        return calculatePercentage(minutes: workMinutes, total: totalTimeForSelectedRange)
    }
    
    // 获取简短建议
    private func getShortSuggestion(for taskType: String, status: String) -> String? {
        switch status {
        case "理想":
            return "保持当前分配"
        case "过多":
            switch taskType {
            case "工作":
                return "尝试减少25%，避免倦怠"
            case "会议":
                return "精简非必要会议"
            case "摸鱼":
                return "适当减少，提高效率"
            default:
                return "考虑减少时间分配"
            }
        case "不足":
            switch taskType {
            case "运动":
                return "增加至少30分钟/天"
            case "思考":
                return "每天增加15-30分钟"
            case "阅读":
                return "增加阅读，拓展见识"
            default:
                return "考虑增加时间分配"
            }
        default:
            return nil
        }
    }
    
    // 获取工作类别颜色
    private func getWorkCategoryColor(percentage: Double) -> Color {
        if percentage > 70 {
            return .red
        } else if percentage > 60 {
            return .orange
        } else if percentage < 40 {
            return .blue
        } else {
            return .green
        }
    }
    
    // 获取生活类别颜色
    private func getLifeCategoryColor(percentage: Double) -> Color {
        if percentage < 30 {
            return .red
        } else if percentage < 40 {
            return .orange
        } else if percentage > 60 {
            return .blue
        } else {
            return .green
        }
    }
    
    // 计算平衡分数
    private func calculateBalanceScore() -> Int {
        let workPercentage = calculateWorkRelatedPercentage()
        let lifePercentage = 100 - workPercentage
        
        // 理想比例为 55:45 到 45:55
        let diff = abs(workPercentage - 50)
        
        if diff <= 5 {
            return 100  // 完美平衡
        } else if diff <= 10 {
            return 90   // 良好平衡
        } else if diff <= 15 {
            return 80   // 一般平衡
        } else if diff <= 20 {
            return 70   // 轻微失衡
        } else if diff <= 25 {
            return 60   // 中度失衡
        } else {
            return 50   // 严重失衡
        }
    }
    
    // 获取平衡分数颜色
    private func getBalanceColor(score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 70..<90:
            return .blue
        case 60..<70:
            return .orange
        default:
            return .red
        }
    }
    
    // 获取健康指数颜色
    private func getHealthColor(for score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

// 添加详细建议视图
private func detailedSuggestionView(for taskType: String) -> some View {
    let percentage = taskTypeStats.first(where: { $0.type == taskType })?.minutes ?? 0
    let totalTime = totalTimeForSelectedRange
    let calculatedPercentage = calculatePercentage(minutes: percentage, total: totalTime)
    let status = getTaskTimeStatus(for: taskType, percentage: calculatedPercentage)
    
    return NavigationView {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题和摘要
                VStack(alignment: .leading, spacing: 8) {
                    Text(taskType)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                            Text(formatTimeString(minutes: percentage))
                                .font(.subheadline)
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text("•")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack(spacing: 4) {
                            Text("\(formatPercentage(calculatedPercentage))%")
                                .font(.subheadline)
                            Text("总时间")
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(themeManager.currentTheme.cardBackgroundColor)
                .cornerRadius(12)
                
                // 状态和建议
                VStack(alignment: .leading, spacing: 16) {
                    Text("状态分析")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    statusAnalysisView(for: taskType, status: status)
                    
                    Text("优化建议")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .padding(.top, 8)
                    
                    optimizationSuggestionsView(for: taskType, status: status)
                }
                .padding()
                .background(themeManager.currentTheme.cardBackgroundColor)
                .cornerRadius(12)
                
                // 相关趋势
                if let trend = getTrendForTaskType(taskType) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("近期趋势")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack(spacing: 8) {
                            Image(systemName: trend.increasing ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 14))
                                .foregroundColor(trend.increasing ? .green : .red)
                            
                            Text(trend.increasing ? "上升趋势" : "下降趋势")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                            Text("\(trend.percentChange)%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(trend.increasing ? .green : .red)
                        }
                        
                        Text(trend.description)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(themeManager.currentTheme.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("详细分析", displayMode: .inline)
        .navigationBarItems(trailing: Button("关闭") {
            showDetailedSuggestion = false
        })
    }
}

// 状态分析视图
private func statusAnalysisView(for taskType: String, status: TaskTimeStatus) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.system(size: 16))
                .foregroundColor(status.color)
            
            Text(status.statusText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        
        Text(getStatusDescription(for: taskType, status: status))
            .font(.subheadline)
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
        
        // 时间比较图表
        HStack(spacing: 0) {
            if let roleStandard = getRoleStandard(for: selectedRole),
               let standard = roleStandard.timeStandards.first(where: { $0.taskType == taskType }) {
                let idealPercentage = Double(standard.idealPercentage)
                let actualPercentage = taskTypeStats.first(where: { $0.type == taskType })?.minutes ?? 0
                let calculatedActualPercentage = calculatePercentage(minutes: actualPercentage, total: totalTimeForSelectedRange)
                
                // 推荐时间
                VStack(spacing: 4) {
                    Text("推荐")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text("\(Int(idealPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(themeManager.currentTheme.secondaryTextColor.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                // 实际时间
                VStack(spacing: 4) {
                    Text("实际")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text("\(formatPercentage(calculatedActualPercentage))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(status.color)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(themeManager.currentTheme.secondaryTextColor.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                // 差异
                VStack(spacing: 4) {
                    Text("差异")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    let diff = calculatedActualPercentage - idealPercentage
                    Text("\(diff > 0 ? "+" : "")\(formatPercentage(diff))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(diff > 0 ? .red : (diff < 0 ? .orange : .green))
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("无推荐标准")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(themeManager.currentTheme.backgroundColor.opacity(0.5))
        .cornerRadius(8)
    }
}

// 优化建议视图
private func optimizationSuggestionsView(for taskType: String, status: TaskTimeStatus) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(getSuggestions(for: taskType, status: status), id: \.self) { suggestion in
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                    .frame(width: 20, height: 20)
                
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }
}

// 获取状态描述
private func getStatusDescription(for taskType: String, status: TaskTimeStatus) -> String {
    switch status.statusText {
    case "理想":
        return "您在\(taskType)上的时间分配非常理想，符合您当前角色的推荐标准。保持这种平衡对提高生产力和生活质量非常有益。"
    case "过多":
        return "您在\(taskType)上花费的时间过多，可能挤占了其他重要活动的时间。适当减少这方面的时间投入，有助于获得更均衡的时间分配。"
    case "不足":
        return "您在\(taskType)上投入的时间不足，低于推荐标准。适当增加这方面的时间投入，可能有助于提高整体效率和满意度。"
    case "额外":
        return "\(taskType)不在当前角色的标准任务类型中，但这不一定是问题。请根据个人需求和目标评估其重要性和时间分配。"
    default:
        return "无法确定\(taskType)的时间分配状态，请参考个人需求和目标进行调整。"
    }
}

// 获取建议
private func getSuggestions(for taskType: String, status: TaskTimeStatus) -> [String] {
    var suggestions: [String] = []
    
    switch taskType {
    case "工作":
        if status.statusText == "过多" {
            suggestions.append("尝试使用番茄工作法，设定工作时间和休息时间，提高工作效率，减少总工作时长。")
            suggestions.append("考虑将一些工作任务委派给他人，或使用工具自动化处理重复性工作。")
            suggestions.append("严格控制工作时间，设定明确的工作结束时间，避免工作侵占私人生活。")
        } else if status.statusText == "不足" {
            suggestions.append("设定明确的工作目标和时间表，确保工作任务得到充分关注。")
            suggestions.append("减少工作中的干扰和中断，提高工作专注度和效率。")
            suggestions.append("考虑是否需要拓展工作技能，以便更高效地完成工作任务。")
        } else {
            suggestions.append("定期检查工作效率，寻找优化工作流程的方法。")
            suggestions.append("保持工作与生活的平衡，确保有足够的休息和恢复时间。")
        }
    case "睡眠":
        if status.statusText == "过多" {
            suggestions.append("睡眠质量可能存在问题，考虑改善睡眠环境或就寝前的习惯，以提高睡眠质量。")
            suggestions.append("尝试逐渐减少睡眠时间，每周减少15-30分钟，直至达到理想睡眠时长。")
            suggestions.append("记录睡眠日志，分析是否有特定因素导致睡眠时间过长。")
        } else if status.statusText == "不足" {
            suggestions.append("睡眠不足会显著影响健康和工作效率，尝试固定就寝和起床时间，培养规律的睡眠习惯。")
            suggestions.append("避免睡前使用电子设备，减少蓝光对睡眠的干扰。")
            suggestions.append("考虑使用冥想或放松技巧来提高睡眠质量。")
        } else {
            suggestions.append("保持规律的睡眠时间表，即使在周末也尽量保持一致。")
            suggestions.append("定期评估睡眠质量，确保睡眠充分恢复体力和精力。")
        }
    case "会议":
        if status.statusText == "过多" {
            suggestions.append("审查会议日程，评估哪些会议是必要的，哪些可以通过电子邮件或即时通讯解决。")
            suggestions.append("为会议设定明确的议程和时间限制，提高会议效率。")
            suggestions.append("考虑使用异步沟通工具减少实时会议的需求。")
        } else if status.statusText == "不足" {
            suggestions.append("增加团队同步的频率，确保信息和决策的有效传达。")
            suggestions.append("考虑设立定期的简短站会，提高团队协作效率。")
            suggestions.append("确保关键决策有足够的讨论时间，避免因沟通不足导致的问题。")
        } else {
            suggestions.append("定期评估会议效率，确保每次会议都有明确的目标和成果。")
            suggestions.append("尝试新的会议形式，如走动式会议或时间限制会议，提高效率。")
        }
    default:
        if status.statusText == "过多" {
            suggestions.append("考虑减少在\(taskType)上的时间投入，将时间重新分配到其他关键活动中。")
            suggestions.append("分析\(taskType)的价值和必要性，确定是否需要调整其优先级。")
        } else if status.statusText == "不足" {
            suggestions.append("适当增加\(taskType)的时间投入，可能有助于提高整体平衡。")
            suggestions.append("设定\(taskType)的具体目标和时间表，确保其获得充分关注。")
        } else if status.statusText == "额外" {
            suggestions.append("评估\(taskType)对您当前角色和目标的重要性，决定是否需要调整时间分配。")
            suggestions.append("考虑\(taskType)是否可以与其他必要活动结合，提高时间利用效率。")
        } else {
            suggestions.append("继续保持\(taskType)的当前时间分配，定期评估其效果和价值。")
        }
    }
    
    // 添加根据当前角色的特定建议
    if let roleStandard = getRoleStandard(for: selectedRole) {
        switch roleStandard.type {
        case "创业者":
            if taskType == "工作" && status.statusText == "过多" {
                suggestions.append("作为创业者，高强度工作是常态，但请确保合理分配时间给团队建设和战略思考。")
            } else if taskType == "休闲" && status.statusText == "不足" {
                suggestions.append("创业压力大，适当的休闲活动对保持创造力和避免倦怠至关重要。")
            }
        case "职场人士":
            if taskType == "会议" && status.statusText == "过多" {
                suggestions.append("作为职场人士，过多的会议可能影响核心工作完成，建议优化会议安排和流程。")
            } else if taskType == "学习" && status.statusText == "不足" {
                suggestions.append("职场竞争激烈，持续学习和技能提升对职业发展至关重要。")
            }
        case "管理者":
            if taskType == "管理" && status.statusText == "不足" {
                suggestions.append("作为管理者，需要确保足够的时间用于团队管理、指导和战略规划。")
            } else if taskType == "个人成长" && status.statusText == "不足" {
                suggestions.append("管理者的成长直接影响团队发展，建议投入更多时间在个人能力提升上。")
            }
        default:
            break
        }
    }
    
    return suggestions
}

// 获取任务类型的趋势信息
private func getTrendForTaskType(_ taskType: String) -> (increasing: Bool, percentChange: Double)? {
    // 如果是周数据，与上周比较
    if selectedTimeRange == .week {
        // 获取本周和上周的任务
        let currentWeekTasks = getTasksForTimeRange(timeRange: .week)
        
        // 计算上周的日期范围
        let calendar = Calendar.current
        let today = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return nil
        }
        
        let previousWeekStart = calendar.date(byAdding: .day, value: -6, to: weekAgo)!
        let previousWeekEnd = weekAgo
        
        // 获取上周的任务
        let previousWeekTasks = taskManager.tasks.filter { task in
            guard let date = task.timestamp else { return false }
            return date >= previousWeekStart && date <= previousWeekEnd && task.type == taskType
        }
        
        // 计算当前周和上周的总时间（分钟）
        let currentWeekMinutes = calculateTotalTimeForTaskType(taskType: taskType, tasks: currentWeekTasks)
        let previousWeekMinutes = calculateTotalTimeForTaskType(taskType: taskType, tasks: previousWeekTasks)
        
        // 避免除以零错误
        if previousWeekMinutes > 0 {
            let percentChange = abs(Double(currentWeekMinutes - previousWeekMinutes) / Double(previousWeekMinutes) * 100)
            return (currentWeekMinutes > previousWeekMinutes, Double(Int(percentChange * 10)) / 10.0)
        }
        
        // 上周没有数据但本周有
        if previousWeekMinutes == 0 && currentWeekMinutes > 0 {
            return (true, 100.0)
        }
    }
    // 如果是月数据，与上月比较
    else if selectedTimeRange == .month {
        // 获取本月和上月的任务
        let currentMonthTasks = getTasksForTimeRange(timeRange: .month)
        
        // 计算上月的日期范围
        let calendar = Calendar.current
        let today = Date()
        guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) else {
            return nil
        }
        
        // 获取上月的第一天和最后一天
        let components = calendar.dateComponents([.year, .month], from: monthAgo)
        guard let previousMonthStart = calendar.date(from: components),
              let previousMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: previousMonthStart) else {
            return nil
        }
        
        // 获取上月的任务
        let previousMonthTasks = taskManager.tasks.filter { task in
            guard let date = task.timestamp else { return false }
            return date >= previousMonthStart && date <= previousMonthEnd && task.type == taskType
        }
        
        // 计算当前月和上月的总时间（分钟）
        let currentMonthMinutes = calculateTotalTimeForTaskType(taskType: taskType, tasks: currentMonthTasks)
        let previousMonthMinutes = calculateTotalTimeForTaskType(taskType: taskType, tasks: previousMonthTasks)
        
        // 避免除以零错误
        if previousMonthMinutes > 0 {
            let percentChange = abs(Double(currentMonthMinutes - previousMonthMinutes) / Double(previousMonthMinutes) * 100)
            return (currentMonthMinutes > previousMonthMinutes, Double(Int(percentChange * 10)) / 10.0)
        }
        
        // 上月没有数据但本月有
        if previousMonthMinutes == 0 && currentMonthMinutes > 0 {
            return (true, 100.0)
        }
    }
    
    // 如果是日数据或没有足够的历史数据进行比较
    return nil
}

// 获取特定任务类型的总时间
private func calculateTotalTimeForTaskType(taskType: String, tasks: [Task]) -> Int {
    let typeTasks = tasks.filter { $0.type == taskType }
    return typeTasks.reduce(0) { result, task in
        result + (task.duration ?? 0)
    }
}

// 获取任务时间状态
private func getTaskTimeStatus(for taskType: String, percentage: Double) -> TaskTimeStatus {
    guard let roleStandard = getRoleStandard(for: selectedRole) else {
        return TaskTimeStatus(statusText: "未知", icon: "questionmark.circle", color: .gray)
    }
    
    if let standard = roleStandard.timeStandards.first(where: { $0.taskType == taskType }) {
        let idealPercentage = Double(standard.idealPercentage)
        let diff = percentage - idealPercentage
        
        if abs(diff) <= 5 {
            return TaskTimeStatus(statusText: "理想", icon: "checkmark.circle", color: .green)
        } else if diff > 5 {
            return TaskTimeStatus(statusText: "过多", icon: "arrow.up.circle", color: .red)
        } else {
            return TaskTimeStatus(statusText: "不足", icon: "arrow.down.circle", color: .orange)
        }
    }
    
    // 对于标准中没有的类型
    return TaskTimeStatus(statusText: "额外", icon: "plus.circle", color: .blue)
}

// 获取角色标准
private func getRoleStandard(for roleName: String) -> RoleStandard? {
    return roleStandards.first { $0.type == roleName }
}

// 获取任务时间状态结构
private struct TaskTimeStatus {
    let statusText: String
    let icon: String
    let color: Color
}

// 获取特定时间范围内的任务类型列表
private func uniqueTaskTypes(for timeRange: TimeRange) -> [String] {
    let tasks = getTasksForTimeRange(timeRange: timeRange)
    var types = Set<String>()
    
    for task in tasks {
        types.insert(task.type)
    }
    
    return Array(types).sorted()
}

// 获取特定时间范围内的任务
private func getTasksForTimeRange(timeRange: TimeRange) -> [Task] {
    let calendar = Calendar.current
    let now = Date()
    
    let completedTasks = appViewModel.tasks.filter { $0.isCompleted }
    
    switch timeRange {
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

// 计算特定任务类型的时间百分比
private func calculatePercentage(for taskType: String, in timeRange: TimeRange) -> Double? {
    let tasks = getTasksForTimeRange(timeRange: timeRange)
    let taskTypeSpecificTasks = tasks.filter { $0.type == taskType }
    
    let totalMinutes = tasks.reduce(0) { $0 + ($1.duration ?? 0) }
    let typeMinutes = taskTypeSpecificTasks.reduce(0) { $0 + ($1.duration ?? 0) }
    
    guard totalMinutes > 0 else { return nil }
    
    return Double(typeMinutes) / Double(totalMinutes) * 100
}

// 获取特定类型任务的建议
private func getSuggestionsForTaskType(_ taskType: String, status: TaskTimeStatus) -> [String] {
    var suggestions: [String] = []
    
    switch status.statusText {
    case "理想":
        suggestions.append("您在\(taskType)上的时间分配非常合理，请继续保持。")
    case "过多":
        switch taskType {
        case "工作":
            suggestions.append("工作时间过多，建议减少加班并提高工作效率。")
        case "会议":
            suggestions.append("会议时间过多，建议控制会议数量和时长。")
        case "摸鱼":
            suggestions.append("摸鱼时间较多，建议提高工作效率和专注度。")
        default:
            suggestions.append("\(taskType)时间占比过高，建议适当减少。")
        }
    case "不足":
        switch taskType {
        case "睡觉":
            suggestions.append("睡眠时间不足，建议保证7-8小时的充足睡眠。")
        case "运动":
            suggestions.append("运动时间不足，建议每天至少安排30分钟。")
        case "思考":
            suggestions.append("思考时间不足，建议每天留出固定时间进行深度思考。")
        default:
            suggestions.append("\(taskType)时间占比不足，建议适当增加。")
        }
    case "额外":
        suggestions.append("此活动不在您当前角色的标准规划中，请根据实际需求调整。")
    default:
        suggestions.append("无法分析\(taskType)的时间分配状态。")
    }
    
    return suggestions
}

// 获取当前时间范围内的任务类型
private func taskTypesForTimeRange() -> [String] {
    return uniqueTaskTypes(for: selectedRange)
}

// 获取当前时间范围内的总分钟数
private func timeMinutesForSelectedRange() -> Int? {
    let tasks = getTasksForTimeRange(timeRange: selectedRange)
    if tasks.isEmpty {
        return nil
    }
    
    return tasks.reduce(0) { $0 + ($1.duration ?? 0) }
}

// 格式化时间显示
private func formatTime(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    
    if hours > 0 {
        return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
    } else {
        return "\(mins)分钟"
    }
}