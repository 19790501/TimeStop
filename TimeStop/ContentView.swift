//
//  ContentView.swift
//  TimeStop
//
//  Created by SamueL on 2025/3/27.
//

import SwiftUI
import Combine
import AudioToolbox

// 移除类型别名定义，直接使用全局 AchievementType

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @StateObject private var navigationManager = NavigationManager()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    @State private var selectedTab: NavigationManager.TabViewSelection = .home
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingAchievementUnlock = false
    @State private var unlockedAchievementType: AchievementType?
    @State private var unlockedAchievementLevel: Int = 0
    @State private var disableTabSwipe: Bool = false // 添加控制TabView滑动的状态
    
    // 用于控制首次加载
    @State private var isFirstAppear = true
    
    // 保存通知观察者以便适当时移除
    @State private var notificationObservers: [NSObjectProtocol] = []
    
    // 添加状态恢复标志
    @State private var isRestoringState = false
    
    // 常量定义，避免魔法数字
    private enum Constants {
        static let standardAnimationDuration: TimeInterval = 0.3
        static let successDisplayDuration: TimeInterval = 5.0
        static let modalTransitionDuration: TimeInterval = 0.3
        static let zIndexWelcome: Double = 20
        static let zIndexVerificationOverlay: Double = 10
        static let zIndexVerificationView: Double = 15
        static let zIndexCompletionView: Double = 2
        static let zIndexFocusTimer: Double = 1
        static let zIndexSuccessView: Double = 30
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content - 仅在经过欢迎页面且已认证后显示
                if viewModel.isAuthenticated && !navigationManager.isShowingWelcome && !isFirstAppear {
                    // Show main app screens when authenticated and not showing welcome
                    if !navigationManager.isShowingFocusTimer && !navigationManager.isShowingCompletion && !navigationManager.isShowingAchievement {
                        mainScreens
                    }
                } else if !viewModel.isAuthenticated && !navigationManager.isShowingWelcome && !isFirstAppear {
                    // Show auth screen when not authenticated and not showing welcome
                    AuthView()
                }
                
                // Modal screens - 使用ZStack叠加层次并设置高优先级显示
                if navigationManager.isShowingWelcome || isFirstAppear {
                    WelcomeView()
                        .transition(.opacity)
                        .zIndex(Constants.zIndexWelcome)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if navigationManager.isShowingVerification {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(Constants.zIndexVerificationOverlay)
                        
                    TaskVerificationView()
                        .transition(.move(edge: .bottom))
                        .zIndex(Constants.zIndexVerificationView)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if navigationManager.isShowingFocusTimer {
                    FocusTimerView()
                        .transition(.move(edge: .bottom))
                        .zIndex(Constants.zIndexFocusTimer)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .overlay {
                if showingAchievementUnlock, let type = unlockedAchievementType {
                    AchievementUnlockOverlay(
                        type: type,
                        level: unlockedAchievementLevel,
                        isPresented: $showingAchievementUnlock
                    )
                }
            }
            .environmentObject(viewModel)
            .environmentObject(navigationManager)
            .environmentObject(themeManager)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: viewModel.activeTask) { newValue in
            withAnimation(.easeInOut(duration: Constants.standardAnimationDuration)) {
                navigationManager.isShowingFocusTimer = newValue != nil
                if newValue != nil {
                    navigationManager.navigate(to: .focusTimer)
                }
            }
        }
        .onChange(of: viewModel.isVerifying) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: Constants.standardAnimationDuration)) {
                    navigationManager.navigate(to: .verification)
                }
            }
        }
        .onAppear {
            // 应用启动时立即设置欢迎界面状态
            navigationManager.isShowingWelcome = true
            
            // 设置并保存所有通知观察者
            setupNotificationObservers()
            
            // 添加navigationManager.activeScreen的观察者
            setupPublisherSubscriptions()
            
            // 检查是否需要恢复状态
            checkAndRestoreState()
        }
        .onDisappear {
            // 移除所有通知观察者
            removeNotificationObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AchievementUnlocked"))) { notification in
            guard let type = notification.userInfo?["type"] as? AchievementType,
                  let level = notification.userInfo?["level"] as? Int else {
                return
            }
            
            unlockedAchievementType = type
            unlockedAchievementLevel = level
            
            // 播放成就解锁音效
            viewModel.playAchievementSound()
            
            withAnimation {
                showingAchievementUnlock = true
            }
        }
    }
    
    private func checkAndRestoreState() {
        guard !isRestoringState else { return }
        isRestoringState = true
        
        // 检查是否有活动任务需要恢复
        if let taskData = UserDefaults.standard.data(forKey: "activeTask"),
           let task = try? JSONDecoder().decode(Task.self, from: taskData) {
            let timeRemaining = UserDefaults.standard.integer(forKey: "timeRemaining")
            let timerIsRunning = UserDefaults.standard.bool(forKey: "timerIsRunning")
            let isVerifying = UserDefaults.standard.bool(forKey: "isVerifying")
            
            // 恢复任务状态
            viewModel.activeTask = task
            viewModel.timeRemaining = timeRemaining
            viewModel.timerIsRunning = timerIsRunning
            viewModel.isVerifying = isVerifying
            
            // 根据状态导航到相应界面
            if isVerifying {
                navigationManager.navigate(to: .verification)
            } else if timerIsRunning {
                navigationManager.navigate(to: .focusTimer)
            }
        }
        
        isRestoringState = false
    }
    
    // 设置通知观察者
    private func setupNotificationObservers() {
        // 切换到统计页签的观察者
        let statsTabObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SwitchToStatsTab"), 
            object: nil, 
            queue: .main
        ) { [self] _ in
            let tab: NavigationManager.TabViewSelection = .timeAnalysis
            withAnimation {
                selectedTab = tab
            }
        }
        
        // 处理从通知返回活动任务的观察者
        let returnToActiveTaskObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReturnToActiveTask"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // 确保先停止所有音频和震动
            AudioService.shared.emergencyCleanup()
            
            // 确保计时器界面显示
            if viewModel.activeTask != nil {
                if viewModel.timeRemaining == 0 || viewModel.isVerifying {
                    // 如果计时器已经结束或者需要验证，直接跳转到验证界面
                    viewModel.startVerification()
                    navigationManager.isShowingVerification = true
                } else {
                    // 否则显示计时器界面
                    navigationManager.isShowingFocusTimer = true
                }
            } else {
                // 没有活动任务，返回主页
                navigationManager.isShowingFocusTimer = false
                navigationManager.isShowingVerification = false
            }
        }
        
        // 任务恢复通知的观察者
        let taskRestoredObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TaskRestored"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // 应用意外退出后恢复任务状态时，显示倒计时界面
            // 确保先停止所有音频和震动
            AudioService.shared.emergencyCleanup()
            
            if viewModel.activeTask != nil {
                navigationManager.isShowingFocusTimer = true
            }
        }
        
        // 需要验证通知的观察者
        let verificationNeededObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("VerificationNeeded"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // 应用意外退出后，如果倒计时已结束，显示验证界面
            // 确保先停止所有音频和震动
            AudioService.shared.emergencyCleanup()
            
            navigationManager.navigateToVerification() // 使用新方法
        }
        
        // 处理完成任务通知的观察者
        let completeTaskObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CompleteTaskFromNotification"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if viewModel.activeTask != nil {
                viewModel.completeTask()
            }
        }
        
        // 处理取消任务通知的观察者
        let cancelTaskObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CancelTaskFromNotification"),
            object: nil,
            queue: .main
        ) { [self] _ in
            if viewModel.activeTask != nil {
                viewModel.cancelTask()
            }
        }
        
        // 欢迎页面关闭的观察者
        let welcomeDismissedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WelcomeViewDismissed"), 
            object: nil, 
            queue: .main
        ) { [self] _ in
            withAnimation {
                isFirstAppear = false
            }
        }
        
        // 用户登出的观察者
        let userSignOutObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UserDidSignOut"), 
            object: nil, 
            queue: .main
        ) { [self] _ in
            // 用户登出后，确保欢迎页不显示，直接显示登录页
            withAnimation {
                navigationManager.isShowingWelcome = false
                isFirstAppear = false
            }
        }
        
        // 添加禁用TabView滑动的观察者
        let disableTabSwipeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DisableTabSwipe"),
            object: nil,
            queue: .main
        ) { [self] notification in
            if let userInfo = notification.userInfo,
               let isDisabled = userInfo["disabled"] as? Bool {
                withAnimation {
                    disableTabSwipe = isDisabled
                }
            }
        }
        
        // 准备导航通知的观察者
        let prepareNavigationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("PrepareForTaskNavigation"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // 重置导航状态
            navigationManager.isShowingFocusTimer = false
            navigationManager.isShowingVerification = false
            navigationManager.isShowingWelcome = false
            navigationManager.isShowingCompletion = false
            navigationManager.isShowingAchievement = false
        }
        
        // 保存所有观察者以便后续移除
        notificationObservers = [
            statsTabObserver,
            returnToActiveTaskObserver,
            taskRestoredObserver,
            verificationNeededObserver,
            completeTaskObserver,
            cancelTaskObserver,
            welcomeDismissedObserver,
            userSignOutObserver,
            disableTabSwipeObserver,
            prepareNavigationObserver
        ]
    }
    
    // 移除所有通知观察者
    private func removeNotificationObservers() {
        notificationObservers.forEach { 
            NotificationCenter.default.removeObserver($0) 
        }
    }
    
    // 设置发布者订阅
    private func setupPublisherSubscriptions() {
        // 添加navigationManager.activeScreen的观察者
        navigationManager.objectWillChange.sink { [self] in
            let navManager = navigationManager // Capture as a local constant
            DispatchQueue.main.async {
                if navManager.activeScreen == .home {
                    withAnimation {
                        selectedTab = .home // 主页标签
                    }
                }
            }
        }
        .store(in: &cancellables)
    }
    
    var mainScreens: some View {
        VStack(spacing: 0) {
            // Main content area - 使用ZStack简单包裹内容，保持结构简单
            ZStack {
                // 基础TabView
                TabView(selection: $selectedTab) {
                    // Home/Create task tab
                    CreateTaskView()
                        .environmentObject(navigationManager)
                        .tag(NavigationManager.TabViewSelection.home)
                    
                    // 时间去哪了标签页
                    TimeWhereView()
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .environmentObject(userModel)
                        .tag(NavigationManager.TabViewSelection.timeAnalysis)
                    
                    // 成就标签页
                    AchievementCollectionView(achievementManager: AchievementManager.shared)
                        .tag(NavigationManager.TabViewSelection.achievements)
                    
                    // 设置标签页
                    SettingsView()
                        .tag(NavigationManager.TabViewSelection.settings)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .edgesIgnoringSafeArea(.bottom)
                
                // 如果需要禁用滑动，覆盖一个透明的遮罩层拦截手势
                if disableTabSwipe {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in }
                                .onEnded { _ in }
                        )
                }
            }
            
            // 将TabBar移到VStack底部，确保它位于ZStack之外
            TabBarView(selectedTab: $selectedTab)
                .background(themeManager.colors.secondaryBackground)
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: selectedTab) { newValue in
            // Update the navigation manager when tab changes
            switch newValue {
            case .home: navigationManager.activeScreen = .home
            case .timeAnalysis: navigationManager.activeScreen = .stats // 时间去哪了对应原stats
            case .achievements: navigationManager.activeScreen = .achievement // 成就收集对应原achievement
            case .settings: navigationManager.activeScreen = .profile
            }
        }
    }
    
    var profileView: some View {
        VStack(spacing: 24) {
            Text("个人设置")
                .font(.title)
                .foregroundColor(themeManager.colors.text)
            
            if let user = viewModel.currentUser {
                ScrollView {
                    VStack(spacing: 24) {
                        // 用户信息部分
                        VStack(spacing: 16) {
                            Text(user.username)
                                .font(.title2)
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("等级: \(user.level)")
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("总专注时间: \(user.totalFocusTime) 分钟")
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("完成任务数: \(user.completedTasks)")
                                .foregroundColor(themeManager.colors.text)
                        }
                        .padding()
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(12)
                        
                        // 应用设置部分
                        VStack(spacing: 16) {
                            Text("应用设置")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 音效开关
                            Toggle(isOn: $viewModel.soundEnabled) {
                                HStack(spacing: 12) {
                                    Image(systemName: viewModel.soundEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                        .foregroundColor(viewModel.soundEnabled ? themeManager.colors.primary : themeManager.colors.secondaryText)
                                    
                                    Text("按钮音效")
                                        .foregroundColor(themeManager.colors.text)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: themeManager.colors.primary))
                            .onChange(of: viewModel.soundEnabled) { newValue in
                                // 直接保存设置，不调用toggleSoundEnabled，避免循环调用
                                UserDefaults.standard.set(newValue, forKey: "soundEnabled")
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(12)
                        
                        // 主题设置部分
                        VStack(spacing: 16) {
                            Text("主题设置")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    withAnimation {
                                        themeManager.switchTheme(to: theme)
                                    }
                                    
                                    // 播放按钮音效 - 确保使用ViewModel的方法
                                    // 这里已经包含了对soundEnabled的检查
                                    viewModel.playButtonSound()
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(theme.colors.primary)
                                            .frame(width: 20, height: 20)
                                        
                                        Text(theme.rawValue)
                                            .foregroundColor(themeManager.colors.text)
                                        
                                        Spacer()
                                        
                                        if themeManager.currentTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeManager.colors.primary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding()
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(12)
                        
                        // 退出登录按钮
                        Button(action: {
                            viewModel.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("退出登录")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .background(themeManager.colors.background.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    ContentView()
}
