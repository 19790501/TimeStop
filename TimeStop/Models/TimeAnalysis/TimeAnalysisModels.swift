import SwiftUI
import Foundation

// MARK: - 时间分析相关数据模型

// 时间分析摘要数据结构
struct TimeAnalysisSummary {
    // 基本分析数据
    var totalTime: Int = 0
    var taskCount: Int = 0
    var avgDuration: Int = 0
    
    // 时间过多/过少分析
    var overAllocatedTypes: [(type: String, minutes: Int)] = []
    var underAllocatedTypes: [(type: String, minutes: Int)] = []
    
    // 调整/终止分析
    var frequentlyAdjustedTypes: [(type: String, adjustmentCount: Int, adjustmentPercentage: Double)] = []
    var frequentlyTerminatedTypes: [(type: String, terminatedCount: Int, terminationPercentage: Double)] = []
    
    // 模式分析
    var mostProductiveTimeOfDay: String = ""
    var leastProductiveTimeOfDay: String = ""
    var bestCombinations: [(first: String, second: String, synergy: String)] = []
    
    // 趋势分析 (仅月总结使用)
    var trendingUpTypes: [(type: String, increasePercentage: Double)] = []
    var trendingDownTypes: [(type: String, decreasePercentage: Double)] = []
    var mostConsistentType: String = ""
    var leastConsistentType: String = ""
}

// 角色标准数据结构
struct RoleStandard {
    let type: String // "创业者", "高管", "白领"
    let standards: [String: TimeStandard]
    let description: String
    
    // 通过任务类型获取时间标准
    func getStandard(for taskType: String) -> TimeStandard? {
        return standards[taskType]
    }
}

// 时间标准数据结构
struct TimeStandard {
    let lowerBound: Double // 小时
    let upperBound: Double // 小时
    let priorityCoefficient: Int // 1-5
    
    // 判断时间是否在基准范围内
    func isWithinStandard(_ hours: Double) -> DeviationType {
        if hours < lowerBound {
            return .deficient
        } else if hours > upperBound {
            return .excess
        } else {
            return .balanced
        }
    }
    
    // 计算偏差百分比
    func deviationPercentage(_ hours: Double) -> Double {
        if hours < lowerBound {
            return (lowerBound - hours) / lowerBound * 100
        } else if hours > upperBound {
            return (hours - upperBound) / upperBound * 100
        } else {
            return 0
        }
    }
}

// 偏差类型枚举
enum DeviationType {
    case excess // 过多
    case deficient // 过少
    case balanced // 正常
}

// 因素类型枚举
enum FactorType {
    case objective // 客观因素
    case subjective // 主观因素
}

// 时间影响因素结构
struct TimeInfluenceFactor {
    let factorType: FactorType
    let description: String
    let impactLevel: Int // 1-5影响程度
}

// 任务类型统计结构
struct TaskTypeStat: Equatable {
    let type: String
    let count: Int
    let minutes: Int
    let originalMinutes: Int
    let adjustmentMinutes: Int
    
    // 新增：终止任务相关数据
    var terminatedCount: Int = 0      // 被终止的任务数量
    var reducedMinutes: Int = 0       // 因终止而减少的分钟数
    
    // 实现Equatable协议的静态方法
    static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
        return lhs.type == rhs.type
    }
}

// 时间范围枚举 - 通用
enum TimeRange: String, CaseIterable, Identifiable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
    
    var id: String { self.rawValue }
}

// 时间健康状态枚举
enum TimeHealthStatus {
    case normal      // 正常
    case warning     // 警告
    case critical    // 严重不足
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
} 