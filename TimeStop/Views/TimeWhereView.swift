import SwiftUI
import Foundation

// 时间范围枚举
enum TimeRange {
    case today   // 今日
    case week    // 本周
    case month   // 本月
}

// 任务类型统计
extension TimeWhereView {
    struct TaskTypeStat: Identifiable {
        let id = UUID()
        let type: String
        let minutes: Int
        let color: Color
        
        var formattedTime: String {
            let hours = minutes / 60
            let mins = minutes % 60
            if hours > 0 {
                return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
            } else {
                return "\(mins)分钟"
            }
        }
    }
}

struct TimeWhereView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedRange: TimeRange = .today
    @State private var selectedRole: String = "全部"
    @State private var showEmptyState: Bool = false
    
    // 获取当前选择范围内的任务
    private var tasksForSelectedRange: [Task] {
        switch selectedRange {
        case .today:
            return appViewModel.getTodayTasks()
        case .week:
            return appViewModel.getWeeklyTasks()
        case .month:
            return appViewModel.getMonthlyTasks()
        }
    }
    
    // 获取任务类型统计
    private var taskTypeStats: [TaskTypeStat] {
        let filtered = selectedRole == "全部" ? tasksForSelectedRange : tasksForSelectedRange.filter { $0.category == selectedRole }
        let completedTasks = filtered.filter { $0.isCompleted }
        
        var typeMinutes: [String: Int] = [:]
        var colors: [String: Color] = [:]
        
        for task in completedTasks {
            typeMinutes[task.type, default: 0] += task.duration
            colors[task.type] = themeManager.colorFor(taskType: task.type)
        }
        
        return typeMinutes.map { type, minutes in
            TaskTypeStat(
                type: type,
                minutes: minutes,
                color: colors[type] ?? .gray
            )
        }.sorted { $0.minutes > $1.minutes }
    }
    
    // 计算总时长
    private var totalTimeForSelectedRange: Int {
        taskTypeStats.reduce(0) { $0 + $1.minutes }
    }
    
    private var formattedTotalTime: String {
        let hours = totalTimeForSelectedRange / 60
        let mins = totalTimeForSelectedRange % 60
        if hours > 0 {
            return "\(hours)小时\(mins > 0 ? " \(mins)分钟" : "")"
        } else {
            return "\(mins)分钟"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 头部
                headerView
                
                // 角色选择器
                roleSelector
                
                // 时间范围选择器
                timeRangeSelector
                
                ScrollView {
                    if taskTypeStats.isEmpty {
                        emptyStateView
                    } else {
                        // 总时长卡片
                        VStack(alignment: .leading, spacing: 16) {
                            Text("时间分配")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal)
                            
                            totalTimeCard
                            
                            // 任务类型列表
                            ForEach(taskTypeStats) { stat in
                                taskTypeCard(stat)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .background(themeManager.backgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
    
    // 头部视图
    private var headerView: some View {
        HStack {
            Text("时间去哪了")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            Spacer()
        }
        .padding()
        .background(themeManager.backgroundColor)
    }
    
    // 角色选择器
    private var roleSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["全部", "工作", "学习", "生活"], id: \.self) { role in
                    Button(action: {
                        selectedRole = role
                    }) {
                        Text(role)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedRole == role ? themeManager.primaryColor : themeManager.secondaryBackgroundColor)
                            .foregroundColor(selectedRole == role ? .white : themeManager.textColor)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // 时间范围选择器
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach([("今日", TimeRange.today), ("本周", TimeRange.week), ("本月", TimeRange.month)], id: \.0) { label, range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(label)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedRange == range ? themeManager.primaryColor : themeManager.secondaryBackgroundColor)
                        .foregroundColor(selectedRange == range ? .white : themeManager.textColor)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("暂无完成任务数据")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("你的已完成任务将在这里显示时间分配情况")
                .font(.system(size: 16))
                .foregroundColor(themeManager.tertiaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // 总时长卡片
    private var totalTimeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("总时长")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.textColor)
                
                Text(formattedTotalTime)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.primaryColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.secondaryBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
    
    // 任务类型卡片
    private func taskTypeCard(_ stat: TimeWhereView.TaskTypeStat) -> some View {
        Button(action: {
            timeAllocationAlertView(for: stat)
        }) {
            HStack {
                Circle()
                    .fill(stat.color)
                    .frame(width: 14, height: 14)
                
                Text(stat.type)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text(stat.formattedTime)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(themeManager.secondaryBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // 时间分配弹窗
    private func timeAllocationAlertView(for stat: TimeWhereView.TaskTypeStat) {
        let percentage = totalTimeForSelectedRange > 0 ? Double(stat.minutes) / Double(totalTimeForSelectedRange) * 100 : 0
        
        let alert = UIAlertController(
            title: "\(stat.type)时间分配",
            message: "在\(rangeTitle)中，你在\(stat.type)上花费了\(stat.formattedTime)，占总时间的\(String(format: "%.1f", percentage))%",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        // 获取当前视图控制器并显示提示
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    // 当前范围标题
    private var rangeTitle: String {
        switch selectedRange {
        case .today: return "今天"
        case .week: return "本周"
        case .month: return "本月"
        }
    }
}

// 按钮缩放动画
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// 预览视图
struct TimeWhereView_Previews: PreviewProvider {
    static var previews: some View {
        TimeWhereView()
            .environmentObject(UserModel())
            .environmentObject(AppViewModel())
            .environmentObject(ThemeManager())
    }
} 