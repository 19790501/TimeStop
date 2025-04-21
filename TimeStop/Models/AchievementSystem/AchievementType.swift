import Foundation
import SwiftUI

// 成就类别，用于分组显示成就
enum SystemAchievementCategory: String, CaseIterable, Identifiable {
    case habit = "习惯与一致性"      // 习惯养成相关成就
    case insight = "时间管理洞察"    // 时间管理洞察相关成就
    case adjustment = "时间调整反馈"  // 关于时间调整的成就
    case role = "角色与目标"         // 与用户角色相关的成就
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .habit: return "calendar.badge.clock"
        case .insight: return "lightbulb.fill" 
        case .adjustment: return "arrow.triangle.2.circlepath"
        case .role: return "person.fill.checkmark"
        }
    }
    
    var color: Color {
        switch self {
        case .habit: return .blue
        case .insight: return .orange
        case .adjustment: return .purple
        case .role: return .green
        }
    }
}

// 新的成就类型枚举，包含所有支持的成就类型
enum AchievementType: String, CaseIterable, Codable, Identifiable {
    // 用于通知系统的通用等级描述
    static let levelDescriptions: [Int: String] = [
        0: "未解锁",
        1: "初级",
        2: "中级", 
        3: "高级",
        4: "专家",
        5: "大师",
        6: "传奇"
    ]
    
    // Legacy types for backward compatibility
    static let legacyTypes: [AchievementType] = [
        .meeting, .thinking, .work, .life, .exercise, .reading, .sleep, .relax
    ]
    
    // 旧有的基础类型 - 保留以确保向后兼容性
    case meeting = "会议"   // 会议
    case thinking = "思考"  // 思考
    case work = "工作"      // 工作
    case life = "生活"      // 生活
    case exercise = "运动"  // 运动
    case reading = "阅读"   // 阅读
    case sleep = "睡眠"     // 睡眠
    case relax = "摸鱼"     // 摸鱼
    
    // 新增习惯养成类成就
    case dailyStreak = "每日打卡"     // 连续每日使用
    case weeklyStreak = "每周印记"    // 连续每周使用
    case monthlyStreak = "月度常客"   // 连续每月使用
    case taskCompletion = "任务完成者" // 完成任务相关
    case focusMilestone = "专注里程碑" // 专注时间里程碑
    
    // 新增时间管理洞察类成就
    case planAccuracy = "规划精准度"   // 任务时间分配符合标准
    case focusEfficiency = "专注与效率" // 专注效率相关
    case timeTrend = "时间趋势"       // 时间趋势分析相关
    case taskEfficiency = "任务效率"   // 任务效率相关
    
    // 新增时间调整反馈类成就
    case timeWizard = "时间魔法师"     // 调整次数/幅度相关
    case estimationMaster = "估时达人"  // 预估准确性相关
    case focusStar = "专注之星"        // 专注稳定性相关
    
    // 新增角色目标类成就
    case rolePractitioner = "角色践行者" // 符合角色标准
    case roleModel = "角色模范"        // 连续符合角色标准 
    case goalCrusher = "目标粉碎机"     // 高优先任务达标
    
    // 周重置类型 - 这三个类型会每周重置进度
    case balanceMaster = "平衡大师"    // 工作生活平衡
    
    var id: String { self.rawValue }
    
    var name: String {
        return self.rawValue
    }
    
    var category: SystemAchievementCategory {
        switch self {
        // 旧有类型归类到相应的新类别
        case .meeting, .thinking, .work, .life, .exercise, .reading, .sleep, .relax:
            return .insight // 暂时归为洞察类
            
        // 新增类型
        case .dailyStreak, .weeklyStreak, .monthlyStreak, .taskCompletion, .focusMilestone:
            return .habit
        case .planAccuracy, .focusEfficiency, .timeTrend:
            return .insight
        case .timeWizard, .estimationMaster, .focusStar:
            return .adjustment
        case .rolePractitioner, .roleModel, .goalCrusher:
            return .role
        case .balanceMaster:
            return .role
        case .taskEfficiency:
            return .insight
        }
    }
    
