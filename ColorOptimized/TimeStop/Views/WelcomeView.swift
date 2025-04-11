import SwiftUI
import Combine

// 欢迎页面文案模型
struct WelcomeQuote {
    let line1: String
    let line2: String
    let line3: String
    let englishLine1: String
    let englishLine2: String
    let englishLine3: String
    let englishLine4: String?
    
    static let quotes = [
        // 原有文案
        WelcomeQuote(
            line1: "有些时候",
            line2: "学会停止",
            line3: "比学会开始更重要",
            englishLine1: "Sometimes,",
            englishLine2: "learning to stop",
            englishLine3: "is more important than",
            englishLine4: "learning to begin"
        ),
        // 新文案1
        WelcomeQuote(
            line1: "让身体",
            line2: "比思维先停下",
            line3: "",
            englishLine1: "Let your body",
            englishLine2: "stop before",
            englishLine3: "your mind does",
            englishLine4: nil
        ),
        // 新文案2
        WelcomeQuote(
            line1: "最有效的停止",
            line2: "不在于声音",
            line3: "而是在于你的动作",
            englishLine1: "The most effective pause",
            englishLine2: "is not in the sound",
            englishLine3: "but in your action",
            englishLine4: nil
        )
    ]
    
    // 随机获取一条文案
    static func random() -> WelcomeQuote {
        quotes.randomElement() ?? quotes[0]  // 提供默认值防止崩溃
    }
}

