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
        // 时间健康仪表盘卡片
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域 - 保留原有设计
            HStack {
                Text("时间分配")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                Text("\(totalTimeForSelectedRange)分钟")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme == .elegantPurple ? 
                                  Color(hex: "8A2BE2").opacity(0.9) : 
                                  Color(hex: "0C4A45").opacity(0.9))
                    )
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // 分隔线
            Rectangle()
                .fill(themeManager.colors.secondaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 14)
            
            // 时间分配内容 - 新的仪表盘风格
            let stats = getTaskTypesStats()
            
            if stats.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 16) {
                    // 健康度指标
                    let healthScore = calculateHealthScore(stats)
                    HStack {
                        Text("时间分配健康度：")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("\(healthScore)/100")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(healthScoreColor(healthScore))
                        
                        Text(healthScoreSymbol(healthScore))
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    
                    // 任务类型列表
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(stats, id: \.type) { stat in
                                timeAllocationRow(stat: stat)
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .frame(height: min(CGFloat(stats.count) * 42 + 20, 250))
                    
                    // 任务调整分析
                    taskAdjustmentAnalysisView(stats: stats)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 时间分配行视图
    private func timeAllocationRow(stat: TaskTypeStat) -> some View {
        let percentage = Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100
        let timeStandard = currentRoleStandard.getStandard(for: stat.type)
        let hoursSpent = Double(stat.minutes) / 60.0
        
        // 计算健康分数
        let healthScore = calculateHealthScore(for: [stat])
        
        // 获取时间状态
        let timeStatus = getTimeStatus(for: stat.type, actualPercentage: percentage)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧：任务类型图标
                Image(systemName: getIconForTaskType(stat.type))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.black)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                
                // 右侧：任务类型和时间信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.type)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                    
                    HStack(spacing: 3) {
                        Text("\(percentage, specifier: "%.1f")%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("(\(hoursSpent, specifier: "%.1f")小时)")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
            }
            
            // 健康分数和时间状态
            HStack(alignment: .center, spacing: 16) {
                Text("\(healthScore, specifier: "%.1f")%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(healthScoreColor(healthScore))
                
                Text(healthScoreSymbol(healthScore))
                    .font(.system(size: 14))
            }
            
            // 时间状态
            Text(timeStatus.localizedDescription)
                .font(.system(size: 12))
                .foregroundColor(getStatusColor(status: timeStatus))
        }
        .padding(.vertical, 8)
    }
    
    // 计算健康分数
    private func calculateHealthScore(for taskStats: [TaskTypeStat]) -> Double {
        guard !taskStats.isEmpty else { return 0 }
        
        var totalDeviation: Double = 0
        var totalWeight: Double = 0
        
        for stat in taskStats {
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
    private func getIdealPercentage(for taskType: TaskType) -> Double {
        switch taskType {
        case .work:
            return 35.0
        case .study:
            return 15.0
        case .rest:
            return 30.0
        case .social:
            return 10.0
        case .entertainment:
            return 7.0
        case .other:
            return 3.0
        }
    }
    
    // 判断任务时间状态
    private func getTimeStatus(for taskType: TaskType, actualPercentage: Double) -> TimeStatus {
        let idealPercentage = getIdealPercentage(for: taskType)
        let tolerance: Double
        
        // 根据不同任务类型设置不同容忍度
        switch taskType {
        case .work, .study:
            tolerance = 7.0
        case .rest:
            tolerance = 5.0
        case .social, .entertainment:
            tolerance = 3.0
        case .other:
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
    
    // 根据任务状态获取建议文本
    private func getSuggestionText(for taskType: TaskType, status: TimeStatus) -> String {
        switch (taskType, status) {
        case (.work, .overTime):
            return "工作时间过长，建议适当减少工作时间，增加休息。"
        case (.work, .underTime):
            return "工作时间不足，可能影响工作效率和进度。"
        case (.study, .overTime):
            return "学习时间过长，注意适当休息以保持学习效率。"
        case (.study, .underTime):
            return "学习时间较少，建议增加学习时间以提升知识和技能。"
        case (.rest, .overTime):
            return "休息时间充足，但可能占用了其他活动的时间。"
        case (.rest, .underTime):
            return "休息时间不足，容易导致疲劳和效率下降，建议增加休息。"
        case (.social, .overTime):
            return "社交时间较多，适当减少可以为其他活动腾出时间。"
        case (.social, .underTime):
            return "社交时间较少，适当增加社交活动有助于保持心理健康。"
        case (.entertainment, .overTime):
            return "娱乐时间较多，可能影响工作和学习，建议适当控制。"
        case (.entertainment, .underTime):
            return "娱乐时间较少，适当增加有助于放松心情，提高生活质量。"
        case (.other, .overTime):
            return "其他活动占用时间较多，考虑是否需要重新规划时间。"
        case (.other, .underTime):
            return "其他活动时间较少，符合预期。"
        case (_, .normal):
            return "时间分配合理，继续保持！"
        }
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
    private func getIconForTaskType(_ type: TaskType) -> String {
        switch type {
        case .work: return "briefcase.fill"
        case .study: return "book.fill"
        case .exercise: return "figure.run"
        case .entertainment: return "play.fill"
        case .social: return "person.2.fill"
        case .rest: return "bed.double.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    // 获取任务类型名称
    private func getTaskTypeName(_ type: TaskType) -> String {
        switch type {
        case .work: return "工作"
        case .study: return "学习"
        case .exercise: return "运动"
        case .entertainment: return "娱乐"
        case .social: return "社交"
        case .rest: return "休息"
        case .other: return "其他"
        }
    }
    
    // 获取任务类型颜色
    private func getTaskTypeColor(_ type: TaskType) -> Color {
        switch type {
        case .work: return Color(hex: "0066CC")
        case .study: return Color(hex: "6E75A8")
        case .exercise: return Color(hex: "FF9500")
        case .entertainment: return Color(hex: "FF2D55")
        case .social: return Color(hex: "5856D6")
        case .rest: return Color(hex: "34C759")
        case .other: return Color(hex: "8E8E93")
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

    // 健康分数对应的表情符号
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
}
