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

// 角色类型枚举
enum RoleType: String, CaseIterable, Identifiable {
    case entrepreneur = "创业者"
    case executive = "高管"
    case employee = "白领"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .entrepreneur: return "追求高效率与创新的创业人士"
        case .executive: return "平衡战略思考与执行的管理者"
        case .employee: return "注重工作与生活平衡的职场人士"
        }
    }
    
    var icon: String {
        switch self {
        case .entrepreneur: return "flame.fill"
        case .executive: return "crown.fill"
        case .employee: return "briefcase.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .entrepreneur: return .orange
        case .executive: return .purple
        case .employee: return .blue
        }
    }
}

// 时间标准结构
struct TimeStandard {
    let lowerBound: Double // 小时
    let upperBound: Double // 小时
    let priorityCoefficient: Int // 1-5优先级系数
    
    // 转换为分钟
    var lowerBoundMinutes: Int { Int(lowerBound * 60) }
    var upperBoundMinutes: Int { Int(upperBound * 60) }
}

// 确保可以访问ThemeManager中定义的AppColors
struct TimeWhereView: View {
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
    @State private var selectedRole: RoleType = .employee // 默认选择白领角色
    @State private var showTaskDetail: Bool = false
    @State private var selectedTaskType: String?
    @State private var showAlert: Bool = false
    @State private var showDetailedSuggestion = false
    @State private var currentTaskType = ""
    @State private var detailedSuggestion = (title: "", clientiveReasons: [String](), subjectiveReasons: [String](), suggestions: [String]())
    @State private var showWeeklySummary: Bool = false
    @State private var showMonthlySummary: Bool = false
    @State private var showRoleAnalysis: Bool = false // 新增：显示角色分析
    
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
            ("阅读", "思考", "阅读后思考更有深度"),
            ("休息", "会议", "短暂休息后会议专注度提高")
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
                let minutes = tasksOfThisType.reduce(0) { $0 + $1.duration }
                let originalMinutes = tasksOfThisType.reduce(0) { $0 + $1.originalDuration() }
                let adjustmentMinutes = minutes - originalMinutes
                
                // 统计终止的任务
                let terminatedTasks = tasksOfThisType.filter { $0.isTerminated }
                let terminatedCount = terminatedTasks.count
                let reducedMinutes = terminatedTasks.reduce(0) { $0 + abs($1.timeAdjustments.filter { $0 < 0 }.reduce(0, +)) }
                
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
                    .padding(.bottom, 4)
                
                roleSelector
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
    
