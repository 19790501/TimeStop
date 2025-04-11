import SwiftUI
import AVFoundation

// 添加自定义任务结构体到文件顶层
struct FavoriteTask: Codable, Identifiable {
    var id = UUID() // 添加Identifiable支持
    var duration: Int = 25
    var taskType: String = "工作"
    var isEnabled: Bool = true
    
    static let empty = FavoriteTask(duration: 25, taskType: "工作", isEnabled: true)
    static let `default` = FavoriteTask(duration: 25, taskType: "工作", isEnabled: true)
}

// 定义任务类型到文件顶层
enum TaskType: String, CaseIterable {
    case meeting = "会议"
    case thinking = "思考"
    case work = "工作"
    case reading = "阅读"
    case life = "生活"
    case exercise = "运动"
    case relax = "摸鱼"
    case sleep = "睡觉"
    
    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .thinking: return "brain"
        case .work: return "briefcase.fill"
        case .reading: return "book.fill"
        case .life: return "heart.fill"
        case .exercise: return "figure.run"
        case .relax: return "fish"
        case .sleep: return "bed.double.fill"
        }
    }
    
    // 基础颜色，不依赖于ThemeManager
    var color: Color {
        switch self {
        case .meeting: return .blue
        case .thinking: return Color(UIColor.systemPink) // 使用系统粉色作为备用
        case .work: return .indigo
        case .reading: return .orange
        case .life: return .pink
        case .exercise: return .green
        case .relax: return .cyan
        case .sleep: return .purple
        }
    }
    
    // 映射到Task.FocusType
    var focusType: Task.FocusType {
        switch self {
        case .meeting, .thinking, .work:
            return .productivity
        case .reading, .life:
            return .writing
        case .exercise:
            return .success
        case .relax, .sleep:
            return .audio
        }
    }
}

