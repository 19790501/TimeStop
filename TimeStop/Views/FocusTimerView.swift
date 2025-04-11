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
    
    private var progress: Double {
        guard let task = viewModel.activeTask else { return 0 }
        return Double(viewModel.timeRemaining) / (Double(task.duration) * 60.0)
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
                                // 取消当前任务并返回主页
                                viewModel.playCancelSound() // 播放取消音效
                                viewModel.cancelTask()
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("新任务")
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
                                    Text("计划有变")
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
            .presentationDetents([.fraction(0.3)]) // 只占屏幕高度的30%
            .presentationDragIndicator(.visible) // 显示拖动指示器
        }
        .sheet(isPresented: $isShowingTaskList) {
            NewTaskView(isPresented: $isShowingTaskList)
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
            VStack(spacing: 20) {
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
                    .padding(.vertical, 12)
                }
                .padding(.horizontal)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // 按钮区域和调整后时间
                VStack(spacing: 15) {
                    // 调整后时间显示
                    Text("结束时间: \(endTimeString(from: currentTime + timeAdjustment * 60))")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, -5)
                    
                    // 按钮区域
                    HStack(spacing: 35) {
                        // 取消按钮
                        Button(action: {
                            viewModel.playCancelSound() // 播放取消音效
                            timeAdjustment = 0
                            isPresented = false
                            dismiss()
                        }) {
                            Text("取消")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(buttonTextColor)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
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
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(buttonTextColor)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
                .padding(.top, 5)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 22)
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