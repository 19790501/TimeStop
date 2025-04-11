import Foundation
import SwiftUI


enum VerificationMethod: String, Codable, CaseIterable {
    case drawing = "绘画"
    case singing = "唱歌"
    case reading = "读单词"
    
    static func random() -> VerificationMethod {
        VerificationMethod.allCases.randomElement() ?? .drawing
    }
    
    var icon: String {
        switch self {
        case .drawing: return "paintbrush"
        case .singing: return "music.mic"
        case .reading: return "text.book.closed"
        }
    }
}

struct Task: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var duration: Int // in minutes
    var completedAt: Date?
    var createdAt: Date
    var note: String?
    var isCompleted: Bool { completedAt != nil }
    var focusType: FocusType
    var verificationMethod: VerificationMethod?
    
    init(id: String = UUID().uuidString, 
         title: String, 
         focusType: FocusType, 
         duration: Int, 
         createdAt: Date = Date(), 
         completedAt: Date? = nil, 
         note: String? = nil, 
         verificationMethod: VerificationMethod? = nil) {
        self.id = id
        self.title = title
        self.focusType = focusType
        self.duration = duration
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.note = note
        self.verificationMethod = verificationMethod
    }
    
    // Implement Equatable
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
    
    enum FocusType: String, Codable, CaseIterable {
        case general
        case audio
        case writing
        case productivity
        case success
        
        var icon: String {
            switch self {
            case .general: return "target"
            case .audio: return "music.note"
            case .writing: return "pencil"
            case .productivity: return "chart.bar.fill"
            case .success: return "trophy"
            }
        }
    }
}

// 任务类型枚举
enum ActivityType: String, CaseIterable {
    case sleep = "睡觉"
    case relax = "摸鱼"
    case thinking = "思考"
    case work = "工作"
    case meeting = "会议"
    case life = "生活"
    case exercise = "运动"
    case reading = "阅读"
    
