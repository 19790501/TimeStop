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
    
    // 实现Equatable协议的静态方法
    static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
        return lhs.type == rhs.type
    }
}

// 偏差类型枚举
enum DeviationType {
    case excess      // 过多
    case deficient   // 不足
    case balanced    // 平衡
}

// 时间范围枚举
enum TimeRange: String, CaseIterable, Identifiable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
    
    var id: String { self.rawValue }
    
    static var allCases: [TimeRange] {
        return [.today, .week, .month]
    }
}

struct TimeWhereView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    
    // 选择的时间范围
    @State private var selectedRange: TimeRange = .today
    
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
    
    // 获取任务类型对应的图标
    private func getIconForTaskType(_ type: String) -> String {
        switch type {
        case "工作":
            return "briefcase.fill"
        case "会议":
            return "person.2.fill"
        case "思考":
            return "brain"
        case "阅读":
            return "book.fill"
        case "生活":
            return "house.fill"
        case "运动":
            return "figure.run"
        case "摸鱼":
            return "gamecontroller.fill"
        case "睡觉":
            return "bed.double.fill"
        default:
            return "clock.fill"
        }
    }
    
    // 获取任务类型对应的颜色
    private func getColorForTaskType(_ type: String) -> Color {
        switch type {
        case "工作":
            return Color.blue
        case "会议":
            return Color.orange
        case "思考":
            return Color.purple
        case "阅读":
            return Color.indigo
        case "生活":
            return Color.brown
        case "运动":
            return Color.green
        case "摸鱼":
            return Color.pink
        case "睡觉":
            return Color.mint
        default:
            return Color.gray
        }
    }
    
    // 格式化时间
    private func formatTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
        } else {
            return "\(mins)分钟"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 标题
            Text("时间去哪了")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(themeManager.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // 时间范围选择器
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases) { range in
                    Button(action: {
                        withAnimation {
                            selectedRange = range
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 15, weight: selectedRange == range ? .semibold : .medium))
                            .foregroundColor(selectedRange == range ? .white : themeManager.colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedRange == range ? themeManager.colors.primary : themeManager.colors.secondaryBackground)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // 时间分配卡片
            timeDistributionCard
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(themeManager.colors.background.edgesIgnoringSafeArea(.all))
    }
    
    // 时间分配卡片
    private var timeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 卡片标题
            Text("时间分配")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.colors.text)
            
            // 分隔线
            Rectangle()
                .fill(themeManager.colors.secondaryText.opacity(0.1))
                .frame(height: 1)
            
            // 时间分配内容
            let stats = getTaskTypesStats()
            
            if stats.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(stats, id: \.type) { stat in
                            timeAllocationRow(stat: stat)
                        }
                    }
                }
                .frame(maxHeight: 350) // 限制最大高度
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.colors.secondaryBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 时间分配行
    private func timeAllocationRow(stat: TaskTypeStat) -> some View {
        let totalTime = totalTimeForSelectedRange
        let percentage = totalTime > 0 ? Double(stat.minutes) / Double(totalTime) * 100 : 0
        
        return HStack(spacing: 12) {
            // 任务类型图标
            Image(systemName: getIconForTaskType(stat.type))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(getColorForTaskType(stat.type))
                )
            
            // 任务类型和统计信息
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.type)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.colors.text)
                
                Text("\(stat.count)次 · \(formatTime(minutes: stat.minutes)) · \(String(format: "%.1f%%", percentage))")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.background)
        )
    }
}

// 时间标准结构
struct TimeStandard {
    let lowerBound: Double  // 单位：小时
    let upperBound: Double  // 单位：小时
    let priorityCoefficient: Int // 1-5，表示优先级
    
    // 判断给定的小时数是否在标准范围内
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

// 扩展Color以支持十六进制颜色代码
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 扩展View来提供eraseToAnyView()方法
extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}
