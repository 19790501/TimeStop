//
//  TimeStopApp.swift
//  TimeStop
//
//  Created by SamueL on 2025/3/27.
//

import SwiftUI
import BackgroundTasks

@main
struct TimeStopApp: App {
    // 使用AppDelegate模式来继续接收UIApplicationDelegate事件
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // 注册应用级别的环境对象
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var userModel = UserModel()
    
    // App主体结构
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(userModel)
                .preferredColorScheme(.dark) // 强制应用使用深色模式
        }
    }
}