    var icon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .relax: return "fish.fill"
        case .thinking: return "brain"
        case .work: return "briefcase.fill"
        case .meeting: return "person.2.fill"
        case .life: return "heart.fill"
        case .exercise: return "figure.run"
        case .reading: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sleep: return Color.indigo.opacity(0.7)
        case .relax: return Color.cyan.opacity(0.7)
        case .thinking: return Color.purple.opacity(0.7)
        case .work: return Color.blue.opacity(0.7)
        case .meeting: return Color.orange.opacity(0.7)
        case .life: return Color.pink.opacity(0.7)
        case .exercise: return Color.green.opacity(0.7)
        case .reading: return Color.yellow.opacity(0.7)
        }
    }
    
    // 判断任务时间是否超过阈值（今日头条）
    func isOverThreshold(minutes: Int) -> Bool {
        switch self {
        case .exercise: return minutes >= 60   // 运动 >= 60分钟
        case .sleep: return minutes >= 500     // 睡觉 >= 500分钟
        case .work: return minutes >= 360      // 工作 >= 360分钟
        case .life: return minutes >= 120      // 生活 >= 120分钟
        case .reading: return minutes >= 90    // 阅读 >= 90分钟
        case .relax: return minutes >= 90      // 摸鱼 >= 90分钟
        case .meeting: return minutes >= 240   // 会议 >= 240分钟
        case .thinking: return minutes >= 180  // 思考 >= 180分钟
        }
    }
    
    // 判断任务时间是否低于阈值（今日辣条）
    func isUnderThreshold(minutes: Int) -> Bool {
        switch self {
        case .exercise: return minutes > 0 && minutes <= 10  // 运动 <= 10分钟
        case .sleep: return minutes > 0 && minutes <= 240    // 睡觉 <= 240分钟
        case .work: return minutes > 0 && minutes <= 120     // 工作 <= 120分钟
        case .life: return minutes > 0 && minutes <= 15      // 生活 <= 15分钟
        case .reading: return minutes > 0 && minutes <= 15   // 阅读 <= 15分钟
        case .relax: return minutes > 0 && minutes <= 10     // 摸鱼 <= 10分钟
        case .meeting: return minutes > 0 && minutes <= 15   // 会议 <= 15分钟
        case .thinking: return minutes > 0 && minutes <= 20  // 思考 <= 20分钟
        }
    }
    
    // 每日最多时间的描述
    func maxDescription() -> (emoji: String, title: String, description: String) {
        switch self {
        case .sleep:
            return ("🛌", "冬眠候选熊", "检测到您已逼近树懒作息，建议将床垫改装成工位以节省通勤痛苦")
        case .relax:
            return ("🦑", "带薪章鱼博士", "您的摸鱼触手已覆盖6.7个平行宇宙，建议向NASA发送天才简历")
        case .thinking:
            return ("🤔", "脑内脱口秀冠军", "您今日的颅内弹幕可填满B站服务器")
        case .work:
            return ("⚡", "资本の闪电侠", "您的时间折叠术导致老板游艇加速生锈，建议用摸鱼缓冲")
        case .meeting:
            return ("🕳️", "时间黑洞质检员", "您参与的无效讨论可填平马里亚纳海沟，建议向联合国申报环保基金")
        case .life:
            return ("🌸", "小确幸收割机", "您的幸福值威胁到资本剩余价值率，建议用KPI中和生活多巴胺")
        case .exercise:
            return ("🏃", "多巴胺狂战士", "您的内啡肽分泌量可供应整栋写字楼，建议向健身房申请股东身份")
        case .reading:
            return ("📚", "纸质宇宙宇航员", "您的脑内图书馆藏书量已超国家数据中心，建议申请知识通胀补贴")
        }
    }
    
    // 每日最少时间的描述
    func minDescription() -> (emoji: String, title: String, description: String) {
        switch self {
        case .sleep:
            return ("☕", "咖啡因永动机", "您的心脏正在用摩斯电码求救，建议用15分钟睡眠偿还生命高利贷")
        case .relax:
            return ("🤖", "AI机器人原型机", "检测到人类情感模块缺失，请速至茶水间补充八卦能量")
        case .thinking:
            return ("📌", "反射弧单线程", "您的决策模式进入二进制状态，请速读《人类迷惑行为大赏》重启脑洞")
        case .work:
            return ("🐢", "树懒の尊严守卫者", "您的生产力已低于办公室绿萝，建议马上打开PPT敲代码")
        case .meeting:
            return ("🗿", "沉默の巨石阵", "检测到您已突破人类憋话极限，请领取《会议生存哑语手册》")
        case .life:
            return ("🧪", "工位摄像头", "您已72小时未离开半径3米办公区，建议马上联系朋友掼个蛋")
        case .exercise:
            return ("🪑", "人体工学雕塑", "您的关节润滑度低于办公室转椅，请用5分钟拉伸避免锈蚀报销")
        case .reading:
            return ("🕸️", "信息茧房原住民", "检测到您的大脑正被短视频算法殖民，请用10分钟长文启动反攻")
        }
    }
    
    // 本周最多时间的描述
    func weekMaxDescription() -> (emoji: String, title: String, description: String) {
        switch self {
        case .sleep:
            return ("🛌", "睡美人综合征", "您上周的睡眠时长可孵化恐龙蛋，建议用咖啡因对冲生物钟紊乱")
        case .relax:
            return ("🐠", "鱼类文明考古学家", "您今日挖掘出3个上古摸鱼图层，建议申报非物质文化遗产")
        case .thinking:
            return ("🌌", "银河脑洞漫游者", "您上周的颅内风暴可点亮黑洞，建议用Excel表格修建思维防波堤")
        case .work:
            return ("⚡", "永动机荣誉零件", "您的工作时长已突破热力学第二定律，建议申请宇宙熵增补偿金")
        case .meeting:
            return ("🕸️", "蜘蛛网建筑师", "您上周编织的会议废话可缠绕地球三圈，建议申报吉尼斯无效沟通奖")
        case .life:
            return ("🍃", "生活禅修大师", "您的幸福浓度导致同事焦虑指数上升，建议用加班稀释人间烟火气")
        case .exercise:
            return ("🏋️", "健身房钉子户", "您上周燃烧的卡路里可供电梯运行一周，请向物业申请会员折扣")
        case .reading:
            return ("📜", "知识军备竞赛者", "您上周的阅读量可填满ChatGPT训练库，建议向OpenAI收取版权费")
        }
    }
    
    // 本周最少时间的描述
    func weekMinDescription() -> (emoji: String, title: String, description: String) {
        switch self {
        case .sleep:
            return ("⏳", "时间债台高筑者", "本周睡眠赤字已超国家外债，建议用周末补觉启动量化宽松")
        case .relax:
            return ("🤖", "OKR永动机", "检测到您的工作纯度突破996阈值，系统建议安装摸鱼防爆阀")
        case .thinking:
            return ("📉", "认知单曲循环", "您的决策模式进入单边下跌通道，请用跨界信息对冲思维泡沫")
        case .work:
            return ("🐌", "反内卷先驱", "您的工作量低于行业均值，系统自动订阅《躺平学导论》课程")
        case .meeting:
            return ("🗿", "沉默是金矿", "您的寡言值威胁到老板控制欲，请速补充3句'我觉得可以再对齐一下'")
        case .life:
            return ("🔭", "火星殖民预备役", "检测到您已适应非人类环境，NASA正在评估您的火星工位适配性")
        case .exercise:
            return ("🪑", "人体工学遗产", "您的脊椎弯曲度逼近埃菲尔铁塔，建议用5分钟深蹲赎回健康权")
        case .reading:
            return ("🕳️", "信息饥荒难民", "您的大脑皮层正在荒漠化，请用10分钟长文滴灌神经突触")
        }
    }
} 