    // 角色选择器
    private var roleSelector: some View {
        VStack(spacing: 6) {
            HStack {
                Text("选择角色视角")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                // 添加角色分析报告按钮
                Button(action: {
                    if !tasksForSelectedRange.isEmpty {
                        showRoleAnalysis = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 12))
                        Text("角色分析")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(tasksForSelectedRange.isEmpty ? themeManager.colors.secondaryText.opacity(0.5) : themeManager.colors.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(tasksForSelectedRange.isEmpty ? 
                                  themeManager.colors.secondaryBackground.opacity(0.5) : 
                                  themeManager.colors.secondaryBackground)
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        tasksForSelectedRange.isEmpty ? 
                                        themeManager.colors.secondaryText.opacity(0.2) : 
                                        themeManager.colors.secondaryText.opacity(0.4),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .disabled(tasksForSelectedRange.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RoleType.allCases) { role in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = role
                            }
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedRole == role ? .white : themeManager.colors.secondaryText)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(selectedRole == role ? role.color : themeManager.colors.secondaryBackground)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                                
                                Text(role.rawValue)
                                    .font(.system(size: 14, weight: selectedRole == role ? .semibold : .regular))
                                    .foregroundColor(selectedRole == role ? themeManager.colors.text : themeManager.colors.secondaryText)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedRole == role ? 
                                          themeManager.colors.secondaryBackground.opacity(0.7) : 
                                          themeManager.colors.background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedRole == role ? 
                                                role.color.opacity(0.5) : 
                                                themeManager.colors.secondaryText.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .scaleEffect(selectedRole == role ? 1.05 : 1.0)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 24)
            }
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
                        taskTypeCard(for taskType: taskType)
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
        .sheet(isPresented: $showRoleAnalysis) {
            RoleAnalysisSummaryView(role: selectedRole, timeStats: getTaskTypesStats(), roleStandards: roleStandards, timeRange: selectedRange, isPresented: $showRoleAnalysis)
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
    func taskTypeCard(for taskType: String) -> some View {
        // 获取对应任务类型的统计数据
        guard let stat = getTaskTypesStats().first(where: { $0.type == taskType }) else {
            return AnyView(EmptyView())
        }
        
        // 角色视角分析
        let timeStatus = analyzeTimeStatus(for: taskType, minutes: stat.minutes)
        let statusColor = getColorForTimeStatus(timeStatus)
        
        // 其他数据分析
        let adjustPercentage = Double(stat.adjustmentMinutes) / Double(stat.originalMinutes) * 100
        let hasAdjustmentIssue = abs(adjustPercentage) > (selectedRange == .today ? 30 : 20)
        let hasTerminationIssue = stat.terminatedCount > 0 && (Double(stat.terminatedCount) / Double(stat.count) * 100 > 30 || stat.reducedMinutes > 60)
        
        return VStack(alignment: .leading, spacing: 14) {
            // 标题栏 - 更紧凑现代的设计
            HStack(alignment: .center, spacing: 14) {
                // 任务图标 - 更精致的设计，使用任务类型对应的颜色
                Image(systemName: getIconForTaskType(stat.type))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(getColorForTaskType(stat.type))
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                    )
                
                // 任务类型和计数
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stat.type)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                        
                        // 角色视角状态指示器
                        Image(systemName: getIconForTimeStatus(timeStatus))
                            .font(.system(size: 14))
                            .foregroundColor(statusColor)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(stat.count)次")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        // 小圆点分隔符
                        Circle()
                            .fill(themeManager.colors.secondaryText.opacity(0.5))
                            .frame(width: 3, height: 3)
                        
                        // 总时长
                        Text("\(formatMinutes(stat.minutes))")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // 更多信息按钮
                Button(action: {
                    currentTaskType = stat.type
                    detailedSuggestion = getDetailedSuggestion(for: stat.type)
                    showDetailedSuggestion = true
                }) {
                    Text("More")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(themeManager.currentTheme == .elegantPurple ? 
                                      Color(hex: "8A2BE2") : Color(hex: "0C4A45"))
                        )
                }
            }
            
            // 分隔线 - 更精致的设计
            Rectangle()
                .fill(themeManager.colors.secondaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 2)
            
            // 统计信息部分
            VStack(spacing: 10) {
                // 过多/过少时间分配简报，始终显示
                timeAllocationAlertView(for: stat)
                
                // 调整频繁提醒
                if hasAdjustmentIssue {
                    HStack {
                        Label(
                            title: { 
                                Text(adjustPercentage > 0 
                                     ? "时间经常被延长，可从客观(任务量)和主观(估算能力)分析原因" 
                                     : "时间经常提前完成，可总结提升效率的方法")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(adjustPercentage > 0 ? .orange : .green)
                            }
                        )
                    }
                }
                
                // 时间调整信息
                if stat.adjustmentMinutes != 0 {
                    HStack {
                        Label(
                            title: { 
                                Text("时间调整:")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                            },
                            icon: { 
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                            }
                        )
                        
                        Text(formatAdjustment(stat.adjustmentMinutes))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                            
                        Text("(\(formatPercentage(stat.adjustmentMinutes, original: stat.originalMinutes)))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // 终止任务频繁提醒
                if hasTerminationIssue {
                    HStack {
                        Label(
                            title: { 
                                Text("任务经常被终止，可从客观(任务复杂度)和主观(专注度)寻找原因")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        )
                    }
                }
                
                // 终止任务信息
                if stat.terminatedCount > 0 {
                    HStack {
                        Label(
                            title: { 
                                Text("终止任务:")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                            },
                            icon: { 
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        )
                        
                        Text("\(stat.terminatedCount)次，减少\(formatMinutes(stat.reducedMinutes))")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                            
                        Text("(\(formatPercentage(stat.reducedMinutes, original: stat.originalMinutes + stat.reducedMinutes)))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // 添加角色建议
                if timeStatus != .optimal {
                    HStack {
                        Label(
                            title: { 
                                Text(getTimeStatusDescription(timeStatus, taskType: stat.type))
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedRole.color)
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 获取时间状态描述
    func getTimeStatusDescription(_ status: TimeAllocationStatus, taskType: String) -> String {
        guard let standards = roleStandards[selectedRole],
              let standard = standards[taskType] else {
            return "未找到标准"
        }
        
        let priority = standard.priorityCoefficient
        let roleName = selectedRole.rawValue
        
        switch status {
        case .tooLittle:
            return "对\(roleName)而言，这是优先级\(priority)的活动，建议增加时间投入"
        case .optimal:
            return "对\(roleName)而言，当前时间分配合理"
        case .tooMuch:
            return "对\(roleName)而言，这项活动时间可适当减少，优先级为\(priority)"
        }
    }
    
    // 时间分配分析视图
    func timeAllocationAlertView(for stat: TaskTypeStat) -> some View {
        let totalMinutes = totalTimeForSelectedRange
        let percentage = totalMinutes > 0 ? Double(stat.minutes) / Double(totalMinutes) * 100 : 0
        let timeStatus = analyzeTimeStatus(for: stat.type, minutes: stat.minutes)
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                // 时间占比展示
                HStack {
                    Text("时间占比:")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                }
                
                // 角色视角分析
                HStack(spacing: 4) {
                    Image(systemName: getIconForTimeStatus(timeStatus))
                        .font(.system(size: 12))
                        .foregroundColor(getColorForTimeStatus(timeStatus))
                    
                    Text(getDescriptionForTimeStatus(timeStatus, taskType: stat.type, minutes: stat.minutes))
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.colors.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 2)
            }
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
    
    // 角色时间标准定义
    let roleStandards: [RoleType: [String: TimeStandard]] = [
        // 创业者标准
        .entrepreneur: [
            "睡觉": TimeStandard(lowerBound: 6.0, upperBound: 7.5, priorityCoefficient: 5),
            "工作": TimeStandard(lowerBound: 10.0, upperBound: 14.0, priorityCoefficient: 5),
            "会议": TimeStandard(lowerBound: 1.0, upperBound: 3.0, priorityCoefficient: 3),
            "思考": TimeStandard(lowerBound: 1.0, upperBound: 2.0, priorityCoefficient: 4),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 2),
            "运动": TimeStandard(lowerBound: 0.25, upperBound: 0.75, priorityCoefficient: 4),
            "阅读": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 3),
            "生活": TimeStandard(lowerBound: 0.5, upperBound: 1.5, priorityCoefficient: 2)
        ],
        
        // 高管标准
        .executive: [
            "睡觉": TimeStandard(lowerBound: 7.0, upperBound: 8.0, priorityCoefficient: 5),
            "工作": TimeStandard(lowerBound: 8.0, upperBound: 10.0, priorityCoefficient: 4),
            "会议": TimeStandard(lowerBound: 3.0, upperBound: 6.0, priorityCoefficient: 4),
            "思考": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 4),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 1),
            "运动": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 3),
            "阅读": TimeStandard(lowerBound: 1.0, upperBound: 2.0, priorityCoefficient: 3),
            "生活": TimeStandard(lowerBound: 2.0, upperBound: 3.0, priorityCoefficient: 3)
        ],
        
        // 白领标准
        .employee: [
            "睡觉": TimeStandard(lowerBound: 7.0, upperBound: 8.0, priorityCoefficient: 4),
            "工作": TimeStandard(lowerBound: 6.0, upperBound: 8.0, priorityCoefficient: 4),
            "会议": TimeStandard(lowerBound: 1.0, upperBound: 2.0, priorityCoefficient: 2),
            "思考": TimeStandard(lowerBound: 0.25, upperBound: 0.5, priorityCoefficient: 3),
            "摸鱼": TimeStandard(lowerBound: 0.5, upperBound: 1.5, priorityCoefficient: 1),
            "运动": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 4),
            "阅读": TimeStandard(lowerBound: 0.5, upperBound: 1.0, priorityCoefficient: 2),
            "生活": TimeStandard(lowerBound: 3.0, upperBound: 4.0, priorityCoefficient: 4)
        ]
    ]
    
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
            let tasksOfThisType = tasksForSelectedRange.filter { $0.title == type }
            let count = tasksOfThisType.count
            if count > 0 {
                let minutes = tasksOfThisType.reduce(0) { $0 + $1.duration }
                let originalMinutes = tasksOfThisType.reduce(0) { $0 + $1.originalDuration() }
                let adjustmentMinutes = minutes - originalMinutes
                
                // 统计终止的任务
                let terminatedTasks = tasksOfThisType.filter { $0.isTerminated }
                let terminatedCount = terminatedTasks.count
                let reducedMinutes = terminatedTasks.reduce(0) { $0 + abs($1.timeAdjustments.filter { $0 < 0 }.reduce(0, +)) }
                
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
        // 创建并添加20个随机完成的任务
        let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        let focusTypes: [Task.FocusType] = [.general, .audio, .writing, .productivity, .success]
        let calendar = Calendar.current
        let now = Date()
        
        // 清理之前的测试数据
        let oldTasks = appViewModel.tasks.filter { $0.id.contains("test_") }
        for task in oldTasks {
            if let index = appViewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                appViewModel.tasks.remove(at: index)
            }
        }
        
        // 控制今日任务的总时长
        var todayTotalMinutes = 0
        let maxTodayMinutes = 24 * 60 // 最多24小时
        
        // 每种时间范围生成的任务数
        let todayTaskCount = 10  // 今日任务
        let weekTaskCount = 6    // 本周任务
        let monthTaskCount = 4   // 本月任务
        
        // 1. 生成今日任务
        for i in 1...todayTaskCount {
            let taskType = taskTypes.randomElement()!
            let focusType = focusTypes.randomElement()!
            
            // 根据任务类型分配合理的时长
            var duration = 0
            switch taskType {
            case "睡觉":
                duration = Int.random(in: 360...480) // 6-8小时
            case "工作":
                duration = Int.random(in: 60...180) // 1-3小时
            case "会议":
                duration = Int.random(in: 30...90) // 30-90分钟
            case "运动":
                duration = Int.random(in: 30...90) // 30-90分钟
            default:
                duration = Int.random(in: 15...60) // 其他任务15-60分钟
            }
            
            // 检查今日总时间是否超出限制
            if todayTotalMinutes + duration > maxTodayMinutes {
                duration = max(15, maxTodayMinutes - todayTotalMinutes) // 确保至少15分钟
                if duration < 15 { // 如果剩余时间不足15分钟，则跳过
                    continue
                }
            }
            
            todayTotalMinutes += duration
            
            // 随机时间调整，有20%概率调整时间
            var timeAdjustments: [Int] = []
            if Int.random(in: 1...10) <= 2 {
                // 调整范围更合理：-15%到+25%
                let adjustment = Int(Double(duration) * Double.random(in: -0.15...0.25))
                timeAdjustments = [adjustment]
            }
            
            // 生成今日随机时间点
            let hourOfDay = Int.random(in: 8...22) // 早8点到晚10点
            let minuteOfHour = Int.random(in: 0...59)
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            todayComponents.hour = hourOfDay
            todayComponents.minute = minuteOfHour
            let completionTime = calendar.date(from: todayComponents)!
            
            let task = Task(
                id: "test_today_\(i)",
                title: taskType,
                focusType: focusType,
                duration: duration + (timeAdjustments.reduce(0, +)),
                createdAt: calendar.date(byAdding: .hour, value: -1, to: completionTime)!,
                completedAt: completionTime,
                note: "今日测试任务\(i)",
                timeAdjustments: timeAdjustments
            )
            
            appViewModel.tasks.append(task)
        }
        
        // 2. 生成本周任务（非今日）
        for i in 1...weekTaskCount {
            let taskType = taskTypes.randomElement()!
            let focusType = focusTypes.randomElement()!
            
            // 随机持续时间
            let duration = Int.random(in: 30...180)
            
            // 随机时间调整
            var timeAdjustments: [Int] = []
            if Int.random(in: 1...10) <= 3 {
                let adjustment = Int(Double(duration) * Double.random(in: -0.2...0.3))
                timeAdjustments = [adjustment]
            }
            
            // 生成本周内的随机日期（1-6天前）
            let daysAgo = Int.random(in: 1...6)
            let weekDate = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            
            let task = Task(
                id: "test_week_\(i)",
                title: taskType,
                focusType: focusType,
                duration: duration + (timeAdjustments.reduce(0, +)),
                createdAt: calendar.date(byAdding: .hour, value: -1, to: weekDate)!,
                completedAt: weekDate,
                note: "本周测试任务\(i)",
                timeAdjustments: timeAdjustments
            )
            
            appViewModel.tasks.append(task)
        }
        
        // 3. 生成本月任务（非本周）
        for i in 1...monthTaskCount {
            let taskType = taskTypes.randomElement()!
            let focusType = focusTypes.randomElement()!
            
            // 随机持续时间
            let duration = Int.random(in: 30...180)
            
            // 随机时间调整
            var timeAdjustments: [Int] = []
            if Int.random(in: 1...10) <= 3 {
                let adjustment = Int(Double(duration) * Double.random(in: -0.2...0.3))
                timeAdjustments = [adjustment]
            }
            
            // 生成本月内但非本周的随机日期（7-29天前）
            let daysAgo = Int.random(in: 7...29)
            let monthDate = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            
            let task = Task(
                id: "test_month_\(i)",
                title: taskType,
                focusType: focusType,
                duration: duration + (timeAdjustments.reduce(0, +)),
                createdAt: calendar.date(byAdding: .hour, value: -1, to: monthDate)!,
                completedAt: monthDate,
                note: "本月测试任务\(i)",
                timeAdjustments: timeAdjustments
            )
            
            appViewModel.tasks.append(task)
        }
        
        // 保存更改
        appViewModel.saveUserData()
        print("已生成测试数据: 今日\(todayTaskCount)条(总\(todayTotalMinutes)分钟), 本周\(weekTaskCount)条, 本月\(monthTaskCount)条")
    }
    
    // 获取所选时间范围内的唯一任务类型
    func getUniqueTaskTypes() -> [String] {
        // 只包含预定义的8种任务类型
        let allTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        
        // 过滤出当前范围内实际存在的任务类型
        let existingTypes = Array(Set(tasksForSelectedRange.map { $0.title }))
        
        // 确保只返回有效的8种类型中的任务
        return existingTypes.filter { allTypes.contains($0) }
    }
    
    // 获取特定类型任务的次数
    func getTaskCountByType(_ type: String) -> Int {
        return tasksForSelectedRange.filter { $0.title == type }.count
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
    func getDetailedSuggestion(for taskType: String) -> (title: String, clientiveReasons: [String], subjectiveReasons: [String], suggestions: [String]) {
        // 获取该任务类型的统计数据
        guard let stats = getTaskTypesStats().first(where: { $0.type == taskType }) else {
            return (title: "暂无分析", clientiveReasons: [], subjectiveReasons: [], suggestions: [])
        }
        
        // 计算时间状态
        let timeStatus = analyzeTimeStatus(for: taskType, minutes: stats.minutes)
        
        // 1. 获取角色特定的时间标准
        guard let standards = roleStandards[selectedRole],
              let standard = standards[taskType] else {
            return (title: "暂无角色标准", clientiveReasons: [], subjectiveReasons: [], suggestions: [])
        }
        
        let priorityLevel = standard.priorityCoefficient
        let priorityDescription: String
        switch priorityLevel {
        case 5: priorityDescription = "最高优先级"
        case 4: priorityDescription = "高优先级"
        case 3: priorityDescription = "中等优先级"
        case 2: priorityDescription = "低优先级"
        case 1: priorityDescription = "最低优先级"
        default: priorityDescription = "未定义优先级"
        }
        
        // 2. 分别处理三种情况：时间过多、时间过少、以及时间适中
        var title = ""
        var clientiveReasons: [String] = []
        var subjectiveReasons: [String] = []
        var suggestions: [String] = []
        
        // 基于角色和时间状态生成标题
        switch timeStatus {
        case .tooLittle:
            title = "时间偏少：对\(selectedRole.rawValue)而言，\(taskType)是\(priorityDescription)活动"
        case .optimal:
            title = "时间适中：对\(selectedRole.rawValue)而言，\(taskType)分配合理"
        case .tooMuch:
            title = "时间过多：对\(selectedRole.rawValue)而言，\(taskType)可适度减少"
        }
        
        // 3. 基于时间状态、任务类型和角色生成分析和建议
        switch taskType {
        case "睡觉":
            // 不同角色对睡眠的不同需求和建议
            if timeStatus == .tooLittle {
                clientiveReasons = [
                    "工作压力和时间紧迫导致睡眠时间被挤压",
                    "环境因素可能影响睡眠质量，使有效睡眠时间减少",
                    "生活节奏快导致入睡困难，延长了入睡时间"
                ]
                
                subjectiveReasons = [
                    "可能存在'睡眠负债不重要'的错误认知",
                    "习惯性晚睡或使用电子产品影响睡眠质量",
                    "压力和焦虑导致难以进入深度睡眠"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "即使在创业阶段，也应确保每晚至少6小时高质量睡眠",
                        "使用20分钟战略小睡提升下午工作效率",
                        "建立严格的睡前1小时无屏幕规则，提高睡眠质量"
                    ]
                case .executive:
                    suggestions = [
                        "作为管理者，良好的决策力需要充足睡眠支持",
                        "安排助理在非紧急情况下过滤晚间通知",
                        "尝试"5-3-1"睡眠法：睡前5小时无咖啡因，3小时无食物，1小时无屏幕"
                    ]
                case .employee:
                    suggestions = [
                        "工作效率与睡眠质量直接相关，建议保持规律作息",
                        "尝试睡眠追踪应用，了解自己的睡眠周期",
                        "周末避免睡眠时间与工作日相差超过1小时"
                    ]
                }
            } else if timeStatus == .tooMuch {
                clientiveReasons = [
                    "可能存在睡眠质量问题，导致需要更长时间休息",
                    "缺乏合理作息计划，被动接受过长睡眠时间",
                    "环境因素如光线、温度不适影响睡眠效率"
                ]
                
                subjectiveReasons = [
                    "可能存在情绪低落或精力不足导致的过度睡眠",
                    "睡眠习惯不规律，影响深度睡眠比例",
                    "对高效睡眠技巧了解不足"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "创业者时间宝贵，尝试睡眠优化技巧提高睡眠质量",
                        "考虑睡眠周期完整性，每晚安排5-6个90分钟完整周期",
                        "使用智能闹钟在浅睡期唤醒，避免睡过头"
                    ]
                case .executive:
                    suggestions = [
                        "管理者需要平衡休息与效率，控制睡眠在7-8小时",
                        "优化睡眠环境，调整室温在18-20°C，改善睡眠质量",
                        "考虑早睡早起策略，提高晨间决策效率"
                    ]
                case .employee:
                    suggestions = [
                        "过长睡眠可能与生活节奏不协调，建议调整作息",
                        "周末尽量维持工作日作息，避免睡眠节律被打乱",
                        "检查是否存在睡眠质量问题，必要时咨询专业医生"
                    ]
                }
            } else {
                // 睡眠时间适中
                clientiveReasons = [
                    "当前的睡眠时间安排合理，符合健康标准",
                    "睡眠规律有助于保持良好的身体状态和工作效率"
                ]
                
                subjectiveReasons = [
                    "您对睡眠重要性有正确认知",
                    "已经形成了良好的睡眠习惯"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "继续保持良好睡眠习惯，为高强度创业工作提供支持",
                        "考虑使用睡眠追踪工具进一步优化睡眠质量",
                        "在特别忙碌的时期，可以尝试多相睡眠以提高时间利用率"
                    ]
                case .executive:
                    suggestions = [
                        "管理者的决策质量与睡眠质量直接相关，继续保持",
                        "可以探索冥想或正念练习，进一步提升睡眠质量",
                        "在出差或时区变化时，优先调整睡眠计划"
                    ]
                case .employee:
                    suggestions = [
                        "继续保持规律作息，有助于长期职业发展和健康",
                        "工作日与周末的睡眠时间保持一致，有益身心健康",
                        "定期评估睡眠质量，必要时调整睡眠环境"
                    ]
                }
            }
            
        // ... 其他任务类型分析 ...
        case "会议":
            // 会议时间管理指南
            if stat.minutes > 180 && selectedRange == .today {
                clientiveReasons = [
                    "会议时间过长，可能导致注意力分散，效率降低",
                    "会议规模不合理，议题设置不当",
                    "参与人员过多或关键人缺席",
                    "会议环境干扰因素多"
                ]
                
                subjectiveReasons = [
                    "您在会议中的角色表现是否影响效率？",
                    "您是否有参与不足或过度发言的情况？",
                    "您是否存在注意力不集中或准备不充分问题？",
                    "您对会议的期望是否与实际会议目的一致？",
                    "您的会议决策流程是否高效？"
                ]
                
                suggestions = [
                    "时间过少建议：提前分发材料减少讨论时间，设置议题优先级",
                    "时间过多建议：设定严格时间限制，非核心议题移至其他渠道",
                    "评估议题复杂度合理安排时间，考虑使用会前材料",
                    "减少非必要参会人员，明确每位参与者的角色",
                    "采用结构化会议流程，确保关键决策有足够讨论时间",
                    "定期评估会议效果，持续改进会议流程"
                ]
            } else if stat.count > 5 && selectedRange == .today {
                clientiveReasons = [
                    "今日会议次数较多，考虑合并部分会议",
                    "会议规模不合理，议题设置不当",
                    "参与人员过多或关键人缺席",
                    "会议环境干扰因素多"
                ]
                
                subjectiveReasons = [
                    "您在会议中的角色表现是否影响效率？",
                    "您是否有参与不足或过度发言的情况？",
                    "您是否存在注意力不集中或准备不充分问题？",
                    "您对会议的期望是否与实际会议目的一致？",
                    "您的会议决策流程是否高效？"
                ]
                
                suggestions = [
                    "时间过多建议：设定严格时间限制，非核心议题移至其他渠道",
                    "评估议题复杂度合理安排时间，考虑使用会前材料",
                    "减少非必要参会人员，明确每位参与者的角色",
                    "采用结构化会议流程，确保关键决策有足够讨论时间",
                    "定期评估会议效果，持续改进会议流程"
                ]
            } else {
                clientiveReasons = [
                    "会议时间分配合理",
                    "会议规模合理，议题设置得当",
                    "参与人员适当，会议环境良好"
                ]
                
                subjectiveReasons = [
                    "您对会议的期望是否与实际会议目的一致？",
                    "您的会议决策流程是否高效？"
                ]
                
                suggestions = [
                    "保持会议时间合理分配，避免过长或过短",
                    "定期评估会议效果，持续改进会议流程"
                ]
            }
            
        // ... 其他任务类型分析 ...
        case "工作":
            // 工作时间分析，针对不同角色
            if timeStatus == .tooLittle {
                clientiveReasons = [
                    "工作任务可能分散或缺乏明确结构",
                    "环境干扰导致有效工作时间减少",
                    "工作内容与个人能力匹配度不足"
                ]
                
                subjectiveReasons = [
                    "可能存在专注力不足或拖延心理",
                    "对工作目标认同感不足",
                    "工作动力不足或倦怠感"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "创业者应确保每日至少10小时高质量工作时间",
                        "使用番茄工作法增加专注度，如25分钟工作+5分钟休息",
                        "重新审视工作优先级，将时间集中在能产生10倍回报的任务上"
                    ]
                case .executive:
                    suggestions = [
                        "高管角色需要8-10小时专注工作，建议重新规划日程",
                        "将会议时间控制在每日总工作时间的30%以内",
                        "使用时间块技术，为不同类型工作划分明确时段"
                    ]
                case .employee:
                    suggestions = [
                        "白领工作效率与专注度相关，建议使用专注力训练工具",
                        "减少多任务处理，采用批处理方式提高工作效率",
                        "每90分钟工作后安排短暂休息，保持持续生产力"
                    ]
                }
            } else if timeStatus == .tooMuch {
                clientiveReasons = [
                    "工作量过大或任务安排不合理",
                    "工作效率低下导致需要更多时间完成任务",
                    "缺乏明确的工作边界和下班机制"
                ]
                
                subjectiveReasons = [
                    "可能存在工作完美主义倾向",
                    "对委托工作或寻求帮助存在心理障碍",
                    "工作与自我价值过度绑定"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "创业虽然耗时，但超过14小时可能导致决策质量下降",
                        "检视是否存在可以外包或自动化的工作内容",
                        "建立每周强制休息日，确保长期创新能力"
                    ]
                case .executive:
                    suggestions = [
                        "高管工作超过10小时可能影响战略思考质量",
                        "重新评估工作权责划分，合理下放决策权",
                        "应用二八法则，专注于能产生80%价值的20%工作"
                    ]
                case .employee:
                    suggestions = [
                        "白领工作超过8小时可能导致效率递减",
                        "学习设置工作边界，避免被动加班",
                        "提高时间管理能力，优先处理高价值工作内容"
                    ]
                }
            } else {
                // 工作时间适中
                clientiveReasons = [
                    "工作时间安排合理，符合角色期望",
                    "工作任务结构化程度适中"
                ]
                
                subjectiveReasons = [
                    "对工作内容有清晰认知和规划",
                    "工作动力和专注度处于良好状态"
                ]
                
                switch selectedRole {
                case .entrepreneur:
                    suggestions = [
                        "创业者工作时间分配合理，继续保持",
                        "定期审视工作产出与时间投入比例",
                        "考虑从执行型工作逐步向战略型工作转变"
                    ]
                case .executive:
                    suggestions = [
                        "当前工作时间安排符合高管角色预期",
                        "继续优化工作内容构成，增加战略思考比重",
                        "确保工作时间质量，减少低价值会议和行政工作"
                    ]
                case .employee:
                    suggestions = [
                        "当前工作时间分配合理，有助于长期职业发展",
                        "可以尝试深度工作技巧，进一步提升工作质量",
                        "保持工作与生活平衡，避免倦怠"
                    ]
                }
            }
        
        // ... 其他任务类型分析 ...
        default:
            // 默认建议
            if timeStatus == .tooLittle {
                clientiveReasons = [
                    "客观环境限制导致时间分配不足",
                    "其他任务占用了过多时间",
                    "缺乏合理的时间规划结构"
                ]
                
                subjectiveReasons = [
                    "可能低估了该活动的重要性",
                    "习惯性忽略或推迟该类活动",
                    "对该活动缺乏足够的兴趣或动力"
                ]
                
                let roleName = selectedRole.rawValue
                let taskImportance = priorityLevel >= 4 ? "高优先级" : "重要"
                
                suggestions = [
                    "对\(roleName)而言，\(taskType)是\(taskImportance)活动，建议增加时间投入",
                    "可以使用日历预约的方式，确保该活动有固定时间段",
                    "尝试将\(taskType)与您喜欢的活动结合，提高参与动力"
                ]
            } else if timeStatus == .tooMuch {
                clientiveReasons = [
                    "可能缺乏时间边界感，导致过度投入",
                    "该活动的执行效率较低，耗时过长",
                    "习惯性将大量时间分配给该活动"
                ]
                
                subjectiveReasons = [
                    "可能对该活动有特别的偏好或依赖",
                    "缺乏对时间投入与回报的客观评估",
                    "使用该活动作为逃避其他责任的方式"
                ]
                
                let roleName = selectedRole.rawValue
                let moreImportantTasks = priorityLevel <= 3 ? "更重要的任务" : "其他关键活动"
                
                suggestions = [
                    "作为\(roleName)，适当减少\(taskType)时间有助于平衡生活",
                    "设定明确的时间限制，避免该活动无限延长",
                    "将节省出的时间投入到\(moreImportantTasks)中"
                ]
            } else {
                // 时间适中
                clientiveReasons = [
                    "当前时间分配合理，符合角色期望",
                    "该活动在整体时间安排中处于平衡状态"
                ]
                
                subjectiveReasons = [
                    "对该活动的重要性有清晰认知",
                    "能够合理控制时间投入"
                ]
                
                let roleName = selectedRole.rawValue
                
                suggestions = [
                    "作为\(roleName)，您对\(taskType)的时间安排非常合理",
                    "继续保持当前的时间分配模式",
                    "定期评估该活动的价值回报，确保时间投入持续有效"
                ]
            }
        }
        
        // 4. 如果有调整或终止问题，添加额外建议
        let adjustPercentage = Double(stats.adjustmentMinutes) / Double(stats.originalMinutes) * 100
        let hasAdjustmentIssue = abs(adjustPercentage) > 30
        
        if hasAdjustmentIssue && stats.adjustmentMinutes > 0 {
            clientiveReasons.append("该类任务经常需要延长时间，可能存在工作量评估不足")
            subjectiveReasons.append("可能低估了任务复杂度或完成所需精力")
            suggestions.append("尝试使用"2倍估计法"：预估时间后乘以2，更接近实际需要")
        } else if hasAdjustmentIssue && stats.adjustmentMinutes < 0 {
            clientiveReasons.append("该类任务经常提前完成，可能存在时间预估过长")
            subjectiveReasons.append("可能对任务效率有保守估计或为应对紧急情况预留过多缓冲")
            suggestions.append("调整时间预估模型，提高规划准确性")
        }
        
        let terminationPercentage = stats.count > 0 ? Double(stats.terminatedCount) / Double(stats.count) * 100 : 0
        let hasTerminationIssue = terminationPercentage > 30
        
        if hasTerminationIssue {
            clientiveReasons.append("该类任务终止率高，可能任务设置不合理或外部干扰多")
            subjectiveReasons.append("任务可能缺乏足够吸引力或持续动力")
            suggestions.append("重新设计任务结构，将大任务分解为25-30分钟小任务，提高完成率")
        }
        
        return (title: title, clientiveReasons: clientiveReasons, subjectiveReasons: subjectiveReasons, suggestions: suggestions)
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
    
    // 获取任务类型
    func getTaskTypes() -> [String] {
        let stats = getTaskTypesStats()
        return stats.map { $0.type }
    }
    
    // 日期范围选择器
    private var dateRangeSelector: some View {
        VStack {
            taskSummaryCard
                .padding(.horizontal, 24) // 增加水平边距
        }
        .padding(.horizontal, 0)
    }
    
    // 根据任务类型创建卡片
    func taskTypeCard(for taskType: String) -> some View {
        // 获取对应任务类型的统计数据
        guard let stat = getTaskTypesStats().first(where: { $0.type == taskType }) else {
            return AnyView(EmptyView())
        }
        
        // 角色视角分析
        let timeStatus = analyzeTimeStatus(for: taskType, minutes: stat.minutes)
        let statusColor = getColorForTimeStatus(timeStatus)
        
        // 其他数据分析
        let adjustPercentage = Double(stat.adjustmentMinutes) / Double(stat.originalMinutes) * 100
        let hasAdjustmentIssue = abs(adjustPercentage) > (selectedRange == .today ? 30 : 20)
        let hasTerminationIssue = stat.terminatedCount > 0 && (Double(stat.terminatedCount) / Double(stat.count) * 100 > 30 || stat.reducedMinutes > 60)
        
        return VStack(alignment: .leading, spacing: 14) {
            // 标题栏 - 更紧凑现代的设计
            HStack(alignment: .center, spacing: 14) {
                // 任务图标 - 更精致的设计，使用任务类型对应的颜色
                Image(systemName: getIconForTaskType(stat.type))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(getColorForTaskType(stat.type))
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                    )
                
                // 任务类型和计数
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(stat.type)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                        
                        // 角色视角状态指示器
                        Image(systemName: getIconForTimeStatus(timeStatus))
                            .font(.system(size: 14))
                            .foregroundColor(statusColor)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(stat.count)次")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        // 小圆点分隔符
                        Circle()
                            .fill(themeManager.colors.secondaryText.opacity(0.5))
                            .frame(width: 3, height: 3)
                        
                        // 总时长
                        Text("\(formatMinutes(stat.minutes))")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // 更多信息按钮
                Button(action: {
                    currentTaskType = stat.type
                    detailedSuggestion = getDetailedSuggestion(for: stat.type)
                    showDetailedSuggestion = true
                }) {
                    Text("More")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(themeManager.currentTheme == .elegantPurple ? 
                                      Color(hex: "8A2BE2") : Color(hex: "0C4A45"))
                        )
                }
            }
            
            // 分隔线 - 更精致的设计
            Rectangle()
                .fill(themeManager.colors.secondaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 2)
            
            // 统计信息部分
            VStack(spacing: 10) {
                // 过多/过少时间分配简报，始终显示
                timeAllocationAlertView(for: stat)
                
                // 调整频繁提醒
                if hasAdjustmentIssue {
                    HStack {
                        Label(
                            title: { 
                                Text(adjustPercentage > 0 
                                     ? "时间经常被延长，可从客观(任务量)和主观(估算能力)分析原因" 
                                     : "时间经常提前完成，可总结提升效率的方法")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(adjustPercentage > 0 ? .orange : .green)
                            }
                        )
                    }
                }
                
                // 时间调整信息
                if stat.adjustmentMinutes != 0 {
                    HStack {
                        Label(
                            title: { 
                                Text("时间调整:")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                            },
                            icon: { 
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                    .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                            }
                        )
                        
                        Text(formatAdjustment(stat.adjustmentMinutes))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(stat.adjustmentMinutes > 0 ? .green : .red)
                            
                        Text("(\(formatPercentage(stat.adjustmentMinutes, original: stat.originalMinutes)))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // 终止任务频繁提醒
                if hasTerminationIssue {
                    HStack {
                        Label(
                            title: { 
                                Text("任务经常被终止，可从客观(任务复杂度)和主观(专注度)寻找原因")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        )
                    }
                }
                
                // 终止任务信息
                if stat.terminatedCount > 0 {
                    HStack {
                        Label(
                            title: { 
                                Text("终止任务:")
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                            },
                            icon: { 
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        )
                        
                        Text("\(stat.terminatedCount)次，减少\(formatMinutes(stat.reducedMinutes))")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                            
                        Text("(\(formatPercentage(stat.reducedMinutes, original: stat.originalMinutes + stat.reducedMinutes)))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
                
                // 添加角色建议
                if timeStatus != .optimal {
                    HStack {
                        Label(
                            title: { 
                                Text(getTimeStatusDescription(timeStatus, taskType: stat.type))
                                    .font(.system(size: 13))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            },
                            icon: { 
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedRole.color)
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 获取时间状态描述
    func getTimeStatusDescription(_ status: TimeAllocationStatus, taskType: String) -> String {
        guard let standards = roleStandards[selectedRole],
              let standard = standards[taskType] else {
            return "未找到标准"
        }
        
        let priority = standard.priorityCoefficient
        let roleName = selectedRole.rawValue
        
        switch status {
        case .tooLittle:
            return "对\(roleName)而言，这是优先级\(priority)的活动，建议增加时间投入"
        case .optimal:
            return "对\(roleName)而言，当前时间分配合理"
        case .tooMuch:
            return "对\(roleName)而言，这项活动时间可适当减少，优先级为\(priority)"
        }
    }
}

// 详细建议视图
struct DetailedSuggestionView: View {
    let taskType: String
    let suggestion: (title: String, clientiveReasons: [String], subjectiveReasons: [String], suggestions: [String])
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部图标和标题
                    HStack(spacing: 15) {
                        // 任务图标
                        Image(systemName: getIconForTaskType(taskType))
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.black)
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(taskType)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(themeManager.colors.text)
                            
                            Text(suggestion.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.colors.secondaryText)
                        }
                    }
                    .padding(.bottom, 5)
                    
                    // 客观因素
                    sectionView(title: "客观因素分析", 
                                icon: "cube", 
                                items: suggestion.clientiveReasons,
                                color: themeManager.currentTheme == .elegantPurple ? Color(hex: "8A2BE2") : Color(hex: "2E8B57"))
                    
                    // 主观因素
                    sectionView(title: "主观因素分析", 
                                icon: "brain", 
                                items: suggestion.subjectiveReasons,
                                color: themeManager.currentTheme == .elegantPurple ? Color(hex: "9370DB") : Color(hex: "3CB371"))
                    
                    // 建议与提升
                    sectionView(title: "提升建议", 
                                icon: "lightbulb", 
                                items: suggestion.suggestions,
                                color: themeManager.currentTheme == .elegantPurple ? Color(hex: "483D8B") : Color(hex: "0C4A45"))
                    
                    // 底部说明
                    Text("以上建议基于您的时间使用模式智能生成，仅供参考。请根据个人情况选择适合的方法。")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.secondaryText)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Text("关闭")
                    .foregroundColor(themeManager.currentTheme == .elegantPurple ? Color(hex: "483D8B") : Color(hex: "0C4A45"))
            })
            .background(themeManager.colors.background.edgesIgnoringSafeArea(.all))
        }
    }
    
    // 辅助函数：获取任务类型对应的图标
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
    
    // 辅助方法：生成段落视图
    private func sectionView(title: String, icon: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 段落标题
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(color)
                    )
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.text)
            }
            
            // 列表项
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.secondaryBackground)
        )
    }
}

// MARK: - Summary Structures
// Using TimeAnalysisSummary for both weekly and monthly summaries

// 修改为使用TimeAnalysisSummary
extension TimeWhereView {
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
            ("摸鱼", 540)    // 9小时
        ]
        
        summary.frequentlyAdjustedTypes = [
            ("工作", 10, 20),
            ("睡觉", 8, 16),
            ("运动", 6, 12),
            ("阅读", 4, 8),
            ("思考", 3, 6),
            ("生活", 2, 4),
            ("会议", 1, 2)
        ]
        
        summary.frequentlyTerminatedTypes = [
            ("工作", 5, 10),
            ("睡觉", 4, 8),
            ("运动", 3, 6),
            ("阅读", 2, 4),
            ("思考", 1, 2),
            ("生活", 1, 2),
            ("会议", 1, 2)
        ]
        
        summary.mostProductiveTimeOfDay = "上午9点-11点"
        summary.leastProductiveTimeOfDay = "下午3点-4点"
        
        summary.bestCombinations = [
            ("运动", "工作", "运动后工作效率提升20%"),
            ("阅读", "思考", "阅读后思考更有深度"),
            ("休息", "会议", "短暂休息后会议专注度提高")
        ]
        
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
        
        return summary
    }
    
    // 定义为方法而非属性，避免重复声明
    func getSampleMonthlySummary() -> TimeAnalysisSummary {
        var summary = TimeAnalysisSummary()
        
        // 基本统计数据
        summary.totalTime = 8310 // 138.5小时 = 8310分钟
        summary.taskCount = 181 // 所有任务数量总和
        summary.avgDuration = Int(4.2 * 60) // 转换为分钟
        
        // 时间过多/过少分析
        summary.overAllocatedTypes = [
            ("工作", 1080), // 18小时
            ("娱乐", 600)  // 10小时
        ]
        
        summary.underAllocatedTypes = [
            ("运动", 900),  // 15小时
            ("阅读", 480)   // 8小时
        ]
        
        summary.frequentlyAdjustedTypes = [
            ("工作", 15, 30),
            ("学习", 10, 20),
            ("阅读", 5, 10)
        ]
        
        summary.frequentlyTerminatedTypes = [
            ("工作", 8, 16),
            ("学习", 5, 10),
            ("娱乐", 12, 24)
        ]
        
        summary.mostProductiveTimeOfDay = "上午10点-12点"
        summary.leastProductiveTimeOfDay = "下午4点-6点"
        
        summary.bestCombinations = [
            ("运动", "工作", "运动后工作效率提升25%"),
            ("冥想", "学习", "冥想后学习专注度提高"),
            ("短休息", "阅读", "休息后阅读理解力增强")
        ]
        
        summary.trendingUpTypes = [
            ("学习", 18.3),
            ("阅读", 7.5)
        ]
        
        summary.trendingDownTypes = [
            ("娱乐", -15.2),
            ("会议", -8.9)
        ]
        
        summary.mostConsistentType = "学习"
        summary.leastConsistentType = "运动"
        
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
                ForEach(taskCounts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
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
                ForEach(taskCounts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
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
        return trends.map { (type: $0.type, increasePercentage: $0.decreasePercentage) }
    }
}

// MARK: - View Extensions
extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

// MARK: - 角色分析总结视图
struct RoleAnalysisSummaryView: View {
    let role: RoleType
    let timeStats: [TaskTypeStat]
    let roleStandards: [String: TimeStandard]
    let timeRange: TimeWhereView.TimeRange
    
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部：角色标题
                    roleHeader
                    
                    // 角色基准说明
                    roleBaseline
                    
                    // 分隔线
                    Divider()
                        .background(themeManager.colors.secondaryText.opacity(0.3))
                        .padding(.vertical, 5)
                    
                    // 时间分配分析
                    timeAllocationAnalysis
                    
                    // 分隔线
                    Divider()
                        .background(themeManager.colors.secondaryText.opacity(0.3))
                        .padding(.vertical, 5)
                    
                    // 改进建议
                    improvementSuggestions
                    
                    // 底部说明
                    Text("以上分析基于\(role.rawValue)角色标准，仅供参考。您可以根据个人情况和职业发展阶段进行调整。")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.secondaryText)
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Text("关闭")
                    .foregroundColor(themeManager.currentTheme == .elegantPurple ? Color(hex: "483D8B") : Color(hex: "0C4A45"))
            })
            .background(themeManager.colors.background.edgesIgnoringSafeArea(.all))
        }
    }
    
    // 角色标题部分
    private var roleHeader: some View {
        HStack(spacing: 15) {
            // 角色图标
            Image(systemName: role.icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(role.color)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(role.rawValue)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.colors.text)
                
                Text("时间分配分析报告")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.colors.secondaryText)
            }
        }
        .padding(.bottom, 10)
    }
    
    // 角色基准说明
    private var roleBaseline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("角色时间基准")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
                .padding(.bottom, 4)
            
            Text("\(role.rawValue)的理想时间分配模式")
                .font(.subheadline)
                .foregroundColor(themeManager.colors.secondaryText)
            
            // 基准图表
            standardsChartView
                .padding(.top, 8)
        }
    }
    
    // 基准图表视图
    private var standardsChartView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(roleStandards.sorted(by: { $0.value.priorityCoefficient > $1.value.priorityCoefficient }), id: \.key) { type, standard in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            // 任务类型图标
                            Image(systemName: getIconForTaskType(type))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(getColorForTaskType(type))
                                )
                            
                            Text(type)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.colors.text)
                        }
                        
                        // 时间范围
                        let lowerText = getAdjustedTimeText(standard.lowerBound)
                        let upperText = getAdjustedTimeText(standard.upperBound)
                        
                        Text("\(lowerText) - \(upperText)")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        // 优先级指示
                        HStack(spacing: 4) {
                            Text("优先级:")
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.colors.secondaryText)
                            
                            // 优先级显示为点
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Circle()
                                        .fill(i <= standard.priorityCoefficient ? role.color : themeManager.colors.secondaryText.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.colors.secondaryBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .frame(width: 120)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // 时间分配分析
    private var timeAllocationAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分配分析")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            // 状态分类
            let tooLittle = timeStats.filter { analyzeTimeStatus(for: $0.type, minutes: $0.minutes) == .tooLittle }
            let tooMuch = timeStats.filter { analyzeTimeStatus(for: $0.type, minutes: $0.minutes) == .tooMuch }
            let optimal = timeStats.filter { analyzeTimeStatus(for: $0.type, minutes: $0.minutes) == .optimal }
            
            // 时间过少部分
            if !tooLittle.isEmpty {
                taskStatusSection(
                    title: "需要增加时间的活动",
                    description: "这些活动时间不足，可能影响生产力和平衡",
                    status: .tooLittle,
                    stats: tooLittle
                )
            }
            
            // 时间过多部分
            if !tooMuch.isEmpty {
                taskStatusSection(
                    title: "可以减少时间的活动",
                    description: "这些活动占用过多时间，可能挤压其他重要事项",
                    status: .tooMuch,
                    stats: tooMuch
                )
            }
            
            // 时间适中部分
            if !optimal.isEmpty {
                taskStatusSection(
                    title: "时间分配合理的活动",
                    description: "这些活动时间分配适当，符合角色期望",
                    status: .optimal,
                    stats: optimal
                )
            }
        }
    }
    
    // 任务状态分类区块
    private func taskStatusSection(title: String, description: String, status: TimeAllocationStatus, stats: [TaskTypeStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: getIconForTimeStatus(status))
                    .font(.system(size: 14))
                    .foregroundColor(getColorForTimeStatus(status))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.colors.text)
            }
            
            // 描述
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.secondaryText)
                .padding(.bottom, 4)
            
            // 任务列表
            VStack(spacing: 10) {
                ForEach(stats, id: \.type) { stat in
                    HStack {
                        // 任务图标和名称
                        Image(systemName: getIconForTaskType(stat.type))
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(getColorForTaskType(stat.type))
                            )
                        
                        Text(stat.type)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.text)
                        
                        Spacer()
                        
                        // 时间差异
                        let timeText = getTimeDeviation(for: stat.type, minutes: stat.minutes)
                        Text(timeText)
                            .font(.system(size: 13))
                            .foregroundColor(getColorForTimeStatus(status))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.colors.secondaryBackground.opacity(0.7))
                    )
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .padding(.vertical, 5)
    }
    
    // 改进建议部分
    private var improvementSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("角色改进建议")
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
                .padding(.bottom, 4)
            
            // 基于角色生成建议
            VStack(alignment: .leading, spacing: 12) {
                suggestionItem(
                    icon: "arrow.up.arrow.down",
                    title: "时间重分配",
                    content: getTimeReallocationSuggestion()
                )
                
                suggestionItem(
                    icon: "chart.bar.fill",
                    title: "优先级调整",
                    content: getPrioritySuggestion()
                )
                
                suggestionItem(
                    icon: "clock.arrow.circlepath",
                    title: "效率提升",
                    content: getEfficiencySuggestion()
                )
            }
        }
    }
    
    // 单个建议项
    private func suggestionItem(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(role.color)
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.colors.text)
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(themeManager.colors.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.secondaryBackground)
        )
    }
    
    // 获取调整后的时间文本
    private func getAdjustedTimeText(_ hours: Double) -> String {
        switch timeRange {
        case .today:
            return "\(String(format: "%.1f", hours))小时"
        case .week:
            let adjusted = hours * 5
            return "\(String(format: "%.1f", adjusted))小时/周"
        case .month:
            let adjusted = hours * 22
            return "\(String(format: "%.1f", adjusted))小时/月"
        }
    }
    
    // 简短格式化时间
    private func formatTimeShort(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = Double(minutes) / 60.0
            return "\(String(format: "%.1f", hours))小时"
        }
    }
    
    // 获取时间偏差描述
    private func getTimeDeviation(for taskType: String, minutes: Int) -> String {
        guard let standard = roleStandards[taskType] else {
            return "无基准"
        }
        
        // 根据当前时间范围调整标准
        let adjustedLower: Int
        let adjustedUpper: Int
        
        switch timeRange {
        case .today:
            adjustedLower = standard.lowerBoundMinutes
            adjustedUpper = standard.upperBoundMinutes
        case .week:
            adjustedLower = standard.lowerBoundMinutes * 5
            adjustedUpper = standard.upperBoundMinutes * 5
        case .month:
            adjustedLower = standard.lowerBoundMinutes * 22
            adjustedUpper = standard.upperBoundMinutes * 22
        }
        
        if minutes < adjustedLower {
            let diff = adjustedLower - minutes
            return "少\(formatTimeShort(diff))"
        } else if minutes > adjustedUpper {
            let diff = minutes - adjustedUpper
            return "多\(formatTimeShort(diff))"
        } else {
            return "适中"
        }
    }
    
    // MARK: - 辅助方法
    
    // 获取角色时间重分配建议
    private func getTimeReallocationSuggestion() -> String {
        let tooLittle = timeStats.filter { analyzeTimeStatus(for: $0.type, minutes: $0.minutes) == .tooLittle }
        let tooMuch = timeStats.filter { analyzeTimeStatus(for: $0.type, minutes: $0.minutes) == .tooMuch }
        
        // 优先级排序
        let sortedTooLittle = tooLittle.sorted { 
            (roleStandards[$0.type]?.priorityCoefficient ?? 0) > (roleStandards[$1.type]?.priorityCoefficient ?? 0)
        }
        
        let sortedTooMuch = tooMuch.sorted { 
            (roleStandards[$0.type]?.priorityCoefficient ?? 5) < (roleStandards[$1.type]?.priorityCoefficient ?? 5)
        }
        
        var suggestion = ""
        
        if !sortedTooLittle.isEmpty && !sortedTooMuch.isEmpty {
            // 有需要增加和减少的活动
            let highPriorityNeed = sortedTooLittle.first!.type
            let lowPriorityExcess = sortedTooMuch.first!.type
            
            suggestion = "建议从\(lowPriorityExcess)中减少时间，转移到\(highPriorityNeed)上。作为\(role.rawValue)，提升\(highPriorityNeed)的时间投入将带来更高回报。"
        } else if !sortedTooLittle.isEmpty {
            // 只有需要增加的活动
            let highPriorityNeeds = sortedTooLittle.prefix(2).map { $0.type }.joined(separator: "和")
            suggestion = "作为\(role.rawValue)，您应当增加\(highPriorityNeeds)的时间。这些活动对您的角色发展至关重要，建议重新审视日程安排，为这些活动创造更多空间。"
        } else if !sortedTooMuch.isEmpty {
            // 只有需要减少的活动
            let lowPriorityExcess = sortedTooMuch.prefix(2).map { $0.type }.joined(separator: "和")
            suggestion = "您在\(lowPriorityExcess)上花费了过多时间。作为\(role.rawValue)，适当减少这些活动的时间投入，可以为更重要的任务释放精力和时间。"
        } else {
            // 都很平衡
            suggestion = "您当前的时间分配非常合理，符合\(role.rawValue)的理想模式。建议继续保持这种平衡状态，并定期回顾时间分配是否仍然适合您的发展阶段。"
        }
        
        return suggestion
    }
    
    // 获取优先级建议
    private func getPrioritySuggestion() -> String {
        // 获取高优先级活动
        let highPriorityActivities = roleStandards.filter { $0.value.priorityCoefficient >= 4 }.keys.sorted()
        
        if highPriorityActivities.isEmpty {
            return "当前角色标准中未定义明确优先级较高的活动。"
        }
        
        let highPriorityList = highPriorityActivities.joined(separator: "、")
        
        switch role {
        case .entrepreneur:
            return "作为创业者，\(highPriorityList)应当是您的核心关注点。建议使用时间块技术，确保每天为这些高优先级活动预留不受干扰的专注时段。创业阶段的时间分配应着重于产出和价值创造，将低优先级活动最小化或外包。"
        case .executive:
            return "高管角色需要平衡战略与执行，\(highPriorityList)是您应当优先关注的领域。建议采用授权与监督相结合的方式，将精力集中在这些高价值活动上，并建立结构化的委派机制处理其他任务。"
        case .employee:
            return "作为职场白领，\(highPriorityList)是您职业发展的关键领域。建议优先保障这些活动的时间投入，并通过提高效率来处理其他必要任务。在工作与生活平衡中，确保这些核心活动得到充分关注将有助于您的长期发展。"
        }
    }
    
    // 获取效率提升建议
    private func getEfficiencySuggestion() -> String {
        // 寻找调整频繁的任务类型
        let adjustmentIssues = timeStats.filter { 
            let adjustPercentage = $0.originalMinutes > 0 ? Double($0.adjustmentMinutes) / Double($0.originalMinutes) * 100 : 0
            return abs(adjustPercentage) > 30
        }
        
        // 寻找终止频繁的任务类型
        let terminationIssues = timeStats.filter {
            $0.count > 0 && (Double($0.terminatedCount) / Double($0.count) * 100 > 30)
        }
        
        var suggestion = ""
        
        if !adjustmentIssues.isEmpty || !terminationIssues.isEmpty {
            let adjustmentTypes = adjustmentIssues.map { $0.type }.joined(separator: "、")
            let terminationTypes = terminationIssues.map { $0.type }.joined(separator: "、")
            
            if !adjustmentIssues.isEmpty && !terminationIssues.isEmpty {
                suggestion = "您在\(adjustmentTypes)活动上频繁调整时间，在\(terminationTypes)活动上存在较高的任务终止率。"
            } else if !adjustmentIssues.isEmpty {
                suggestion = "您在\(adjustmentTypes)活动上频繁调整时间。"
            } else {
                suggestion = "您在\(terminationTypes)活动上存在较高的任务终止率。"
            }
            
            switch role {
            case .entrepreneur:
                suggestion += " 创业者面临的不确定性较高，建议：1) 应用"2倍估计法"提高时间预估准确性；2) 使用最小可行任务法，将大项目分解为25-30分钟小任务；3) 建立专注工作环境，减少外部干扰；4) 每周进行时间估计复盘，持续优化您的时间感知能力。"
            case .executive:
                suggestion += " 作为管理者，建议：1) 使用缓冲区管理技术，在日程中预留应对意外的时间；2) 优化会议结构，确保每个任务时间长度合理；3) 培养时间边界意识，避免任务无限扩展；4) 考虑使用专业助理管理日程，确保高价值任务不被干扰。"
            case .employee:
                suggestion += " 建议您：1) 学习任务分解技术，将工作拆分为可管理的小块；2) 识别并减少工作中的干扰源；3) 与上级沟通，明确任务优先级和时间期望；4) 使用番茄工作法等技术提高专注度，减少任务中断和终止。"
            }
        } else {
            suggestion = "您的任务执行效率良好，很少出现时间调整或提前终止的情况。作为\(role.rawValue)，建议继续保持这种稳定的执行力，并考虑进一步提高工作质量和创新性，而不仅仅关注效率。合理的休息和思考时间对保持长期高效同样重要。"
        }
        
        return suggestion
    }
}