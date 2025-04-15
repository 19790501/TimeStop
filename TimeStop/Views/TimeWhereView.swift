import SwiftUI
import Foundation

// 导入TimeWhereDashboardView文件
// 因为没有添加到项目中，所以直接嵌入代码

// 时间去哪了分析视图
struct TimeWhereView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // 顶部标题
                    HStack {
                        Text("时间去哪了")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(themeManager.colors.text)
                        
                        Spacer()
                        
                        Button(action: {
                            generateRandomTestData()
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
                    .padding(.top, 15)
                    
                    // 时间分配卡片
                    VStack(alignment: .leading, spacing: 10) {
                        let stats = getTaskStats()
                        if stats.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                
                                Text("暂无任务数据")
                                    .font(.title3)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Text("点击页面右上角闪电⚡按钮生成测试数据")
                                    .font(.callout)
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(stats, id: \.type) { stat in
                                        timeAllocationCard(for: stat)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
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
    
    // 获取任务统计数据
    func getTaskStats() -> [TaskStat] {
        // 定义任务类型
        let taskTypes = ["会议", "思考", "工作", "阅读", "生活", "运动", "摸鱼", "睡觉"]
        var stats: [TaskStat] = []
        
        // 获取今日已完成的任务
        let today = Calendar.current.startOfDay(for: Date())
        let completedTasks = appViewModel.tasks.filter { task in
            if let completedAt = task.completedAt {
                return Calendar.current.isDate(completedAt, inSameDayAs: today)
            }
            return false
        }
        
        // 计算总时长
        let totalDuration = completedTasks.reduce(0) { $0 + $1.duration }
        
        // 按类型统计
        for type in taskTypes {
            let tasksOfType = completedTasks.filter { $0.title == type }
            if !tasksOfType.isEmpty {
                let duration = tasksOfType.reduce(0) { $0 + $1.duration }
                let percentage = totalDuration > 0 ? Double(duration) / Double(totalDuration) * 100 : 0
                
                stats.append(TaskStat(
                    type: type,
                    count: tasksOfType.count,
                    duration: duration,
                    percentage: percentage
                ))
            }
        }
        
        // 按时间降序排序
        return stats.sorted { $0.duration > $1.duration }
    }
    
    // 时间分配卡片
    func timeAllocationCard(for stat: TaskStat) -> some View {
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
                
                Text("\(formatTime(stat.duration)) (\(stat.count)个任务)")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.colors.secondaryText)
            }
            
            Spacer()
            
            // 任务占比
            Text(String(format: "%.1f%%", stat.percentage))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeManager.colors.text)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.colors.secondaryBackground)
        )
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
    
    // 格式化时间
    func formatTime(_ minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        return String(format: "%.1f小时", hours)
    }
    
    // 简易任务统计结构
    struct TaskStat {
        let type: String
        let count: Int
        let duration: Int
        let percentage: Double
    }
}

// 预览
struct TimeWhereView_Previews: PreviewProvider {
    static var previews: some View {
        TimeWhereView()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
            .environmentObject(AppViewModel())
    }
}