    var icon: String {
        switch self {
        // 旧有类型图标保持不变
        case .work: return "briefcase.fill"
        case .thinking: return "brain.head.profile"
        case .meeting: return "person.2.fill"
        case .exercise: return "figure.walk"
        case .reading: return "book.closed.fill"
        case .life: return "heart.fill"
        case .relax: return "fish.fill"
        case .sleep: return "bed.double.fill"
            
        // 新增类型图标
        case .dailyStreak: return "calendar.badge.clock"
        case .weeklyStreak: return "calendar.badge.exclamationmark"
        case .monthlyStreak: return "calendar.circle.fill"
        case .taskCompletion: return "checkmark.circle.fill"
        case .focusMilestone: return "timer"
            
        case .planAccuracy: return "ruler.fill"
        case .focusEfficiency: return "bolt.fill"
        case .timeTrend: return "chart.line.uptrend.xyaxis"
            
        case .timeWizard: return "wand.and.stars"
        case .estimationMaster: return "clock.fill"
        case .focusStar: return "star.fill"
            
        case .rolePractitioner: return "person.fill"
        case .roleModel: return "person.3.fill"
        case .goalCrusher: return "target"
        case .balanceMaster: return "balance.fill"
        case .taskEfficiency: return "gauge.with.dots.needle.50percent"
        }
    }
    
    // 定义成就等级门槛 - 根据不同的成就类型有不同的评判标准
    func getThresholds() -> [Int] {
        switch self {
        // 旧有类型的时间门槛（分钟）保持不变
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
            
        // 新增类型的门槛设定 (根据对应单位)
        
        // 连续天数/周数/月数
        case .dailyStreak:
            return [3, 7, 14, 30, 60, 90] // 天数
        case .weeklyStreak:
            return [2, 4, 8, 12, 16, 20] // 周数
        case .monthlyStreak:
            return [1, 2, 3, 6, 9, 12] // 月数
            
        // 任务完成相关
        case .taskCompletion:
            return [10, 50, 100, 200, 500, 1000] // 完成任务数量
        case .focusMilestone:
            return [300, 1000, 3000, 10000, 30000, 60000] // 专注总分钟数
            
        // 规划相关
        case .planAccuracy:
            return [3, 7, 14, 21, 30, 60] // 连续达标天数
        case .focusEfficiency:
            return [3, 7, 14, 21, 30, 60] // 高效率连续天数
        case .timeTrend:
            return [2, 4, 6, 8, 10, 12] // 持续优化周数
            
        // 调整相关 - 这些采用不同的评判标准，这里仅是占位
        case .timeWizard, .estimationMaster, .focusStar:
            return [5, 10, 20, 40, 80, 100] // 这些成就有特殊判定逻辑
            
        // 角色相关
        case .rolePractitioner, .roleModel, .goalCrusher:
            return [1, 3, 7, 14, 30, 60] // 符合标准的天数/次数
        case .balanceMaster:
            return [1, 7, 14, 21, 30, 60] // 平衡大师的等级门槛
        case .taskEfficiency:
            return [3, 7, 14, 21, 30, 60] // 任务效率的门槛
        }
    }
    
    // 兼容旧有的成就等级计算方法
    func achievementLevel(for value: Int) -> Int {
        let thresholds = getThresholds()
        for (index, threshold) in thresholds.enumerated() {
            if value < threshold {
                return index
            }
        }
        return thresholds.count
    }
    
    // 兼容性别名
    func level(for minutes: Int) -> Int {
        return achievementLevel(for: minutes)
    }
    
    // Adding compatibility method for UserModel.swift
    var levelThresholds: [Int] {
        return getThresholds()
    }
    
    // 计算到下一级所需的值
    func valueToNextLevel(current: Int) -> Int {
        let thresholds = getThresholds()
        let currentLevel = achievementLevel(for: current)
        if currentLevel < thresholds.count {
            return thresholds[currentLevel] - current
        }
        return 0
    }
    
    // 获取下一级的阈值
    func nextLevelThreshold(current: Int) -> Int? {
        let thresholds = getThresholds()
        let currentLevel = achievementLevel(for: current)
        if currentLevel < thresholds.count {
            return thresholds[currentLevel]
        }
        return nil
    }
    
    var color: Color {
        switch self {
        // 旧有类型颜色
        case .work: return .blue
        case .reading: return .orange
        case .exercise: return .red
        case .meeting: return .pink
        case .thinking: return .orange
        case .life: return .red
        case .relax: return .mint
        case .sleep: return .green.opacity(0.8)
            
        // 新增类型颜色
        case .dailyStreak, .weeklyStreak, .monthlyStreak:
            return .blue
        case .taskCompletion, .focusMilestone:
            return .indigo
            
        case .planAccuracy, .focusEfficiency, .timeTrend:
            return .orange
            
        case .timeWizard:
            return .purple
        case .estimationMaster:
            return .cyan
        case .focusStar:
            return .yellow
            
        case .rolePractitioner, .roleModel, .goalCrusher:
            return .green
        case .balanceMaster:
            return .purple
        case .taskEfficiency:
            return .teal
        }
    }
    
