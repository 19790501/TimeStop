//
//  TimeStopApp.swift
//  TimeStop
//
//  Created by SamueL on 2025/3/27.
//

import SwiftUI

@main
struct TimeStopApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var themeManager = ThemeManager()
    
    // 在全局确保成就管理器被初始化
    private let achievementManager = AchievementManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Force dark mode for the entire app
                .environmentObject(viewModel)
                .environmentObject(themeManager)
                .environmentObject(UserModel.shared)
                .onAppear {
                    // 确保应用启动时初始化成就系统
                    _ = achievementManager
                    
                    // 根据UserDefaults设置当前主题
                    if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
                       let theme = ThemeManager.AppTheme(rawValue: savedTheme) {
                        themeManager.switchTheme(to: theme)
                    }
                    
                    // 初始化模型
                    initializeModels()
                    
                    // Set up appearance
                    setupAppearance()
                    
                    // 检查颜色系统健康状态
                    checkColorSystemHealth()
                    
                    // 监听主题变化通知
                    NotificationCenter.default.addObserver(
                        forName: ThemeManager.themeChangeNotification,
                        object: nil,
                        queue: .main
                    ) { _ in
                        setupAppearance()
                    }
                }
        }
    }
    
    private func setupAppearance() {
        // 根据当前主题设置 tintColor
        UIView.appearance().tintColor = UIColor(themeManager.colors.primary)
        
        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.colors.background)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(themeManager.colors.text)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(themeManager.colors.text)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Customize tab bar appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(themeManager.colors.secondaryText)
        UITabBar.appearance().backgroundColor = UIColor(themeManager.colors.background)
    }
    
    // 检查颜色系统健康状态并生成报告
    private func checkColorSystemHealth() {
        #if DEBUG
        print("=== 颜色系统健康检查 ===")
        
        // 检查主题管理器状态
        let isHealthy = themeManager.checkColorSystemHealth()
        
        if isHealthy {
            print("✅ 颜色系统运行正常")
        } else {
            print("⚠️ 颜色系统存在问题，某些颜色可能使用备用值")
            
            // 检查具体的颜色状态
            if themeManager.hasError {
                print("❌ 主题系统错误标志已设置")
            }
            
            // 打印当前使用的主题
            print("📊 当前主题: \(themeManager.currentTheme.rawValue)")
            
            // 打印当前主题的颜色
            print("🔍 检查主题颜色...")
            let colorsToCheck = [
                ("主要颜色", themeManager.colors.primary),
                ("次要颜色", themeManager.colors.secondary),
                ("强调色", themeManager.colors.accent),
                ("背景色", themeManager.colors.background),
                ("次要背景色", themeManager.colors.secondaryBackground),
                ("文本颜色", themeManager.colors.text),
                ("次要文本颜色", themeManager.colors.secondaryText),
                ("按钮文本颜色", themeManager.colors.buttonText),
                ("按钮背景色", themeManager.colors.buttonBackground)
            ]
            
            for (name, color) in colorsToCheck {
                if color == Color.red {
                    print("  ❌ \(name)已回退到错误颜色")
                }
            }
        }
        
        print("\n=== 当前主题报告 ===")
        print(themeManager.generateThemeUsageReport())
        
        print("\n=== 颜色使用报告 ===")
        print(themeManager.generateColorUsageReport())
        #endif
    }
    
    // 配置模型初始化
    private func initializeModels() {
        // 移除自动生成测试数据的代码
        // 仅保留必要的初始化逻辑
    }
}
