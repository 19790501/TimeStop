import SwiftUI

struct AchievementUnlockOverlay: View {
    let type: AchievementType
    let level: Int
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var offset: CGFloat = 1000
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var showConfetti: Bool = false
    @State private var rotationAngle: Double = 0
    
    // 获取对应级别的描述文本
    var levelText: String {
        switch level {
        case 1: return "初次解锁"
        case 2: return "进阶成就"
        case 3: return "专业水准"
        case 4: return "大师级别"
        case 5: return "传奇成就"
        default: return "成就解锁"
        }
    }
    
    var body: some View {
        ZStack {
            // 背景蒙层
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            // 成就卡片
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Text("恭喜！")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeManager.colors.primary)
                    
                    Text(levelText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(type.levelColor(level))
                }
                
                // 图标
                ZStack {
                    // 辐射光效果
                    ForEach(0..<5) { i in
                        Circle()
                            .stroke(type.levelColor(level).opacity(0.2), lineWidth: 1)
                            .frame(width: 120 + CGFloat(i * 15), height: 120 + CGFloat(i * 15))
                            .rotationEffect(.degrees(Double(i) * 18 + rotationAngle))
                    }
                    
                    // 主圆形背景
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [type.levelColor(level).opacity(0.7), type.levelColor(level).opacity(0.2)]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.1 : 1.0, anchor: .center)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showConfetti)
                    
                    // 图标
                    Image(systemName: type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(showConfetti ? 1.2 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showConfetti)
                    
                    // 闪光效果
                    ForEach(0..<8) { i in
                        let angle = Double(i) * .pi / 4
                        let distance: CGFloat = 70
                        let x = cos(angle) * distance
                        let y = sin(angle) * distance
                        
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .offset(x: x, y: y)
                            .opacity(showConfetti ? 1 : 0)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .delay(Double(i) * 0.1)
                                    .repeatForever(autoreverses: true),
                                value: showConfetti
                            )
                    }
                }
                
                // 成就名称和等级
                VStack(spacing: 12) {
                    Text(type.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("\(type.levelDescription(level))级别")
                        .font(.title3)
                        .foregroundColor(type.levelColor(level))
                }
                
                // 描述
                Text(type.achievementSuggestion(for: level))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.colors.secondaryText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // 关闭按钮
                Button(action: {
                    dismiss()
                }) {
                    Text("继续")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(themeManager.colors.primary)
                        .cornerRadius(25)
                        .shadow(color: themeManager.colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 16)
            }
            .padding(30)
            .background(themeManager.colors.background)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(type.levelColor(level).opacity(0.3), lineWidth: 2)
            )
            .shadow(color: type.levelColor(level).opacity(0.3), radius: 20, x: 0, y: 10)
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .padding(.horizontal, 24)
            
            // 使用系统的ConfettiView
            if showConfetti {
                ConfettiView()
                    .opacity(0.6)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // 显示入场动画
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
                scale = 1.0
            }
            
            // 稍微延迟显示五彩纸屑
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                
                // 开始旋转动画
                withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
    }
    
    private func dismiss() {
        // 关闭动画
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            offset = 1000
            opacity = 0
            scale = 0.5
            showConfetti = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isPresented = false
        }
    }
}

struct AchievementUnlockOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementUnlockOverlay(type: AchievementType.work, level: 2, isPresented: .constant(true))
                .previewDisplayName("工作 - 2级")
            
            AchievementUnlockOverlay(type: AchievementType.exercise, level: 4, isPresented: .constant(true))
                .previewDisplayName("运动 - 4级")
        }
        .environmentObject(ThemeManager())
    }
} 