    // 根据等级获取颜色
    func colorForLevel(_ level: Int) -> Color {
        let opacity = min(Double(level) * 0.2 + 0.2, 1.0)
        return self.color.opacity(opacity)
    }
    
    // 通用等级颜色
    func levelColor(_ level: Int) -> Color {
        let colors: [Color] = [
            .gray,    // 0级 - 未解锁
            .blue,    // 1级 - 新手
            .green,   // 2级 - 进阶
            .yellow,  // 3级 - 专家
            .orange,  // 4级 - 大师
            .red,     // 5级 - 传奇
            .purple   // 6级 - 传说(额外)
        ]
        return colors[min(level, colors.count - 1)]
    }
    
    // 计算进度百分比
    func progressPercentage(for value: Int) -> Double {
        let thresholds = getThresholds()
        let currentLevel = achievementLevel(for: value)
        
        if currentLevel == 0 {
            return Double(value) / Double(thresholds[0])
        } else if currentLevel >= thresholds.count {
            return 1.0
        } else {
            let prevThreshold = thresholds[currentLevel - 1]
            let nextThreshold = thresholds[currentLevel]
            return Double(value - prevThreshold) / Double(nextThreshold - prevThreshold)
        }
    }
    
    // 获取成就等级描述
    func levelDescription(_ level: Int) -> String {
        // 旧有类型保持原有描述
        if [.meeting, .thinking, .life, .exercise, .work, .reading, .sleep, .relax].contains(self) {
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
            default:
                return "等级 \(level)"
        }
    }
    
