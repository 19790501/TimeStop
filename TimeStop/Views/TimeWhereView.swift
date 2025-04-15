import SwiftUI
import Foundation

// 时间分析摘要数据结构
struct TimeAnalysisSummary {
    // 基本分析数据
    var totalTime: Int = 0
    var taskCount: Int = 0
    var avgDuration: Int = 0
    
    // 时间分配分析
    var overAllocatedTypes: [(type: String, minutes: Int)] = []
    var underAllocatedTypes: [(type: String, minutes: Int)] = []
}

// 时间分配视图
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
    @State private var showTaskDetail: Bool = false
    @State private var selectedTaskType: String?
    
    // 获取当前范围内的所有任务
    private func getTasksForSelectedRange() -> [Task] {
        switch selectedRange {
        case .today:
            return getTodayTasks()
        case .week:
            return getWeekTasks()
        case .month:
            return getMonthTasks()
        }
    }
    
    // 获取今日任务
    private func getTodayTasks() -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return appViewModel.completedTasks.filter { task in
            task.startDate >= today && task.startDate < endOfDay
        }
    }
    
    // 获取本周任务
    private func getWeekTasks() -> [Task] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return appViewModel.completedTasks.filter { task in
            task.startDate >= startOfWeek && task.startDate < endOfWeek
        }
    }
    
    // 获取本月任务
    private func getMonthTasks() -> [Task] {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        return appViewModel.completedTasks.filter { task in
            task.startDate >= startOfMonth && task.startDate < endOfMonth
        }
    }
    
    // 获取任务类型统计
    private func getTaskTypeStats() -> [TaskTypeStat] {
        let tasks = getTasksForSelectedRange()
        return getTaskTypeStatsForTasks(tasks)
    }
    
    // 计算任务类型统计
    private func getTaskTypeStatsForTasks(_ tasks: [Task]) -> [TaskTypeStat] {
        var stats: [String: Int] = [:]
        
        for task in tasks {
            stats[task.type, default: 0] += task.duration
        }
        
        return stats.map { TaskTypeStat(type: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }
    
    // 计算任务类型所占总时间的百分比
    private func calculatePercentage(for stat: TaskTypeStat) -> Double {
        let totalTime = getTasksForSelectedRange().reduce(0) { $0 + $1.duration }
        guard totalTime > 0 else { return 0 }
        return Double(stat.minutes) / Double(totalTime) * 100
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部标题和范围选择
                    VStack(spacing: 0) {
                        // 标题
                        Text("时间分配")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.leading, .top])
                        
                        // 时间范围选择器
                        timeRangeSelector
                            .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        if getTaskTypeStats().isEmpty {
                            emptyStateView
                        } else {
                            timeAllocationSection
                        }
                    }
                    .background(themeManager.currentTheme.backgroundColor)
                    
                    Spacer()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .sheet(isPresented: $showTaskDetail) {
                if let typeSelected = selectedTaskType {
                    TaskDetailView(selectedType: typeSelected, timeRange: selectedRange.rawValue, tasks: getTasksForSelectedRange().filter { $0.type == typeSelected })
                }
            }
        }
    }
    
    // 时间范围选择器
    private var timeRangeSelector: some View {
        HStack(spacing: 10) {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    withAnimation {
                        selectedRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: selectedRange == range ? .bold : .regular))
                        .foregroundColor(selectedRange == range ? themeManager.currentTheme.accentColor : themeManager.currentTheme.textColor.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedRange == range ? themeManager.currentTheme.accentColor.opacity(0.2) : Color.clear)
                        )
                }
            }
            Spacer()
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("暂无数据")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                .padding(.top, 50)
            
            Text("完成任务后，这里将显示你的时间分配情况")
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // 时间分配部分
    private var timeAllocationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("时间分配")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textColor)
                .padding(.horizontal)
                .padding(.bottom, 10)
                .padding(.top, 20)
            
            VStack(spacing: 15) {
                // 任务类型列表
                ForEach(getTaskTypeStats(), id: \.type) { stat in
                    timeAllocationCard(for: stat)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // 时间分配卡片
    private func timeAllocationCard(for stat: TaskTypeStat) -> some View {
        Button(action: {
            selectedTaskType = stat.type
            showTaskDetail = true
        }) {
            HStack {
                // 任务类型图标和名称
                HStack(spacing: 12) {
                    Circle()
                        .fill(themeManager.getColorForTaskType(stat.type))
                        .frame(width: 10, height: 10)
                    
                    Text(stat.type)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Spacer()
                
                // 时间和百分比
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(stat.minutes.minutesToHoursMinutesString())")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(String(format: "%.1f%%", calculatePercentage(for: stat)))
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
}

// 任务类型统计结构
struct TaskTypeStat: Identifiable {
    let id = UUID()
    let type: String
    let minutes: Int
}

// 任务详情视图
struct TaskDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    let selectedType: String
    let timeRange: String
    let tasks: [Task]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack {
                    if tasks.isEmpty {
                        Text("暂无任务数据")
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                            .padding()
                    } else {
                        List {
                            ForEach(tasks.sorted(by: { $0.startDate > $1.startDate })) { task in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(task.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    
                                    Text("\(task.formattedStartDate) · \(task.duration.minutesToHoursMinutesString())")
                                        .font(.system(size: 14))
                                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.6))
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationBarTitle("\(selectedType) · \(timeRange)", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("完成")
                    .foregroundColor(themeManager.currentTheme.accentColor)
            })
        }
    }
}

// 扩展 Int 将分钟转为小时分钟格式
extension Int {
    func minutesToHoursMinutesString() -> String {
        let hours = self / 60
        let minutes = self % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes > 0 ? " \(minutes)分钟" : "")"
        } else {
            return "\(minutes)分钟"
        }
    }
} 