struct CreateTaskView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    // MARK: - State Properties
    @State private var selectedTaskType: TaskType = .work
    @State private var selectedTimeMode: TimeMode = .minutes
    @State private var selectedMinutes: Int = 30 // 分钟滑块值（0-59）
    @State private var selectedHours: Int = 0    // 小时滑块值（0-12）
    @State private var maxMinutes: Int = 59      // 分钟滑块最大值
    @State private var maxHours: Int = 12        // 小时滑块最大值
    @State private var isShowingTimerClocks: Bool = false  // 确保初始状态为隐藏
    @State private var isDraggingSlider: Bool = false
    @State private var isButtonPressed: Bool = false
    
    // 常用任务相关状态
    @State private var showingFavoriteTaskSetup: Bool = false
    @State private var editingFavoriteTask: FavoriteTask = FavoriteTask.default
    @State private var selectedFavoriteTaskIndex: Int = 0
    @State private var favoriteTasks: [FavoriteTask] = [
        FavoriteTask.default,
        FavoriteTask.default,
        FavoriteTask.default
    ]
    
    @State private var hapticImpact = UIImpactFeedbackGenerator(style: .rigid)
    
    // 初始化默认的常用任务
    init() {
        // 加载保存的自定义任务
        _favoriteTasks = State(initialValue: [
            FavoriteTask(duration: 25, taskType: "工作", isEnabled: true),
            FavoriteTask(duration: 10, taskType: "摸鱼", isEnabled: true),
            FavoriteTask(duration: 30, taskType: "阅读", isEnabled: true)
        ])
    }
    
    // 修改 updateMinutesFromDrag 方法 - 简化日志
    private func updateMinutesFromDrag(value: DragGesture.Value) {
        // 立即设置拖动状态，禁用滚动
        isDraggingSlider = true
        
        let screenWidth = (UIScreen.main.bounds.width - 50) * 0.85 // 与显示宽度保持一致
        
        // 计算百分比位置
        var percentage = min(value.location.x / screenWidth, 1.0)
        percentage = max(0, percentage)
        
        // 按5分钟的步进计算分钟数
        let rawMinutes = Int(percentage * CGFloat(maxMinutes))
        let newMinutes = (rawMinutes / 5) * 5
        
        // 仅当值发生变化时才播放反馈和更新状态
        if selectedMinutes != newMinutes {
            // 播放触觉反馈
            playFeedback()
            
            // 更新状态
            selectedMinutes = min(newMinutes, maxMinutes)
        }
        
        // 设置当前时间模式
        selectedTimeMode = .minutes
        
        // 显示时间显示器
        if !isShowingTimerClocks {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingTimerClocks = true
            }
        }
    }
    
    // 修改 updateHoursFromDrag 方法
    private func updateHoursFromDrag(value: DragGesture.Value) {
        // 立即设置拖动状态，禁用滚动
        isDraggingSlider = true
        
        let screenWidth = (UIScreen.main.bounds.width - 50) * 0.85 // 与显示宽度保持一致
        
        // 计算百分比位置
        var percentage = min(value.location.x / screenWidth, 1.0)
        percentage = max(0, percentage)
        
        // 计算小时数
        let rawHours = Int(percentage * CGFloat(maxHours))
        
        // 仅当值发生变化时才播放反馈和更新状态
        if selectedHours != rawHours {
            // 播放触觉反馈
            playFeedback()
            
            // 更新状态
            selectedHours = min(rawHours, maxHours)
        }
        
        // 设置当前时间模式
        selectedTimeMode = .hours
        
        // 显示时间显示器
        if !isShowingTimerClocks {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingTimerClocks = true
            }
        }
    }
    
    // 在 body 中的显示代码，确保条件正确
    var body: some View {
        ZStack(alignment: .top) { // 设置整个ZStack为顶部对齐
            // Background
            themeManager.colors.background
                .edgesIgnoringSafeArea(.all)
            
            // Main content - 保持在下层
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部标题区域合并
                    VStack(spacing: 5) {
                        Text("TimeStop")
                            .font(.custom("PingFangSC-Thin", size: 36))
                            .tracking(2)
                            .foregroundColor(Color.black.opacity(0.6))
                            .shadow(color: .white.opacity(0.3), radius: 1, x: 1, y: 1)
                        
                        Text("你需要的不是倒计时，而是\"停止力\"")
                            .font(.system(size: 14, weight: .regular))
                            .italic()
                            .foregroundColor(AppColors.pureBlack.opacity(0.7))
                            .padding(.top, 4)
                        
                        Text("You don't need a countdown, but the \"Power to Stop\"")
                            .font(.system(size: 12, weight: .light))
                            .italic()
                            .foregroundColor(AppColors.pureBlack.opacity(0.5))
                            .padding(.top, 2)
                    }
                    .padding(.top, 40) // 从50减少到40，整体内容上移10点
                    .padding(.bottom, 20)
                    
                    // 内容区域
                    VStack(spacing: 15) {
                        // 任务类型选择区
                        VStack(alignment: .leading, spacing: 10) {
                            Text("选择任务")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.text)
                            
                            // 任务类型网格
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(TaskType.allCases, id: \.self) { type in
                                    TaskTypeButton(
                                        type: type,
                                        isSelected: selectedTaskType == type,
                                        themeManager: themeManager,
                                        onTap: {
                                            viewModel.playButtonSound() // 恢复按钮声音
                                            selectedTaskType = type
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 10) // 从5点增加到10点，让第一个时间滑块再下移5点
                        
                        // 时间选择区域 - 简化结构
                        VStack(spacing: 15) {
                            // 分钟时长选择区
                            TimeSlider(
                                title: "分钟",
                                subtitle: "时间缝纫鸡",
                                value: selectedMinutes,
                                maxValue: maxMinutes,
                                isSelected: selectedTimeMode == .minutes,
                                unit: "分钟",
                                step: 5,
                                onValueChanged: { value in
                                    updateMinutesFromDrag(value: value)
                                },
                                onTap: {
                                    selectedTimeMode = .minutes
                                },
                                onDragEnded: {
                                    handleDragEnded()
                                }
                            )
                            
                            Spacer().frame(height: 5)
                            
                            // 小时时长选择区
                            TimeSlider(
                                title: "小时",
                                subtitle: "时间吞金兽",
                                value: selectedHours,
                                maxValue: maxHours,
                                isSelected: selectedTimeMode == .hours,
                                unit: "小时",
                                step: 1,
                                onValueChanged: { value in
                                    updateHoursFromDrag(value: value)
                                },
                                onTap: {
                                    selectedTimeMode = .hours
                                },
                                onDragEnded: {
                                    handleDragEnded()
                                }
                            )
                        }
                        
                        Spacer().frame(height: 5) // 从10点减少到5点，使常用任务模块往上移动5点
                        
                        // 常用任务模块
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .lastTextBaseline) {
                                Text("常用任务")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Text("点击开始任务 / 长按2秒自定义")
                                    .font(.system(size: 11))
                                    .foregroundColor(themeManager.colors.secondaryText)
                                    .padding(.leading, 8)
                            }
                            
                            // 始终显示常用任务图标，不再使用if条件
                            HStack(spacing: 6) {
                                ForEach(0..<3) { index in
                                    FavoriteTaskButton(
                                        task: favoriteTasks[index],
                                        onTap: {
                                            let favoriteTask = favoriteTasks[index]
                                            if favoriteTask.isEnabled {
                                                let taskType = TaskType.allCases.first(where: { $0.rawValue == favoriteTask.taskType }) ?? .work
                                                
                                                viewModel.createTaskWithVerification(
                                                    title: taskType.rawValue,
                                                    duration: favoriteTask.duration,
                                                    focusType: taskType.focusType
                                                )
                                                
                                                if let newTask = viewModel.tasks.last {
                                                    viewModel.startTask(newTask)
                                                }
                                                
                                                viewModel.playSuccessSound()
                                            }
                                        },
                                        onLongPress: {
                                            hapticImpact.impactOccurred()
                                            editingFavoriteTask = favoriteTasks[index]
                                            selectedFavoriteTaskIndex = index
                                            showingFavoriteTaskSetup = true
                                        },
                                        themeManager: themeManager
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 33) // 从48减少到33，使开始任务按钮往上移动15点
                    
                    // 开始任务按钮
                    Button(action: {
                        isButtonPressed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isButtonPressed = false
                            startTask()
                        }
                    }) {
                        StartTaskButtonContent(isButtonPressed: isButtonPressed)
                    }
                }
                .padding(.horizontal, 25)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 5) // 从10点减小到5点
                }
            }
            .scrollDisabled(isDraggingSlider) // 在滑块拖动时禁用滚动
            .zIndex(1)
            
            // 时间显示器 - 完全分离的固定位置覆盖层
            if isShowingTimerClocks {
                Color.clear
                    .contentShape(Rectangle())
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingTimerClocks = false
                        }
                    }
                    .overlay(
                        timeClockView()
                            .padding(.top, 45)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top))
                        , alignment: .top
                    )
                    .zIndex(100)
            }
        }
        
        .sheet(isPresented: $showingFavoriteTaskSetup) {
            FavoriteTaskSetupView(
                task: $editingFavoriteTask,
                onSave: { updatedTask in
                    if selectedFavoriteTaskIndex >= 0 && selectedFavoriteTaskIndex < favoriteTasks.count {
                        favoriteTasks[selectedFavoriteTaskIndex] = updatedTask
                        saveFavoriteTasks()
                    }
                },
                onStart: { task in
                    let taskType = TaskType.allCases.first(where: { $0.rawValue == task.taskType }) ?? .work
                    let taskTitle = taskType.rawValue
                    
                    viewModel.createTaskWithVerification(
                        title: taskTitle,
                        duration: task.duration,
                        focusType: taskType.focusType
                    )
                    
                    if let newTask = viewModel.tasks.last {
                        viewModel.startTask(newTask)
                    }
                    
                    viewModel.playSuccessSound()
                }
            )
        }
        .onAppear {
            // 确保初始状态时间显示器隐藏
            self.isShowingTimerClocks = false
            
            // 初始化触觉反馈生成器
            hapticImpact.prepare()
            
            // 加载保存的常用任务
            loadFavoriteTasks()
        }
    }
    
    // MARK: - Helper Methods
    
    // 获取任务类型的主题相关颜色
    private func getThemeColor(for type: TaskType) -> Color {
        switch type {
        case .thinking:
            return themeManager.colors.primary
        default:
            return type.color
        }
    }
    
    // 向CreateTaskView结构体中添加持久化功能
    private func saveFavoriteTasks() {
        if let encoded = try? JSONEncoder().encode(favoriteTasks) {
            UserDefaults.standard.set(encoded, forKey: "favoriteTasks")
        }
    }
    
    private func loadFavoriteTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "favoriteTasks"),
           let decodedTasks = try? JSONDecoder().decode([FavoriteTask].self, from: savedTasks) {
            favoriteTasks = decodedTasks
        }
    }
    
    // 播放滑块声音和触觉反馈
    private func playFeedback() {
        // 播放系统声音
        AudioServicesPlaySystemSound(1519) // 标准系统声音
        
        // 播放App内声音
        viewModel.playButtonSound()
        
        // 触觉反馈
        hapticImpact.impactOccurred(intensity: 0.6)
    }
    
    // 时间模式枚举
    private enum TimeMode {
        case minutes
        case hours
    }

    // 计算属性 - 总时长（分钟）
    private var totalDurationMinutes: Int {
        return selectedHours * 60 + selectedMinutes
    }
    
    // 计算属性 - 时长显示字符串
    private func durationTimeString() -> String {
        let hours = selectedHours
        let minutes = selectedMinutes
        
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    // 计算结束时间
    private func endTimeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // 使用总时长计算结束时间
        let minutes = totalDurationMinutes
        
        // 计算结束时间
        if let endTime = calendar.date(byAdding: .minute, value: minutes, to: now) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: endTime)
        }
        
        return "--:--"
    }
    
    // 简化拖动结束处理逻辑
    private func handleDragEnded() {
        // 即刻允许滚动，不再延迟
        isDraggingSlider = false
        
        // 延迟隐藏时钟显示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isShowingTimerClocks = false
            }
        }
    }
    
    // 时钟显示组件
    private func timeClockView() -> some View {
        ZStack {
            // 根据主题选择背景颜色
            let backgroundColor = themeManager.currentTheme == .elegantPurple ? 
                Color(hex: "483D8B") : // 深紫色
                Color(red: 0.08, green: 0.28, blue: 0.22) // 墨绿色
            
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
            
            HStack(spacing: 30) {
                // 左侧显示用户选择的时长
                VStack(spacing: 4) {
                    Text("任务时长")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(durationTimeString())
                        .font(.system(size: 40, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false) // 确保文本完全显示
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                // 右侧显示结束时间点
                VStack(spacing: 4) {
                    Text("结束时间")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(endTimeString())
                        .font(.system(size: 40, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false) // 确保文本完全显示
                }
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 20)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // 添加 startTask 函数
    private func startTask() {
        viewModel.playSuccessSound()
        
        let taskTitle = selectedTaskType.rawValue
        let duration = totalDurationMinutes // 使用总时长
        
        viewModel.createTaskWithVerification(
            title: taskTitle, 
            duration: duration, 
            focusType: selectedTaskType.focusType
        )
        
        if let newTask = viewModel.tasks.last {
            viewModel.startTask(newTask)
        }
    }
}

// 扩展用于实现部分圆角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// 添加常用任务设置视图
struct FavoriteTaskSetupView: View {
    @Binding var task: FavoriteTask
    var onSave: (FavoriteTask) -> Void
    var onStart: (FavoriteTask) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var localTask: FavoriteTask
    @State private var durationText: String = ""
    @State private var selectedTaskType: TaskType
    @EnvironmentObject var themeManager: ThemeManager
    
    // 根据主题选择背景颜色
    private var backgroundColor: Color {
        themeManager.currentTheme == .elegantPurple ?
            Color(hex: "483D8B") : // 深紫色
            Color(red: 0.08, green: 0.28, blue: 0.22) // 墨绿色
    }
    
    init(task: Binding<FavoriteTask>, onSave: @escaping (FavoriteTask) -> Void, onStart: @escaping (FavoriteTask) -> Void) {
        self._task = task
        self.onSave = onSave
        self.onStart = onStart
        self._localTask = State(initialValue: task.wrappedValue)
        self._durationText = State(initialValue: "\(task.wrappedValue.duration)")
        
        // 设置初始任务类型
        if let type = TaskType.allCases.first(where: { $0.rawValue == task.wrappedValue.taskType }) {
            self._selectedTaskType = State(initialValue: type)
        } else {
            self._selectedTaskType = State(initialValue: .work)
        }
    }
    
    var body: some View {
        ZStack {
            // 使用主题响应背景色
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 18) {
                // 移除标题
                // Text("常用任务设置")
                //    .font(.system(size: 20, weight: .medium))
                //    .foregroundColor(.white)
                //    .padding(.top, 16)
                
                // 顶部空间
                Spacer().frame(height: 10)
                
                // 1. 任务类型选择网格 - 移除标题文字
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(TaskType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedTaskType = type
                            localTask.taskType = type.rawValue
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(selectedTaskType == type ? 
                                        type.color : 
                                        Color.white.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                    .overlay(
                                        Image(systemName: type.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedTaskType == type ? .white : .white.opacity(0.85))
                                    )
                                    .shadow(color: selectedTaskType == type ? type.color.opacity(0.5) : .clear, radius: 4, x: 0, y: 2)
                                
                                Text(type.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedTaskType == type ? 
                                        type.color.opacity(0.15) : 
                                        Color.clear)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 2. 时长输入
                VStack(alignment: .leading, spacing: 10) {
                    Text("自定义")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    
                    HStack {
                        TextField("", text: $durationText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20, weight: .medium))
                            .frame(width: 100, height: 50)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(10)
                            .onChange(of: durationText) { newValue in
                                if let duration = Int(newValue), duration > 0 {
                                    localTask.duration = min(duration, 600)
                                    if duration > 600 {
                                        durationText = "600"
                                    }
                                }
                            }
                        
                        Text("分钟")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.leading, 6)
                        
                        Spacer()
                    }
                    
                    Text("最大可设置600分钟")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.top, 5)
                
                Spacer()
                
                // 3. 保存按钮区 - 往上再移动3点
                HStack(spacing: 20) {
                    // 取消按钮
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .font(.system(size: 17))
                            .foregroundColor(backgroundColor)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    // 保存按钮
                    Button(action: {
                        // 确保任务时长有效
                        if let duration = Int(durationText), duration > 0 {
                            localTask.duration = min(duration, 600)
                            localTask.isEnabled = true
                            onSave(localTask)
                            dismiss()
                        }
                    }) {
                        Text("保存")
                            .font(.system(size: 17))
                            .foregroundColor(backgroundColor)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 17) // 从20减少到17，按钮再往上移动3点
            }
        }
        .presentationDetents([.height(400)]) // 从410点改回400点
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CreateTaskView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 