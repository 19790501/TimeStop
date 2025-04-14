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
        // 高级现代感时间分配卡片
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域 - 更精致的设计
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
            
            // 时间分配内容
            let stats = getTaskTypesStats()
            
            if stats.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 18) {
                        ForEach(stats, id: \.type) { stat in
                            modernTimeCell(stat: stat)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - 组件
    
    // 统计项目组件
    func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.colors.secondaryText)
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.colors.text)
        }
    }
    
    // 任务类型卡片
    func taskTypeCard(taskType: String) -> some View {
        let stats = getTaskTypesStats()
        guard let stat = stats.first(where: { $0.type == taskType }) else {
            return EmptyView().eraseToAnyView()
        }
        
        let percentage = Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100
        let hoursSpent = Double(stat.minutes) / 60.0 // 转换为小时
        
        // 根据角色标准评估时间分配
        let timeStandard = currentRoleStandard.getStandard(for: taskType)
        let deviationType: DeviationType = timeStandard?.isWithinStandard(hoursSpent) ?? .balanced
        let deviationPercentage = timeStandard?.deviationPercentage(hoursSpent) ?? 0
        
        return HStack(spacing: 0) {
            // 左侧：图标和任务类型
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    // 任务类型图标
                    Image(systemName: getIconForTaskType(taskType))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(getColorForTaskType(taskType))
                        )
                    
                    Text(taskType)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                }
                
                // 任务统计信息
                HStack(spacing: 12) {
                    Text("\(stat.count)次")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text("\(formatMinutes(stat.minutes))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.colors.text)
                }
                .padding(.leading, 4)
                .padding(.top, 2)
                
                // 角色基准参考
                if let standard = timeStandard {
                    HStack(spacing: 4) {
                        Text("基准:")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        Text("\(String(format: "%.1f", standard.lowerBound))-\(String(format: "%.1f", standard.upperBound))小时")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        // 优先级指示器
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { i in
                                Circle()
                                    .fill(i <= standard.priorityCoefficient ? 
                                          getRoleColor(selectedRole).opacity(0.8) : 
                                          Color.gray.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .padding(.leading, 2)
                    }
                    .padding(.leading, 4)
                    .padding(.top, 1)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            
            Spacer()
            
            // 右侧：时间百分比和建议
            VStack(alignment: .trailing, spacing: 6) {
                // 百分比
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(getColorForTaskType(taskType))
                
                // 基于角色标准的偏差指示
                if let _ = timeStandard {
                    HStack(spacing: 4) {
                        // 偏差指示器
                        Image(systemName: getDeviationIcon(deviationType))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(getDeviationColor(deviationType))
                        
                        // 偏差文本
                        Text(getDeviationText(deviationType, hours: hoursSpent, taskType: taskType))
                            .font(.system(size: 11))
                            .foregroundColor(getDeviationColor(deviationType))
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // 显示调整或终止频率（如果存在）
                if stat.adjustmentMinutes != 0 || stat.terminatedCount > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        if stat.adjustmentMinutes != 0 {
                            Text("调整: \(formatAdjustment(stat.adjustmentMinutes))")
                                .font(.system(size: 11))
                                .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                        }
                        
                        if stat.terminatedCount > 0 {
                            Text("终止: \(stat.terminatedCount)次")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            currentTaskType = taskType
            generateDetailedSuggestion(for: stat)
            showDetailedSuggestion = true
        }
        .eraseToAnyView()
    }
    
    // 获取偏差图标
    private func getDeviationIcon(_ deviationType: DeviationType) -> String {
        switch deviationType {
        case .excess:
            return "arrow.up.circle.fill"
        case .deficient:
            return "arrow.down.circle.fill"
        case .balanced:
            return "checkmark.circle.fill"
        }
    }
    
    // 获取偏差颜色
    private func getDeviationColor(_ deviationType: DeviationType) -> Color {
        switch deviationType {
        case .excess:
            return Color.red.opacity(0.8)
        case .deficient:
            return Color.orange.opacity(0.8)
        case .balanced:
            return Color.green.opacity(0.8)
        }
    }
    
    // 获取偏差文本
    private func getDeviationText(_ deviationType: DeviationType, hours: Double, taskType: String) -> String {
        guard let standard = currentRoleStandard.getStandard(for: taskType) else {
            return "无基准数据"
        }
        
        switch deviationType {
        case .excess:
            let difference = hours - standard.upperBound
            return "高出\(String(format: "%.1f", difference))小时"
        case .deficient:
            let difference = standard.lowerBound - hours
            return "低于\(String(format: "%.1f", difference))小时"
        case .balanced:
            return "在基准范围内"
        }
    }
    
    // 生成详细建议
    private func generateDetailedSuggestion(for stat: TaskTypeStat) {
        let taskType = stat.type
        let hours = Double(stat.minutes) / 60.0
        let timeStandard = currentRoleStandard.getStandard(for: taskType)
        let deviationType = timeStandard?.isWithinStandard(hours) ?? .balanced
        
        var title = ""
        var objectiveReasons: [String] = []
        var subjectiveReasons: [String] = []
        var suggestions: [String] = []
        
        // 生成客观和主观因素
        switch deviationType {
        case .excess:
            title = "⚠️ \(taskType)类任务时间过多"
            
            // 客观因素
            objectiveReasons = [
                "工作要求不得不增加这类任务时长",
                "外部环境限制导致效率降低",
                "任务未分解导致连续处理时间延长"
            ]
            
            // 主观因素
            subjectiveReasons = [
                "专注度不足导致任务时长被拉长",
                "完美主义倾向花费过多时间在细节上",
                "缺乏明确目标导致任务无法及时结束"
            ]
            
            // 建议
            suggestions = [
                "设定明确时间限制，使用番茄工作法",
                "将任务分解为更小的步骤以提高完成感",
                "识别并减少低效行为模式",
                "优先处理高优先级项目，调低\(taskType)任务的频率"
            ]
            
        case .deficient:
            title = "⚠️ \(taskType)类任务时间不足"
            
            // 客观因素
            objectiveReasons = [
                "其他高优先级任务压缩了此类任务时间",
                "环境干扰导致无法集中足够时间",
                "缺乏必要的外部支持资源"
            ]
            
            // 主观因素
            subjectiveReasons = [
                "对此类任务兴趣不足",
                "技能不足导致回避此类任务",
                "未意识到此类任务的重要性"
            ]
            
            // 建议
            suggestions = [
                "在日程中为\(taskType)类任务预留专门时段",
                "尝试新的\(taskType)方式提高兴趣",
                "提升相关技能以增强信心",
                "寻找或创造更适合进行此类活动的环境"
            ]
            
        case .balanced:
            title = "✓ \(taskType)类任务时间合理"
            
            // 客观因素
            objectiveReasons = [
                "当前任务量与时间分配平衡",
                "环境支持有效完成此类任务",
                "任务安排合理，无冲突"
            ]
            
            // 主观因素
            subjectiveReasons = [
                "对此类任务有合理的兴趣与重视",
                "具备完成此类任务的必要技能",
                "时间管理策略有效"
            ]
            
            // 建议
            suggestions = [
                "保持当前的时间分配模式",
                "关注此类任务的质量提升",
                "探索更高效的方法进一步优化",
                "将成功经验应用到其他类型任务中"
            ]
        }
        
        // 根据终止频率和调整频率添加更多建议
        if stat.terminatedCount > 0 {
            let terminationRate = Double(stat.terminatedCount) / Double(stat.count) * 100
            
            if terminationRate > 30 {
                title = "⚠️ \(taskType)类任务频繁终止"
                objectiveReasons.append("外部干扰导致任务无法完成")
                subjectiveReasons.append("任务难度超出预期导致放弃")
                suggestions.append("降低此类任务的单次时长，增加频次")
                suggestions.append("尝试减少环境干扰，创造更专注的环境")
            }
        }
        
        if stat.adjustmentMinutes != 0 {
            let adjustmentPercentage = Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100
            
            if adjustmentPercentage > 20 {
                if stat.adjustmentMinutes > 0 {
                    title += " (频繁延长)"
                    objectiveReasons.append("任务复杂度被低估")
                    subjectiveReasons.append("时间估计能力需要提升")
                    suggestions.append("提前分解任务，预留缓冲时间")
                } else {
                    title += " (频繁缩短)"
                    objectiveReasons.append("任务复杂度被高估")
                    subjectiveReasons.append("任务中断或注意力不足")
                    suggestions.append("设置更精确的时间预期")
                }
            }
        }
        
        // 更新建议元组
        detailedSuggestion = (title, objectiveReasons, subjectiveReasons, suggestions)
    }
    
    // 时间分配警报视图
    private func timeAllocationAlertView(for stat: TaskTypeStat) -> some View {
        let totalTime = totalTimeForSelectedRange
        let percentage = totalTime > 0 ? Double(stat.minutes) / Double(totalTime) * 100 : 0
        
        // 根据任务类型的不同时间阈值
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
        
        let isOverAllocated = percentage > upperThreshold
        let isUnderAllocated = percentage < lowerThreshold && stat.minutes > 0
        
        if isOverAllocated || isUnderAllocated {
            return AnyView(
                HStack {
                    Label(
                        title: { 
                            Text(isOverAllocated 
                                 ? "\(stat.type)时间占比较高(\(String(format: "%.1f", percentage))%)，建议适当控制" 
                                 : "\(stat.type)时间占比较低(\(String(format: "%.1f", percentage))%)，建议适当增加")
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.secondaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        },
                        icon: { 
                            Image(systemName: isOverAllocated ? "chart.bar.fill" : "chart.bar")
                                .font(.system(size: 12))
                                .foregroundColor(isOverAllocated ? .orange : .blue)
                        }
                    )
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - 数据处理
    
    // 任务类型统计结构
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
    
    // MARK: - 辅助函数
    
    // 格式化分钟为易读时间
    func formatMinutes(_ minutes: Int) -> String {
        return "\(minutes)分钟"
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
    func formatPercentage(_ adjustment: Int, original: Int) -> String {
        if original == 0 { return "N/A" }
        let percentage = (Double(adjustment) / Double(original)) * 100
        return String(format: "%.1f%%", percentage)
    }
    
    // 获取饼图起始角度
    func getStartAngle(for index: Int) -> Double {
        let stats = getTaskTypesStats()
        var angle: Double = 0
        
        for i in 0..<index {
            let percentage = Double(stats[i].minutes) / Double(totalTimeForSelectedRange)
            angle += percentage * 360
        }
        
        return angle
    }
    
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
    
    // 获取任务类型建议
    func getSuggestionForTaskType(stat: TaskTypeStat) -> String {
        let adjustPercentage = Double(stat.adjustmentMinutes) / Double(stat.originalMinutes) * 100
        
        switch stat.type {
        case "会议":
            if stat.minutes > 180 && selectedRange == .today {
                return "📊 今日会议时间较长，考虑控制会议效率"
            } else if stat.count > 5 && selectedRange == .today {
                return "📊 今日会议次数较多，考虑合并部分会议"
            }
            return "会议时间分配合理"
            
        case "工作":
            if stat.minutes > 360 && selectedRange == .today {
                return "⚠️ 今日工作时间较长，注意休息与工作平衡"
            } else if stat.minutes < 120 && selectedRange == .today && stat.count > 0 {
                return "⏱ 今日工作时间较少，考虑提高工作专注度"
            }
            return "工作时间分配合理"
            
        case "摸鱼":
            if stat.minutes > (selectedRange == .today ? 120 : 500) {
                return "⚠️ 休闲时间较多，考虑调整时间分配"
            }
            return "适度休闲有助于恢复精力"
            
        case "运动":
            if stat.minutes < (selectedRange == .week ? 150 : 30) && stat.count > 0 {
                return "⏱ 运动时间不足，建议增加运动频率"
            }
            return "坚持运动有助于身心健康"
            
        case "睡觉":
            if stat.minutes < 420 && selectedRange == .today && stat.count > 0 {
                return "⚠️ 今日睡眠时间不足，可能影响工作效率和健康"
            } else if stat.minutes > 540 && selectedRange == .today {
                return "📊 今日睡眠时间较长，可能与睡眠质量有关"
            }
            return "保持良好睡眠习惯"
            
        case "阅读":
            if stat.minutes < 30 && selectedRange == .today && stat.count > 0 {
                return "⏱ 今日阅读时间较少，建议培养阅读习惯"
            }
            return "坚持阅读有助于拓展知识"
            
        case "思考":
            if adjustPercentage > 40 {
                return "⏱ 思考时间常超出预期，可尝试结构化思考方法"
            }
            return "深度思考助力决策质量"
            
        case "生活":
            if stat.minutes < 60 && selectedRange == .today && stat.count > 0 {
                return "⚠️ 今日生活时间较少，注意工作与生活平衡"
            }
            return "平衡生活与工作"
            
        default:
            return "查看详细分析与建议"
        }
    }
    
    // 生成随机测试数据
    func generateRandomTestData() {
        // 清除之前的测试数据
        appViewModel.tasks.removeAll { task in
            task.createdAt > Date().addingTimeInterval(-30 * 24 * 60 * 60) && 
            task.note == "测试数据"
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 日期范围
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // 任务类型及其基本配置
        let taskConfigs: [(title: String, minDuration: Int, maxDuration: Int, todayCount: Int, weekCount: Int, monthCount: Int, adjustFrequency: Double, terminateFrequency: Double)] = [
            // 标题, 最短时长, 最长时长, 今日数量, 本周数量, 本月数量, 调整频率, 终止频率
            ("睡觉", 360, 540, 1, 7, 30, 0.1, 0.05),
            ("工作", 180, 540, 1, 5, 22, 0.3, 0.1),
            ("会议", 30, 120, 1, 3, 12, 0.4, 0.2),
            ("思考", 20, 90, 1, 4, 15, 0.2, 0.1),
            ("摸鱼", 15, 60, 2, 10, 40, 0.1, 0.05),
            ("运动", 15, 60, 1, 3, 12, 0.1, 0.05),
            ("阅读", 20, 90, 1, 4, 16, 0.2, 0.1),
            ("生活", 30, 180, 2, 10, 40, 0.1, 0.05)
        ]
        
        // 基于当前选择的角色调整任务时长和数量
        for (index, config) in taskConfigs.enumerated() {
            let taskType = config.title
            var minDuration = config.minDuration
            var maxDuration = config.maxDuration
            var todayCount = config.todayCount
            var weekCount = config.weekCount
            
            // 根据选定角色调整测试数据
            if let standard = currentRoleStandard.getStandard(for: taskType) {
                // 调整数据以反映当前角色标准
                let lowerBound = Int(standard.lowerBound * 60) // 转换为分钟
                let upperBound = Int(standard.upperBound * 60) // 转换为分钟
                
                // 随机决定是否让数据偏离基准范围(50%概率)
                let shouldDeviate = Bool.random()
                
                if shouldDeviate {
                    // 随机决定是高于还是低于基准范围(50/50概率)
                    let isHigher = Bool.random()
                    
                    if isHigher {
                        // 高于基准范围10-30%
                        let deviationFactor = Double.random(in: 1.1...1.3)
                        minDuration = max(lowerBound, Int(Double(upperBound) * deviationFactor))
                        maxDuration = Int(Double(upperBound) * deviationFactor * 1.2)
                    } else {
                        // 低于基准范围10-30%
                        let deviationFactor = Double.random(in: 0.7...0.9)
                        maxDuration = min(lowerBound, Int(Double(lowerBound) * deviationFactor))
                        minDuration = Int(Double(lowerBound) * deviationFactor * 0.8)
                    }
                } else {
                    // 在基准范围内
                    minDuration = lowerBound
                    maxDuration = upperBound
                }
                
                // 确保最小值不小于10分钟
                minDuration = max(10, minDuration)
            }
            
            // 生成今日任务
            for _ in 0..<todayCount {
                createRandomTask(taskType: taskType, 
                                minDuration: minDuration, 
                                maxDuration: maxDuration,
                                startDate: todayStart, 
                                endDate: now,
                                adjustFrequency: config.adjustFrequency,
                                terminateFrequency: config.terminateFrequency)
            }
            
            // 生成本周任务(除去今日)
            let additionalWeekTasks = max(0, weekCount - todayCount)
            for _ in 0..<additionalWeekTasks {
                createRandomTask(taskType: taskType, 
                                minDuration: minDuration, 
                                maxDuration: maxDuration,
                                startDate: weekStart, 
                                endDate: todayStart.addingTimeInterval(-1),
                                adjustFrequency: config.adjustFrequency,
                                terminateFrequency: config.terminateFrequency)
            }
            
            // 生成本月任务(除去本周)
            let additionalMonthTasks = max(0, config.monthCount - weekCount)
            for _ in 0..<additionalMonthTasks {
                createRandomTask(taskType: taskType, 
                                minDuration: minDuration, 
                                maxDuration: maxDuration,
                                startDate: monthStart, 
                                endDate: weekStart.addingTimeInterval(-1),
                                adjustFrequency: config.adjustFrequency,
                                terminateFrequency: config.terminateFrequency)
            }
        }
    }
    
    // 辅助方法：创建单个随机任务
    private func createRandomTask(taskType: String, minDuration: Int, maxDuration: Int, startDate: Date, endDate: Date, adjustFrequency: Double, terminateFrequency: Double) {
        let duration = Int.random(in: minDuration...maxDuration)
        let randomTimeOffset = Double.random(in: 0...(endDate.timeIntervalSince(startDate)))
        let completedAt = startDate.addingTimeInterval(randomTimeOffset)
        
        var task = Task(
            id: UUID().uuidString,
            title: taskType,
            focusType: .general,
            duration: duration,
            createdAt: completedAt.addingTimeInterval(-Double(duration) * 60),
            completedAt: completedAt,
            note: "测试数据",
            verificationMethod: nil,
            timeAdjustments: [],
            isTerminated: false
        )
        
        // 添加随机调整
        if Double.random(in: 0...1) < adjustFrequency {
            let adjustmentAmount = Int.random(in: -duration/3...duration/2)
            if adjustmentAmount != 0 {
                task.timeAdjustments.append(adjustmentAmount)
                task.duration += adjustmentAmount
            }
        }
        
        // 随机终止任务
        if Double.random(in: 0...1) < terminateFrequency {
            task.isTerminated = true
            let reductionAmount = -Int.random(in: 5...min(30, task.duration / 2))
            task.timeAdjustments.append(reductionAmount)
            task.duration += reductionAmount
        }
        
        appViewModel.tasks.append(task)
    }
    
    // 获取所选时间范围内的唯一任务类型
    func getUniqueTaskTypes() -> [String] {
        // 只包含预定义的8种任务类型
        let allTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        
        // 过滤出当前范围内实际存在的任务类型
        let existingTypes = Array(Set(tasksForSelectedRange.map { task in task.title }))
        
        // 确保只返回有效的8种类型中的任务
        return existingTypes.filter { type in allTypes.contains(type) }
    }
    
    // 获取特定类型任务的次数
    func getTaskCountByType(_ type: String) -> Int {
        return tasksForSelectedRange.filter { task in task.title == type }.count
    }
    
    // 格式化时间占比为百分比字符串
    func formatTimePercentage(_ minutes: Int, total: Int) -> String {
        if total == 0 { return "0%" }
        let percentage = Double(minutes) / Double(total) * 100
        return String(format: "%.1f%%", percentage)
    }
    
    // 添加现代感十足的时间单元格组件
    private func modernTimeCell(stat: TaskTypeStat) -> some View {
        VStack(spacing: 6) {
            // 图标容器 - 现代设计风格
            ZStack {
                // 黑色背景圆形 - 更现代的阴影设计
                Circle()
                    .fill(Color.black)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                
                // 图标
                Image(systemName: getIconForTaskType(stat.type))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // 任务类型名称 - 精致设计
            Text(stat.type)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeManager.colors.text)
                .lineLimit(1)
            
            // 时间值 - 更高对比度的设计
            Text("\(stat.minutes)分钟")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(themeManager.colors.secondaryText)
                
            // 百分比显示 - 增加视觉层次感
            let percentage = Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(
                    themeManager.currentTheme == .elegantPurple ? 
                    Color(hex: "8A2BE2") : Color(hex: "0C4A45")
                )
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(
                    Capsule()
                        .fill((themeManager.currentTheme == .elegantPurple ? 
                              Color(hex: "8A2BE2") : Color(hex: "0C4A45"))
                              .opacity(0.1))
                )
        }
        .padding(.vertical, 6)
    }
    
    // 获取详细建议
    func getDetailedSuggestion(for taskType: String) -> (title: String, objectiveReasons: [String], subjectiveReasons: [String], suggestions: [String]) {
        switch taskType {
        case "会议":
            return (
                title: "会议时间管理指南",
                objectiveReasons: [
                    "会议时间过少：议题无法充分讨论，决策仓促",
                    "会议时间过多：注意力分散，效率降低",
                    "会议规模不合理，议题设置不当",
                    "参与人员过多或关键人缺席",
                    "会议环境干扰因素多"
                ],
                subjectiveReasons: [
                    "您在会议中的角色表现是否影响效率？",
                    "您是否有参与不足或过度发言的情况？",
                    "您是否存在注意力不集中或准备不充分问题？",
                    "您对会议的期望是否与实际会议目的一致？",
                    "您的会议决策流程是否高效？"
                ],
                suggestions: [
                    "时间过少建议：提前分发材料减少讨论时间，设置议题优先级",
                    "时间过多建议：设定严格时间限制，非核心议题移至其他渠道",
                    "评估议题复杂度合理安排时间，考虑使用会前材料",
                    "减少非必要参会人员，明确每位参与者的角色",
                    "采用结构化会议流程，确保关键决策有足够讨论时间",
                    "定期评估会议效果，持续改进会议流程"
                ]
            )
            
        case "思考":
            return (
                title: "思考效率提升方法",
                objectiveReasons: [
                    "思考时间过少：分析肤浅，无法深入理解复杂问题",
                    "思考时间过多：陷入分析瘫痪，决策延迟",
                    "问题复杂度与思考时间不匹配",
                    "缺少安静的思考环境与不受打扰的时间",
                    "信息获取不完整或信息过载"
                ],
                subjectiveReasons: [
                    "您是否容易陷入过度分析而难以做决定？",
                    "您在思考时是否有决策焦虑？",
                    "您的思维方式是否灵活多元？",
                    "您如何评价自己的专注能力和思考习惯？",
                    "您是否对思考过程有过高期望而导致压力？"
                ],
                suggestions: [
                    "时间过少建议：为重要思考预留整块时间，确保深度分析",
                    "时间过多建议：设定思考截止线，接受足够好的方案而非完美解决方案",
                    "使用思维导图进行结构化思考，厘清复杂问题",
                    "应用六顶思考帽等多角度思考方法打破思维固化",
                    "记录思考过程便于回顾，避免重复思考",
                    "创造专注思考的环境，减少外部干扰"
                ]
            )
            
        case "工作":
            return (
                title: "工作效率提升指南",
                objectiveReasons: [
                    "工作时间过少：任务质量下降，无法按期完成",
                    "工作时间过多：其他任务被挤压，工作效率降低",
                    "工作量评估不准确，任务复杂度被低估",
                    "工作环境干扰多，中断频繁",
                    "任务优先级不明确，资源分配不当"
                ],
                subjectiveReasons: [
                    "您的工作专注度如何？是否容易分心？",
                    "您是否存在拖延行为或完美主义倾向？",
                    "您对完成工作的质量标准是否合理？",
                    "您的时间管理意识是否足够？",
                    "您是否在高效时段安排重要工作？"
                ],
                suggestions: [
                    "时间过少建议：学习时间预估技巧，拆分大任务为小步骤",
                    "时间过多建议：设定任务时间上限，应用帕金森定律",
                    "应用番茄工作法提高专注度，减少工作中断",
                    "创建不受打扰的深度工作环境和时段",
                    "使用任务分解和时间评估工具提高规划准确性",
                    "定期回顾工作流程，识别并消除效率瓶颈"
                ]
            )
            
        case "阅读":
            return (
                title: "高效阅读方法",
                objectiveReasons: [
                    "阅读时间过少：理解浅显，难以掌握复杂内容",
                    "阅读时间过多：信息消化不良，输出和应用不足",
                    "阅读材料难度与阅读能力不匹配",
                    "阅读环境存在干扰，影响专注度",
                    "阅读目标和方法选择不当"
                ],
                subjectiveReasons: [
                    "您的阅读专注力如何？是否能长时间保持？",
                    "您阅读时的目的是否明确？",
                    "您阅读材料的选择标准是什么？",
                    "您阅读时是否主动思考和质疑？",
                    "您的阅读速度与理解能力是否平衡？"
                ],
                suggestions: [
                    "时间过少建议：掌握速读技巧，设定小目标增强动力",
                    "时间过多建议：实践读书笔记法，定期应用所读内容",
                    "使用\"SQ3R\"阅读法（浏览-提问-阅读-复述-回顾）提高效率",
                    "创建专注阅读环境，减少外部干扰",
                    "尝试多元化阅读形式（有声书、电子书）适应不同场景",
                    "建立阅读-思考-应用的闭环，提升阅读价值"
                ]
            )
            
        case "生活":
            return (
                title: "生活与工作平衡指南",
                objectiveReasons: [
                    "生活时间过少：影响身心健康和工作长期表现",
                    "生活时间过多：可能影响职业发展和目标达成",
                    "工作与生活物理空间界限模糊",
                    "社会压力和文化期望影响决策",
                    "缺少支持系统和资源"
                ],
                subjectiveReasons: [
                    "您是否难以在下班后断开工作思维？",
                    "您对个人生活和休闲的重视程度如何？",
                    "您是否为自己设立了清晰的生活界限？",
                    "您如何看待生活质量与职业成功的关系？",
                    "您在生活决策中是否感到内疚或冲突？"
                ],
                suggestions: [
                    "时间过少建议：建立生活时间预算，设置不可侵占的生活时间",
                    "时间过多建议：设定合理生活时间上限，确保关键工作不受影响",
                    "建立工作与生活的明确物理和心理边界",
                    "预留不受打扰的家庭和个人时间",
                    "学会委派和寻求帮助，减轻负担",
                    "定期评估生活满意度，进行必要调整"
                ]
            )
            
        case "运动":
            return (
                title: "高效运动指南",
                objectiveReasons: [
                    "运动时间过少：健康效益无法达成，形式大于实质",
                    "运动时间过多：占用工作生活时间，可能导致过度疲劳",
                    "生活环境不便于运动，场所和设施受限",
                    "时间安排不合理，难以坚持",
                    "缺乏合适的运动计划和指导"
                ],
                subjectiveReasons: [
                    "您对运动的内在动机是什么？",
                    "您是否依赖情绪决定是否运动？",
                    "您对运动强度的把握准确吗？",
                    "您的运动类型选择是基于兴趣还是随大流？",
                    "您运动习惯的持续性如何？"
                ],
                suggestions: [
                    "时间过少建议：寻找高效率运动如HIIT，融入日常生活",
                    "时间过多建议：设定合理运动时长，关注质量而非数量",
                    "融入日常生活的运动方式（步行通勤、站立办公）",
                    "固定运动时间，建立习惯，减少决策消耗",
                    "加入运动社群，增加外部约束和动力",
                    "选择真正感兴趣的运动项目，提高长期坚持可能性"
                ]
            )
            
        case "摸鱼":
            return (
                title: "休闲与恢复平衡指南",
                objectiveReasons: [
                    "休息时间过少：疲劳积累，影响长期工作效率",
                    "休息时间过多：工作节奏被打断，进入状态困难",
                    "工作压力和期限紧迫，难以真正放松",
                    "环境干扰和打断，休息质量低",
                    "缺乏恢复性休息的场所和条件"
                ],
                subjectiveReasons: [
                    "您在休息时是否仍感到焦虑或负罪感？",
                    "您选择的休息方式是否真正有助于恢复？",
                    "您能否区分有效休息和无效消遣？",
                    "您休息后的恢复感和能量水平如何？",
                    "您对休息价值的认识是否充分？"
                ],
                suggestions: [
                    "时间过少建议：安排规律小休息，实践5-1工作法",
                    "时间过多建议：设定休息时间上限，使用计时器控制",
                    "区分恢复性休息与无效消遣，提高休息质量",
                    "建立\"工作-休息-工作\"循环模式，形成良性节奏",
                    "设计适合自己的休息仪式，提高休息效果",
                    "尝试正念休息，增强短时间休息的恢复效果"
                ]
            )
            
        case "睡觉":
            return (
                title: "睡眠质量提升指南",
                objectiveReasons: [
                    "睡眠时间过少：认知功能下降，健康风险增加",
                    "睡眠时间过多：日间精力不足，时间利用率降低",
                    "睡眠环境存在光线、噪音等干扰因素",
                    "生活作息不规律，生物钟紊乱",
                    "工作压力导致难以入睡或保持睡眠"
                ],
                subjectiveReasons: [
                    "您是否在睡前使用电子设备？",
                    "您入睡和起床是否困难？",
                    "您是否存在睡眠焦虑或过度关注睡眠？",
                    "您对自己的睡眠状况感知准确吗？",
                    "您的睡眠习惯是否支持高质量睡眠？"
                ],
                suggestions: [
                    "时间过少建议：优先保障基本睡眠（7-8小时），建立睡前仪式",
                    "时间过多建议：渐进调整睡眠时间，监测最佳睡眠长度",
                    "保持规律的睡眠时间表，包括周末",
                    "睡前1小时避免电子设备，减少蓝光暴露",
                    "创造舒适安静的睡眠环境，控制温度和光线",
                    "睡前进行放松活动，如阅读纸质书或冥想"
                ]
            )
            
        default:
            return (
                title: "时间管理通用指南",
                objectiveReasons: [
                    "时间分配不均衡：某些活动过少或过多",
                    "计划执行一致性低，频繁调整",
                    "任务优先级设置不清晰",
                    "环境干扰因素多，影响效率",
                    "时间估计不准确，规划与现实脱节"
                ],
                subjectiveReasons: [
                    "您的时间管理习惯和意识如何？",
                    "您在安排时间时考虑的关键因素是什么？",
                    "您如何评价自己的规划能力和执行力？",
                    "您对时间投入与回报的看法是什么？",
                    "您如何处理计划变更和突发事件？"
                ],
                suggestions: [
                    "平衡各类活动时间，避免某一领域过度或不足",
                    "使用时间追踪工具提高自我时间意识",
                    "应用时间矩阵区分任务优先级",
                    "为任务设定明确的开始和结束时间",
                    "减少多任务处理，增加深度工作时间段",
                    "定期回顾时间使用情况，持续优化"
                ]
            )
        }
    }
    
    // 周报月报入口按钮
    private var summaryReportButton: some View {
        Button(action: {
            if selectedRange == .week {
                showWeeklySummary = true
            } else if selectedRange == .month {
                showMonthlySummary = true
            }
        }) {
            HStack {
                // 左侧图标
                Image(systemName: selectedRange == .week ? "chart.line.uptrend.xyaxis" : "chart.bar.doc.horizontal")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    
                // 中间文本
                Text(selectedRange == .week ? "查看周总结分析" : "查看月度时间报告")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                ZStack(alignment: .bottom) {
                    // 主背景
                    RoundedRectangle(cornerRadius: 14)
                        .fill(themeManager.currentTheme == .elegantPurple ? 
                              Color(hex: "8A2BE2") : 
                              Color(hex: "0C4A45"))
                    
                    // 底部渐变装饰
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.15)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 24)
                }
            )
            .shadow(color: (themeManager.currentTheme == .elegantPurple ? 
                           Color(hex: "8A2BE2") : 
                           Color(hex: "0C4A45")).opacity(0.3),
                    radius: 5, x: 0, y: 3)
        }
    }
    
    // 获取任务类型列表
    func getTaskTypes() -> [String] {
        let stats = getTaskTypesStats()
        return stats.map { stat in stat.type }
    }
    
    // 日期范围选择器（也做任务类型过滤器）
    private var dateRangeSelector: some View {
        VStack(spacing: 8) {
            // 移除日期文本显示器
            
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
        }
    }
    
    // 生成完整的分析报告
    private func generateAnalysisReport() {
        let stats = getTaskTypesStats()
        let totalHours = Double(totalTimeForSelectedRange) / 60.0
        
        // 分析各时间类型的偏差
        var excessiveTypes: [String] = []
        var deficientTypes: [String] = []
        var balancedTypes: [String] = []
        
        for stat in stats {
            let hours = Double(stat.minutes) / 60.0
            if let standard = currentRoleStandard.getStandard(for: stat.type) {
                let deviationType = standard.isWithinStandard(hours)
                
                switch deviationType {
                case .excess:
                    excessiveTypes.append(stat.type)
                case .deficient:
                    deficientTypes.append(stat.type)
                case .balanced:
                    balancedTypes.append(stat.type)
                }
            }
        }
        
        // 生成标题
        var title = "「\(selectedRole)」角色时间分配分析"
        
        // 生成分析内容
        var objectiveReasons: [String] = []
        var subjectiveReasons: [String] = []
        var suggestions: [String] = []
        
        // 分析超时的任务类型
        if !excessiveTypes.isEmpty {
            let typesText = excessiveTypes.joined(separator: "、")
            objectiveReasons.append("您在\(typesText)等活动上花费了超出基准的时间")
            
            // 根据角色和任务类型生成具体原因
            if excessiveTypes.contains("会议") && selectedRole == "高管" {
                subjectiveReasons.append("作为高管，可能过度依赖会议进行决策和沟通")
                suggestions.append("考虑将部分会议转为简短的书面沟通或一对一对话")
            }
            
            if excessiveTypes.contains("工作") && selectedRole == "创业者" {
                objectiveReasons.append("创业阶段通常需要投入大量时间到工作中")
                subjectiveReasons.append("可能缺乏有效的任务委派或团队协作")
                suggestions.append("尝试识别20%能产生80%结果的核心任务，优先处理这些任务")
            }
            
            if excessiveTypes.contains("摸鱼") {
                subjectiveReasons.append("对当前任务可能存在动力不足或倦怠情绪")
                suggestions.append("使用番茄工作法，在集中工作后给予自己短暂的休息奖励")
            }
        }
        
        // 分析不足的任务类型
        if !deficientTypes.isEmpty {
            let typesText = deficientTypes.joined(separator: "、")
            objectiveReasons.append("您在\(typesText)等活动上投入的时间少于建议基准")
            
            // 根据角色和任务类型生成具体原因
            if deficientTypes.contains("思考") && (selectedRole == "创业者" || selectedRole == "高管") {
                subjectiveReasons.append("忙于执行任务，可能忽略了战略思考的重要性")
                suggestions.append("在日程表中设置固定的\"思考时间\"，关闭通知，专注于思考问题")
            }
            
            if deficientTypes.contains("运动") {
                objectiveReasons.append("工作压力大导致挤占了运动时间")
                subjectiveReasons.append("可能将运动视为可选活动而非必要活动")
                suggestions.append("将运动安排在精力最佳的时段，如清晨，并视为不可协商的日程")
            }
            
            if deficientTypes.contains("阅读") && selectedRole == "高管" {
                subjectiveReasons.append("执行任务太多，忽略了持续学习的重要性")
                suggestions.append("尝试利用碎片时间进行有效阅读，如通勤途中听有声书")
            }
        }
        
        // 分析频繁调整和终止的任务
        let frequentlyAdjustedTasks = stats.filter { stat in
            let adjustmentPercentage = Double(abs(stat.adjustmentMinutes)) / Double(stat.originalMinutes) * 100
            return adjustmentPercentage > 20
        }
        
        let frequentlyTerminatedTasks = stats.filter { stat in
            stat.terminatedCount > 0 && (Double(stat.terminatedCount) / Double(stat.count) * 100 > 30)
        }
        
        if !frequentlyAdjustedTasks.isEmpty {
            let taskTypes = frequentlyAdjustedTasks.map { task in task.type }.joined(separator: "、")
            objectiveReasons.append("\(taskTypes)等活动时长经常需要调整，说明时间规划与实际情况存在差异")
            subjectiveReasons.append("时间估计能力有提升空间，对任务复杂度的判断可能不够准确")
            suggestions.append("任务开始前进行更细致的分解，为每个子任务设定更精确的时间预期")
        }
        
        if !frequentlyTerminatedTasks.isEmpty {
            let taskTypes = frequentlyTerminatedTasks.map { task in task.type }.joined(separator: "、")
            objectiveReasons.append("\(taskTypes)等活动经常被中途终止，可能受到外部干扰或优先级变化")
            subjectiveReasons.append("专注度或持久性可能需要提升，难以长时间维持在同一任务上")
            suggestions.append("使用\"不受干扰\"模式工作，设置较短的工作时段（25-45分钟），减少中断概率")
        }
        
        // 添加更多通用建议
        if balancedTypes.count >= stats.count / 2 {
            suggestions.append("您已经在大部分活动上达到了较好的时间平衡，可以关注如何提升每种活动的质量和效率")
        } else {
            suggestions.append("尝试根据\(selectedRole)角色的基准标准，逐步调整您的时间分配模式")
        }
        
        // 根据角色添加特定建议
        switch selectedRole {
        case "创业者":
            suggestions.append("创建一个\"每日必做清单\"，确保高优先级的工作和思考任务得到处理")
            suggestions.append("尝试早起工作，利用清晨的高效时段处理需要创造性思考的任务")
        case "高管":
            suggestions.append("使用\"会议批处理\"策略，将会议集中在特定时段，留出连续的深度工作时间")
            suggestions.append("定期回顾时间分配，确保战略思考和团队发展获得足够关注")
        case "白领":
            suggestions.append("利用工作效率高的时段处理最复杂的任务，将例行公事放在效率较低的时段")
            suggestions.append("建立健康的工作-生活边界，避免工作时间过度延伸影响生活质量")
        default:
            break
        }
        
        // 如果建议太少，添加一些通用建议
        if suggestions.count < 3 {
            suggestions.append("每周审视时间分配情况，识别可以优化的方面")
            suggestions.append("尝试新的时间管理方法，如番茄工作法或时间块技术")
        }
        
        // 更新建议元组
        detailedSuggestion = (title, objectiveReasons, subjectiveReasons, suggestions)
        currentTaskType = selectedRole
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
