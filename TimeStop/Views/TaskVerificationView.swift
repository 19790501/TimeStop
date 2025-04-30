import SwiftUI
import PencilKit
import AVFoundation
import ObjectiveC
import Combine
import UserNotifications
import MediaPlayer
import AudioToolbox

struct TaskVerificationView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var userModel: UserModel
    
    @State private var canvasView = PKCanvasView()
    @State private var drawingImage: UIImage?
    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var verificationText = ""
    @State private var isVerifying = false
    @State private var verificationResult: Bool?
    @State private var showResult = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var hasRecording: Bool = false
    @State private var drawingPrompt: String = "苹果" // 默认绘画提示
    @State private var verificationTimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var verificationTimerSubscription: Cancellable?
    @State private var remainingTime: Int = 5 // 读取倒计时
    @State private var currentWord: (word: String, spelling: String) = ("", "")
    @State private var recordingStartTime: Date? // 记录录音开始时间
    @State private var recordingDuration: TimeInterval = 0 // 记录录音持续时间
    @State private var recordingTimer: Timer? // 用于管理录音时间更新计时器
    
    // 评分相关状态
    @State private var showScore: Bool = false
    @State private var score: Int = 0
    @State private var scoreComment: String = ""
    
    // 评分详情
    @State private var detailedScores: [String: Int] = [:]
    @State private var showDetailedScores: Bool = false
    
    // 单词数据库
    private let wordDatabase: [(word: String, spelling: String)] = [
        ("Apple", "A-P-P-L-E"),
        ("Book", "B-O-O-K"),
        ("Cat", "C-A-T"),
        ("Door", "D-O-O-R"),
        ("Egg", "E-G-G"),
        ("Fish", "F-I-S-H"),
        ("Game", "G-A-M-E"),
        ("House", "H-O-U-S-E"),
        ("Ice", "I-C-E"),
        ("Jacket", "J-A-C-K-E-T"),
        ("King", "K-I-N-G"),
        ("Lion", "L-I-O-N"),
        ("Moon", "M-O-O-N"),
        ("Nest", "N-E-S-T"),
        ("Orange", "O-R-A-N-G-E"),
        ("Pen", "P-E-N"),
        ("Queen", "Q-U-E-E-N"),
        ("Rain", "R-A-I-N"),
        ("Sun", "S-U-N"),
        ("Tree", "T-R-E-E"),
        ("Umbrella", "U-M-B-R-E-L-L-A"),
        ("Van", "V-A-N"),
        ("Window", "W-I-N-D-O-W"),
        ("Box", "B-O-X"),
        ("Yellow", "Y-E-L-L-O-W"),
        ("Zoo", "Z-O-O"),
        ("Bird", "B-I-R-D"),
        ("Cloud", "C-L-O-U-D"),
        ("Dog", "D-O-G"),
        ("Elephant", "E-L-E-P-H-A-N-T"),
        ("Flower", "F-L-O-W-E-R"),
        ("Guitar", "G-U-I-T-A-R"),
        ("Heart", "H-E-A-R-T"),
        ("Island", "I-S-L-A-N-D"),
        ("Juice", "J-U-I-C-E"),
        ("Key", "K-E-Y"),
        ("Leaf", "L-E-A-F"),
        ("Mountain", "M-O-U-N-T-A-I-N"),
        ("Night", "N-I-G-H-T"),
        ("Ocean", "O-C-E-A-N"),
        ("Pencil", "P-E-N-C-I-L"),
        ("Quilt", "Q-U-I-L-T"),
        ("River", "R-I-V-E-R"),
        ("Star", "S-T-A-R"),
        ("Table", "T-A-B-L-E"),
        ("Unicorn", "U-N-I-C-O-R-N"),
        ("Violin", "V-I-O-L-I-N"),
        ("Water", "W-A-T-E-R"),
        ("Xylophone", "X-Y-L-O-P-H-O-N-E"),
        ("Yacht", "Y-A-C-H-T"),
        ("Zebra", "Z-E-B-R-A")
    ]
    
    @State private var showSpelling: Bool = false
    @State private var isPlayingPronunciation: Bool = false
    
    // 常量定义，避免魔法数字
    private enum Constants {
        static let canvasHeight: CGFloat = 450
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 90
        static let standardPadding: CGFloat = 5
        static let verificationDuration: TimeInterval = 0.5
    }
    
    @State private var speechSynthesizer: AVSpeechSynthesizer?
    @State private var speechDelegate: SpeechDelegate?
    
    // 添加单词中文翻译字典
    private let wordTranslations: [String: String] = [
        "Apple": "苹果",
        "Book": "书",
        "Cat": "猫",
        "Door": "门",
        "Egg": "蛋",
        "Fish": "鱼",
        "Game": "游戏",
        "House": "房子",
        "Ice": "冰",
        "Jacket": "夹克",
        "King": "国王",
        "Lion": "狮子",
        "Moon": "月亮",
        "Nest": "巢",
        "Orange": "橙子",
        "Pen": "笔",
        "Queen": "女王",
        "Rain": "雨",
        "Sun": "太阳",
        "Tree": "树",
        "Umbrella": "伞",
        "Van": "厢式货车",
        "Window": "窗户",
        "Box": "盒子",
        "Yellow": "黄色",
        "Zoo": "动物园",
        "Bird": "鸟",
        "Cloud": "云",
        "Dog": "狗",
        "Elephant": "大象",
        "Flower": "花",
        "Guitar": "吉他",
        "Heart": "心脏",
        "Island": "岛屿",
        "Juice": "果汁",
        "Key": "钥匙",
        "Leaf": "叶子",
        "Mountain": "山",
        "Night": "夜晚",
        "Ocean": "海洋",
        "Pencil": "铅笔",
        "Quilt": "被子",
        "River": "河流",
        "Star": "星星",
        "Table": "桌子",
        "Unicorn": "独角兽",
        "Violin": "小提琴",
        "Water": "水",
        "Xylophone": "木琴",
        "Yacht": "游艇",
        "Zebra": "斑马"
    ]
    
    // 添加新状态变量
    @State private var disableCompletionButton: Bool = true // 初始禁用完成按钮
    @State private var isGeneratingScore: Bool = false
    @State private var scoreAnimationActive: Bool = false
    
    // 添加随机激励文案数组
    private let motivationalQuotes = [
        "恭喜您，这一波操作，你已成功抽离，并且给大脑安装了隔离舱！下一场倒计时启动5、4、3...",
        "恭喜！您的专注力能量槽已回复至满格状态",
        "您已获得纯净工作脑，请投入新战斗",
        "真正的倒计时现在才开始",
        "停止是一个动作，更是一种觉醒",
        "别让任务像502胶水层层粘连，你要撕开它"
    ]
    
    // 添加状态变量存储选择的激励文案
    @State private var selectedMotivationalQuote: String = ""
    
    // 在结构体顶部添加新状态
    @State private var transitioningOut: Bool = false
    
    // Add new properties near the top of the struct
    @State private var audioRecorderDelegate: AudioRecorderDelegate?
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 移除顶部导航栏，直接显示验证内容区域
                if showScore {
                    scoreResultView
                } else {
                    if let task = viewModel.activeTask, let method = task.verificationMethod {
                        switch method {
                        case .drawing:
                            drawingVerificationView
                        case .singing:
                            singingVerificationView
                        case .reading:
                            readingVerificationView
                        }
                    }
                }
                
                // 底部操作按钮
                if !showScore {
                    verificationActionButtons
                        .padding(.bottom, 25)
                        .padding(.top, 5)
                } else {
                    // 评分后的确认按钮
                    Button(action: {
                        // 使用异步处理以避免UI卡顿
                        DispatchQueue.main.async {
                            // 先停止所有可能的音频和震动
                            viewModel.stopVerificationAlert()
                            
                            // 使用淡出动画提前开始转场
                            withAnimation(.easeOut(duration: 0.2)) {
                                // 设置过渡状态
                                transitioningOut = true
                            }
                            
                            // 延迟一小段时间后再完成验证
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                completeVerification()
                            }
                        }
                    }) {
                        Text("完成")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.colors.primary)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 25)
                    .padding(.top, 5)
                    .opacity(transitioningOut ? 0.3 : 1.0) // 添加透明度变化以增强过渡效果
                    .disabled(transitioningOut) // 禁用按钮防止重复点击
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("确定") {
                // 确保立即停止声音和震动
                viewModel.stopVerificationAlert()
                
                // 先完成验证
                viewModel.completeVerification()
                
                // 直接关闭验证界面并立即导航到完成页面
                DispatchQueue.main.async {
                    // 确保状态更新
                    navigationManager.isShowingVerification = false
                    navigationManager.isShowingCompletion = true
                    navigationManager.navigate(to: .completion)
                }
            }
        } message: {
            Text(alertMessage)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 设置随机绘画提示
            drawingPrompt = getRandomDrawingPrompt()
            setupCanvas()
            
            // 启动计时器
            startVerificationTimer()
            
            // 只在初次加载时设置一个固定的单词
            if currentWord.word.isEmpty {
                currentWord = wordDatabase.randomElement() ?? ("Apple", "A-P-P-L-E")
            }
            
            // 初始禁用完成按钮
            disableCompletionButton = true
            
            // 5秒后启用完成按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation {
                    disableCompletionButton = false
                }
            }
            
            // 随机选择一条激励文案
            selectedMotivationalQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
            
            // 预加载评分页面资源
            DispatchQueue.global(qos: .userInitiated).async {
                // 预加载任何评分页面需要的资源
                // 这里可以加载图片、预计算数据等
            }
            
            // 重置过渡状态
            transitioningOut = false
            
            // 设置应用生命周期监听
            setupAppLifecycleObservers()
            
            // 确保必要的目录存在
            ensureDirectoriesExist()
            
            // 添加应用终止通知监听
            NotificationCenter.default.addObserver(
                forName: UIApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.prepareForAppTermination()
            }
        }
        .onDisappear {
            // 1. 先取消所有计时器
            cancelVerificationTimer()
            stopRecordingTimer()
            
            // 2. 停止录音和播放
            stopRecording()
            stopPlaying()
            
            // 3. 释放音频资源
            releaseAudioResources()
            
            // 4. 移除通知观察者
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: viewModel.selectedVerificationMethod) { newValue in
            // 切换到绘画验证时重新设置提示
            if newValue == .drawing {
                drawingPrompt = getRandomDrawingPrompt()
            }
        }
        .onChange(of: remainingTime) { newValue in
            if newValue <= 0 {
                cancelVerificationTimer()
                
                if viewModel.selectedVerificationMethod == .reading {
                    readVerificationCompleted()
                }
            }
        }
        .onReceive(verificationTimerPublisher) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            }
        }
    }
    
    // 绘画验证视图
    private var drawingVerificationView: some View {
        VStack(spacing: 6) {
            Text("请根据提示绘画")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // 绘画提示
            Text(viewModel.verificationDrawingPrompt)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.vertical, 10)
            
            // 新增暂停铃声按钮
            Button(action: {
                viewModel.stopVerificationAlert()
                viewModel.playButtonSound()
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "bell.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text("暂停铃声")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.7))
                )
            }
            .padding(.bottom, 5)
            
            // 添加参考图
            referenceImageView(for: viewModel.verificationDrawingPrompt)
                .padding(.bottom, 10)
            
            // 画布视图
            CanvasWrapper(canvasView: $canvasView)
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
        }
    }
    
    // 根据提示获取对应的参考图
    private func referenceImageView(for prompt: String) -> some View {
        let imageName = getReferenceImage(for: prompt)
        let size: CGFloat = prompt == "房子" ? 80 : 70
        
        return VStack {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.white)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            Text("参考图")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.top, 5)
        }
    }
    
    // 根据提示获取对应的系统图标名称 - 更新图标集合
    private func getReferenceImage(for prompt: String) -> String {
        switch prompt {
        // 原有图标
        case "苹果": return "apple.logo"
        case "太阳": return "sun.max.fill"
        case "树": return "leaf.fill"
        case "花": return "flower.fill" 
        case "房子": return "house.fill"
        case "笑脸": return "face.smiling.fill"
        case "星星": return "star.fill"
        case "汽车": return "car.fill"
        case "小猫": return "cat.fill"
        case "小狗": return "pawprint.fill"
        case "鸡蛋": return "oval.fill"
        case "鱼": return "fish.fill"
        
        // 新增图标 - 额外十种绘画参考
        case "月亮": return "moon.fill"
        case "飞机": return "airplane"
        case "手机": return "iphone"
        case "铅笔": return "pencil"
        case "书本": return "book.fill"
        case "电脑": return "desktopcomputer"
        case "心形": return "heart.fill"
        case "山脉": return "mountain.2.fill"
        case "钟表": return "clock.fill"
        case "伞": return "umbrella.fill"
        
        default: return "scribble"
        }
    }
    
    // 唱歌验证视图
    private var singingVerificationView: some View {
        VStack(spacing: 6) {
            Text("请唱一首歌曲")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // 录音状态显示
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 450)
                
                VStack(spacing: 20) {
                    // 新增暂停铃声按钮
                    Button(action: {
                        viewModel.stopVerificationAlert()
                        viewModel.playButtonSound()
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "bell.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            Text("暂停铃声")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.7))
                        )
                    }
                    .padding(.bottom, 10)
                    
                    Image(systemName: isRecording ? "waveform" : "music.mic")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(isRecording ? .red : .white)
                    
                    if isRecording {
                        Text("正在录音... \(formatRecordingTimeWithMs(recordingDuration))")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .monospacedDigit() // 使用等宽字体确保数字对齐
                    } else {
                        Text(hasRecording ? "录音完成 (\(formatRecordingTime(recordingDuration)))" : "点击下方按钮开始录音\n需要录制至少8秒")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    if isRecording {
                        // 录音时的波形动画效果
                        HStack(spacing: 4) {
                            ForEach(0..<7) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                                    .frame(width: 4, height: CGFloat.random(in: 10...40))
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(i) * 0.1),
                                        value: isRecording
                                    )
                            }
                        }
                        
                        // 添加计时进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .fill(recordingDuration >= 8.0 ? Color.green : Color.red)
                                .frame(width: min(CGFloat(recordingDuration) / 8.0, 1.0) * 200, height: 10)
                        }
                        .frame(width: 200)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 朗读验证视图
    private var readingVerificationView: some View {
        VStack(spacing: 6) {
            Text("请朗读单词")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // 朗读内容显示
            VStack(spacing: 25) {
                // 新增暂停铃声按钮
                Button(action: {
                    viewModel.stopVerificationAlert()
                    viewModel.playButtonSound()
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: "bell.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text("暂停铃声")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.7))
                    )
                }
                .padding(.bottom, 5)
                
                Text("请朗读以下单词")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // 添加中文翻译
                if let translation = wordTranslations[currentWord.word] {
                    Text(translation)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, -15)
                }
                
                Text(currentWord.word)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                
                // 播放发音按钮
                Button(action: {
                    playWordPronunciation()
                }) {
                    HStack {
                        Image(systemName: isPlayingPronunciation ? "speaker.wave.2.fill" : "speaker.wave.2")
                        Text("播放发音")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    )
                }
                .disabled(isPlayingPronunciation)
            }
            .frame(maxWidth: .infinity, maxHeight: 450)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal)
    }
    
    // 底部操作按钮
    private var verificationActionButtons: some View {
        HStack(spacing: 20) {
            // 根据不同的验证方式显示不同的按钮
            if let task = viewModel.activeTask, let method = task.verificationMethod {
                switch method {
                case .drawing:
                    // 清除按钮
                    Button(action: {
                        // 播放按钮音效
                        viewModel.playButtonSound()
                        
                        // 直接在主线程执行清除操作
                        DispatchQueue.main.async {
                            // 创建新的空白绘图并设置到canvasView
                            self.canvasView = PKCanvasView() // 创建全新实例
                            self.canvasView.isOpaque = true
                            self.canvasView.backgroundColor = .white
                            self.canvasView.drawingPolicy = .anyInput
                            
                            // 使用更粗的红色笔束，确保可见性
                            let ink = PKInk(.marker, color: .red)
                            let tool = PKInkingTool(ink: ink, width: 18.0)
                            self.canvasView.tool = tool
                            
                            // 移除对objectWillChange的引用，替换为临时设置状态变量以刷新视图
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                // 通过修改和还原某个@State变量来强制视图刷新
                                let originalValue = self.disableCompletionButton
                                self.disableCompletionButton = !originalValue
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                    self.disableCompletionButton = originalValue
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                        )
                    }
                    
                    // 任务完成按钮 - 改为关闭铃声功能
                    Button(action: {
                        // 停止铃声
                        viewModel.stopVerificationAlert()
                        // 播放成功音效
                        viewModel.playSuccessSound()
                        // 验证绘画
                        verifyDrawing()
                    }) {
                        Text("绘画完成")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(disableCompletionButton ? Color.gray : themeManager.colors.primary)
                            )
                    }
                    .disabled(disableCompletionButton) // 5秒内禁用
                    
                case .singing:
                    // 开始/停止录音按钮
                    Button(action: {
                        if isRecording {
                            // 如果正在录音，则停止录音
                            stopRecording()
                        } else {
                            // 播放按钮音效
                            viewModel.playButtonSound()
                            
                            // 开始录音
                            startRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(isRecording ? "停止" : "开始录音")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isRecording ? Color.red : Color.gray.opacity(0.3))
                        )
                    }
                    .disabled(disableCompletionButton) // 5秒内禁用
                    
                    // 完成按钮 - 改为关闭铃声功能，5秒内禁用
                    Button(action: {
                        // 停止铃声以确保安静
                        viewModel.stopVerificationAlert()
                        // 播放成功音效
                        viewModel.playSuccessSound()
                        // 验证唱歌
                        verifySinging()
                    }) {
                        Text("唱歌完成")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(disableCompletionButton || !hasRecording || recordingDuration < 8.0 ? 
                                         Color.gray : themeManager.colors.primary)
                            )
                    }
                    .disabled(disableCompletionButton || !hasRecording || recordingDuration < 8.0) // 5秒内或不满条件时禁用
                    .opacity(disableCompletionButton ? 0.5 : (hasRecording && recordingDuration >= 8.0 ? 1.0 : 0.5))
                    
                case .reading:
                    // 开始/停止录音按钮
                    Button(action: {
                        if isRecording {
                            // 如果正在录音，则停止录音
                            stopRecording()
                        } else {
                            // 播放按钮音效
                            viewModel.playButtonSound()
                            
                            // 开始录音
                            startRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(isRecording ? "停止" : "开始录音")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isRecording ? Color.red : Color.gray.opacity(0.3))
                        )
                    }
                    .disabled(disableCompletionButton) // 5秒内禁用
                    
                    // 完成按钮
                    Button(action: {
                        // 停止铃声以确保安静
                        viewModel.stopVerificationAlert()
                        // 播放成功音效
                        viewModel.playSuccessSound()
                        // 验证朗读
                        verifyReading()
                    }) {
                        Text("朗读完成")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(disableCompletionButton || !hasRecording ? 
                                         Color.gray : themeManager.colors.primary)
                            )
                    }
                    .disabled(disableCompletionButton || !hasRecording) // 5秒内或没有录音时禁用
                    .opacity(disableCompletionButton ? 0.5 : (hasRecording ? 1.0 : 0.5))
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 评分结果视图
    private var scoreResultView: some View {
        VStack(spacing: 40) {
            // 分数显示
            VStack(spacing: 25) {
                if isGeneratingScore {
                    // 生成分数时显示加载动画
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical, 60)
                    
                    Text("正在生成评分...")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 60)
                } else {
                    // 显示生成的评分
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(score) / 100)
                            .stroke(
                                getScoreColor(),
                                style: StrokeStyle(lineWidth: 15, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: scoreAnimationActive)
                        
                        VStack(spacing: 5) {
                            Text("\(score)")
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("分")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // 添加随机激励文字 - 增强显示效果
                    VStack(spacing: 15) {
                        Text(scoreComment)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .padding(.top, -10)
                        
                        Text(selectedMotivationalQuote)
                            .font(.custom("時·停", size: 22))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal)
                            .padding(.vertical, 20)
                    }
                    .padding(.bottom, 10)
                    
                    // 显示/隐藏评分详情按钮
                    Button(action: {
                        withAnimation {
                            showDetailedScores.toggle()
                        }
                    }) {
                        HStack {
                            Text(showDetailedScores ? "隐藏详情" : "查看详情")
                                .font(.system(size: 14))
                            Image(systemName: showDetailedScores ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .padding(.top, 5)
                    
                    // 评分详情
                    if showDetailedScores {
                        VStack(spacing: 12) {
                            ForEach(Array(detailedScores.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\(detailedScores[key] ?? 0)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(getDetailScoreColor(score: detailedScores[key] ?? 0))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }
                        .padding(.top, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.3))
                    .shadow(color: getScoreColor().opacity(0.2), radius: 15, x: 0, y: 0)
            )
        }
        .padding()
        .transition(.opacity)
    }
    
    // 单项评分颜色
    private func getDetailScoreColor(score: Int) -> Color {
        switch score {
        case 0...5:
            return .red
        case 6...10:
            return .orange
        case 11...15:
            return .yellow
        default:
            return .green
        }
    }
    
    // 获取评分对应的颜色
    private func getScoreColor() -> Color {
        switch score {
        case 0...25:
            return .red
        case 26...50:
            return .orange
        case 51...75:
            return .yellow
        default:
            return .green
        }
    }
    
    // 获取评分对应的评价
    private func getScoreComment(for score: Int, method: VerificationMethod) -> String {
        switch method {
        case .drawing:
            switch score {
            case 0...25:
                return "🎨 您画的\(drawingPrompt)成功避开了\(drawingPrompt)所有的特征"
            case 26...50:
                return "🖌️ 我觉得您把柚子也能画成屁股"
            case 51...75:
                return "🖼️ 系统怀疑您偷偷安装了Photoshop插件"
            default:
                return "🏆 蒙娜丽莎看到您的画作，露出了神秘的微笑"
            }
        case .singing:
            switch score {
            case 0...25:
                return "🎤 亲，这边建议您改行玩尖叫鸡呢~"
            case 26...50:
                return "🔇 当您按下暂停键的瞬间，全人类都在感恩"
            case 51...75:
                return "🎵 您让歌神宣布退出歌坛"
            default:
                return "🏆 建议立即联系格莱美"
            }
        case .reading:
            switch score {
            case 0...25:
                return "🗣️ 您难道是我失散多年的广西表哥？"
            case 26...50:
                return "🦜 鹦鹉也能听懂您的发音"
            case 51...75:
                return "📱 您肯定是用了英语提词器"
            default:
                return "🏆 系统已将您的发音作为AI学习样本"
            }
        }
    }
    
    // MARK: - 功能方法
    
    private func setupCanvas() {
        // 基础配置
        canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        
        // 使用更粗的红色笔束，确保可见性
        let ink = PKInk(.marker, color: .red)
        let tool = PKInkingTool(ink: ink, width: 18.0)
        canvasView.tool = tool
    }
    
    // 获取随机绘画提示
    private func getRandomDrawingPrompt() -> String {
        // 包含所有有可靠系统图标的提示，包括原有和新增的
        let prompts = [
            // 原有提示
            "苹果", "太阳", "树", "房子", "笑脸", "星星", "汽车", "小猫", "鸡蛋",
            // 新增提示
            "月亮", "飞机", "手机", "铅笔", "书本", "电脑", "心形", "山脉", "钟表", "伞"
        ]
        return prompts.randomElement() ?? "苹果"
    }
    
    // 获取随机单词
    private func getRandomWord() -> String {
        let words = ["Apple", "Book", "Cat", "Door", "Egg", "Fish", "Game", "House", "Ice", "Jacket"]
        return words.randomElement() ?? "Apple"
    }
    
    // 修改任务完成按钮处理函数 - 绘画验证
    private func verifyDrawing() {
        // 停止所有铃声和震动
        viewModel.stopVerificationAlert()
        
        // 立即显示评分界面
        withAnimation(.easeInOut(duration: 0.3)) {
            showScore = true
            isGeneratingScore = true
        }
        
        // 预先生成分数数据，避免后续卡顿
        var newDetailedScores: [String: Int] = [:]
        
        // 设置基础分数
        var baseScore = Int.random(in: 5...15)
        newDetailedScores["基础分"] = baseScore
        
        // 1. 绘画完成度评分（根据画布是否有内容）
        let completionScore = canvasView.drawing.bounds.isEmpty ? 0 : Int.random(in: 10...20)
        newDetailedScores["完成度"] = completionScore
        
        // 2. 绘画完成时间评分
        let timeScore = Int.random(in: 5...15)
        newDetailedScores["速度"] = timeScore
        
        // 3. 线条流畅度评分
        let strokeScore = Int.random(in: 5...25)
        newDetailedScores["线条流畅度"] = strokeScore
        
        // 4. 创意分数
        let creativityScore = Int.random(in: 5...25)
        newDetailedScores["创意"] = creativityScore
        
        baseScore += completionScore + timeScore + strokeScore + creativityScore
        
        // 确保分数不超过100
        let finalScore = min(baseScore, 100)
        let finalComment = getScoreComment(for: finalScore, method: .drawing)
        
        // 触发成功反馈
        playSuccessSound()
        
        // 延迟非常短的时间后更新UI，确保动画流畅
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 动画显示分数
            self.scoreAnimationActive = true
            self.score = finalScore
            self.scoreComment = finalComment
            self.detailedScores = newDetailedScores
            
            // 短暂延迟后隐藏加载状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isGeneratingScore = false
                
                // 触发成功验证
                self.handleVerificationSuccess()
            }
        }
    }
    
    // 修改任务完成按钮处理函数 - 唱歌验证
    private func verifySinging() {
        // 停止所有铃声和震动
        viewModel.stopVerificationAlert()
        
        // 确保录音已完全停止
        if isRecording {
            stopRecording()
        }
        
        // 立即显示评分界面
        withAnimation(.easeInOut(duration: 0.3)) {
            showScore = true
            isGeneratingScore = true
        }
        
        // 在后台线程生成分数
        DispatchQueue.global(qos: .userInitiated).async {
            // 预先生成分数数据，避免后续卡顿
            var newDetailedScores: [String: Int] = [:]
            
            // 设置基础分数
            var baseScore = Int.random(in: 5...15)
            newDetailedScores["基础分"] = baseScore
            
            // 1. 基础录音评分
            let recordingScore = self.hasRecording ? Int.random(in: 10...20) : 0
            newDetailedScores["录音质量"] = recordingScore
            
            // 2. 录音时长评分 - 增加录音时长评分
            let durationScore = min(Int(self.recordingDuration) / 2, 20) // 每2秒1分，最高20分
            newDetailedScores["录音时长"] = durationScore
            
            // 3. 音准评分
            let pitchScore = Int.random(in: 5...20)
            newDetailedScores["音准"] = pitchScore
            
            // 4. 情感表达
            let expressionScore = Int.random(in: 5...20)
            newDetailedScores["情感表达"] = expressionScore
            
            baseScore += recordingScore + durationScore + pitchScore + expressionScore
            
            // 确保分数不超过100
            let finalScore = min(baseScore, 100)
            let finalComment = self.getScoreComment(for: finalScore, method: .singing)
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                // 触发成功反馈
                self.playSuccessSound()
                
                // 动画显示分数
                self.scoreAnimationActive = true
                self.score = finalScore
                self.scoreComment = finalComment
                self.detailedScores = newDetailedScores
                
                // 短暂延迟后隐藏加载状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isGeneratingScore = false
                    
                    // 触发成功验证
                    self.handleVerificationSuccess()
                }
            }
        }
    }
    
    // 修改任务完成按钮处理函数 - 朗读验证
    private func verifyReading() {
        // 停止所有铃声和震动
        viewModel.stopVerificationAlert()
        
        // 确保录音已完全停止
        if isRecording {
            stopRecording()
        }
        
        // 立即显示评分界面
        withAnimation(.easeInOut(duration: 0.3)) {
            showScore = true
            isGeneratingScore = true
        }
        
        // 在后台线程生成分数
        DispatchQueue.global(qos: .userInitiated).async {
            // 预先生成分数数据，避免后续卡顿
            var newDetailedScores: [String: Int] = [:]
            
            // 设置基础分数
            var baseScore = Int.random(in: 5...15)
            newDetailedScores["基础分"] = baseScore
            
            // 1. 基础录音评分
            let recordingScore = self.hasRecording ? Int.random(in: 10...20) : 0
            newDetailedScores["录音质量"] = recordingScore
            
            // 2. 发音准确度评分
            let pronunciationScore = Int.random(in: 5...20) 
            newDetailedScores["发音准确度"] = pronunciationScore
            
            // 3. 语速评分
            let speedScore = Int.random(in: 5...20)
            newDetailedScores["语速"] = speedScore
            
            // 4. 清晰度
            let clarityScore = Int.random(in: 5...20)
            newDetailedScores["清晰度"] = clarityScore
            
            baseScore += recordingScore + pronunciationScore + speedScore + clarityScore
            
            // 确保分数不超过100
            let finalScore = min(baseScore, 100)
            let finalComment = self.getScoreComment(for: finalScore, method: .reading)
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                // 触发成功反馈
                self.playSuccessSound()
                
                // 动画显示分数
                self.scoreAnimationActive = true
                self.score = finalScore
                self.scoreComment = finalComment
                self.detailedScores = newDetailedScores
                
                // 短暂延迟后隐藏加载状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isGeneratingScore = false
                    
                    // 触发成功验证
                    self.handleVerificationSuccess()
                }
            }
        }
    }
    
    // 格式化录音时间 (分:秒)
    private func formatRecordingTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 格式化录音时间带毫秒 (分:秒.毫秒)
    private func formatRecordingTimeWithMs(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time - floor(time)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
    
    // 播放单词发音
    private func playWordPronunciation() {
        // 避免重复播放
        if isPlayingPronunciation {
            return
        }
        
        // 先确保停止所有铃声，这样才能听清发音
        viewModel.stopVerificationAlert()
        
        // 设置系统音量到最大（可选）
        MPVolumeView.setVolume(1.0)
        
        // 测试设备是否能发声 - 播放系统声音
        AudioServicesPlaySystemSound(1306) // 使用系统声音UIAccessibilityReduceMotionChangedNotification
        
        // 延迟300毫秒再播放单词，确保系统声音和单词发音不重叠
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // 标记为正在播放
            self.isPlayingPronunciation = true
            
            // 尝试激活音频会话，强制使用扬声器进行播放
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                // 输出调试信息
                print("音频会话激活成功，输出路由: \(audioSession.currentRoute)")
                print("当前音量: \(audioSession.outputVolume)")
            } catch {
                print("无法设置音频会话: \(error)")
            }
            
            // 创建一个全新的合成器实例
            let synthesizer = AVSpeechSynthesizer()
            self.speechSynthesizer = synthesizer
            
            // 创建发音请求，使用明确的美式发音
            let utterance = AVSpeechUtterance(string: self.currentWord.word)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 确保是美式英语
            utterance.rate = 0.4 // 降低速度，使发音更清晰
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0 // 最大音量
            utterance.preUtteranceDelay = 0.2 // 添加前置延迟
            
            // 添加一个强引用的代理处理完成回调
            let delegate = SpeechDelegate()
            delegate.onFinish = {
                DispatchQueue.main.async {
                    self.isPlayingPronunciation = false
                    self.speechSynthesizer = nil
                    // 播放完成系统声音
                    AudioServicesPlaySystemSound(1315) // 使用另一个系统声音UIAccessibilityAnnouncementDidFinishNotification
                    
                    // 打印调试信息
                    print("发音已完成")
                }
            }
            self.speechDelegate = delegate
            synthesizer.delegate = delegate
            
            // 启动计时器记录播放是否真正开始
            var hasStarted = false
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if synthesizer.isSpeaking {
                    hasStarted = true
                    print("发音已开始")
                    timer.invalidate()
                }
            }
            
            // 开始播放
            do {
                // 确保再次设置活跃状态
                try AVAudioSession.sharedInstance().setActive(true)
                synthesizer.speak(utterance)
                print("已请求播放发音: \(self.currentWord.word)")
                
                // 再次确认声音可以播放
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !synthesizer.isSpeaking {
                        // 如果0.5秒后还没开始说话，尝试播放系统声音
                        print("发音未开始，尝试系统声音")
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // 振动
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            AudioServicesPlaySystemSound(1307) // 再次尝试系统声音
                        }
                    }
                }
            } catch {
                print("播放发音时出错: \(error)")
            }
            
            // 备用恢复机制
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if self.isPlayingPronunciation {
                    print("发音超时，强制结束")
                    self.isPlayingPronunciation = false
                    self.speechSynthesizer = nil
                    
                    // 如果发音未成功开始，显示错误提示
                    if !hasStarted {
                        self.showError = true
                        self.errorMessage = "无法播放发音，请检查设备声音设置"
                    }
                }
            }
        }
    }
    
    private func handleVerificationSuccess() {
        // 避免重复处理
        if let result = verificationResult, result == true {
            // 已经成功验证过，不重复处理
            return
        }
        
        verificationResult = true
        
        // 确保先停止声音和震动提醒 - 使用正确的方法
        viewModel.stopVerificationAlert()
        
        // 触发成功反馈
        playSuccessSound()
    }
    
    private func playSuccessSound() {
        // 播放成功音效的代码（如果需要）
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func readVerificationCompleted() {
        // 朗读验证完成后处理
        isVerifying = true
        
        // 移除不必要的延迟，立即完成验证
        isVerifying = false
        handleVerificationSuccess()
    }
    
    // 完成验证
    private func completeVerification() {
        // 先确保铃声停止
        viewModel.stopVerificationAlert()
        
        // 停止所有计时器和录音
        cancelVerificationTimer()
        if isRecording {
            stopRecording()
        }
        
        // 释放音频资源
        releaseAudioResources()
        
        // 重置状态
        isVerifying = false
        showResult = false
        verificationResult = nil
        
        // 使用不阻塞主线程的方式来完成后续步骤
        DispatchQueue.main.async {
            // 调用 ViewModel 的完成验证方法
            viewModel.completeVerification()
            
            // 立即关闭验证界面，确保用户体验流畅
            navigationManager.isShowingVerification = false
        }
    }
    
    // 取消验证
    private func cancelVerification() {
        // 停止所有计时器和录音
        cancelVerificationTimer()
        if isRecording {
            stopRecording()
        }
        
        // 重置状态
        isVerifying = false
        showResult = false
        verificationResult = nil
        
        // 调用 ViewModel 的取消验证方法
        viewModel.cancelVerification()
        
        // 关闭验证界面
        navigationManager.isShowingVerification = false
    }
    
    // 启动验证计时器
    private func startVerificationTimer() {
        // 先取消之前的计时器订阅
        cancelVerificationTimer()
        
        // 重置倒计时时间
        remainingTime = 5
        
        // 创建新的计时器并连接
        verificationTimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
        verificationTimerSubscription = verificationTimerPublisher.connect()
    }
    
    // 取消验证计时器
    private func cancelVerificationTimer() {
        verificationTimerSubscription?.cancel()
        verificationTimerSubscription = nil
    }
    
    // 启动录音计时器
    private func startRecordingTimer() {
        // 先确保之前的计时器被清理
        stopRecordingTimer()
        
        // 创建新的计时器，并使用弱引用避免循环引用
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            guard isRecording else { return }
            
            if let startTime = recordingStartTime {
                // 计算并更新录音时长
                let currentDuration = Date().timeIntervalSince(startTime)
                
                // 在主线程更新UI状态
                DispatchQueue.main.async {
                    recordingDuration = currentDuration
                }
            }
        }
        
        // 确保计时器在所有RunLoop模式下工作
        if let timer = recordingTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // 停止录音计时器
    private func stopRecordingTimer() {
        if let timer = recordingTimer {
            timer.invalidate()
            recordingTimer = nil
        }
    }
    
    // 优化开始录音方法，减少卡顿并实现权限检查
    private func startRecording() {
        // 确保避免重复启动
        guard !isRecording else { return }
        
        // 检查麦克风权限状态
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            // 已经有权限，直接开始
            beginRecordingAfterPermissionGranted()
            
        case .denied:
            // 权限被拒绝，显示提示
            self.showError = true
            self.errorMessage = "麦克风权限被拒绝，请在设置中允许访问麦克风"
            
        case .undetermined:
            // 尚未请求权限，请求权限
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.beginRecordingAfterPermissionGranted()
                    } else {
                        self.showError = true
                        self.errorMessage = "需要麦克风权限才能进行录音"
                    }
                }
            }
            
        @unknown default:
            // 未知状态，尝试请求权限
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.beginRecordingAfterPermissionGranted()
                    } else {
                        self.showError = true
                        self.errorMessage = "无法获取麦克风权限"
                    }
                }
            }
        }
    }
    
    // 添加新方法，在获得权限后开始录音
    private func beginRecordingAfterPermissionGranted() {
        // 设置状态
        isRecording = true
        recordingStartTime = Date()
        recordingDuration = 0
        
        // 启动UI更新计时器
        startRecordingTimer()
        
        // 配置音频会话 (使用默认配置)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            // 简单模拟录音成功，不实际录制
            hasRecording = true
        } catch {
            // 处理音频会话设置错误，但不中断流程
            print("音频会话配置错误: \(error.localizedDescription)")
        }
    }
    
    // 停止录音 - 优化清理过程
    private func stopRecording() {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 更新UI状态
            self.isRecording = false
            
            // 确保最终时长准确
            if let startTime = self.recordingStartTime {
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
            
            // 停止录音计时器
            self.stopRecordingTimer()
            
            // 清理录音资源
            self.audioRecorder = nil
            self.recordingURL = nil
            self.audioRecorderDelegate = nil
        }
    }
    
    // 播放录音
    private func playRecording() {
        // 模拟播放
        isPlaying = true
        
        // 2秒后模拟播放结束
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isPlaying = false
        }
    }
    
    // 停止播放
    private func stopPlaying() {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 停止音频播放
            self.audioPlayer?.stop()
            self.audioPlayer = nil
            
            // 停止语音合成
            self.speechSynthesizer?.stopSpeaking(at: .immediate)
            self.speechSynthesizer = nil
            
            // 更新状态
            self.isPlaying = false
            self.isPlayingPronunciation = false
        }
    }
    
    // 获取文档目录
    private func getDocumentsDirectory() -> URL {
        do {
            // Using a more robust approach with error handling
            let fileManager = FileManager.default
            
            // Try to get the documents directory with proper error handling
            return try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            // Log the error
            print("Error accessing documents directory: \(error.localizedDescription)")
            
            // Notify about I/O error
            NotificationCenter.default.post(
                name: NSNotification.Name("DataOperationError"),
                object: nil,
                userInfo: ["error": error, "operation": "accessing documents directory"]
            )
            
            // Fallback to the old method as a last resort
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    }
    
    // 完全重写releaseAudioResources方法，使其更加健壮
    private func releaseAudioResources() {
        // 先停止所有异步操作
        DispatchQueue.main.async {
            // 1. 停止所有计时器
            self.stopRecordingTimer()
            self.cancelVerificationTimer()
            
            // 2. 停止所有录音和播放
            if self.isRecording {
                self.isRecording = false
            }
            if self.isPlaying {
                self.isPlaying = false
            }
            if self.isPlayingPronunciation {
                self.isPlayingPronunciation = false
            }
            
            // 3. 释放音频播放器
            if let player = self.audioPlayer {
                player.stop()
                self.audioPlayer = nil
            }
            
            // 4. 释放语音合成器
            if let synthesizer = self.speechSynthesizer {
                synthesizer.stopSpeaking(at: .immediate)
                self.speechSynthesizer = nil
                self.speechDelegate = nil
            }
            
            // 5. 尝试重置音频会话
            do {
                // 首先尝试停用会话
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                
                // 可选: 重置会话类别
                try AVAudioSession.sharedInstance().setCategory(.ambient)
                
                print("音频会话已停用")
            } catch {
                print("停用音频会话时出错: \(error.localizedDescription)")
            }
            
            // 6. 重置所有状态
            self.hasRecording = false
            self.recordingDuration = 0
            self.recordingStartTime = nil
        }
    }

    // 添加应用生命周期监听
    private func setupAppLifecycleObservers() {
        // 先移除所有可能存在的观察者，避免重复添加
        NotificationCenter.default.removeObserver(self)
        
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("应用进入后台，执行清理...")
            self.releaseAudioResources()
        }
        
        // 监听应用即将终止
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.releaseAudioResources()
        }
    }

    // 添加一个方法来检查和创建必要的目录
    private func ensureDirectoriesExist() {
        do {
            let fileManager = FileManager.default
            let docsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            // 创建一个专用于录音的子目录
            let recordingsDir = docsURL.appendingPathComponent("Recordings", isDirectory: true)
            if !fileManager.fileExists(atPath: recordingsDir.path) {
                try fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
            }
            
            print("目录准备完成: \(recordingsDir.path)")
        } catch {
            print("创建目录时出错: \(error.localizedDescription)")
        }
    }

    // 添加用于安全关闭应用的方法
    private func prepareForAppTermination() {
        print("准备应用终止...")
        
        // 1. 停止所有正在进行的任务
        if isRecording {
            stopRecording()
        }
        
        // 2. 释放所有音频资源
        releaseAudioResources()
        
        // 3. 取消所有计时器
        cancelVerificationTimer()
        stopRecordingTimer()
        
        // 4. 移除所有通知观察者
        NotificationCenter.default.removeObserver(self)
        
        print("应用终止准备完成")
    }
}

