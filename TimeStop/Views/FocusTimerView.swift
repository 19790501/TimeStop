import SwiftUI
import Combine
import AudioToolbox

struct FocusTimerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var isShowingTimeAdjustment = false
    @State private var isShowingTaskList = false
    @State private var showTerminationAlert = false // 添加终止任务确认对话框状态
    
    private var progress: Double {
        guard let task = viewModel.activeTask else { return 0 }
        return Double(viewModel.timeRemaining) / (Double(task.duration) * 60.0)
    }
    
    // 计算已经过的时间（用于终止任务提示）
    private var elapsedTimeString: String {
        guard let task = viewModel.activeTask else { return "0分钟" }
        let totalSeconds = task.duration * 60
        let elapsedSeconds = totalSeconds - viewModel.timeRemaining
        let elapsedMinutes = max(1, Int(elapsedSeconds / 60))
        return "\(elapsedMinutes)分钟"
    }
    
    // 计算减少的时间（用于终止任务提示）
    private var reducedTimeString: String {
        guard let task = viewModel.activeTask else { return "0分钟" }
        let totalMinutes = task.duration
        let elapsedSeconds = (task.duration * 60) - viewModel.timeRemaining
        let elapsedMinutes = max(1, Int(elapsedSeconds / 60))
        let reducedMinutes = totalMinutes - elapsedMinutes
        return reducedMinutes > 0 ? "\(reducedMinutes)分钟" : "0分钟"
    }
    
    // 计时器是否已结束或即将结束(剩余10秒)
    private var isTimerEnded: Bool {
        return viewModel.timeRemaining <= 10 && !viewModel.timerIsRunning
    }
    
    // 获取验证方法名称
    private func verificationMethodName(_ method: VerificationMethod?) -> String {
        guard let method = method else { return "绘画" }
        switch method {
        case .drawing: return "绘画"
        case .reading: return "朗读单词"
        case .singing: return "唱歌"
        }
    }
    
    // 获取验证方法图标
    private func verificationMethodIcon(_ method: VerificationMethod?) -> String {
        guard let method = method else { return "paintbrush" }
        switch method {
        case .drawing: return "paintbrush"
        case .reading: return "text.book.closed"
        case .singing: return "music.mic"
        }
    }
    
    // 获取与CreateTaskView中一致的图标和颜色
    private func getIconForTask(_ task: Task) -> (icon: String, color: Color) {
        switch task.title {
        case "会议":
            return ("person.2.fill", .blue)
        case "思考":
            return ("brain", themeManager.colors.primary)
        case "工作":
            return ("briefcase.fill", .indigo)
        case "阅读":
            return ("book.fill", .orange)
        case "生活":
            return ("heart.fill", .pink)
        case "运动":
            return ("figure.run", .green)
        case "摸鱼":
            return ("fish", .cyan)
        case "睡觉":
            return ("bed.double.fill", .purple)
        default:
            // 如果没有特定标题的任务，回退到FocusType的图标
            switch task.focusType {
            case .productivity:
                return ("chart.bar.fill", .indigo)
            case .writing:
                return ("pencil", .orange)
            case .success:
                return ("trophy", .green)
            case .audio:
                return ("music.note", .red)
            case .general:
                return ("target", .gray)
            }
        }
    }
    
    // 生成渐变背景色 - 根据主题调整
    private var backgroundGradient: some View {
        Group {
            if themeManager.currentTheme == .elegantPurple {
                // 知性紫主题的深紫色背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "483D8B").opacity(0.95), // 暗深紫色
                        Color(hex: "2E1A47")                // 更深的紫色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        // 添加精致的紫色光效元素
                        Circle()
                            .fill(Color(hex: "8A2BE2").opacity(0.08))
                            .frame(width: 300, height: 300)
                            .blur(radius: 50)
                            .offset(x: -100, y: -200)
                        
                        Circle()
                            .fill(Color(hex: "9370DB").opacity(0.08))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: 150, y: 150)
                    }
                )
            } else {
                // 经典霓光绿主题的墨绿色背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.jadeGreen.opacity(0.9),
                        AppColors.jadeGreen
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    ZStack {
                        // 添加一些细微的设计元素
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 300, height: 300)
                            .blur(radius: 50)
                            .offset(x: -100, y: -200)
                        
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .offset(x: 150, y: 150)
                    }
                )
            }
        }
    }
    
    // 根据主题获取按钮背景色
    private var buttonBackgroundGradient: LinearGradient {
        if themeManager.currentTheme == .elegantPurple {
            return LinearGradient(
                gradient: Gradient(colors: [.white, .white.opacity(0.95)]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [.white, .white.opacity(0.95)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 获取按钮文本颜色
    private var buttonTextColor: Color {
        if themeManager.currentTheme == .elegantPurple {
            return Color(hex: "483D8B") // 深紫色文字
        } else {
            return AppColors.jadeGreen // 墨绿色文字
        }
    }
    
    // 计算结束时间
    private func endTimeString() -> String {
        guard viewModel.activeTask != nil else { return "" }
        let calendar = Calendar.current
        let now = Date()
        
        if viewModel.timeRemaining <= 0 {
            return "已完成"
        }
        
        if let endTime = calendar.date(byAdding: .second, value: viewModel.timeRemaining, to: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: endTime)
        }
        
        return ""
    }
    
    var body: some View {
        GeometryReader { geometry in
            backgroundGradient
                .edgesIgnoringSafeArea(.all)
                .overlay {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60) // 添加顶部间距
                        
                        // 任务名称区域
                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                // 根据任务显示图标和颜色 - 使用统一的图标方法
                                if let task = viewModel.activeTask {
                                    let iconInfo = getIconForTask(task)
                                    
                                    Image(systemName: iconInfo.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                    
                                    Text(task.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white) // 白色文本更适合深色背景
                                }
                            }
                            
                            Text("专注时长: \(Int(viewModel.activeTask?.duration ?? 0))分钟")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8)) // 白色文本更适合深色背景
                        }
                        .padding(.bottom, 50) // 增加底部间距
                        
                        // 倒计时显示
                        CircularProgressView(
                            progress: progress,
                            timeRemaining: String(format: "%02d:%02d", Int(viewModel.timeRemaining) / 60, Int(viewModel.timeRemaining) % 60),
                            taskTitle: "", // 不再在环内显示任务标题
                            endTime: endTimeString() // 传递结束时间
                        )
                        .frame(width: min(geometry.size.width - 80, 300), height: min(geometry.size.width - 80, 300))
                        .padding(.bottom, 30)
                        
                        // 停止方式展示 - 简化版本
                        if let task = viewModel.activeTask, let method = task.verificationMethod {
                            HStack(spacing: 6) {
                                Image(systemName: verificationMethodIcon(method))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("结束后需要\(verificationMethodName(method))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                        }
                        
                        // 停止吵闹按钮 - 只在计时器结束后显示
                        if isTimerEnded {
                            Button(action: {
                                // 进入随机验证界面
                                viewModel.playButtonSound() // 播放按钮音效
                                viewModel.isVerifying = true
                                navigationManager.navigate(to: .verification)
                            }) {
                                HStack {
                                    Image(systemName: "bell.slash.fill")
                                    Text("停止吵闹")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(buttonTextColor) // 使用主题按钮文本颜色
                                .frame(width: geometry.size.width * 0.7)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                )
                                .scaleEffect(1.05) // 稍微放大以引起注意
                            }
                            .padding(.bottom, 20)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.5), value: isTimerEnded)
                        }
                        
                        Spacer()
                        
                        // 底部按钮
                        HStack(spacing: 20) {
                            Button(action: {
                                // 显示确认对话框
                                if let task = viewModel.activeTask {
                                    let elapsedSeconds = task.duration * 60 - viewModel.timeRemaining
                                    let elapsedMinutes = max(1, Int(elapsedSeconds / 60))
                                    
                                    // 只有当经过了一定时间时才提示
                                    if elapsedMinutes > 1 {
                                        showTerminationAlert = true
                                    } else {
                                        // 如果几乎没有经过时间，直接取消
                                        viewModel.playCancelSound() // 播放取消音效
                                        viewModel.cancelTask()
                                        dismiss()
                                    }
                                } else {
                                    // 如果没有活动任务，直接取消
                                    viewModel.playCancelSound() // 播放取消音效
                                    viewModel.cancelTask()
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text("终止任务")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(buttonTextColor) // 使用主题按钮文本颜色
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    Capsule()
                                        .fill(buttonBackgroundGradient)
                                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                )
                            }
                            
                            Button(action: {
                                viewModel.playButtonSound() // 播放按钮音效
                                isShowingTimeAdjustment = true
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("调整时间")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(buttonTextColor) // 使用主题按钮文本颜色
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    Capsule()
                                        .fill(buttonBackgroundGradient)
                                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $isShowingTimeAdjustment) {
            TimeAdjustmentView(
                isPresented: $isShowingTimeAdjustment,
                currentTime: viewModel.timeRemaining,
                onTimeAdjusted: { newTime in
                    viewModel.updateTaskTime(by: newTime)
                }
            )
            .presentationDetents([.height(285), .fraction(0.4)]) // 增加高度以容纳更多内容，增加了5%
            .presentationDragIndicator(.visible) // 显示拖动指示器
        }
        .sheet(isPresented: $isShowingTaskList) {
            NewTaskView(isPresented: $isShowingTaskList)
        }
        .alert(isPresented: $showTerminationAlert) {
            Alert(
                title: Text("确认终止任务"),
                message: Text("您已完成\(elapsedTimeString)，将减少\(reducedTimeString)。\n系统会记录您已完成的时间。"),
                primaryButton: .destructive(Text("终止任务")) {
                    viewModel.playCancelSound() // 播放取消音效
                    viewModel.cancelTask()
                    dismiss()
                },
                secondaryButton: .cancel(Text("继续任务"))
            )
        }
    }
}

struct TimeAdjustmentView: View {
    @Binding var isPresented: Bool
    let currentTime: Int
    let onTimeAdjusted: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var timeAdjustment: Int = 0
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    // 计算当前最小可调整时间
    private var minimumAdjustment: Int {
        // 允许减少时间，但不能让调整值本身低于0
        return 0
    }
    
    // 获取当前任务
    private var currentTask: Task? {
        return viewModel.activeTask
    }
    
    // 获取原始设定时间
    private var originalDuration: Int {
        return currentTask?.originalDuration() ?? currentTime / 60
    }
    
    // 获取总调整时间
    private var totalAdjustment: Int {
        return currentTask?.totalTimeAdjustment() ?? 0
    }
    
    // 获取调整历史
    private var adjustmentHistory: [Int] {
        return currentTask?.timeAdjustments ?? []
    }
    
    // 根据主题获取背景渐变
    private var backgroundGradient: LinearGradient {
        if themeManager.currentTheme == .elegantPurple {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "483D8B").opacity(0.95),
                    Color(hex: "2E1A47")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.jadeGreen.opacity(0.9),
                    AppColors.jadeGreen
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 获取按钮文本颜色
    private var buttonTextColor: Color {
        if themeManager.currentTheme == .elegantPurple {
            return Color(hex: "483D8B") // 深紫色文字
        } else {
            return AppColors.jadeGreen // 墨绿色文字
        }
    }
    
    var body: some View {
        ZStack {
            // 背景层 - 使用渐变增强设计感
            backgroundGradient
            .edgesIgnoringSafeArea(.all)
            
            // 内容层 - 精简布局以适应30%高度的弹窗
            VStack(spacing: 12) {
                // 任务原始时间和调整历史信息 - 改为更紧凑的横向布局
                VStack(spacing: 8) {
                    // 原始设定、调整后时间和调整差值都在一行显示
                    HStack(spacing: 12) {
                        // 原始设定时间
                        HStack(spacing: 4) {
                            Text("原始:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("\(originalDuration)分钟")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // 调整后时间(实时显示)
                        HStack(spacing: 4) {
                            Text("调整后:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                            
                            // 显示调整后的分钟数
                            Text("\(originalDuration + timeAdjustment)分钟")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(timeAdjustment > 0 ? .green : (timeAdjustment < 0 ? .red : .white))
                        }
                        
                        Spacer()
                        
                        // 即时调整值
                        HStack(spacing: 2) {
                            Text(timeAdjustment > 0 ? "+\(timeAdjustment)" : "\(timeAdjustment)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(timeAdjustment > 0 ? .green : (timeAdjustment < 0 ? .red : .white))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(timeAdjustment > 0 ? Color.green.opacity(0.2) : (timeAdjustment < 0 ? Color.red.opacity(0.2) : Color.clear))
                                )
                                .opacity(timeAdjustment == 0 ? 0 : 1)
                        }
                    }
                    
                    // 累计调整和结束时间放在一行
                    HStack {
                        // 总调整时间
                        HStack(spacing: 4) {
                            Text("累计调整:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(totalAdjustment > 0 ? "+\(totalAdjustment)" : "\(totalAdjustment)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(totalAdjustment > 0 ? .green : (totalAdjustment < 0 ? .red : .white))
                        }
                        
                        Spacer()
                        
                        // 结束时间
                        HStack(spacing: 4) {
                            Text("结束时间:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(endTimeString(from: currentTime + timeAdjustment * 60))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 调整历史记录 - 如果有历史记录，才显示
                    if !adjustmentHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("调整历史:")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                            
                            // 使用固定高度的滚动视图确保不会占用太多空间
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(adjustmentHistory.indices, id: \.self) { index in
                                        let adjustment = adjustmentHistory[index]
                                        Text(adjustment > 0 ? "+\(adjustment)" : "\(adjustment)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(adjustment > 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                            )
                                    }
                                }
                            }
                            .frame(height: 24) // 减小高度以节省空间
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
                
                // 自定义时间调整控件
                VStack(spacing: 5) {
                    // 自定义加减按钮
                    HStack(spacing: 35) {
                        Spacer()
                        
                        // 减少按钮
                        Button(action: {
                            viewModel.playButtonSound()
                            // 确保调整后的总时间不会小于1分钟
                            let currentMinutes = currentTime / 60
                            let adjustedMinutes = currentMinutes + timeAdjustment - 5
                            
                            if adjustedMinutes >= 1 {
                                timeAdjustment -= 5
                            } else {
                                // 计算可以减少的最大值，确保总时间至少为1分钟
                                let maxReduction = currentMinutes + timeAdjustment - 1
                                if maxReduction > 0 {
                                    timeAdjustment -= maxReduction
                                }
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        // 数值显示
                        Text("\(timeAdjustment)")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                            .frame(minWidth: 75)
                            .multilineTextAlignment(.center)
                        
                        // 增加按钮
                        Button(action: {
                            viewModel.playButtonSound()
                            if timeAdjustment < 120 {
                                timeAdjustment += 5
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10) // 减小垂直padding
                }
                .padding(.horizontal)
                .padding(.vertical, 10) // 减小垂直padding
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // 按钮区域和调整后时间
                VStack(spacing: 12) { // 减小间距
                    // 按钮区域
                    HStack(spacing: 30) { // 减小按钮间距
                        // 取消按钮
                        Button(action: {
                            viewModel.playCancelSound() // 播放取消音效
                            timeAdjustment = 0
                            isPresented = false
                            dismiss()
                        }) {
                            Text("取消")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(buttonTextColor)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                        
                        // 确定按钮
                        Button(action: {
                            viewModel.playSuccessSound() // 播放确认音效
                            onTimeAdjusted(timeAdjustment)
                            isPresented = false
                            dismiss()
                        }) {
                            Text("确定")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(buttonTextColor)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16) // 减小整体垂直padding
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func endTimeString(from seconds: Int) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if seconds <= 0 {
            return "已完成"
        }
        
        if let endTime = calendar.date(byAdding: .second, value: seconds, to: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: endTime)
        }
        
        return ""
    }
}

#Preview {
    FocusTimerView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 