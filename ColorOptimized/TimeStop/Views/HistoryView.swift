import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeframe: Timeframe = .today
    @State private var isAnimating: Bool = false
    
    enum Timeframe {
        case today
        case thisWeek
        
        var title: String {
            switch self {
            case .today:
                return "今日"
            case .thisWeek:
                return "本周"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景层
            VStack(spacing: 0) {
                // 修改前:
                // 上部分荧光绿背景
                themeManager.colors.background
                    .frame(height: 240)

                // 修改后:
                // 上部分主题背景
                themeManager.colors.background
                    .frame(height: 240)
                
                // 下部分白色背景
                Color.white
            }
            .edgesIgnoringSafeArea(.all)
            
            // 内容层
            VStack(spacing: 0) {
                // 标题区域
                Text("时间去哪了")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 55)
                
                // 时间范围选择
                HStack(spacing: 12) {
                    ForEach([Timeframe.today, .thisWeek], id: \.title) { timeframe in
                        Button(action: {
                            if !isAnimating && selectedTimeframe != timeframe {
                                isAnimating = true
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTimeframe = timeframe
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isAnimating = false
                                }
                            }
                        }) {
                            Text(timeframe.title)
                                .font(.system(size: 15, weight: selectedTimeframe == timeframe ? .medium : .regular))
                                .foregroundColor(selectedTimeframe == timeframe ? .black : .black.opacity(0.4))
                                .frame(width: 80)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeframe == timeframe ? .white : .clear)
                                        .shadow(color: selectedTimeframe == timeframe ? .black.opacity(0.08) : .clear, radius: 6, x: 0, y: 3)
                                )
                        }
                        .disabled(isAnimating)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.03))
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 统计卡片
                HStack(spacing: 12) {
                    summaryItem(
                        value: "\(filteredTasks.count)",
                        label: "已完成任务",
                        icon: "checkmark.circle.fill"
                    )
                    
                    summaryItem(
                        value: "\(totalFocusTime)",
                        label: "专注总时长",
                        unit: "分钟",
                        icon: "clock.fill"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                // 任务列表
                if filteredTasks.isEmpty {
                    emptyStateView()
                        .padding(.top, 40)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTasks) { task in
                                taskCard(task: task)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .scrollContentBackground(.hidden)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        let completedTasks = viewModel.tasks.filter { $0.isCompleted }
        
        switch selectedTimeframe {
        case .today:
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: now)
                }
                return false
            }
        case .thisWeek:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return completedAt >= startOfWeek && completedAt < endOfWeek
                }
                return false
            }
        }
    }
    
    private var totalFocusTime: Int {
        filteredTasks.reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func summaryItem(value: String, label: String, unit: String = "", icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.5))
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func taskCard(task: Task) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                // 任务图标
                ZStack {
                    Circle()
                        .fill(themeManager.colors.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Group {
                        switch task.title {
                        case "会议":
                            Image(systemName: "person.2.fill")
                        case "思考":
                            Image(systemName: "brain")
                        case "工作":
                            Image(systemName: "briefcase.fill")
                        case "阅读":
                            Image(systemName: "book.fill")
                        case "生活":
                            Image(systemName: "heart.fill")
                        case "运动":
                            Image(systemName: "figure.run")
                        case "摸鱼":
                            Image(systemName: "fish")
                        default:
                            Image(systemName: task.focusType.icon)
                        }
                    }
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.65))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.85))
                    
                    if let completedAt = task.completedAt {
                        Text(formatDate(completedAt))
                            .font(.system(size: 13))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                
                Spacer()
                
                Text("\(task.duration)分钟")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.65))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                // 修改前:
                .background(
                    Capsule()
                        .fill(themeManager.colors.primary.opacity(0.12))
                )

                // 修改后:
                .background(
                    Capsule()
                        .fill(themeManager.colors.primary.opacity(0.12))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.15))
            
            Text("暂无完成记录")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
            
            Text("创建一个专注任务\n开始你的专注之旅吧")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.35))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 更新任务类型描述方法接收整个Task
    private func getTaskTypeText(_ task: Task) -> String {
        // 基于任务标题和类型组合确定适当的描述
        if task.title == "会议" {
            return "会议记录"
        } else if task.title == "思考" {
            return "思考冥想"
        } else if task.title == "工作" {
            return "工作效率"
        } else if task.title == "阅读" {
            return "阅读学习"
        } else if task.title == "生活" {
            return "生活记录"
        } else if task.title == "运动" {
            return "健康运动"
        } else if task.title == "摸鱼" {
            return "休闲放松"
        } else if task.title == "其它" {
            return "其他活动"
        } else {
            // 根据focusType返回默认描述
            switch task.focusType {
            case .general: return "常规专注"
            case .audio: return "音频记录"
            case .writing: return "写作记录"
            case .productivity: return "生产力记录"
            case .success: return "成功记录"
            }
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject({
            let viewModel = AppViewModel()
            
            // Add some mock data
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let lastWeek = Calendar.current.date(byAdding: .day, value: -6, to: Date())!
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            
            viewModel.tasks = [
                Task(title: "完成产品设计文档", focusType: .writing, duration: 25, completedAt: Date()),
                Task(title: "编写代码", focusType: .general, duration: 45, completedAt: yesterday),
                Task(title: "阅读书籍", focusType: .productivity, duration: 30, completedAt: lastWeek),
                Task(title: "录制视频", focusType: .audio, duration: 60, completedAt: lastMonth)
            ]
            
            return viewModel
        }())
} 
