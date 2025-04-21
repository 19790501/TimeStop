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
    
    // 用于控制首次加载
    @State private var isFirstAppear = true
    
    // 保存通知观察者以便适当时移除
    @State private var notificationObservers: [NSObjectProtocol] = []
    
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
                selectedTab = tab // 时间去哪了页签
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
        
        // 保存观察者引用以便后续移除
        notificationObservers = [statsTabObserver, welcomeDismissedObserver, userSignOutObserver]
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
            // Main content area
            TabView(selection: $selectedTab) {
                // Home/Create task tab
                CreateTaskView()
                    .tag(NavigationManager.TabViewSelection.home)
                
                // 时间去哪了标签页
                TimeWhereView_test()
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
            .safeAreaInset(edge: .bottom) {
                // Custom tab bar with adjusted position
                TabBarView(selectedTab: $selectedTab)
                    .background(themeManager.colors.secondaryBackground)
                    .frame(height: 55) // 修改固定高度为55
            }
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
