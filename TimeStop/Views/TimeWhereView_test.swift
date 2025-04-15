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
    
    // 获取状态颜色
    var color: Color {
        switch self {
        case .healthy: return Color.green
        case .warning: return Color.orange
        case .critical: return Color.red
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
        ZStack {
            themeManager.colors.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                headerView
                
                timeRangeSelector
                    .padding(.bottom, 8)
                
                if tasksForSelectedRange.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .onAppear {
                print("时间去哪了页面加载: 任务总数 \(appViewModel.tasks.count)")
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
    
    // 时间分配卡片
    private var timeDistributionCard: some View {
        // 时间健康仪表盘卡片 - 方案E样式
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Text("时间分配")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                Text("\(totalTimeForSelectedRange)分钟")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme == .elegantPurple ? 
                                  Color(hex: "8A2BE2").opacity(0.9) : 
                                  Color(hex: "0C4A45").opacity(0.9))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 分隔线
            Rectangle()
                .fill(themeManager.colors.secondaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // 时间分配内容
            let stats = getTaskTypesStats()
            
            if stats.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 健康度指标 - 方案E风格
                        timeHealthDashboard(stats)
                            .padding(.top, 16)
                        
                        // 分隔线
                        Rectangle()
                            .fill(themeManager.colors.secondaryText.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                        
                        // 任务类型列表标题
                        HStack {
                            Text("任务分配详情")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(themeManager.colors.text)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                        
                        // 任务类型列表 - 增强版健康状态卡片
                        VStack(spacing: 16) {
                            ForEach(stats, id: \.type) { stat in
                                enhancedTimeAllocationRow(stat: stat)
                                    .padding(.horizontal, 16)
                                
                                if stats.last?.type != stat.type {
                                    Rectangle()
                                        .fill(themeManager.colors.secondaryText.opacity(0.08))
                                        .frame(height: 1)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .frame(maxHeight: 500)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
    
    // 时间健康仪表盘 - 方案E主要组件
    private func timeHealthDashboard(_ stats: [TaskTypeStat]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            // 顶部健康度指标
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("时间健康度")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("基于当前角色标准评估")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    let healthScore = calculateHealthScore(stats)
                    
                    ZStack {
                        Circle()
                            .fill(healthScoreColor(healthScore).opacity(0.15))
                            .frame(width: 46, height: 46)
                        
                        Circle()
                            .trim(from: 0, to: min(CGFloat(healthScore) / 100, 1.0))
                            .stroke(healthScoreColor(healthScore), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(Int(healthScore))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(healthScoreColor(healthScore))
                        }
                    }
                }
                
                // 健康度评分条
                ZStack(alignment: .leading) {
                    // 背景层
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // 得分层
                    let healthScore = calculateHealthScore(stats)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(healthScoreColor(healthScore))
                        .frame(width: max(5, UIScreen.main.bounds.width * 0.85 * CGFloat(healthScore) / 100), height: 12)
                    
                    // 得分区间标记
                    HStack(spacing: 0) {
                        ForEach(0..<3) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 1, height: 8)
                                .offset(x: UIScreen.main.bounds.width * 0.85 * CGFloat((i + 1) * 25) / 100)
                        }
                    }
                }
                
                // 健康度评价
                HStack {
                    let healthScore = calculateHealthScore(stats)
                    Text(getHealthScoreEvaluation(healthScore))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Text(healthScoreSymbol(healthScore))
                        .font(.system(size: 18))
                        .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, 16)
            
            // 核心指标
            VStack(alignment: .leading, spacing: 8) {
                Text("核心指标")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    // 工作效率指标
                    metricCard(
                        title: "工作效率",
                        value: calculateWorkEfficiencyIndex(stats),
                        icon: "briefcase.fill",
                        color: Color.blue
                    )
                    
                    // 生活平衡指标
                    metricCard(
                        title: "生活平衡",
                        value: calculateLifeBalanceIndex(stats),
                        icon: "heart.fill",
                        color: Color.pink
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // 指标卡片
    private func metricCard(title: String, value: Int, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.colors.secondaryText)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("/100")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.secondaryText)
                }
            }
            
            Spacer()
            
            // 评分标识
            ZStack {
                Circle()
                    .fill(getMetricStatusColor(value).opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Text(getMetricStatusSymbol(value))
                    .font(.system(size: 12))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.background.opacity(0.5))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
    }
    
    // 增强版时间分配行
    private func enhancedTimeAllocationRow(stat: TaskTypeStat) -> some View {
        let percentage = Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100
        let idealPercentage = getIdealPercentage(for: stat.type)
        let hoursSpent = Double(stat.minutes) / 60.0
        let timeStatus = getTimeStatus(for: stat.type, actualPercentage: percentage)
        
        return VStack(alignment: .leading, spacing: 12) {
            // 任务类型标题区域
            HStack(alignment: .center) {
                // 任务图标和名称
                HStack(spacing: 10) {
                    Image(systemName: getIconForTaskType(stat.type))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(getTaskTypeColor(stat.type))
                                .shadow(color: getTaskTypeColor(stat.type).opacity(0.3), radius: 2, x: 0, y: 1)
                        )
                    
                    Text(stat.type)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                }
                
                Spacer()
                
                // 健康状态标签
                HStack(spacing: 4) {
                    Text(getStatusDescription(status: timeStatus))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(getStatusColor(status: timeStatus).opacity(0.9))
                        )
                }
            }
            
            // 时间详情区域
            HStack(spacing: 16) {
                // 实际时间
                VStack(alignment: .leading, spacing: 2) {
                    Text("实际")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(hoursSpent, specifier: "%.1f")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("小时")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // 理想时间
                VStack(alignment: .leading, spacing: 2) {
                    Text("理想")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    let idealHours = Double(totalTimeForSelectedRange) * idealPercentage / 100 / 60
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(idealHours, specifier: "%.1f")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        Text("小时")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // 百分比信息
                VStack(alignment: .trailing, spacing: 2) {
                    Text("占比")
                        .font(.system(size: 11))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(percentage, specifier: "%.1f")")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("%")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
            }
            
            // 进度条区域
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)
                    
                    // 实际时间条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getStatusColor(status: timeStatus))
                        .frame(width: max(4, UIScreen.main.bounds.width * 0.8 * CGFloat(percentage) / 100), height: 10)
                    
                    // 理想时间标记线
                    if idealPercentage > 0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 15)
                            .offset(x: UIScreen.main.bounds.width * 0.8 * CGFloat(idealPercentage) / 100 - 1, y: -2)
                    }
                }
                
                // 建议信息
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(getStatusColor(status: timeStatus).opacity(0.7))
                    
                    Text(getEnhancedSuggestionText(for: stat.type, status: timeStatus))
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    // 增强版建议文本
    private func getEnhancedSuggestionText(for taskType: String, status: TimeStatus) -> String {
        let roleName = currentRoleStandard.type
        
        switch (taskType, status) {
        case ("工作", .overTime):
            return "作为\(roleName)，工作时间过长。建议：减少20%的工作量，增加休息频率，关注效率而非时长。"
        case ("工作", .underTime):
            return "作为\(roleName)，工作时间不足。建议：使用番茄工作法，设置集中工作时段，减少干扰因素。"
        case ("会议", .overTime):
            return "作为\(roleName)，会议占用时间过多。建议：控制会议时长，明确议程，减少非必要参与者。"
        case ("会议", .underTime):
            return "作为\(roleName)，会议时间适中。建议：维持良好的沟通效率，确保会议成果及时落实。"
        case ("思考", .overTime):
            return "作为\(roleName)，思考时间充足。建议：多产出实际成果，将思考转化为行动计划或文档。"
        case ("思考", .underTime):
            return "作为\(roleName)，思考时间不足。建议：每日安排15-30分钟独处思考时间，避免过度执行而缺乏规划。"
        case ("阅读", .overTime):
            return "作为\(roleName)，阅读时间充足。建议：关注阅读效率，选择更聚焦的材料，应用所学到实际工作中。"
        case ("阅读", .underTime):
            return "作为\(roleName)，阅读时间不足。建议：每日安排固定阅读时段，选择对角色发展有帮助的专业书籍。"
        case ("生活", .overTime):
            return "作为\(roleName)，生活事务占用时间较多。建议：优化生活流程，考虑外包部分家务，提高效率。"
        case ("生活", .underTime):
            return "作为\(roleName)，生活事务时间合理。建议：保持当前平衡，确保生活质量不受工作影响。"
        case ("运动", .overTime):
            return "作为\(roleName)，运动时间充足。建议：保持当前运动习惯，可以适当提高运动强度以获得更好效果。"
        case ("运动", .underTime):
            return "作为\(roleName)，运动时间不足。建议：每日至少安排30分钟运动，可分散为短时间高强度间歇训练。"
        case ("摸鱼", .overTime):
            return "作为\(roleName)，休闲时间过多。建议：将部分休闲时间转化为学习或创造性活动，增加高质量休闲内容。"
        case ("摸鱼", .underTime):
            return "作为\(roleName)，休闲时间适中。建议：保持当前平衡，确保休闲活动能够有效缓解压力。"
        case ("睡觉", .overTime):
            return "作为\(roleName)，睡眠时间充足。建议：保持规律作息，关注睡眠质量，避免过度睡眠导致的倦怠感。"
        case ("睡觉", .underTime):
            return "作为\(roleName)，睡眠时间不足。建议：保证7-8小时高质量睡眠，建立睡前仪式，避免使用电子设备。"
        case (_, .normal):
            return "作为\(roleName)，您的\(taskType)时间分配非常合理。建议：继续保持当前节奏，适时微调以适应工作生活变化。"
        default:
            return "请根据\(roleName)角色标准，合理调整\(taskType)的时间分配，保持生活与工作的平衡。"
        }
    }
    
    // 计算健康分数
    private func calculateHealthScore(_ stats: [TaskTypeStat]) -> Double {
        guard !stats.isEmpty else { return 0 }
        
        var totalDeviation: Double = 0
        var totalWeight: Double = 0
        
        for stat in stats {
            let idealPercentage = getIdealPercentage(for: stat.type)
            let actualPercentage = stat.percentage
            
            // 计算偏差，使用绝对值
            let deviation = abs(actualPercentage - idealPercentage)
            
            // 根据任务类型的重要性给予权重
            let weight: Double
            switch stat.type {
            case .work, .study:
                weight = 1.5
            case .rest:
                weight = 1.3
            case .social:
                weight = 1.0
            case .entertainment:
                weight = 0.8
            case .other:
                weight = 0.5
            }
            
            totalDeviation += deviation * weight
            totalWeight += weight
        }
        
        // 计算加权平均偏差
        let averageDeviation = totalWeight > 0 ? totalDeviation / totalWeight : 0
        
        // 转换为健康分数，最大偏差为50%时分数为0，无偏差时分数为100
        let score = max(0, 100 - (averageDeviation * 2))
        return score
    }
    
    // 获取各类任务的理想百分比
    private func getIdealPercentage(for taskType: String) -> Double {
        // 根据当前角色标准获取理想百分比
        if let standard = currentRoleStandard.getStandard(for: taskType) {
            // 计算每日理想小时数的中间值，转换为百分比
            let avgHours = (standard.lowerBound + standard.upperBound) / 2
            return (avgHours / 24) * 100
        }
        
        // 默认百分比（如果未在角色标准中定义）
        switch taskType {
        case "工作":
            return 30.0
        case "会议":
            return 10.0
        case "思考":
            return 5.0
        case "阅读":
            return 5.0
        case "生活":
            return 10.0
        case "运动":
            return 5.0
        case "摸鱼":
            return 5.0
        case "睡觉":
            return 30.0
        default:
            return 5.0
        }
    }
    
    // 判断任务时间状态
    private func getTimeStatus(for taskType: String, actualPercentage: Double) -> TimeStatus {
        let idealPercentage = getIdealPercentage(for: taskType)
        let tolerance: Double
        
        // 根据不同任务类型设置不同容忍度
        switch taskType {
        case "工作", "会议":
            tolerance = 7.0
        case "睡觉":
            tolerance = 5.0
        case "思考", "阅读":
            tolerance = 3.0
        case "生活", "运动", "摸鱼":
            tolerance = 4.0
        default:
            tolerance = 2.0
        }
        
        if actualPercentage > idealPercentage + tolerance {
            return .overTime
        } else if actualPercentage < idealPercentage - tolerance {
            return .underTime
        } else {
            return .normal
        }
    }
    
    // 计算工作效率指标 (0-100)
    private func calculateWorkEfficiencyIndex(_ stats: [TaskTypeStat]) -> Int {
        // 提取工作相关类型
        let workRelatedTypes = ["工作", "会议", "思考"]
        let workTasks = stats.filter { workRelatedTypes.contains($0.type) }
        
        if workTasks.isEmpty {
            return 0
        }
        
        // 基础分数 - 根据工作时间占比计算基础分
        let totalWorkTime = workTasks.reduce(0) { $0 + $1.minutes }
        let workPercentage = Double(totalWorkTime) / Double(totalTimeForSelectedRange) * 100
        
        // 理想工作占比根据角色确定
        var idealWorkPercentage: Double = 0
        if let workStandard = currentRoleStandard.getStandard(for: "工作") {
            idealWorkPercentage = ((workStandard.lowerBound + workStandard.upperBound) / 2) * 100 / 24
        } else {
            idealWorkPercentage = 30 // 默认值
        }
        
        // 计算工作时间偏差得分 (0-50分)
        let deviationPercentage = abs(workPercentage - idealWorkPercentage)
        let timeScore = max(0, 50 - (deviationPercentage * 50 / idealWorkPercentage))
        
        // 调整得分 - 考虑终止的任务和时间调整情况 (0-50分)
        var adjustmentScore: Double = 50
        let workStats = workTasks.filter { $0.type == "工作" }
        if !workStats.isEmpty {
            let terminatedRatio = Double(workStats.first?.terminatedCount ?? 0) / Double(workStats.first?.count ?? 1)
            let adjustmentRatio = abs(Double(workStats.first?.adjustmentMinutes ?? 0)) / Double(workStats.first?.originalMinutes ?? 1)
            
            // 终止任务越多，调整时间越大，得分越低
            adjustmentScore = max(0, 50 - (terminatedRatio * 25) - (adjustmentRatio * 25))
        }
        
        return Int(timeScore + adjustmentScore)
    }
    
    // 计算生活平衡指标 (0-100)
    private func calculateLifeBalanceIndex(_ stats: [TaskTypeStat]) -> Int {
        // 提取生活相关类型
        let lifeRelatedTypes = ["生活", "运动", "摸鱼", "睡觉"]
        let lifeTasks = stats.filter { lifeRelatedTypes.contains($0.type) }
        
        if lifeTasks.isEmpty {
            return 0
        }
        
        // 计算生活时间占比
        let totalLifeTime = lifeTasks.reduce(0) { $0 + $1.minutes }
        let lifePercentage = Double(totalLifeTime) / Double(totalTimeForSelectedRange) * 100
        
        // 理想生活占比
        var idealLifePercentage: Double = 0
        // 计算理想比例 - 基于角色标准汇总
        for type in lifeRelatedTypes {
            if let standard = currentRoleStandard.getStandard(for: type) {
                idealLifePercentage += ((standard.lowerBound + standard.upperBound) / 2) * 100 / 24
            }
        }
        if idealLifePercentage == 0 {
            idealLifePercentage = 50 // 默认值
        }
        
        // 计算生活时间平衡得分 (0-60分)
        let deviationPercentage = abs(lifePercentage - idealLifePercentage)
        let balanceScore = max(0, 60 - (deviationPercentage * 60 / idealLifePercentage))
        
        // 计算生活类型多样性得分 (0-40分)
        let typeCount = lifeTasks.count
        let diversityScore = min(40, Double(typeCount) * 10)
        
        return Int(balanceScore + diversityScore)
    }
    
    // 获取指标状态颜色
    private func getMetricStatusColor(_ value: Int) -> Color {
        switch value {
        case 0..<40:
            return .red
        case 40..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
    
    // 获取指标状态符号
    private func getMetricStatusSymbol(_ value: Int) -> String {
        switch value {
        case 0..<40:
            return "!"
        case 40..<60:
            return "?"
        case 60..<80:
            return "✓"
        default:
            return "★"
        }
    }
    
    // 获取健康分数对应的表情符号
    private func healthScoreSymbol(_ score: Double) -> String {
        switch score {
        case 0..<40:
            return "😟"
        case 40..<70:
            return "😐"
        case 70..<90:
            return "🙂"
        default:
            return "😄"
        }
    }

    private var timeAllocationStatsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("时间分配")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            if taskTypeStats.isEmpty {
                Text("暂无任务数据")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(taskTypeStats) { stat in
                    timeAllocationStatRow(for: stat)
                }
                
                // 添加健康建议视图
                healthSuggestionsView
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    // 健康建议视图
    private var healthSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("健康分数")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 计算健康分数
                let healthScore = calculateHealthScore()
                Text("\(Int(healthScore))分")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(healthScoreColor(healthScore))
                
                Text(healthScoreSymbol(healthScore))
                    .font(.title2)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // 检查是否所有任务类型都正常
            if isAllTaskTypesNormal() {
                Text("太棒了！你的时间分配非常均衡，继续保持！")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("时间管理建议")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(typeStats.filter { $0.status != .normal }, id: \.type) { stat in
                        suggestionRow(for: stat)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.8)))
        .padding(.horizontal)
    }

    // 计算整体健康分数（基于所有任务类型状态）
    private func calculateHealthScore() -> Double {
        let statusScores: [TaskTypeStatus: Double] = [
            .normal: 100,
            .underAllocated: 75,
            .overAllocated: 60,
            .highlyOverAllocated: 30,
            .severelyUnderAllocated: 40
        ]
        
        if typeStats.isEmpty {
            return 100 // 没有任务时返回满分
        }
        
        let totalScore = typeStats.reduce(0.0) { sum, stat in
            sum + (statusScores[stat.status] ?? 50)
        }
        
        return totalScore / Double(typeStats.count)
    }

    // 检查是否所有任务类型都处于正常状态
    private func isAllTaskTypesNormal() -> Bool {
        return typeStats.allSatisfy { $0.status == .normal }
    }

    // 为特定任务类型创建建议行
    private func suggestionRow(for stat: TaskTypeStat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(getTaskTypeColor(stat.type))
                    .frame(width: 10, height: 10)
                
                Text(getTaskTypeName(stat.type))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(stat.percentage))%")
                    .font(.subheadline)
                    .foregroundColor(getStatusColor(status: stat.status))
            }
            
            Text(getSuggestionText(for: stat))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 18)
        }
    }

    // 获取任务类型状态的建议文本
    private func getSuggestionText(for stat: TaskTypeStat) -> String {
        switch stat.status {
        case .normal:
            return "时间分配合理，继续保持！"
        case .underAllocated:
            return "时间分配略少，可以适当增加\(getTaskTypeName(stat.type))的时间。"
        case .severelyUnderAllocated:
            return "时间分配严重不足，建议增加\(getTaskTypeName(stat.type))的时间以保持平衡。"
        case .overAllocated:
            return "时间分配略多，可以适当减少\(getTaskTypeName(stat.type))的时间。"
        case .highlyOverAllocated:
            return "时间分配过多，建议减少\(getTaskTypeName(stat.type))的时间，注意时间平衡。"
        }
    }

    // 获取状态对应的颜色
    private func getStatusColor(_ status: TaskTypeStatus) -> Color {
        switch status {
        case .normal:
            return .green
        case .underAllocated, .overAllocated:
            return .orange
        case .severelyUnderAllocated, .highlyOverAllocated:
            return .red
        }
    }

    private func timeAllocationView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分配")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.titleColor)
                .padding(.horizontal)
            
            if taskTypeSummary.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.subtitleColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(taskTypeSummary) { stat in
                        Button(action: {
                            selectedStat = stat
                            showTimeAllocationAlert = true
                        }) {
                            timeAllocationCard(for: stat)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showTimeAllocationAlert) {
            if let stat = selectedStat {
                timeAllocationAlertView(for: stat)
            }
        }
    }

    private func timeAllocationCard(for stat: TaskTypeStat) -> some View {
        let percentage = calculatePercentage(for: stat)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(getTaskTypeColor(stat.type))
                    .frame(width: 12, height: 12)
                
                Text(getTaskTypeName(stat.type))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.titleColor)
                
                Spacer()
            }
            
            Text("\(stat.formattedDuration)")
                .font(.system(size: 14))
                .foregroundColor(themeManager.subtitleColor)
            
            Text("\(Int(percentage))%")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(getTaskTypeColor(stat.type))
        }
        .padding()
        .background(themeManager.secondaryBackgroundColor)
        .cornerRadius(10)
    }

    private func calculatePercentage(for stat: TaskTypeStat) -> Double {
        let totalTime = taskTypeSummary.reduce(0) { $0 + $1.minutes }
        return totalTime > 0 ? (Double(stat.minutes) / Double(totalTime)) * 100 : 0
    }

    private func timeAllocationAlertView(for stat: TaskTypeStat) -> some View {
        let percentage = calculatePercentage(for: stat)
        let totalTimeForSelectedRange = taskTypeSummary.reduce(0) { $0 + $1.minutes }
        
        return VStack(spacing: 25) {
            VStack(spacing: 10) {
                Text(getTaskTypeName(stat.type))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.titleColor)
                
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("总时长")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.subtitleColor)
                        Text("\(stat.formattedDuration)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.titleColor)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(spacing: 4) {
                        Text("占比")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.subtitleColor)
                        Text("\(Int(percentage))%")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(themeManager.titleColor)
                    }
                }
                .padding(.top, 5)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("时间分布")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.titleColor)
                
                VStack(spacing: 15) {
                    if let tasks = tasksForSelectedRange.filter({ $0.type == stat.type }).sorted(by: { $0.completedAt ?? Date() > $1.completedAt ?? Date() }), !tasks.isEmpty {
                        ForEach(tasks.prefix(5), id: \.id) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeManager.titleColor)
                                        .lineLimit(1)
                                    
                                    if let completedAt = task.completedAt {
                                        Text(dateFormatter.string(from: completedAt))
                                            .font(.system(size: 14))
                                            .foregroundColor(themeManager.subtitleColor)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(task.formattedDuration)")
                                    .font(.system(size: 16))
                                    .foregroundColor(getTaskTypeColor(stat.type))
                            }
                            .padding(.vertical, 5)
                            
                            if tasks.firstIndex(where: { $0.id == task.id }) != tasks.prefix(5).count - 1 {
                                Divider()
                            }
                        }
                    } else {
                        Text("暂无数据")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.subtitleColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .padding()
            .background(themeManager.secondaryBackgroundColor)
            .cornerRadius(12)
            
            Button(action: {
                showTimeAllocationAlert = false
            }) {
                Text("关闭")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(getTaskTypeColor(stat.type))
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(themeManager.backgroundColor)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }

    // 获取任务类型统计数据
    private func getTaskTypesStats() -> [TaskTypeStat] {
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
    
    // 获取时间状态对应的颜色
    private func getStatusColor(status: TimeStatus) -> Color {
        switch status {
        case .overTime:
            return Color.red
        case .normal:
            return Color.green
        case .underTime:
            return Color.orange
        }
    }
    
    // 获取任务类型图标
    private func getIconForTaskType(_ type: String) -> String {
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
    private func getTaskTypeColor(_ type: String) -> Color {
        switch type {
        case "会议": return Color.orange.opacity(0.7)  // 对应meeting
        case "思考": return Color.purple.opacity(0.7)  // 对应thinking
        case "工作": return Color.blue.opacity(0.7)    // 对应work
        case "阅读": return Color.yellow.opacity(0.7)  // 对应reading
        case "生活": return Color.pink.opacity(0.7)    // 对应life
        case "运动": return Color.green.opacity(0.7)   // 对应exercise
        case "摸鱼": return Color.cyan.opacity(0.7)    // 对应relax
        case "睡觉": return Color.indigo.opacity(0.7)  // 对应sleep
        default: return Color.blue.opacity(0.7)       // 默认颜色
        }
    }
    
    // 健康分数颜色
    private func healthScoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<70:
            return .orange
        case 70..<90:
            return .yellow
        default:
            return .green
        }
    }
    
    // 生成随机测试数据
    private func generateRandomTestData() {
        // 清除现有测试数据
        let existingTestTasks = appViewModel.tasks.filter { $0.isTestData }
        for task in existingTestTasks {
            appViewModel.deleteTask(task)
        }
        
        // 任务类型
        let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        
        // 时间周期
        let calendar = Calendar.current
        let now = Date()
        
        // 创建今天的测试数据
        for _ in 1...4 {
            let randomType = taskTypes.randomElement() ?? "工作"
            let randomDuration = Int.random(in: 15...120)
            let randomHoursAgo = Double.random(in: 1...10)
            let completedTime = calendar.date(byAdding: .hour, value: -Int(randomHoursAgo), to: now)!
            
            let task = Task(
                title: randomType,
                duration: randomDuration,
                isCompleted: true,
                completedAt: completedTime,
                isTestData: true
            )
            appViewModel.addTask(task)
        }
        
        // 创建本周的测试数据
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        for day in 1...6 {
            for _ in 1...3 {
                let randomType = taskTypes.randomElement() ?? "工作"
                let randomDuration = Int.random(in: 15...120)
                let dayDate = calendar.date(byAdding: .day, value: -day, to: now)!
                
                let task = Task(
                    title: randomType,
                    duration: randomDuration,
                    isCompleted: true,
                    completedAt: dayDate,
                    isTestData: true
                )
                appViewModel.addTask(task)
            }
        }
        
        // 创建本月的测试数据
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components)!
        for day in 7...20 {
            if let dayDate = calendar.date(byAdding: .day, value: -day, to: now),
               dayDate >= startOfMonth {
                for _ in 1...2 {
                    let randomType = taskTypes.randomElement() ?? "工作"
                    let randomDuration = Int.random(in: 15...120)
                    
                    let task = Task(
                        title: randomType,
                        duration: randomDuration,
                        isCompleted: true,
                        completedAt: dayDate,
                        isTestData: true
                    )
                    appViewModel.addTask(task)
                }
            }
        }
    }
    
    // 任务类型状态评分映射 - 用于计算健康度
    private func getTaskStatusScores() -> [TaskTypeStatus: Double] {
        return [
            .healthy: 1.0,
            .warning: 0.5,
            .critical: 0.0
        ]
    }
    
    // 获取任务类型状态颜色
    private func getStatusColor(_ status: TaskTypeStatus) -> Color {
        return status.color
    }
}
