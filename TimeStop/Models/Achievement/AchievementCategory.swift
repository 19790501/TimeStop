import SwiftUI

/// 成就分类
enum AchievementCategory: String, CaseIterable, Identifiable {
    // 工作相关
    case work = "工作"
    case meeting = "会议"
    case thinking = "思考"

    // 个人成长相关
    case reading = "阅读"
    case learning = "学习"
    case creating = "创作"

    // 生活健康相关
    case exercise = "运动"
    case sleep = "睡眠"
    case life = "生活"

    // 娱乐休闲相关
    case entertainment = "娱乐"
    case relax = "休息"
    case social = "社交"

    // Identifiable 协议要求
    var id: String { rawValue }

    /// 分类对应的图标名称
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .meeting: return "person.2.fill"
        case .thinking: return "brain.head.profile"
        case .reading: return "book.fill"
        case .learning: return "graduationcap.fill"
        case .creating: return "paintbrush.fill"
        case .exercise: return "figure.run"
        case .sleep: return "bed.double.fill"
        case .life: return "house.fill"
        case .entertainment: return "tv.fill"
        case .relax: return "leaf.fill"
        case .social: return "person.3.fill"
        }
    }

    /// 分类对应的颜色
    var color: Color {
        switch self {
        // 工作相关 - 蓝色系列
        case .work: return Color(red: 0.1, green: 0.6, blue: 0.9)     // 天蓝色
        case .meeting: return Color(red: 0.2, green: 0.4, blue: 0.8)  // 宝蓝色
        case .thinking: return Color(red: 0.4, green: 0.5, blue: 0.9) // 淡紫蓝色

        // 个人成长相关 - 紫色系列
        case .reading: return Color(red: 0.5, green: 0.3, blue: 0.9)  // 紫罗兰色
        case .learning: return Color(red: 0.6, green: 0.2, blue: 0.8) // 深紫色
        case .creating: return Color(red: 0.7, green: 0.4, blue: 0.9) // 浅紫色

        // 生活健康相关 - 绿色系列
        case .exercise: return Color(red: 0.2, green: 0.8, blue: 0.4) // 翠绿色
        case .sleep: return Color(red: 0.4, green: 0.7, blue: 0.9)    // 天青色
        case .life: return Color(red: 0.3, green: 0.7, blue: 0.5)     // 薄荷绿

        // 娱乐休闲相关 - 暖色系列
        case .entertainment: return Color(red: 0.9, green: 0.5, blue: 0.2) // 橙色
        case .relax: return Color(red: 1.0, green: 0.7, blue: 0.3)     // 金黄色
        case .social: return Color(red: 0.95, green: 0.4, blue: 0.4)   // 珊瑚红
        }
    }
}
