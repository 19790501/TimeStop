import SwiftUI

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
    @State private var selectedRole: String = "创业者" // 默认选择创业者角色
    @State private var selectedTaskType: String?
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部标题栏
                    headerView
                    
                    // 时间范围选择器
                    timeRangeSelector
                    
                    // 任务类型统计卡片
                    if taskTypeStats.isEmpty {
                        emptyStateView
                    } else {
                        taskTypeStatCards
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
                .background(themeManager.colors.background)
            }
            .background(themeManager.colors.background)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .sheet(item: $selectedTaskType) { taskType in
                timeAllocationAlertView(for: getTaskTypeStat(for: taskType))
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var taskTypeStats: [TaskTypeStat] {
        let taskTypes = Dictionary(grouping: tasksForSelectedRange) { $0.type }
        
        return taskTypes.map { type, tasks in
            let totalMinutes = tasks.reduce(0) { $0 + $1.duration }
            return TaskTypeStat(type: type, minutes: totalMinutes, count: tasks.count)
        }.sorted { $0.minutes > $1.minutes }
    }
    
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
    
    // MARK: - Helper Views
    
    var headerView: some View {
        HStack {
            Text("时间去哪了")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeManager.colors.text)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    withAnimation {
                        selectedRange = range
                    }
                    
                    appViewModel.playButtonSound()
                }) {
                    Text(range.rawValue)
                        .font(.system(size: 15, weight: selectedRange == range ? .bold : .medium))
                        .foregroundColor(selectedRange == range ? themeManager.colors.textOnPrimary : themeManager.colors.text)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedRange == range ? 
                            themeManager.colors.primary : 
                            themeManager.colors.secondaryBackground
                        )
                        .cornerRadius(12)
                        .shadow(color: selectedRange == range ? themeManager.colors.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .scaleEffect(selectedRange == range ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: selectedRange)
            }
        }
        .padding(.vertical, 10)
    }
    
    var taskTypeStatCards: some View {
        VStack(spacing: 12) {
            ForEach(taskTypeStats) { stat in
                taskTypeStatCard(for: stat)
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(themeManager.colors.text.opacity(0.3))
                .padding(.top, 50)
            
            Text("暂无数据")
                .font(.title3)
                .foregroundColor(themeManager.colors.text.opacity(0.6))
            
            Text("完成一些任务后，这里将显示您的时间分配情况")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.colors.text.opacity(0.4))
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 50)
    }
    
    // MARK: - Helper Functions
    
    private func getTaskTypeStat(for type: String) -> TaskTypeStat {
        return taskTypeStats.first { $0.type == type } ?? 
               TaskTypeStat(type: type, minutes: 0, count: 0)
    }
    
    // Task type card view
    private func taskTypeStatCard(for stat: TaskTypeStat) -> some View {
        Button(action: {
            selectedTaskType = stat.type
            appViewModel.playButtonSound()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(stat.type)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("\(stat.formattedTime) · \(stat.count)个任务")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.colors.text.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(Int(totalTimePercentage(for: stat.minutes)))%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.colors.primary)
            }
            .padding()
            .background(themeManager.colors.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // Detail view when tapping on a task type
    func timeAllocationAlertView(for stat: TaskTypeStat) -> some View {
        let percentage = totalTimePercentage(for: stat.minutes)
        
        return VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Button(action: {
                    selectedTaskType = nil
                    appViewModel.playButtonSound()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.colors.text.opacity(0.5))
                }
            }
            .padding(.top, 10)
            
            Text("\(stat.type) 时间分配")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(themeManager.colors.text)
            
            VStack(spacing: 16) {
                TimeStatView(
                    title: "\(stat.formattedTime)",
                    subtitle: "总时长",
                    icon: "clock",
                    color: themeManager.colors.primary
                )
                
                TimeStatView(
                    title: "\(Int(percentage))%",
                    subtitle: "时间占比",
                    icon: "percent",
                    color: .blue
                )
                
                TimeStatView(
                    title: "\(stat.count)",
                    subtitle: "任务数量",
                    icon: "checklist",
                    color: .green
                )
                
                TimeStatView(
                    title: "\(Int(Double(stat.minutes) / Double(stat.count)))分钟",
                    subtitle: "平均每个任务时长",
                    icon: "stopwatch",
                    color: .orange
                )
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .background(themeManager.colors.background)
    }
    
    private func totalTimePercentage(for minutes: Int) -> Double {
        let totalMinutes = taskTypeStats.reduce(0) { $0 + $1.minutes }
        guard totalMinutes > 0 else { return 0 }
        return Double(minutes) / Double(totalMinutes) * 100
    }
}

// Helper views
struct TimeStatView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.text.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.colors.text)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
    }
}

// Data Models
struct TaskTypeStat: Identifiable, Equatable {
    let id = UUID()
    let type: String
    let minutes: Int
    let count: Int
    
    var formattedTime: String {
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
    
    static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Preview
struct TimeWhereView_Previews: PreviewProvider {
    static var previews: some View {
        TimeWhereView()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
            .environmentObject(AppViewModel())
    }
} 