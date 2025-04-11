import SwiftUI

struct CircularProgressView: View {
    var progress: Double // 0.0 to 1.0
    var timeRemaining: String
    var taskTitle: String
    var endTime: String = "" // 添加结束时间参数
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    @State private var pulseEffect = false
    @State private var glowPosition: Double = 0
    @State private var isGlowing = false
    @State private var glowTimer: Timer? = nil
    @State private var sparkles: [Sparkle] = []
    @State private var rotationDegree: Double = 0
    @State private var baseAngle: Double = -90
    
    // 闪光粒子结构 - 改进版
    struct Sparkle: Identifiable {
        let id = UUID()
        var angle: Double      // 粒子在圆上的角度
        var radius: CGFloat    // 到圆心的距离
        var size: CGFloat      // 粒子大小
        var opacity: Double    // 透明度
        var createdAt: Date    // 创建时间
        var speed: Double      // 旋转速度
        var radiusChange: CGFloat // 半径变化速度
        var scaleChange: CGFloat  // 大小变化速度
    }
    
    // 根据主题获取发光背景效果
    private var glowBackgroundGradient: RadialGradient {
        if themeManager.currentTheme == .elegantPurple {
            return RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "8A2BE2").opacity(0.3), // 深紫色
                    Color(hex: "9370DB").opacity(0.1), // 中紫色
                    Color.black.opacity(0.0)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 200
            )
        } else {
            return RadialGradient(
                gradient: Gradient(colors: [
                    AppColors.fluorGreen.opacity(0.3),
                    AppColors.fluorGreen.opacity(0.1),
                    Color.black.opacity(0.0)
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 200
            )
        }
    }
    
    // 根据主题获取主圆环背景
    private var ringBackgroundGradient: LinearGradient {
        if themeManager.currentTheme == .elegantPurple {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "8A2BE2").opacity(0.2), // 深紫色
                    Color(hex: "9370DB").opacity(0.3)  // 中紫色
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.fluorGreen.opacity(0.2),
                    AppColors.fluorGreen.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 根据主题获取进度圆环渐变
    private var progressRingGradient: AngularGradient {
        if themeManager.currentTheme == .elegantPurple {
            return AngularGradient(
                gradient: Gradient(colors: [
                    Color(hex: "8A2BE2").opacity(0.7), // 深紫色
                    Color(hex: "9370DB"),              // 中紫色
                    Color(hex: "9932CC").opacity(1.0), // 暗兰花紫
                    Color.white.opacity(0.9),          // 白色高光
                    Color(hex: "8A2BE2").opacity(1.0)  // 深紫色
                ]),
                center: .center
            )
        } else {
            return AngularGradient(
                gradient: Gradient(colors: [
                    AppColors.fluorGreen.opacity(0.7),
                    AppColors.fluorGreen,
                    AppColors.fluorGreen.opacity(1.0),
                    Color.white.opacity(0.9),
                    AppColors.fluorGreen.opacity(1.0)
                ]),
                center: .center
            )
        }
    }
    
    // 根据主题获取光晕颜色
    private var glowShadowColor: Color {
        if themeManager.currentTheme == .elegantPurple {
            return Color(hex: "8A2BE2").opacity(0.5) // 深紫色阴影
        } else {
            return AppColors.fluorGreen.opacity(0.5) // 绿色阴影
        }
    }
    
    var body: some View {
        ZStack {
            // 发光背景效果
            Circle()
                .fill(glowBackgroundGradient)
                .scaleEffect(pulseEffect ? 1.15 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.8)
                        .repeatForever(autoreverses: true),
                    value: pulseEffect
                )
            
            // 主圆环背景
            Circle()
                .stroke(
                    ringBackgroundGradient,
                    lineWidth: 18
                )
                .blur(radius: 2)
            
            // 进度圆环 - 带闪光渐变
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressRingGradient,
                    style: StrokeStyle(
                        lineWidth: 18,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(baseAngle))
                .shadow(color: glowShadowColor, radius: 8, x: 0, y: 0)
                .animation(.easeInOut, value: progress)
                .rotationEffect(Angle.degrees(rotationDegree))
            
            // 旋转的光晕轨迹
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: 18,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(baseAngle))
                .rotationEffect(Angle.degrees(rotationDegree))
                .blur(radius: 2)
            
            // 中心内容
            VStack(spacing: 8) {
                Text(timeRemaining)
                    .font(.system(size: 75, weight: .thin))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        Text(endTime)
                            .font(.system(size: 20, weight: .thin))
                            .foregroundColor(.white)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    private func startAnimations() {
        // 开始脉冲动画
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            pulseEffect = true
        }
        
        // 开始旋转动画
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationDegree = 360
        }
        
        // 开始生成闪光粒子
        startSparkleGeneration()
    }
    
    private func stopAnimations() {
        pulseEffect = false
        rotationDegree = 0
        stopSparkleGeneration()
    }
    
    private func startSparkleGeneration() {
        glowTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            addSparkle()
        }
    }
    
    private func stopSparkleGeneration() {
        glowTimer?.invalidate()
        glowTimer = nil
    }
    
    private func addSparkle() {
        let newSparkle = Sparkle(
            angle: Double.random(in: 0...360),
            radius: CGFloat.random(in: 100...150),
            size: CGFloat.random(in: 4...8),
            opacity: 0.0,
            createdAt: Date(),
            speed: Double.random(in: 1...3),
            radiusChange: CGFloat.random(in: -0.5...0.5),
            scaleChange: CGFloat.random(in: -0.1...0.1)
        )
        
        withAnimation {
            sparkles.append(newSparkle)
        }
        
        // 移除旧的闪光粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let index = sparkles.firstIndex(where: { $0.id == newSparkle.id }) {
                sparkles.remove(at: index)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .edgesIgnoringSafeArea(.all)
        
        CircularProgressView(
            progress: 0.65,
            timeRemaining: "18:45",
            taskTitle: "完成产品设计文档"
        )
        .frame(width: 300, height: 300)
        .environmentObject(ThemeManager())
    }
} 