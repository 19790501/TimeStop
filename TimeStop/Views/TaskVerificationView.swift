import SwiftUI
import PencilKit
import AVFoundation
import ObjectiveC
import Combine
import UserNotifications
import MediaPlayer

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
    
    @State private var speechDelegate: SpeechSynthesizerDelegate?
    
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
    
    // 添加音量控制相关变量
    @State private var originalVolume: Float = 0.0 // 保存原始音量
    @State private var volumeView: MPVolumeView? // 改为@State变量
    
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
        }
        .onDisappear {
            // 取消计时器
            cancelVerificationTimer()
            stopRecordingTimer()
            
            // 停止录音和播放
            stopRecording()
            stopPlaying()
        }
        .onChange(of: viewModel.selectedVerificationMethod) { oldValue, newValue in
            // 切换到绘画验证时重新设置提示
            if newValue == .drawing {
                drawingPrompt = getRandomDrawingPrompt()
            }
        }
        .onChange(of: remainingTime) { oldValue, newValue in
            if newValue <= 0 {
                cancelVerificationTimer()
                
                if viewModel.selectedVerificationMethod == .reading {
                    readVerificationCompleted()
                }
            }
        }
        .onChange(of: isRecording) { oldValue, newValue in
            if newValue {
                startRecording()
            } else {
                stopRecording()
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
        VStack(spacing: 2) {
            // 绘画提示文字
            Text("请按图绘画")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // 参考图片与"换一张"按钮
            HStack {
                Spacer()
                
                // 参考图示
                Image(systemName: getReferenceImage(for: drawingPrompt))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(width: 90, height: 90)
                
                Spacer()
                
                // 换一张按钮
                Button(action: {
                    drawingPrompt = getRandomDrawingPrompt()
                    canvasView.drawing = PKDrawing() // 清除画布
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20))
                        Text("换一张")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    )
                }
                
                Spacer()
            }
            .padding(.vertical, 2)
            
            // 绘画画布 - 增大区域，改为白色背景
            CanvasWrapper(canvasView: $canvasView)
                .frame(height: 450) // 增大绘画区域
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white) // 改为白色背景
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .cornerRadius(12)
        }
        .padding(.horizontal)
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
                        // 播放按钮音效 - 符合全局声音设置
                        viewModel.playButtonSound()
                        canvasView.drawing = PKDrawing()
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
                    // 开始按钮 - 暂停铃声并开始录音
                    Button(action: {
                        // 播放按钮音效
                        viewModel.playButtonSound()
                        
                        if isRecording {
                            // 如果正在录音，则停止录音
                            stopRecording()
                        } else {
                            // 如果未录音，先暂停铃声再开始录音
                            viewModel.stopVerificationAlert() // 暂停铃声
                            startRecording() // 开始录音
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(isRecording ? "停止" : "开始")
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
                    
                    // 完成按钮 - 改为关闭铃声功能，5秒内禁用
                    Button(action: {
                        // 停止铃声
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
                    // 开始按钮 - 暂停铃声并开始录音
                    Button(action: {
                        // 播放按钮音效
                        viewModel.playButtonSound()
                        
                        if isRecording {
                            // 如果正在录音，则停止录音
                            stopRecording()
                        } else {
                            // 如果未录音，先暂停铃声再开始录音
                            viewModel.stopVerificationAlert() // 暂停铃声
                            startRecording() // 开始录音
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 24))
                            Text(isRecording ? "停止" : "开始")
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
                    
                    // 完成按钮 - 改为关闭铃声功能，5秒内禁用
                    Button(action: {
                        // 停止铃声
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
        // 配置画布以确保可以正常绘画
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 5) // 改为红色画笔
        canvasView.backgroundColor = .white // 设置白色背景
        canvasView.isOpaque = true
    }
    
    // 获取随机绘画提示
    private func getRandomDrawingPrompt() -> String {
        // 确保只使用有可靠系统图标的提示
        let prompts = ["苹果", "太阳", "树", "房子", "笑脸", "星星", "汽车", "小猫"] 
        // 移除花和小狗，直到我们有更好的图标
        return prompts.randomElement() ?? "苹果"
    }
    
    // 根据提示获取对应的系统图标名称
    private func getReferenceImage(for prompt: String) -> String {
        switch prompt {
        case "苹果": return "apple.logo"
        case "太阳": return "sun.max.fill"
        case "树": return "leaf.fill"
        case "花": return "florette" // 修正花的图标为florette
        case "房子": return "house.fill"
        case "笑脸": return "face.smiling.fill"
        case "星星": return "star.fill"
        case "汽车": return "car.fill"
        case "小猫": return "cat.fill"
        case "小狗": return "hare.fill" // 暂时使用兔子图标代替小狗
        default: return "scribble"
        }
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
        
        // 1. 基础录音评分
        let recordingScore = hasRecording ? Int.random(in: 10...20) : 0
        newDetailedScores["录音质量"] = recordingScore
        
        // 2. 录音时长评分 - 增加录音时长评分
        let durationScore = min(Int(recordingDuration) / 2, 20) // 每2秒1分，最高20分
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
        let finalComment = getScoreComment(for: finalScore, method: .singing)
        
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
    
    // 修改任务完成按钮处理函数 - 朗读验证
    private func verifyReading() {
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
        
        // 1. 基础录音评分
        let recordingScore = hasRecording ? Int.random(in: 10...20) : 0
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
        let finalComment = getScoreComment(for: finalScore, method: .reading)
        
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
        let utterance = AVSpeechUtterance(string: currentWord.word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        let synthesizer = AVSpeechSynthesizer()
        
        // 创建并保持对代理的引用
        speechDelegate = SpeechSynthesizerDelegate {
            isPlayingPronunciation = false
        }
        synthesizer.delegate = speechDelegate
        
        isPlayingPronunciation = true
        synthesizer.speak(utterance)
    }
    
    // 添加音量控制相关方法
    private func saveOriginalVolume() {
        originalVolume = AVAudioSession.sharedInstance().outputVolume
        print("保存原始音量: \(originalVolume)")
    }
    
    // 修改lowerSystemVolume方法，避免使用self赋值和过时API
    private func lowerSystemVolume() {
        print("正在降低系统音量...")
        
        DispatchQueue.main.async {
            // 创建一个音量控制视图并添加到窗口
            let tempVolumeView = MPVolumeView(frame: CGRect(x: -3000, y: -3000, width: 1, height: 1))
            
            // 使用新的API获取窗口
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(tempVolumeView)
                
                // 直接强制音量为最低值
                if let slider = tempVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                    // 在这里将原始值保存到@State变量中
                    DispatchQueue.main.async {
                        self.originalVolume = slider.value
                    }
                    print("已保存原始音量: \(slider.value)")
                    
                    // 强制设置最低音量
                    slider.value = 0.0
                    
                    // 模拟用户交互以确保系统接受更改
                    slider.sendActions(for: .touchUpInside)
                    
                    print("已将音量设置为最低: \(slider.value)")
                    
                    // 短暂延迟后，确认音量值
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        print("确认当前音量: \(AVAudioSession.sharedInstance().outputVolume)")
                    }
                } else {
                    print("找不到音量滑块控件")
                }
                
                // 将新创建的视图保存到@State变量中
                DispatchQueue.main.async {
                    self.volumeView = tempVolumeView
                }
            } else {
                print("找不到窗口来添加音量控件")
            }
        }
    }
    
    // 修改restoreSystemVolume方法，修复过时API的使用
    private func restoreSystemVolume() {
        let volumeToRestore = originalVolume
        
        print("正在恢复音量到: \(volumeToRestore)")
        
        DispatchQueue.main.async {
            // 获取volumeView的本地副本
            let currentVolumeView = self.volumeView
            
            // 如果有既有的音量视图，尝试使用它
            if let volumeView = currentVolumeView,
               let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                // 恢复到原始音量
                slider.value = volumeToRestore
                
                // 模拟用户交互以确保系统接受更改
                slider.sendActions(for: .touchUpInside)
                
                // 移除音量视图
                volumeView.removeFromSuperview()
                
                // 清除状态变量
                DispatchQueue.main.async {
                    self.volumeView = nil
                }
                
                print("音量已恢复到: \(volumeToRestore)")
            } else {
                // 如果找不到已有视图，创建新的音量视图
                let newVolumeView = MPVolumeView(frame: CGRect(x: -3000, y: -3000, width: 1, height: 1))
                
                // 使用新的API获取窗口
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.addSubview(newVolumeView)
                    
                    if let slider = newVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                        slider.value = volumeToRestore
                        slider.sendActions(for: .touchUpInside)
                    }
                    
                    // 短暂延迟后移除视图
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        newVolumeView.removeFromSuperview()
                    }
                    
                    print("通过新视图恢复音量到: \(volumeToRestore)")
                }
            }
            
            // 最后检查确认音量值
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("最终音量确认: \(AVAudioSession.sharedInstance().outputVolume)")
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
        // 停止所有计时器和录音
        cancelVerificationTimer()
        if isRecording {
            stopRecording()
        }
        
        // 立即终止所有可能的音频和震动
        viewModel.stopVerificationAlert()
        
        // 重置状态
        isVerifying = false
        showResult = false
        verificationResult = nil
        
        // 使用不阻塞主线程的方式来完成后续步骤
        DispatchQueue.global(qos: .userInitiated).async {
            // 在后台处理数据更新
            DispatchQueue.main.async {
                // 调用 ViewModel 的完成验证方法
                viewModel.completeVerification()
                
                // 短暂延迟后关闭验证界面，确保动画平滑
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    navigationManager.isShowingVerification = false
                }
            }
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
        // 取消之前的计时器
        stopRecordingTimer()
        
        // 创建新的计时器
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            guard isRecording else { return }
            
            if let startTime = recordingStartTime {
                recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
        
        // 添加到RunLoop确保在滚动时依然有效
        if let timer = recordingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // 停止录音计时器
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // 优化开始录音方法，减少卡顿
    private func startRecording() {
        // 先设置录音状态，让UI立即响应
        isRecording = true
        recordingStartTime = Date() // 立即记录开始时间
        recordingDuration = 0 // 立即重置录音时长
        
        // 立即启动录音计时器，确保UI即时更新
        startRecordingTimer()
        
        // 立即停止铃声，优先处理
        viewModel.stopVerificationAlert()
        
        // 后台执行可能导致卡顿的操作
        DispatchQueue.global(qos: .userInitiated).async {
            // 降低系统音量 - 在后台线程进行
            self.saveOriginalVolume()
            
            // 回到主线程进行音量设置和录音
            DispatchQueue.main.async {
                // 音量控制只需执行一次简单操作
                self.simpleLowerVolume()
                
                // 设置音频会话
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    try audioSession.setCategory(.playAndRecord, mode: .default)
                    try audioSession.setActive(true)
                    
                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    self.recordingURL = self.getDocumentsDirectory().appendingPathComponent("recording.m4a")
                    
                    // 安全处理recordingURL，避免强制解包
                    guard let url = self.recordingURL else {
                        self.showError = true
                        self.errorMessage = "录音失败：无法创建文件URL"
                        return
                    }
                    
                    self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                    self.audioRecorder?.record()
                } catch {
                    self.showError = true
                    self.errorMessage = "录音失败：\(error.localizedDescription)"
                    self.isRecording = false
                }
            }
        }
    }
    
    // 简化的音量控制方法 - 直接使用系统API而不是视图
    private func simpleLowerVolume() {
        // 直接使用MPVolumeView的静态方法调整音量，不需要添加到视图层次
        MPVolumeView.setVolume(0.1) // 设置为较低音量但非零
    }
    
    // 停止录音
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        hasRecording = true
        
        // 恢复系统音量
        restoreSystemVolume()
        
        // 确保最终时长准确
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        // 停止录音计时器
        stopRecordingTimer()
    }
    
    // 播放录音
    private func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            
            // 创建并设置代理，使用弱引用避免循环引用
            let delegate = AudioPlayerDelegate(onFinish: {
                self.isPlaying = false
            })
            delegate.setup(with: player)
            
            // 保持对代理的引用
            objc_setAssociatedObject(player, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            audioPlayer?.play()
            isPlaying = true
        } catch {
            showError = true
            errorMessage = "播放失败：\(error.localizedDescription)"
        }
    }
    
    // 停止播放
    private func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
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
}

// 音频播放器代理
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: () -> Void
    // 保持对播放器的强引用
    private var player: AVAudioPlayer?
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func setup(with player: AVAudioPlayer) {
        self.player = player
        self.player?.delegate = self
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
        // 任务完成后可以释放播放器引用
        self.player = nil
    }
}

// 绘画画布包装器，确保可以正常绘画
struct CanvasWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasWrapper
        
        init(_ parent: CanvasWrapper) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .white
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
        canvasView.isOpaque = false
        canvasView.becomeFirstResponder()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 更新视图
    }
}

#Preview {
    TaskVerificationView()
        .environmentObject(NavigationManager())
        .environmentObject(ThemeManager())
        .environmentObject(AppViewModel())
}

// 在文件末尾添加语音合成代理类
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

// 在文件末尾添加MPVolumeView扩展
// 添加MPVolumeView的扩展
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider?.value = volume
        }
    }
} 