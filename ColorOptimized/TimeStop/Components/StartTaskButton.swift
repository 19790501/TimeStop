import SwiftUI

// 开始任务按钮内容组件
struct StartTaskButtonContent: View {
    let isButtonPressed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "play.fill")
                .font(.system(size: 14))
            Text("开始任务")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(StartTaskButtonBackground(isButtonPressed: isButtonPressed))
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 6)
        .shadow(color: Color.white.opacity(0.4), radius: 6, x: 0, y: -3)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        .shadow(color: Color.white.opacity(0.2), radius: 3, x: 0, y: -1)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        .shadow(color: Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.6), radius: 8, x: 0, y: 4)
        .shadow(color: Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.4), radius: 6, x: 0, y: 3)
        .shadow(color: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.3), radius: 10, x: 0, y: 8)
        .shadow(color: Color(red: 0.25, green: 0.25, blue: 0.25).opacity(0.2), radius: 15, x: 0, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.white, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .scaleEffect(isButtonPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isButtonPressed)
    }
}

// 开始任务按钮背景组件
struct StartTaskButtonBackground: View {
    let isButtonPressed: Bool
    
    var body: some View {
        ZStack {
            // 基础玻璃效果
            RoundedRectangle(cornerRadius: 23)
                .fill(AppColors.pureBlack)
            
            // 玻璃高光效果
            glassHighlightEffect()
            
            // 玻璃边缘高光
            glassEdgeHighlight()
            
            // 内部光晕效果
            innerGlowEffect()
            
            // 动态光效
            dynamicLightEffect()
            
            // 顶部高光线
            topHighlightLine()
            
            // 底部高光线
            bottomHighlightLine()
            
            // 内部高光圆环
            innerHighlightRing()
            
            // 基础背景效果
            RoundedRectangle(cornerRadius: 23)
                .fill(Color.white.opacity(0.3))
                .blur(radius: 5)
            
            // 额外背景阴影
            additionalBackgroundShadows()
            
            // 环境光效果
            ambientLightEffect()
        }
    }
    
    private func glassHighlightEffect() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.5),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: 1)
    }
    
    private func glassEdgeHighlight() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
    
    private func innerGlowEffect() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .blur(radius: 2)
    }
    
    private func dynamicLightEffect() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .blur(radius: 3)
            .offset(x: isButtonPressed ? 50 : -50)
            .animation(
                Animation.linear(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: isButtonPressed
            )
    }
    
    private func topHighlightLine() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.7),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
            .offset(y: -0.5)
    }
    
    private func bottomHighlightLine() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
            .offset(y: 0.5)
    }
    
    private func innerHighlightRing() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
            .padding(2)
    }
    
    private func additionalBackgroundShadows() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 23)
                .fill(Color.black.opacity(0.2))
                .blur(radius: 3)
                .offset(y: 2)
            
            RoundedRectangle(cornerRadius: 23)
                .fill(Color.white.opacity(0.2))
                .blur(radius: 2)
                .offset(y: -1)
            
            RoundedRectangle(cornerRadius: 23)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.5))
                .blur(radius: 4)
                .offset(y: 3)
            
            RoundedRectangle(cornerRadius: 23)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.3))
                .blur(radius: 6)
                .offset(y: 5)
            
            RoundedRectangle(cornerRadius: 23)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.2))
                .blur(radius: 8)
                .offset(y: 8)
            
            RoundedRectangle(cornerRadius: 23)
                .fill(Color(red: 0.02, green: 0.02, blue: 0.02).opacity(0.15))
                .blur(radius: 10)
                .offset(y: 12)
        }
    }
    
    private func ambientLightEffect() -> some View {
        RoundedRectangle(cornerRadius: 23)
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .blur(radius: 3)
    }
} 