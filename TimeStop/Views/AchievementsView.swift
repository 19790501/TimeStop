import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: Int = 0 // 默认选择"今日"标签
    @State private var showRandomDataAlert = false
    @State private var showComparisonDetail = false
    @State private var selectedComparisonType: ActivityType? = nil
    @State private var refreshTimer: Timer?
    
    enum ViewTab: Int {
        case today = 0
        case week = 1
    }
    
    var body: some View {
        ZStack {
            // 背景层
            VStack(spacing: 0) {
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
                // 标题
                Text("时间去哪了")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 45)
                
                // 标签选择器，只保留今日和本周
                HStack(spacing: 12) {
                    ForEach([ViewTab.today, .week], id: \.rawValue) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab.rawValue
                            }
                        }) {
                            Text(tabTitle(for: tab))
                                .font(.system(size: 15))
                                .foregroundColor(selectedTab == tab.rawValue ? .black : .black.opacity(0.4))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == tab.rawValue ? .white : .clear)
                                        .shadow(color: selectedTab == tab.rawValue ? .black.opacity(0.08) : .clear, radius: 6, x: 0, y: 3)
                                )
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.03))
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                // 随机数据测试按钮
                Button(action: {
                    showRandomDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 14))
                        Text("生成随机数据")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.8))
                    )
                }
                .padding(.top, 8)
                
                // 显示下次刷新时间（简化版）
                HStack {
                    Spacer()
                    Text("下次刷新: \(timeToNextRefresh)")
                        .font(.system(size: 11.5))
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12) // 增加顶部间距，往下移5点
                
                // 内容区域
                if selectedTab == ViewTab.today.rawValue {
                    if taskTypeStats.isEmpty {
                        emptyStateView()
                            .padding(.top, 40)
                    } else {
                        // 统计卡片固定在上方
                        VStack(spacing: 0) {
                            // 统计卡片
                            HStack(spacing: 12) {
                                summaryItem(
                                    value: "\(todayTasks.count)",
                                    label: "任务数量",
                                    icon: "checkmark.circle.fill"
                                )
                                
                                summaryItem(
                                    value: "\(todayTotalTime)",
                                    label: "总时长",
                                    unit: "分钟",
                                    icon: "clock.fill"
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            // 其余内容可滚动
                            ScrollView {
                                VStack(spacing: 24) {
                                    // 今日头条：超过阈值的任务类型
                                    if let overThresholdType = overThresholdTaskTypes.randomElement() {
                                        let (emoji, title, description) = overThresholdType.type.maxDescription()
                                        insightCard(
                                            emoji: emoji,
                                            taskType: overThresholdType.type,
                                            title: title,
                                            minutes: overThresholdType.minutes,
                                            description: description,
                                            isMax: true
                                        )
                                        .padding(.horizontal, 20)
                                    } else if !taskTypeStats.isEmpty {
                                        // 如果没有超过阈值的任务类型，但有任务数据
                                        let placeholderType = taskTypeStats.first!.type
                                        insightCard(
                                            emoji: "⏱️",
                                            taskType: placeholderType,
                                            title: "时间管理达人",
                                            minutes: 0,
                                            description: "您的所有任务时间都很合理，请继续保持良好习惯",
                                            isMax: true
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    // 今日辣条：低于阈值的任务类型
                                    if let underThresholdType = underThresholdTaskTypes.randomElement() {
                                        let (emoji, title, description) = underThresholdType.type.minDescription()
                                        insightCard(
                                            emoji: emoji,
                                            taskType: underThresholdType.type,
                                            title: title,
                                            minutes: underThresholdType.minutes,
                                            description: description,
                                            isMax: false
                                        )
                                        .padding(.horizontal, 20)
                                    } else if !taskTypeStats.isEmpty {
                                        // 如果没有低于阈值的任务类型，但有任务数据
                                        let placeholderType = taskTypeStats.first!.type
                                        insightCard(
                                            emoji: "🎯",
                                            taskType: placeholderType,
                                            title: "精准时间分配",
                                            minutes: 0,
                                            description: "您没有时间不足的任务类型，各项任务分配均衡",
                                            isMax: false
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    // 任务类型时间排行
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("今日时间排行")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black.opacity(0.8))
                                            .padding(.horizontal, 20)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(taskTypeStats, id: \.type) { stat in
                                                taskTypeRow(type: stat.type, minutes: stat.minutes)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    Spacer(minLength: 80)
                                }
                                .padding(.top, 16)
                            }
                        }
                    }
                } else {
                    if weekTaskTypeStats.isEmpty {
                        emptyStateView()
                            .padding(.top, 40)
                    } else {
                        // 本周视图固定统计卡片
                        VStack(spacing: 0) {
                            // 统计卡片
                            HStack(spacing: 12) {
                                if let mostIncreased = mostIncreasedTaskType {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.forward")
                                                .font(.system(size: 14))
                                                .foregroundColor(.green.opacity(0.8))
                                            Text("上升状元（同比上周）")
                                                .font(.system(size: 12, weight: .regular, design: .default).italic())
                                                .foregroundColor(.black.opacity(0.5))
                                        }
                                        
                                        HStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(mostIncreased.type.color.opacity(0.15))
                                                    .frame(width: 32, height: 32)
                                                
                                                Image(systemName: mostIncreased.type.icon)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(mostIncreased.type.color)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mostIncreased.type.rawValue)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.black.opacity(0.8))
                                                
                                                HStack(spacing: 2) {
                                                    Text("+\(mostIncreased.change)分钟")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.green)
                                                }
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
                                    .onTapGesture {
                                        selectedComparisonType = mostIncreased.type
                                        showComparisonDetail = true
                                    }
                                } else {
                                    summaryItem(
                                        value: "暂无数据",
                                        label: "本周上升状元",
                                        icon: "arrow.up.forward"
                                    )
                                }
                                
                                if let mostDecreased = mostDecreasedTaskType {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.down.forward")
                                                .font(.system(size: 14))
                                                .foregroundColor(.red.opacity(0.8))
                                            Text("下滑麻瓜（同比上周）")
                                                .font(.system(size: 12, weight: .regular, design: .default).italic())
                                                .foregroundColor(.black.opacity(0.5))
                                        }
                                        
                                        HStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(mostDecreased.type.color.opacity(0.15))
                                                    .frame(width: 32, height: 32)
                                                
                                                Image(systemName: mostDecreased.type.icon)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(mostDecreased.type.color)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mostDecreased.type.rawValue)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.black.opacity(0.8))
                                                
                                                HStack(spacing: 2) {
                                                    Text("\(mostDecreased.change)分钟")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.red)
                                                }
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
                                    .onTapGesture {
                                        selectedComparisonType = mostDecreased.type
                                        showComparisonDetail = true
                                    }
                                } else {
                                    summaryItem(
                                        value: "暂无数据",
                                        label: "本周下滑麻瓜",
                                        icon: "arrow.down.forward"
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            // 其余内容可滚动
                            ScrollView {
                                VStack(spacing: 24) {
                                    // 最多时间类型展示
                                    if let maxType = weekTaskTypeStats.first {
                                        let (emoji, title, description) = maxType.type.weekMaxDescription()
                                        insightCard(
                                            emoji: emoji,
                                            taskType: maxType.type,
                                            title: title,
                                            minutes: maxType.minutes,
                                            description: description,
                                            isMax: true,
                                            prefix: "下周建议"
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    // 最少时间类型展示
                                    if let minType = weekTaskTypeStats.last, weekTaskTypeStats.count > 1 {
                                        let (emoji, title, description) = minType.type.weekMinDescription()
                                        insightCard(
                                            emoji: emoji,
                                            taskType: minType.type,
                                            title: title,
                                            minutes: minType.minutes,
                                            description: description,
                                            isMax: false,
                                            prefix: "下周建议"
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    // 任务类型时间排行
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("本周时间排行")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.black.opacity(0.8))
                                            .padding(.horizontal, 20)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(weekTaskTypeStats, id: \.type) { stat in
                                                taskTypeRow(type: stat.type, minutes: stat.minutes)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    
                                    Spacer(minLength: 80)
                                }
                                .padding(.top, 16)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .alert(isPresented: $showRandomDataAlert) {
            Alert(
                title: Text("生成随机数据"),
                message: Text("将生成8种任务类型的随机时间数据，用于测试展示效果"),
                primaryButton: .default(Text("确定")) {
                    generateRandomData()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .sheet(isPresented: $showComparisonDetail, onDismiss: {
            selectedComparisonType = nil
        }) {
            if let selectedType = selectedComparisonType {
                NavigationView {
                    ComparisonDetailView(taskType: selectedType)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    // 刷新定时器相关方法
    private func startRefreshTimer() {
        // 首次出现时立即刷新一次
        refreshData()
        
        // 启动定时器，每分钟检查一次是否需要刷新
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            checkAndRefresh()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func checkAndRefresh() {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // 检查是否是需要刷新的时间点：11:30, 17:30, 20:30
        if (hour == 11 || hour == 17 || hour == 20) && minute == 30 {
            refreshData()
        }
    }
    
    private func refreshData() {
        // 随机生成数据用于测试，实际应用中可能是加载最新数据
        generateRandomData()
    }
    
    // 计算距离下一次刷新的时间
    private var timeToNextRefresh: String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // 定义刷新时间点
        let refreshTimes = [(11, 30), (17, 30), (20, 30)]
        
        // 计算下一个刷新时间点
        var nextRefreshComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        var foundNextRefresh = false
        
        for (h, m) in refreshTimes {
            if h > hour || (h == hour && m > minute) {
                nextRefreshComponents.hour = h
                nextRefreshComponents.minute = m
                foundNextRefresh = true
                break
            }
        }
        
        // 如果当前时间已经超过了所有刷新点，那么下一个刷新点是明天的第一个
        if !foundNextRefresh {
            nextRefreshComponents.hour = refreshTimes[0].0
            nextRefreshComponents.minute = refreshTimes[0].1
            
            // 如果是明天的刷新点
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: now) {
                nextRefreshComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                nextRefreshComponents.hour = refreshTimes[0].0
                nextRefreshComponents.minute = refreshTimes[0].1
            }
        }
        
        nextRefreshComponents.second = 0
        
        // 计算时间差
        if let nextRefreshDate = calendar.date(from: nextRefreshComponents) {
            let diff = calendar.dateComponents([.hour, .minute], from: now, to: nextRefreshDate)
            if let hour = diff.hour, let minute = diff.minute {
                return "\(hour)小时\(minute)分钟"
            }
        }
        
        return "未知"
    }
    
    // 今日详情视图
    private var todayDetailView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 统计卡片
                HStack(spacing: 12) {
                    summaryItem(
                        value: "\(todayTasks.count)",
                        label: "任务数量",
                        icon: "checkmark.circle.fill"
                    )
                    
                    summaryItem(
                        value: "\(todayTotalTime)",
                        label: "总时长",
                        unit: "分钟",
                        icon: "clock.fill"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // 今日头条：超过阈值的任务类型
                if let overThresholdType = overThresholdTaskTypes.randomElement() {
                    let (emoji, title, description) = overThresholdType.type.maxDescription()
                    insightCard(
                        emoji: emoji,
                        taskType: overThresholdType.type,
                        title: title,
                        minutes: overThresholdType.minutes,
                        description: description,
                        isMax: true
                    )
                    .padding(.horizontal, 20)
                } else if !taskTypeStats.isEmpty {
                    // 如果没有超过阈值的任务类型，但有任务数据
                    let placeholderType = taskTypeStats.first!.type
                    insightCard(
                        emoji: "⏱️",
                        taskType: placeholderType,
                        title: "时间管理达人",
                        minutes: 0,
                        description: "您的所有任务时间都很合理，请继续保持良好习惯",
                        isMax: true
                    )
                    .padding(.horizontal, 20)
                }
                
                // 今日辣条：低于阈值的任务类型
                if let underThresholdType = underThresholdTaskTypes.randomElement() {
                    let (emoji, title, description) = underThresholdType.type.minDescription()
                    insightCard(
                        emoji: emoji,
                        taskType: underThresholdType.type,
                        title: title,
                        minutes: underThresholdType.minutes,
                        description: description,
                        isMax: false
                    )
                    .padding(.horizontal, 20)
                } else if !taskTypeStats.isEmpty {
                    // 如果没有低于阈值的任务类型，但有任务数据
                    let placeholderType = taskTypeStats.first!.type
                    insightCard(
                        emoji: "🎯",
                        taskType: placeholderType,
                        title: "精准时间分配",
                        minutes: 0,
                        description: "您没有时间不足的任务类型，各项任务分配均衡",
                        isMax: false
                    )
                    .padding(.horizontal, 20)
                }
                
                // 任务类型时间排行
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日时间排行")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(taskTypeStats, id: \.type) { stat in
                            taskTypeRow(type: stat.type, minutes: stat.minutes)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 80)
            }
        }
    }
    
    // 本周详情视图
    private var weekDetailView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 统计卡片
                HStack(spacing: 12) {
                    if let mostIncreased = mostIncreasedTaskType {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green.opacity(0.8))
                                Text("上升状元（同比上周）")
                                    .font(.system(size: 12, weight: .regular, design: .default).italic())
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(mostIncreased.type.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: mostIncreased.type.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(mostIncreased.type.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mostIncreased.type.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black.opacity(0.8))
                                    
                                    HStack(spacing: 2) {
                                        Text("+\(mostIncreased.change)分钟")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.green)
                                    }
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
                        .onTapGesture {
                            selectedComparisonType = mostIncreased.type
                            showComparisonDetail = true
                        }
                    } else {
                        summaryItem(
                            value: "暂无数据",
                            label: "本周上升状元",
                            icon: "arrow.up.forward"
                        )
                    }
                    
                    if let mostDecreased = mostDecreasedTaskType {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.forward")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.8))
                                Text("下滑麻瓜（同比上周）")
                                    .font(.system(size: 12, weight: .regular, design: .default).italic())
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(mostDecreased.type.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: mostDecreased.type.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(mostDecreased.type.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mostDecreased.type.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black.opacity(0.8))
                                    
                                    HStack(spacing: 2) {
                                        Text("\(mostDecreased.change)分钟")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.red)
                                    }
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
                        .onTapGesture {
                            selectedComparisonType = mostDecreased.type
                            showComparisonDetail = true
                        }
                    } else {
                        summaryItem(
                            value: "暂无数据",
                            label: "本周下滑麻瓜",
                            icon: "arrow.down.forward"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // 最多时间类型展示
                if let maxType = weekTaskTypeStats.first {
                    let (emoji, title, description) = maxType.type.weekMaxDescription()
                    insightCard(
                        emoji: emoji,
                        taskType: maxType.type,
                        title: title,
                        minutes: maxType.minutes,
                        description: description,
                        isMax: true,
                        prefix: "下周建议"
                    )
                    .padding(.horizontal, 20)
                }
                
                // 最少时间类型展示
                if let minType = weekTaskTypeStats.last, weekTaskTypeStats.count > 1 {
                    let (emoji, title, description) = minType.type.weekMinDescription()
                    insightCard(
                        emoji: emoji,
                        taskType: minType.type,
                        title: title,
                        minutes: minType.minutes,
                        description: description,
                        isMax: false,
                        prefix: "下周建议"
                    )
                    .padding(.horizontal, 20)
                }
                
                // 任务类型时间排行
                VStack(alignment: .leading, spacing: 16) {
                    Text("本周时间排行")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(weekTaskTypeStats, id: \.type) { stat in
                            taskTypeRow(type: stat.type, minutes: stat.minutes)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 80)
            }
        }
    }
    
    // 任务类型行
    private func taskTypeRow(type: ActivityType, minutes: Int) -> some View {
        HStack(spacing: 14) {
            // 任务图标
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.85))
            }
            
            Spacer()
            
            Text("\(minutes)分钟")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black.opacity(0.65))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(type.color.opacity(0.15))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
    
    // 见解卡片
    private func insightCard(emoji: String, taskType: ActivityType, title: String, minutes: Int, description: String, isMax: Bool, prefix: String = "今日") -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(prefix == "今日" 
                     ? (isMax ? "今日头条" : "今日辣条") 
                     : prefix)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isMax ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                    )
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: taskType.icon)
                        .foregroundColor(taskType.color)
                    
                    Text(taskType.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(taskType.color.opacity(0.15))
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black.opacity(0.9))
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
                    .lineSpacing(4)
            }
            
            HStack {
                Spacer()
                Text("\(minutes)分钟")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(taskType.color)
                
                if prefix == "下周建议" {
                    Text(isMax ? "max↑" : "min↓")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isMax ? .green : .orange)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: taskType.color.opacity(0.1), radius: 15, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(taskType.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    // 按任务类型统计的时间，并排序 (今日)
    private var taskTypeStats: [(type: ActivityType, minutes: Int)] {
        var stats: [ActivityType: Int] = [:]
        
        // 初始化所有任务类型的时间为0
        for type in ActivityType.allCases {
            stats[type] = 0
        }
        
        // 累加每种类型的时间
        for task in todayTasks {
            if let type = ActivityType(rawValue: task.title) {
                stats[type, default: 0] += task.duration
            }
        }
        
        // 转换为数组并排序（从多到少）
        return stats.map { (type: $0.key, minutes: $0.value) }
            .filter { $0.minutes > 0 }
            .sorted(by: { $0.minutes > $1.minutes })
    }
    
    // 按任务类型统计的时间，并排序 (本周)
    private var weekTaskTypeStats: [(type: ActivityType, minutes: Int)] {
        var stats: [ActivityType: Int] = [:]
        
        // 初始化所有任务类型的时间为0
        for type in ActivityType.allCases {
            stats[type] = 0
        }
        
        // 累加每种类型的时间
        for task in weekTasks {
            if let type = ActivityType(rawValue: task.title) {
                stats[type, default: 0] += task.duration
            }
        }
        
        // 转换为数组并排序（从多到少）
        return stats.map { (type: $0.key, minutes: $0.value) }
            .filter { $0.minutes > 0 }
            .sorted(by: { $0.minutes > $1.minutes })
    }
    
    // 今日任务
    private var todayTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        return viewModel.tasks.filter { task in
            if task.isCompleted, let completedAt = task.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: now)
            }
            return false
        }
    }
    
    // 本周任务
    private var weekTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return viewModel.tasks.filter { task in
            if task.isCompleted, let completedAt = task.completedAt {
                return completedAt >= startOfWeek && completedAt < endOfWeek
            }
            return false
        }
    }
    
    // 今日总时间
    private var todayTotalTime: Int {
        todayTasks.reduce(0) { $0 + $1.duration }
    }
    
    // 本周总时间
    private var weekTotalTime: Int {
        weekTasks.reduce(0) { $0 + $1.duration }
    }
    
    private var filteredTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        let completedTasks = viewModel.tasks.filter { $0.isCompleted }
        
        switch selectedTab {
        case ViewTab.today.rawValue:
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: now)
                }
                return false
            }
        case ViewTab.week.rawValue:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return completedAt >= startOfWeek && completedAt < endOfWeek
                }
                return false
            }
        default:
            return []
        }
    }
    
    private var totalFocusTime: Int {
        filteredTasks.reduce(0) { $0 + $1.duration }
    }
    
    // 标签标题
    private func tabTitle(for tab: ViewTab) -> String {
        switch tab {
        case .today: return "今日"
        case .week: return "本周"
        }
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
                // 上部分荧光绿背景
                themeManager.colors.background
                    .frame(height: 240)

                // 修改后:
                // 上部分主题背景
                themeManager.colors.background
                    .frame(height: 240)
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
        VStack(spacing: 20) {
            Image(systemName: "hourglass")
                .font(.system(size: 50))
                .foregroundColor(.black.opacity(0.15))
            
            Text(selectedTab == ViewTab.today.rawValue ? "今日暂无时间记录" : "本周暂无时间记录")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
            
            Text("使用\"时停\"来记录你的时间去向！")
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
    
    // MARK: - Helper Methods
    
    // 随机生成测试数据
    private func generateRandomData() {
        // 清除现有任务
        viewModel.tasks.removeAll { task in
            task.isCompleted && Calendar.current.isDateInToday(task.completedAt ?? Date())
        }
        
        let taskTypes = ActivityType.allCases
        
        // 为每种任务类型生成随机数据
        for type in taskTypes {
            // 随机决定是生成超过阈值的数据还是低于阈值的数据
            let generateOverThreshold = Bool.random()
            
            // 根据任务类型和是否超过阈值确定时间范围
            var minutes: Int
            
            if generateOverThreshold {
                // 生成超过阈值的数据
                switch type {
                case .exercise: minutes = Int.random(in: 60...120)    // 运动
                case .sleep: minutes = Int.random(in: 500...600)      // 睡觉
                case .work: minutes = Int.random(in: 360...480)       // 工作
                case .life: minutes = Int.random(in: 120...180)       // 生活
                case .reading: minutes = Int.random(in: 90...150)     // 阅读
                case .relax: minutes = Int.random(in: 90...150)       // 摸鱼
                case .meeting: minutes = Int.random(in: 240...300)    // 会议
                case .thinking: minutes = Int.random(in: 180...240)   // 思考
                }
            } else {
                // 生成低于阈值的数据
                switch type {
                case .exercise: minutes = Int.random(in: 1...10)       // 运动
                case .sleep: minutes = Int.random(in: 180...240)       // 睡觉
                case .work: minutes = Int.random(in: 60...120)         // 工作
                case .life: minutes = Int.random(in: 5...15)           // 生活
                case .reading: minutes = Int.random(in: 5...15)        // 阅读
                case .relax: minutes = Int.random(in: 1...10)          // 摸鱼
                case .meeting: minutes = Int.random(in: 5...15)        // 会议
                case .thinking: minutes = Int.random(in: 5...20)       // 思考
                }
            }
            
            // 创建任务
            var completionDate = Date()
            // 随机设置完成时间在今天的不同时段
            let randomHours = Int.random(in: -12...0)
            let randomMinutes = Int.random(in: -59...0)
            completionDate = Calendar.current.date(byAdding: .hour, value: randomHours, to: completionDate) ?? completionDate
            completionDate = Calendar.current.date(byAdding: .minute, value: randomMinutes, to: completionDate) ?? completionDate
            
            // 获取对应的FocusType
            let focusType: Task.FocusType
            switch type {
            case .work, .meeting, .thinking:
                focusType = .productivity
            case .reading, .life:
                focusType = .writing
            case .exercise:
                focusType = .success
            case .relax, .sleep:
                focusType = .audio
            }
            
            let task = Task(
                id: UUID().uuidString,
                title: type.rawValue,
                focusType: focusType,
                duration: minutes,
                createdAt: Calendar.current.date(byAdding: .hour, value: -1, to: completionDate) ?? Date(),
                completedAt: completionDate,
                note: "随机生成的测试数据"
            )
            
            viewModel.tasks.append(task)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
    
    // 上周任务
    private var lastWeekTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        let endOfLastWeek = startOfThisWeek
        
        return viewModel.tasks.filter { task in
            if task.isCompleted, let completedAt = task.completedAt {
                return completedAt >= startOfLastWeek && completedAt < endOfLastWeek
            }
            return false
        }
    }
    
    // 按任务类型统计的时间，并排序 (上周)
    private var lastWeekTaskTypeStats: [(type: ActivityType, minutes: Int)] {
        var stats: [ActivityType: Int] = [:]
        
        // 初始化所有任务类型的时间为0
        for type in ActivityType.allCases {
            stats[type] = 0
        }
        
        // 累加每种类型的时间
        for task in lastWeekTasks {
            if let type = ActivityType(rawValue: task.title) {
                stats[type, default: 0] += task.duration
            }
        }
        
        // 转换为数组并排序（从多到少）
        return stats.map { (type: $0.key, minutes: $0.value) }
            .filter { $0.minutes > 0 }
            .sorted(by: { $0.minutes > $1.minutes })
    }
    
    // 计算每种任务类型本周相比上周的变化
    private var taskTypeChanges: [(type: ActivityType, thisWeek: Int, lastWeek: Int, change: Int)] {
        var changes: [ActivityType: (thisWeek: Int, lastWeek: Int, change: Int)] = [:]
        
        // 初始化所有任务类型的数据
        for type in ActivityType.allCases {
            changes[type] = (0, 0, 0)
        }
        
        // 收集本周数据
        for stat in weekTaskTypeStats {
            changes[stat.type]?.thisWeek = stat.minutes
        }
        
        // 收集上周数据并计算变化
        for stat in lastWeekTaskTypeStats {
            if var data = changes[stat.type] {
                data.lastWeek = stat.minutes
                data.change = data.thisWeek - data.lastWeek
                changes[stat.type] = data
            }
        }
        
        // 转换为数组并计算最终变化值
        return changes.map { (type: $0.key, thisWeek: $0.value.thisWeek, lastWeek: $0.value.lastWeek, change: $0.value.change) }
    }
    
    // 本周相比上周增长最多的任务类型
    private var mostIncreasedTaskType: (type: ActivityType, change: Int)? {
        let increasedTypes = taskTypeChanges
            .filter { $0.change > 0 }
            .sorted(by: { $0.change > $1.change })
        
        if let first = increasedTypes.first {
            return (first.type, first.change)
        }
        return nil
    }
    
    // 本周相比上周减少最多的任务类型
    private var mostDecreasedTaskType: (type: ActivityType, change: Int)? {
        let decreasedTypes = taskTypeChanges
            .filter { $0.change < 0 }
            .sorted(by: { $0.change < $1.change })
        
        if let first = decreasedTypes.first {
            return (first.type, first.change)
        }
        return nil
    }
    
    // 超过阈值的任务类型
    private var overThresholdTaskTypes: [(type: ActivityType, minutes: Int)] {
        taskTypeStats.filter { $0.type.isOverThreshold(minutes: $0.minutes) }
    }
    
    // 低于阈值的任务类型
    private var underThresholdTaskTypes: [(type: ActivityType, minutes: Int)] {
        taskTypeStats.filter { $0.type.isUnderThreshold(minutes: $0.minutes) }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
}

// MARK: - Comparison Detail View
struct ComparisonDetailView: View {
    let taskType: ActivityType
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(8)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("时间对比详情")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // 任务类型标题
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(taskType.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: taskType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(taskType.color)
                    }
                    
                    Text(taskType.rawValue)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                }
                .padding(.vertical, 16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 本周vs上周总览
                        comparisonCard()
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // 每日对比
                        dailyComparisonSection()
                            .padding(.horizontal, 20)
                        
                        // 使用场景统计
                        usagePatternSection()
                            .padding(.horizontal, 20)
                        
                        // 底部空间
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private func comparisonCard() -> some View {
        let thisWeekData = weekDataForType(taskType)
        let lastWeekData = lastWeekDataForType(taskType)
        let change = thisWeekData - lastWeekData
        let percentChange = lastWeekData > 0 ? Double(change) / Double(lastWeekData) * 100 : 0
        
        return VStack(spacing: 16) {
            HStack {
                Text("时间对比")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                
                Spacer()
                
                Text("本周 vs 上周")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            HStack(spacing: 20) {
                // 本周时间
                VStack(spacing: 4) {
                    Text("\(thisWeekData)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text("本周分钟")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1, height: 40)
                
                // 上周时间
                VStack(spacing: 4) {
                    Text("\(lastWeekData)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text("上周分钟")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1, height: 40)
                
                // 变化百分比
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(change >= 0 ? .green : .red)
                        
                        Text("\(abs(Int(percentChange)))%")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                    
                    Text("变化率")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
            
            if change != 0 {
                Text(change > 0 ? "本周比上周多了\(change)分钟的\(taskType.rawValue)时间" : "本周比上周少了\(abs(change))分钟的\(taskType.rawValue)时间")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func dailyComparisonSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("每日对比")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
            
            VStack(spacing: 12) {
                // 标题行
                HStack {
                    Text("星期")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    Text("本周")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("上周")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("变化")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                
                // 每天的数据行
                ForEach(0..<7, id: \.self) { dayIndex in
                    let dayName = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][dayIndex]
                    let thisWeekValue = dailyData(for: taskType, dayOffset: dayIndex, isCurrentWeek: true)
                    let lastWeekValue = dailyData(for: taskType, dayOffset: dayIndex, isCurrentWeek: false)
                    let change = thisWeekValue - lastWeekValue
                    
                    HStack {
                        Text(dayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        Text("\(thisWeekValue)")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 70, alignment: .trailing)
                        
                        Text("\(lastWeekValue)")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.7))
                            .frame(width: 70, alignment: .trailing)
                        
                        HStack(spacing: 2) {
                            if change != 0 {
                                Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(change > 0 ? .green : .red)
                            }
                            
                            Text(change == 0 ? "-" : "\(abs(change))")
                                .font(.system(size: 15, weight: change == 0 ? .regular : .medium))
                                .foregroundColor(change > 0 ? .green : (change < 0 ? .red : .black.opacity(0.5)))
                        }
                        .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(dayIndex % 2 == 0 ? Color.white : Color.black.opacity(0.02))
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            )
        }
    }
    
    // Helper to get minutes for a specific day
    private func dailyData(for type: ActivityType, dayOffset: Int, isCurrentWeek: Bool) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of this week (Monday)
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        // Calculate the start date based on current/last week and day offset
        let startOfWeek = isCurrentWeek ? 
            startOfThisWeek : 
            calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        
        // Add day offset to get the specific day
        let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)!
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let tasksOfType = viewModel.tasks.filter { task in
            guard task.isCompleted, 
                  let completedAt = task.completedAt,
                  completedAt >= dayStart && completedAt < dayEnd else {
                return false
            }
            return task.title == type.rawValue
        }
        
        return tasksOfType.reduce(0) { $0 + $1.duration }
    }
    
    private func usagePatternSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使用场景分析")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
            
            VStack(spacing: 16) {
                // 时段分布
                VStack(alignment: .leading, spacing: 12) {
                    Text("时段分布")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    HStack(spacing: 0) {
                        timeDistributionBar(label: "上午", percent: 30, color: .blue)
                        timeDistributionBar(label: "下午", percent: 40, color: .orange)
                        timeDistributionBar(label: "晚上", percent: 30, color: .purple)
                    }
                    .frame(height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    HStack(spacing: 16) {
                        ForEach([(label: "上午", color: Color.blue), 
                                 (label: "下午", color: Color.orange),
                                 (label: "晚上", color: Color.purple)], id: \.label) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(item.label)
                                    .font(.system(size: 12))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                
                // 持续时间分析
                VStack(alignment: .leading, spacing: 12) {
                    Text("持续时间分析")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        statsItem(value: "25", label: "平均时长", unit: "分钟")
                        statsItem(value: "5", label: "最短时长", unit: "分钟")
                        statsItem(value: "45", label: "最长时长", unit: "分钟")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            )
        }
    }
    
    private func timeDistributionBar(label: String, percent: CGFloat, color: Color) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(color)
                .frame(width: geometry.size.width * percent / 100)
        }
    }
    
    private func statsItem(value: String, label: String, unit: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func weekDataForType(_ type: ActivityType) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        let tasksOfType = viewModel.tasks.filter { task in
            guard task.isCompleted, 
                  let completedAt = task.completedAt,
                  completedAt >= startOfWeek && completedAt < endOfWeek else {
                return false
            }
            return task.title == type.rawValue
        }
        
        let totalMinutes = tasksOfType.reduce(0) { $0 + $1.duration }
        print("DEBUG: This week minutes for \(type.rawValue): \(totalMinutes)")
        return totalMinutes
    }
    
    private func lastWeekDataForType(_ type: ActivityType) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
        let endOfLastWeek = startOfThisWeek
        
        let tasksOfType = viewModel.tasks.filter { task in
            guard task.isCompleted, 
                  let completedAt = task.completedAt,
                  completedAt >= startOfLastWeek && completedAt < endOfLastWeek else {
                return false
            }
            return task.title == type.rawValue
        }
        
        let totalMinutes = tasksOfType.reduce(0) { $0 + $1.duration }
        print("DEBUG: Last week minutes for \(type.rawValue): \(totalMinutes)")
        return totalMinutes
    }
} 
