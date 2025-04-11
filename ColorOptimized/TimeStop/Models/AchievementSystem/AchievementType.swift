import Foundation
import SwiftUI

enum AchievementType: String, CaseIterable, Codable, Identifiable {
    // 核心8种类型 - 原始设计
    case meeting = "会议"   // 会议
    case thinking = "思考"  // 思考
    case work = "工作"      // 工作
    case life = "生活"      // 生活（图标改为心形）
    case exercise = "运动"  // 运动（原锻炼）
    case reading = "阅读"   // 阅读
    case sleep = "睡眠"     // 睡眠
    case relax = "摸鱼"     // 摸鱼（原休闲，图标改为鱼）
    
    // 注意：以下是扩展类型，不在核心8种类型中
    // 如果需要恢复完整类型列表，取消下面的注释
    /*
    case study = "学习"
    case meditation = "冥想"
    case writing = "写作"
    case coding = "编程"
    case music = "音乐"
    case art = "艺术"
    case language = "语言"
    case cooking = "烹饪"
    case gardening = "园艺"
    case gaming = "游戏"
    case social = "社交"
    case family = "家庭"
    case health = "健康"
    case finance = "财务"
    case travel = "旅行"
    */
    
    var id: String { self.rawValue }
    
    var name: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .thinking: return "brain.head.profile"
        case .meeting: return "person.2.fill"
        case .exercise: return "figure.walk"
        case .reading: return "book.closed.fill"
        case .life: return "heart.fill"          // 生活图标改为心形
        case .relax: return "fish.fill"          // 摸鱼图标改为鱼
        case .sleep: return "bed.double.fill"
        }
    }
    
    var levelThresholds: [Int] {
        switch self {
        case .work:
            return [300, 600, 900, 1200, 1500, 1800] // 5h, 10h, 15h, 20h, 25h, 30h
        case .reading:
            return [30, 60, 180, 240, 360, 450] // 0.5h, 1h, 3h, 4h, 6h, 7.5h
        case .life:
            return [30, 60, 120, 180, 240, 350] // 0.5h, 1h, 2h, 3h, 4h, ~6h
        case .exercise:
            return [30, 105, 140, 210, 280, 420] // 0.5h, 1.75h, 2.33h, 3.5h, 4.67h, 7h
        case .meeting:
            return [105, 210, 420, 630, 840, 1260] // 1.75h, 3.5h, 7h, 10.5h, 14h, 21h
        case .thinking:
            return [150, 280, 420, 630, 840, 1260] // 2.5h, 4.67h, 7h, 10.5h, 14h, 21h
        case .relax:
            return [105, 210, 420, 630, 840, 1260] // 1.75h, 3.5h, 7h, 10.5h, 14h, 21h
        case .sleep:
            return [560, 1120, 1680, 2240, 2800, 3360] // 9.33h, 18.67h, 28h, 37.33h, 46.67h, 56h
        }
    }
    
    func achievementLevel(for minutes: Int) -> Int {
        for (index, threshold) in levelThresholds.enumerated() {
            if minutes < threshold {
                return index
            }
        }
        return levelThresholds.count
    }
    
    // 兼容性别名
    func level(for minutes: Int) -> Int {
        return achievementLevel(for: minutes)
    }
    
    func minutesToNextLevel(for minutes: Int) -> Int {
        let currentLevel = achievementLevel(for: minutes)
        if currentLevel < levelThresholds.count {
            return levelThresholds[currentLevel] - minutes
        }
        return 0
    }
    
    func nextLevelMinutes(currentMinutes: Int) -> Int? {
        let currentLevel = achievementLevel(for: currentMinutes)
        if currentLevel < levelThresholds.count {
            return levelThresholds[currentLevel]
        }
        return nil
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .reading: return .orange
        case .exercise: return .red
        case .meeting: return .pink
        case .thinking: return .orange
        case .life: return .red       // 心形图标改为红色（原为绿色）
        case .relax: return .mint
        case .sleep: return .green.opacity(0.8)    // 睡眠图标改为墨绿色（原为靛蓝色）
        }
    }
    
    func colorForLevel(level: Int) -> Color {
        let opacity = min(Double(level) * 0.2 + 0.2, 1.0)
        return self.color.opacity(opacity)
    }
    
    func levelColor(_ level: Int) -> Color {
        let colors: [Color] = [
            .gray,   // 0级 - 未解锁
            .blue,   // 1级 - 新手
            .green,  // 2级 - 进阶
            .yellow, // 3级 - 专家
            .orange, // 4级 - 大师
            .red,    // 5级 - 传奇
            .purple  // 6级 - 传说(额外)
        ]
        return colors[min(level, colors.count - 1)]
    }
    
    func nextLevelThreshold(for minutes: Int) -> Int {
        let currentLevel = achievementLevel(for: minutes)
        if currentLevel < levelThresholds.count {
            return levelThresholds[currentLevel]
        }
        return levelThresholds.last ?? 0
    }
    
    func progressPercentage(for minutes: Int) -> Double {
        let currentLevel = achievementLevel(for: minutes)
        if currentLevel == 0 {
            return Double(minutes) / Double(levelThresholds[0])
        } else if currentLevel >= levelThresholds.count {
            return 1.0
        } else {
            let currentThreshold = levelThresholds[currentLevel - 1]
            let nextThreshold = levelThresholds[currentLevel]
            return Double(minutes - currentThreshold) / Double(nextThreshold - currentThreshold)
        }
    }
    
    // 兼容性别名
    func progressPercentage(minutes: Int) -> Double {
        return progressPercentage(for: minutes)
    }
    
    func levelDescription(_ level: Int) -> String {
        switch self {
        case .meeting:
            let titles = ["未解锁", "会议室保安", "笔记刺客", "鼓掌机器人", "PPT鉴赏家", "灵魂出窍者", "时间黑洞缔造者"]
            return titles[min(level, titles.count - 1)]
        case .thinking:
            let titles = ["未解锁", "脑内散步者", "颅内辩论冠军", "宇宙信号接收员", "薛定谔的猫监护人", "高维生物接线员", "银河系脑洞总工程师"]
            return titles[min(level, titles.count - 1)]
        case .life:
            let titles = ["未解锁", "烟火气收集者", "茄子炒土豆骑士", "阳台光合作用者", "猫主子御用按摩师", "深夜哲学家", "人间幸福体MVP"]
            return titles[min(level, titles.count - 1)]
        case .exercise:
            let titles = ["未解锁", "出汗初级生", "多巴胺战士", "健身社交悍匪", "刘某宏关门弟子", "撸铁诗人", "宙斯名誉私教"]
            return titles[min(level, titles.count - 1)]
        case .work:
            let titles = ["未解锁", "键盘敲击学徒", "Excel单元画家", "咖啡因续航者", "PPT驯兽师", "数据驯兽师", "公司永动机"]
            return titles[min(level, titles.count - 1)]
        case .reading:
            let titles = ["未解锁", "油墨嗅探汪", "羊皮卷驯兽师", "叙事链反应堆操作员", "阅读时光大祭司", "意识流蒸馏师", "真理之眼传承人"]
            return titles[min(level, titles.count - 1)]
        case .sleep:
            let titles = ["未解锁", "修仙实习生", "熬夜预备役", "人间清醒侠", "佛系充电宝", "睡神候选人", "睡眠副本终极BOSS"]
            return titles[min(level, titles.count - 1)]
        case .relax:
            let titles = ["未解锁", "茶水间纠缠体", "精神离职体验官", "带薪光合作用体", "老板の盲点洞察官", "反内卷炼金术士", "资本の眼泪收割者"]
            return titles[min(level, titles.count - 1)]
        }
    }
    
    func achievementDescription(for level: Int) -> String {
        return levelDescription(level)
    }
    
    func levelSuggestion(_ level: Int) -> String {
        if level == 0 {
            return "继续努力，完成\(levelThresholds[0])分钟即可解锁"
        } else if level < 5 {
            let nextLevel = level + 1
            return "再接再厉，距离\(levelDescription(nextLevel))不远了"
        } else if level == 5 {
            return "恭喜你达到最高等级！"
        } else {
            return "继续努力"
        }
    }
    
    static var levelDescriptions: [Int: String] {
        // 由于每种成就类型有不同的等级描述，这里只返回通用的等级提示
        return [
            0: "未解锁",
            1: "1级",
            2: "2级",
            3: "3级",
            4: "4级",
            5: "5级",
            6: "6级"
        ]
    }
} 