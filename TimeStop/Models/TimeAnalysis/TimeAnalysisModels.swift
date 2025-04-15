import SwiftUI
import Foundation

// MARK: - 时间分析相关数据模型

// 时间分析摘要数据结构
public struct TimeAnalysisSummary {
    // 基本分析数据
    public var totalTime: Int = 0
    public var taskCount: Int = 0
    public var avgDuration: Int = 0
    
    // 时间过多/过少分析
    public var overAllocatedTypes: [(type: String, minutes: Int)] = []
    public var underAllocatedTypes: [(type: String, minutes: Int)] = []
    
    // 调整/终止分析
    public var frequentlyAdjustedTypes: [(type: String, adjustmentCount: Int, adjustmentPercentage: Double)] = []
    public var frequentlyTerminatedTypes: [(type: String, terminatedCount: Int, terminationPercentage: Double)] = []
    
    // 模式分析
    public var mostProductiveTimeOfDay: String = ""
    public var leastProductiveTimeOfDay: String = ""
    public var bestCombinations: [(first: String, second: String, synergy: String)] = []
    
    // 趋势分析 (仅月总结使用)
    public var trendingUpTypes: [(type: String, increasePercentage: Double)] = []
    public var trendingDownTypes: [(type: String, decreasePercentage: Double)] = []
    public var mostConsistentType: String = ""
    public var leastConsistentType: String = ""
}

// 角色标准数据结构
public struct RoleStandard {
    public let type: String // "创业者", "高管", "白领"
    public let standards: [String: TimeStandard]
    public let description: String
    
    // 通过任务类型获取时间标准
    public func getStandard(for taskType: String) -> TimeStandard? {
        return standards[taskType]
    }
}

// 时间标准数据结构
public struct TimeStandard {
    public let lowerBound: Double // 小时
    public let upperBound: Double // 小时
    public let priorityCoefficient: Int // 1-5
    
    // 判断时间是否在基准范围内
    public func isWithinStandard(_ hours: Double) -> DeviationType {
        if hours < lowerBound {
            return .deficient
        } else if hours > upperBound {
            return .excess
        } else {
            return .balanced
        }
    }
    
    // 计算偏差百分比
    public func deviationPercentage(_ hours: Double) -> Double {
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
public enum DeviationType {
    case excess // 过多
    case deficient // 过少
    case balanced // 正常
}

// 因素类型枚举
public enum FactorType {
    case objective // 客观因素
    case subjective // 主观因素
}

// 时间影响因素结构
public struct TimeInfluenceFactor {
    public let factorType: FactorType
    public let description: String
    public let impactLevel: Int // 1-5影响程度
}

// 任务类型统计结构
public struct TaskTypeStat: Equatable {
    public let type: String
    public let count: Int
    public let minutes: Int
    public let originalMinutes: Int
    public let adjustmentMinutes: Int
    
    // 新增：终止任务相关数据
    public var terminatedCount: Int = 0      // 被终止的任务数量
    public var reducedMinutes: Int = 0       // 因终止而减少的分钟数
    
    // 实现Equatable协议的静态方法
    public static func == (lhs: TaskTypeStat, rhs: TaskTypeStat) -> Bool {
        return lhs.type == rhs.type
    }
}

// 时间范围枚举 - 通用
public enum TimeRange: String, CaseIterable, Identifiable {
    case today = "今日"
    case week = "本周"
    case month = "本月"
    
    public var id: String { self.rawValue }
}

// 时间健康状态枚举
public enum TimeHealthStatus {
    case normal      // 正常
    case warning     // 警告
    case critical    // 严重不足
    
    public var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
} 