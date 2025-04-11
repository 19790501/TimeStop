import Foundation
import SwiftUI

// 应用程序和小部件共享的数据模型
public struct SharedTimerData: Codable {
    let taskName: String
    let timerRemaining: Int  // 以秒为单位
    let totalDuration: Int   // 以秒为单位
    let isActive: Bool
    let taskType: String
    let lastUpdated: Date
    
    // 格式化显示时间
    var formattedTime: String {
        let minutes = timerRemaining / 60
        let seconds = timerRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 计算进度百分比 (0-1)
    var progressPercentage: Double {
        if totalDuration == 0 { return 0 }
        return Double(totalDuration - timerRemaining) / Double(totalDuration)
    }
}

// 注意：Color的hex扩展已移至ThemeManager.swift中，避免重复声明 