struct WelcomeView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    @State private var showContent = false
    @State private var showQuote = false
    @State private var showEnglishTranslation = false
    @State private var initialAnimationComplete = false
    @State private var glowOffset: CGFloat = -200
    @State private var timeRemaining: Int = 3 // 3秒倒计时
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var timerSubscription: Cancellable? = nil
    @State private var currentQuote: WelcomeQuote = WelcomeQuote.random()
    @State private var brandLogoScale: CGFloat = 0.1
    @State private var brandLogoOpacity: Double = 0
    @State private var opacity: Double = 1
    
    // 预先计算和缓存随机值，避免每次绘制都重新生成
    @State private var cachedRefraction: [RefractiveElement] = []
    @State private var cachedParticles: [ParticleElement] = []
    
    // Animation timings
    private enum Constants {
        static let animationDelay: Double = 0.2
        static let quoteAnimationDuration: Double = 0.9
        static let brandLogoAnimationDuration: Double = 1.5
        static let countdownTime: Int = 3
        static let countdownInterval: TimeInterval = 1.0
        static let dismissAnimationDuration: Double = 0.5
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            contentView
                .opacity(opacity)
        }
        .onAppear {
            // 预先生成随机元素以提高性能
            generateCachedElements()
            
            // 确保每次显示欢迎界面时动画都会重置并重新播放
            resetAnimationState()
            
            // 随机选择一条欢迎文案
            currentQuote = WelcomeQuote.random()
            
            // 延迟一小段时间后开始动画
            startAnimationSequence()
        }
        .onDisappear {
            // 确保在视图消失时取消计时器订阅，防止内存泄漏
            cancelTimerSubscription()
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        .statusBar(hidden: true)
    }
    
    // 生成缓存元素
    private func generateCachedElements() {
        // 生成折射线元素
        cachedRefraction = (0..<7).map { _ in
            RefractiveElement(
                width: UIScreen.main.bounds.width * CGFloat.random(in: 0.5...1.2),
                height: CGFloat.random(in: 0.5...1.5),
                rotation: Double.random(in: -20...20),
                positionX: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                positionY: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.3...0.6)
            )
        }
        
        // 生成粒子元素
        cachedParticles = (0..<100).map { _ in
            ParticleElement(
                size: CGFloat.random(in: 1...4),
                positionX: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                positionY: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.05...0.25)
            )
        }
    }
    
    // 背景视图
    private var backgroundView: some View {
        ZStack {
            // Base gradient with more vibrant colors
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(#colorLiteral(red: 0.85, green: 0.95, blue: 0.3, alpha: 1)),  // 亮荧光绿
                    Color(#colorLiteral(red: 0.75, green: 0.9, blue: 0.2, alpha: 1))    // 略深的荧光绿
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Glass-like surface texture overlay
            glassTextureOverlay
            
            // 玻璃折射光线 - 使用缓存元素
            OptimizedGlassRefractionLines(elements: cachedRefraction)
                .edgesIgnoringSafeArea(.all)
                .drawingGroup() // 使用Metal渲染以提高性能
            
            // Enhanced light rays from top
            lightRaysEffect
            
            // Enhanced particle effect with light grains - 使用缓存元素
            OptimizedParticleEffect(particles: cachedParticles)
                .foregroundColor(Color.white.opacity(0.3))
                .drawingGroup() // 使用Metal渲染以提高性能
        }
    }
    
    // 玻璃质感纹理叠加层
    private var glassTextureOverlay: some View {
        ZStack {
            // 主要玻璃反光
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.4),
                    Color.white.opacity(0.0)
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 600
            )
            .edgesIgnoringSafeArea(.all)
            .blendMode(.overlay)
            
            // 次要玻璃纹理
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.0)
                ]),
                center: .bottomTrailing,
                startRadius: 50,
                endRadius: 800
            )
            .edgesIgnoringSafeArea(.all)
            .blendMode(.overlay)
        }
    }
    
    // 光线效果
    private var lightRaysEffect: some View {
        VStack {
            ZStack {
                // Main glow
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 350, height: 350)
                    .blur(radius: 60)
                    .offset(y: -150)
                
                // Secondary glow
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: 40, y: -120)
                    
                // Bright spot highlight
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 30, height: 30)
                    .blur(radius: 10)
                    .offset(x: 100, y: -200)
            }
            
            Spacer()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // 主要内容视图
    private var contentView: some View {
        ZStack {
            // 中文水印 - 居中偏上
            Text("TimeStop")
                .font(.custom("PingFangSC-Thin", size: 36))
                .tracking(2)
                .foregroundColor(Color.black.opacity(0.6))
                .offset(y: -UIScreen.main.bounds.height * 0.15) // 向上偏移，大约在屏幕上方40%位置
                .scaleEffect(brandLogoScale)
                .opacity(brandLogoOpacity)
            
            // 引用容器 - 居中偏下
            quoteContainer
                .offset(y: UIScreen.main.bounds.height * 0.15) // 向下偏移，大约在屏幕下方40%位置
        }
        .animation(.default, value: showContent) // 使用较简单的动画
    }
    
    // 引用容器
    private var quoteContainer: some View {
        VStack(alignment: .leading, spacing: 65) {
            // 中文引用
            chineseQuoteView
            
            // 英文翻译
            englishTranslationView
        }
        .padding(.horizontal, 30)
    }
    
    // 中文引用视图
    private var chineseQuoteView: some View {
        VStack(alignment: .leading, spacing: currentQuote.line3.isEmpty ? 15 : 30) {
            // 第一行
            if !currentQuote.line1.isEmpty {
                Text(currentQuote.line1)
                    .font(.custom("PingFangSC-Light", size: 26))
                    .foregroundColor(Color.black.opacity(0.9))
                    .tracking(2)
                    .opacity(showQuote ? 1 : 0)
                    .offset(x: showQuote ? 0 : -20)
                    .animation(.easeOut(duration: Constants.quoteAnimationDuration).delay(Constants.animationDelay), value: showQuote)
                    .shadow(color: Color.white.opacity(0.6), radius: 3, x: 1, y: 1)
            }
            
            // 第二行（高亮）
            highlightedSecondLine
            
            // 第三行
            if !currentQuote.line3.isEmpty {
                Text(currentQuote.line3)
                    .font(.custom("PingFangSC-Light", size: 26))
                    .foregroundColor(Color.black.opacity(0.9))
                    .tracking(2)
                    .opacity(showQuote ? 1 : 0)
                    .offset(x: showQuote ? 0 : -20)
                    .animation(.easeOut(duration: Constants.quoteAnimationDuration).delay(Constants.animationDelay + 0.4), value: showQuote)
                    .shadow(color: Color.white.opacity(0.6), radius: 3, x: 1, y: 1)
            }
        }
    }
    
    // 高亮的第二行
    private var highlightedSecondLine: some View {
        ZStack {
            // 高亮背景 - 简化效果以减少闪烁
            if showQuote {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 50)
                    .blur(radius: 15)
                    .padding(.horizontal, -20)
                    .offset(x: 0, y: 2)
                    .opacity(showQuote ? 0.7 : 0)
            }
            
            // 主文本带发光效果 - 减少阴影数量
            Text(currentQuote.line2)
                .font(.custom("PingFangSC-Medium", size: 34))
                .foregroundColor(Color.black)
                .tracking(4)
                .opacity(showQuote ? 1 : 0)
                .offset(x: showQuote ? 0 : -20)
                .animation(.easeOut(duration: Constants.quoteAnimationDuration).delay(Constants.animationDelay + 0.2), value: showQuote)
                .shadow(color: Color.white, radius: 6, x: 0, y: 0) // 简化阴影效果
        }
    }
    
    // 英文翻译视图
    private var englishTranslationView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentQuote.englishLine1)
                .font(.system(size: 18, weight: .light, design: .default))
                .foregroundColor(Color.black.opacity(0.7))
                .italic()
                .opacity(showEnglishTranslation ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(Constants.animationDelay), value: showEnglishTranslation)
            
            Text(currentQuote.englishLine2)
                .font(.system(size: 22, weight: .regular, design: .default))
                .foregroundColor(Color.black.opacity(0.85))
                .italic()
                .shadow(color: Color.white, radius: 3, x: 0, y: 0)
                .opacity(showEnglishTranslation ? 1 : 0)
                .animation(.easeOut(duration: 0.7).delay(Constants.animationDelay + 0.2), value: showEnglishTranslation)
            
            Text(currentQuote.englishLine3)
                .font(.system(size: 18, weight: .light, design: .default))
                .foregroundColor(Color.black.opacity(0.7))
                .italic()
                .opacity(showEnglishTranslation ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(Constants.animationDelay + 0.4), value: showEnglishTranslation)
        }
        .opacity(showEnglishTranslation ? 1 : 0)
    }
    
    // 重置动画状态
    private func resetAnimationState() {
        showContent = false
        showQuote = false
        showEnglishTranslation = false
        initialAnimationComplete = false
        glowOffset = -200
        timeRemaining = Constants.countdownTime
        brandLogoScale = 0.1
        brandLogoOpacity = 0
        opacity = 1
    }
    
    // 启动动画序列
    private func startAnimationSequence() {
        // 确保先取消之前的计时器订阅
        cancelTimerSubscription()
        
        // 简化动画步骤，减少并行动画数量
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                self.showQuote = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                self.showEnglishTranslation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: Constants.brandLogoAnimationDuration)) {
                self.brandLogoOpacity = 1
                self.brandLogoScale = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.initialAnimationComplete = true
            withAnimation { 
                self.showContent = true 
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.dismissWelcomeView()
        }
    }
    
    // 取消计时器订阅
    private func cancelTimerSubscription() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func dismissWelcomeView() {
        // 确保先取消计时器
        cancelTimerSubscription()
        
        // 简化过渡动画
        withAnimation(.easeOut(duration: Constants.dismissAnimationDuration)) {
            opacity = 0
        }
        
        // 使用延迟确保动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.dismissAnimationDuration) {
            // 首先发送通知，告知WelcomeView已关闭
            NotificationCenter.default.post(name: NSNotification.Name("WelcomeViewDismissed"), object: nil)
            
            // 然后进行导航更新
            navigationManager.isShowingWelcome = false
            navigationManager.navigate(to: .home)
        }
    }
}

// 预缓存的折射元素
struct RefractiveElement: Identifiable {
    let id = UUID()
    let width: CGFloat
    let height: CGFloat
    let rotation: Double
    let positionX: CGFloat
    let positionY: CGFloat
    let opacity: Double
}

// 优化的玻璃折射线条效果
struct OptimizedGlassRefractionLines: View {
    let elements: [RefractiveElement]
    
    var body: some View {
        ZStack {
            // 水平光线
            ForEach(elements) { element in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(element.opacity),
                                Color.white.opacity(0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: element.width, height: element.height)
                    .rotationEffect(Angle(degrees: element.rotation))
                    .position(x: element.positionX, y: element.positionY)
                    .blendMode(.overlay)
            }
        }
    }
}

// 预缓存的粒子元素
struct ParticleElement: Identifiable {
    let id = UUID()
    let size: CGFloat
    let positionX: CGFloat
    let positionY: CGFloat
    let opacity: Double
}

// 优化的粒子效果
struct OptimizedParticleEffect: View {
    let particles: [ParticleElement]
    
    var body: some View {
        ZStack {
            // 粒子点
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.white.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.positionX, y: particle.positionY)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(NavigationManager())
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 