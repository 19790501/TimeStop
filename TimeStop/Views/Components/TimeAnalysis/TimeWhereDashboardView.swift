import SwiftUI
import Foundation

// 时间健康仪表盘视图
struct TimeWhereDashboardView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appViewModel: AppViewModel
    
    // 状态变量
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
    let roleStandards = [
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
    
    // 生成测试数据
    func generateRandomTestData() {
        // 测试任务类型
        let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        let durations = [30, 45, 60, 90, 120, 180, 240]
        
        // 生成今日数据
        for type in taskTypes {
            // 为每个类型创建1-3个不同的任务
            let count = Int.random(in: 1...3)
            for _ in 0..<count {
                let duration = durations.randomElement() ?? 60
                let date = Date() // 今天
                
                // 创建任务
                let newTask = Task(
                    title: type, 
                    focusType: .general, 
                    duration: duration,
                    createdAt: date.addingTimeInterval(-Double(duration * 60)),
                    completedAt: date
                )
                
                // 添加到 viewModel
                appViewModel.tasks.append(newTask)
            }
        }
        
        // 打印添加的测试数据总数
        print("生成测试数据: \(taskTypes.count * 2) 条")
    }
    
    // 生成分析报告
    func generateAnalysisReport() {
        // 在这里添加基于当前数据生成分析报告的逻辑
    }
    
    // 生成详细建议
    func generateDetailedSuggestion(for stat: TaskTypeStat) {
        // 在这里添加基于任务统计数据生成建议的逻辑
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
    
    // 获取每类任务的完成次数
    func getTaskCountByType(_ type: String) -> Int {
        return tasksForSelectedRange.filter { task in task.title == type }.count
    }
}

// MARK: - UI组件
extension TimeWhereDashboardView {
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
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
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
                }
            }
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
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeManager.colors.secondaryText.opacity(0.2), lineWidth: 1.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(themeManager.colors.secondaryBackground.opacity(0.5))
                                            )
                                    }
                                }
                            )
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
        }
        .background(themeManager.colors.background)
    }
    
    // 空状态视图
    var emptyStateView: some View {
        VStack {
            headerView
            timeRangeSelector
            
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
    var mainContentView: some View {
        VStack(spacing: 0) {
            headerView
            timeRangeSelector
            
            ScrollView {
                VStack(spacing: 20) {
                    // 时间健康评分
                    VStack(alignment: .leading, spacing: 4) {
                        Text("时间健康评分")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        let healthScore = calculateTimeHealthScore()
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(healthScore) / 100)
                                    .stroke(
                                        healthScore > 70 ? Color.green : 
                                            healthScore > 40 ? Color.orange : Color.red,
                                        lineWidth: 10
                                    )
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(healthScore)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(themeManager.colors.text)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(healthScore > 70 ? "良好" : healthScore > 40 ? "一般" : "需要调整")
                                    .font(.headline)
                                    .foregroundColor(
                                        healthScore > 70 ? Color.green : 
                                            healthScore > 40 ? Color.orange : Color.red
                                    )
                                
                                Text("根据\(selectedRole)标准")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 时间分配卡片
                    VStack(alignment: .leading, spacing: 10) {
                        Text("时间分配")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        let stats = getTaskTypesStats()
                        if stats.isEmpty {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.secondaryText)
                                .padding()
                        } else {
                            ForEach(stats, id: \.type) { stat in
                                timeAllocationCard(for: stat)
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 显示查看周报和月报的按钮
                    if !tasksForSelectedRange.isEmpty {
                        HStack(spacing: 15) {
                            Button(action: {
                                showWeeklySummary = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                    Text("周报告")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .sheet(isPresented: $showWeeklySummary) {
                                DetailedSuggestionView(
                                    taskType: "周报告",
                                    suggestion: (
                                        title: "本周时间分析",
                                        objectiveReasons: ["本周总时长：\(formatHours(totalTimeForSelectedRange))", "任务数：\(tasksForSelectedRange.count)个"],
                                        subjectiveReasons: [],
                                        suggestions: ["保持良好习惯"]
                                    ),
                                    isPresented: $showWeeklySummary
                                )
                                .environmentObject(themeManager)
                            }
                            
                            Button(action: {
                                showMonthlySummary = true
                            }) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                    Text("月报告")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(Color.purple)
                                .cornerRadius(10)
                            }
                            .sheet(isPresented: $showMonthlySummary) {
                                DetailedSuggestionView(
                                    taskType: "月报告",
                                    suggestion: (
                                        title: "本月时间分析",
                                        objectiveReasons: ["本月总时长：\(formatHours(totalTimeForSelectedRange))", "任务数：\(tasksForSelectedRange.count)个"],
                                        subjectiveReasons: [],
                                        suggestions: ["建议合理安排时间"]
                                    ),
                                    isPresented: $showMonthlySummary
                                )
                                .environmentObject(themeManager)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .background(themeManager.colors.background)
    }
    
    // 时间分配卡片
    private func timeAllocationCard(for stat: TaskTypeStat) -> some View {
        HStack(spacing: 15) {
            // 任务类型图标
            Image(systemName: getIconForTaskType(stat.type))
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(getColorForTaskType(stat.type))
                )
            
            // 任务类型和时间
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.type)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                
                Text("\(formatHours(stat.minutes)) (\(stat.count)个任务)")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
            }
            
            Spacer()
            
            // 任务占比
            let percentage = totalTimeForSelectedRange > 0 ? Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100 : 0
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.colors.text)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
            .fill(themeManager.colors.background)
        )
    }
}