// 语音合成代理类实现
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
}

// Audio Recorder Delegate class改为空类实现
class AudioRecorderDelegate: NSObject {
    var onFinish: ((Bool) -> Void)?
    
    override init() {
        super.init()
    }
}

// 简化播放器代理
class AudioPlayerDelegate: NSObject {
    var onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func setup(with player: Any) {
        // 模拟设置，不做任何操作
    }
}

// 完全重新实现的画布包装器
struct CanvasWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasWrapper
        
        init(_ parent: CanvasWrapper) {
            self.parent = parent
            super.init()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        // 创建全新的画布实例
        let newCanvas = PKCanvasView()
        
        // 基本配置
        newCanvas.delegate = context.coordinator
        newCanvas.backgroundColor = UIColor.white
        newCanvas.isOpaque = true
        newCanvas.drawingPolicy = .anyInput
        
        // 设置粗红色笔
        let ink = PKInk(.marker, color: .red)
        let tool = PKInkingTool(ink: ink, width: 18.0)
        newCanvas.tool = tool
        
        // 同步当前绘图
        if !canvasView.drawing.bounds.isEmpty {
            newCanvas.drawing = canvasView.drawing
        }
        
        // 强制设置禁用任何可能的调试覆盖层
        newCanvas.layer.sublayers?.forEach { layer in
            if layer.name?.contains("Debug") == true ||
               layer.name?.contains("FPS") == true ||
               layer.name?.contains("GPU") == true {
                layer.isHidden = true
                layer.opacity = 0
            }
        }
        
        // 确保绘画视图不是调试模式
        if let mirror = Mirror(reflecting: newCanvas).children.first(where: { $0.label == "debugEnabled" }) {
            if let debugEnabledProperty = mirror.value as? Bool {
                // 使用KVC尝试禁用调试
                newCanvas.setValue(false, forKey: "debugEnabled")
            }
        }
        
        // 返回新画布
        return newCanvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 只更新绘图内容，保持其他设置不变
        if uiView.drawing != canvasView.drawing {
            uiView.drawing = canvasView.drawing
        }
        
        // 每次更新时持续移除任何调试层
        for subview in uiView.subviews {
            let className = NSStringFromClass(type(of: subview))
            if className.contains("Debug") || 
               className.contains("Performance") || 
               className.contains("FPS") || 
               className.contains("Monitor") {
                subview.isHidden = true
                subview.removeFromSuperview()
            }
        }
    }
}

#Preview {
    TaskVerificationView()
        .environmentObject(NavigationManager())
        .environmentObject(ThemeManager())
        .environmentObject(AppViewModel())
}

// Extension to handle volume control without adding UIView to hierarchy
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            slider?.value = volume
        }
    }
}

// 添加一个专门的代理类
class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
} 