        // 新增类型的等级描述
        switch self {
        // 习惯养成类
        case .dailyStreak:
            let titles = ["未解锁", "习惯萌芽", "习惯生根", "习惯成长", "习惯开花", "习惯结果", "习惯大师"]
            return titles[min(level, titles.count - 1)]
        case .weeklyStreak:
            let titles = ["未解锁", "周常初学者", "周常探索者", "周常实践者", "周常专家", "周常大师", "周常传奇"]
            return titles[min(level, titles.count - 1)]
        case .monthlyStreak:
            let titles = ["未解锁", "月度新星", "月度常青", "季度常客", "半年铁粉", "年度钻石", "终身VIP"]
            return titles[min(level, titles.count - 1)]
        case .taskCompletion:
            let titles = ["未解锁", "任务起步者", "任务猎手", "任务收割机", "任务主宰", "任务传奇", "任务之神"]
            return titles[min(level, titles.count - 1)]
        case .focusMilestone:
            let titles = ["未解锁", "专注初学者", "专注实践者", "专注行家", "专注大师", "专注宗师", "专注传奇"]
            return titles[min(level, titles.count - 1)]
            
        // 时间管理洞察类
        case .planAccuracy:
            let titles = ["未解锁", "时间学徒", "时间实习生", "时间规划师", "时间策略家", "时间大师", "时间建筑师"]
            return titles[min(level, titles.count - 1)]
        case .focusEfficiency:
            let titles = ["未解锁", "效率觉醒", "效率提升", "效率专家", "效率引擎", "效率大师", "效率传奇"]
            return titles[min(level, titles.count - 1)]
        case .timeTrend:
            let titles = ["未解锁", "趋势观察者", "趋势分析师", "趋势预测师", "趋势操盘手", "趋势大师", "趋势先知"]
            return titles[min(level, titles.count - 1)]
            
        // 时间调整反馈类
        case .timeWizard:
            let titles = ["未解锁", "时间学徒", "时间工匠", "时间魔术师", "时间炼金师", "时间领主", "时间守护者"]
            return titles[min(level, titles.count - 1)]
        case .estimationMaster:
            let titles = ["未解锁", "估时学徒", "估时能手", "估时专家", "估时大师", "估时预言家", "估时传奇"]
            return titles[min(level, titles.count - 1)]
        case .focusStar:
            let titles = ["未解锁", "专注新秀", "专注能手", "专注明星", "专注巨星", "专注宗师", "专注传奇"]
            return titles[min(level, titles.count - 1)]
            
        // 角色目标类
        case .rolePractitioner:
            let titles = ["未解锁", "角色体验者", "角色实习生", "角色专家", "角色大师", "角色传承者", "角色传奇"]
            return titles[min(level, titles.count - 1)]
        case .roleModel:
            let titles = ["未解锁", "模范学徒", "模范践行者", "模范专家", "模范领袖", "模范宗师", "模范传奇"]
            return titles[min(level, titles.count - 1)]
        case .goalCrusher:
            let titles = ["未解锁", "目标追寻者", "目标实现者", "目标征服者", "目标粉碎者", "目标收割机", "目标主宰"]
            return titles[min(level, titles.count - 1)]
        case .balanceMaster:
            let titles = ["未解锁", "平衡初学者", "平衡实践者", "平衡行家", "平衡大师", "平衡宗师", "平衡传奇"]
            return titles[min(level, titles.count - 1)]
        case .taskEfficiency:
            let titles = ["未解锁", "效率萌新", "效率学徒", "效率能手", "效率专家", "效率大师", "效率之王"]
            return titles[min(level, titles.count - 1)]
        default:
            return "等级 \(level)"
        }
    }
    
    // 获取成就描述 - 返回可以展示给用户的详细说明
    func achievementDescription(for level: Int) -> String {
        // 成就具体的描述，解释如何获取该成就
        switch self {
        case .dailyStreak:
            let days = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(days)天每天记录至少1项任务"
        case .weeklyStreak:
            let weeks = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(weeks)周每周记录至少3天"
        case .monthlyStreak:
            let months = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(months)个月每月记录至少15天"
        case .taskCompletion:
            let tasks = getThresholds()[min(level, getThresholds().count-1)]
            return "成功完成\(tasks)个任务"
        case .focusMilestone:
            let minutes = getThresholds()[min(level, getThresholds().count-1)]
            return "累计专注时长达到\(minutes)分钟"
            
        case .planAccuracy:
            let days = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(days)天将任务时间偏差控制在合理范围内"
        case .focusEfficiency:
            let days = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(days)天保持高效率，低任务终止率"
        case .timeTrend:
            let weeks = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(weeks)周优化时间分配，持续改进"
            
        case .timeWizard:
            return "在调整任务时间方面达到了一定水平"
        case .estimationMaster:
            return "在准确预估任务时间方面达到了精通"
        case .focusStar:
            return "在保持专注、减少中断方面有卓越表现"
            
        case .rolePractitioner:
            return "在符合所选角色标准的时间管理上有所成就"
        case .roleModel:
            let days = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(days)天时间分配符合所选角色标准"
        case .goalCrusher:
            return "在完成高优先级任务方面表现出色"
        case .balanceMaster:
            return "在平衡工作与生活方面表现出色"
        case .taskEfficiency:
            let days = getThresholds()[min(level, getThresholds().count-1)]
            return "连续\(days)天完成任务效率达到优秀水平"
            
        // 旧类型返回简单描述
        default:
            if level == 0 {
                return "继续努力，完成更多时间"
            } else if level < getThresholds().count {
                return "达到了\(self.rawValue)时间累计的第\(level)级成就"
            } else {
                return "达到了\(self.rawValue)时间累计的最高级成就"
            }
        }
    }
    
    // 提供成就建议
    func achievementSuggestion(for level: Int) -> String {
        if level == 0 {
            let nextThreshold = getThresholds()[0]
            
            switch self {
            case .dailyStreak, .weeklyStreak, .monthlyStreak, 
                 .taskCompletion, .focusMilestone:
                return "继续保持记录和完成任务的习惯"
                
            case .planAccuracy, .focusEfficiency, .timeTrend:
                return "关注自己的时间管理模式，尝试优化分配"
                
            case .timeWizard, .estimationMaster, .focusStar:
                return "留意任务时间的调整和执行情况"
                
            case .rolePractitioner, .roleModel, .goalCrusher:
                return "尝试按照自己的角色标准分配时间"
            case .balanceMaster:
                return "尝试平衡工作与生活，寻找更好的工作与生活平衡"
            case .taskEfficiency:
                return "关注任务完成的效率，避免拖延和低效的工作方式"
                
            // 旧有类型
            default:
                return "继续积累\(self.rawValue)类型的时间，再需\(nextThreshold)分钟解锁下一级"
            }
        } else if level < getThresholds().count {
            // 给已有一定等级的成就提供进一步建议
            return "再接再厉，挑战\(levelDescription(level+1))级别"
        } else {
            return "恭喜达到最高级别！继续保持优秀"
        }
    }
} 
