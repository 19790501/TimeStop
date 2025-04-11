import SwiftUI

struct AchievementBadgeView: View {
    let badge: AchievementBadge
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    @State private var rotationDegrees = 0.0
    @State private var pulseEffect = false
    
    var body: some View {
        // 将复杂表达式拆分为多个子视图
        VStack(spacing: 4) {
            // 成就徽章
            badgeCircle
            
            // 成就名称
            badgeName
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            isAnimating = true
            pulseEffect = true
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationDegrees = 360
            }
        }
    }
    
    // 徽章圆形部分
    private var badgeCircle: some View {
        ZStack {
            // 背景光晕
            backgroundHalo
            
            // 高等级光效
            if badge.level >= 5 {
                glowEffect
            }
            
            // 装饰环
            decorativeRings
            
            // 外环
            outerRing
            
            // 高等级边框
            if badge.level >= 4 {
                dashedBorder
            }
            
            // 内圈
            innerCircle
            
            // 图标和等级
            iconAndLevel
            
            // 高等级星星装饰
            if badge.level >= 5 {
                starDecorations
            }
            
            // 最高等级皇冠
            if badge.level >= 6 {
                crownDecoration
            }
        }
    }
    
    // 背景光晕
    private var backgroundHalo: some View {
        Circle()
            .fill(badge.type.color.opacity(0.1 + Double(badge.level) * 0.05))
            .frame(width: 98, height: 98)
            .shadow(
                color: badge.type.color.opacity(0.4 + Double(badge.level) * 0.1),
                radius: 5 + CGFloat(badge.level),
                x: 0,
                y: 0
            )
            // 高等级添加光晕动画
            .overlay(
                badge.level >= 4 ? 
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, badge.type.color.opacity(0.6), .white.opacity(0.8), badge.type.color.opacity(0.6), .clear]),
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
                    .blur(radius: 2)
                : nil
            )
    }
    
    // 高等级发光效果
    private var glowEffect: some View {
        ZStack {
            // 亮度增强的背景光晕 - 调整大小使其比放射光线小
            RadialGradient(
                gradient: Gradient(colors: [
                    badge.type.color.opacity(0.8),
                    badge.type.color.opacity(0.0)
                ]),
                center: .center,
                startRadius: 20,
                endRadius: badge.level >= 6 ? 63 : 80 // 6级时光晕范围改为63
            )
            .frame(width: badge.level >= 6 ? 115 : 120, height: badge.level >= 6 ? 115 : 120)
            .scaleEffect(pulseEffect ? 1.1 : 1.0)
            .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseEffect)
            
            // 6级添加额外的光芒效果 - 放射光线增长
            if badge.level >= 6 {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(badge.type.color.opacity(0.6))
                        .frame(width: 2, height: 13) // 光线长度改为13像素
                        .offset(y: -65) // 向外偏移更多
                        .rotationEffect(.degrees(Double(i) * 45))
                        .blur(radius: 1)
                }
                .rotationEffect(.degrees(isAnimating ? 22.5 : 0))
                .animation(Animation.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
            }
        }
    }
    
    // 装饰环
    private var decorativeRings: some View {
        ForEach(0..<min(badge.level, 3), id: \.self) { i in
            Circle()
                .stroke(
                    badge.type.color.opacity(0.1 + Double(badge.level) * 0.05), 
                    lineWidth: 1 + CGFloat(badge.level) * 0.2
                )
                .frame(width: 98 - CGFloat(i * 8), height: 98 - CGFloat(i * 8))
                .rotationEffect(.degrees(rotationDegrees + Double(i * 30)))
        }
    }
    
    // 外环
    private var outerRing: some View {
        Circle()
            .stroke(
                getGradientForLevel(),
                lineWidth: 2.5 + CGFloat(badge.level) * 0.2
            )
            .frame(width: 90, height: 90)
    }
    
    // 虚线边框
    private var dashedBorder: some View {
        Circle()
            .stroke(
                badge.type.color.opacity(0.3),
                style: StrokeStyle(lineWidth: 1.5, dash: [3, 2])
            )
            .frame(width: 95, height: 95)
            .rotationEffect(.degrees(-rotationDegrees))
    }
    
    // 内圈
    private var innerCircle: some View {
        Circle()
            .fill(getInnerCircleColor())
            .frame(width: 80, height: 80)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // 图标和等级文字
    private var iconAndLevel: some View {
        VStack(spacing: 0) {
            Image(systemName: badge.type.icon)
                .font(.system(size: 38, weight: badge.level >= 3 ? .black : .bold))
                .foregroundColor(.white)
                .shadow(
                    color: badge.type.color.opacity(0.5 + Double(badge.level) * 0.1),
                    radius: 2 + CGFloat(badge.level) * 0.5,
                    x: 0,
                    y: 0
                )
                .brightness(0.1)
                .contrast(1.2)
            
            Text("Level \(romanNumeralFor(badge.level))")
                .font(.system(size: 10, weight: badge.level >= 3 ? .bold : .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, -2)
                .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
        }
    }
    
    // 星星装饰
    private var starDecorations: some View {
        ForEach(0..<5, id: \.self) { i in
            Image(systemName: "star.fill")
                .font(.system(size: 8))
                .foregroundColor(badge.type.color.opacity(0.8))
                .offset(
                    x: 38 * cos(2 * .pi * Double(i) / 5),
                    y: 38 * sin(2 * .pi * Double(i) / 5)
                )
        }
    }
    
    // 皇冠装饰
    private var crownDecoration: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: 15))
            .foregroundColor(badge.type.color)
            .offset(y: -48)
            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
    
    // 成就名称
    private var badgeName: some View {
        Text(badge.type.levelDescription(badge.level))
            .font(.system(size: 11 + CGFloat(badge.level) * 0.2, weight: badge.level >= 4 ? .bold : .semibold))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.top, 0)
    }
    
    // 将数字转换为罗马数字
    private func romanNumeralFor(_ number: Int) -> String {
        let romanValues = ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ"]
        let index = min(number - 1, romanValues.count - 1)
        return index >= 0 ? romanValues[index] : ""
    }
    
    // 根据等级获取渐变效果
    private func getGradientForLevel() -> LinearGradient {
        switch badge.level {
        case 1:
            return LinearGradient(
                gradient: Gradient(colors: [.white.opacity(0.9), badge.type.color, badge.type.color.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [.white, badge.type.color, badge.type.color.opacity(0.7), badge.type.color]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                gradient: Gradient(colors: [.white, badge.type.color, .white.opacity(0.7), badge.type.color]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 4:
            return LinearGradient(
                gradient: Gradient(colors: [.white, badge.type.levelColor(badge.level), .white.opacity(0.9), badge.type.color]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 5:
            return LinearGradient(
                gradient: Gradient(colors: [.white, badge.type.levelColor(badge.level), .yellow.opacity(0.7), badge.type.color]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 6:
            return LinearGradient(
                gradient: Gradient(colors: [.white, .yellow, badge.type.levelColor(badge.level), .purple, badge.type.color]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [.white.opacity(0.8), badge.type.color, badge.type.color.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 根据等级获取内圈颜色
    private func getInnerCircleColor() -> AnyShapeStyle {
        switch badge.level {
        case 1:
            return LinearGradient(
                gradient: Gradient(colors: [badge.type.color.opacity(0.6), badge.type.color.opacity(0.45)]),
                startPoint: .top,
                endPoint: .bottom
            ).asAnyShapeStyle()
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [badge.type.color.opacity(0.7), badge.type.color.opacity(0.5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).asAnyShapeStyle()
        case 3:
            return LinearGradient(
                gradient: Gradient(colors: [badge.type.color.opacity(0.75), badge.type.color.opacity(0.55)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).asAnyShapeStyle()
        case 4:
            return LinearGradient(
                gradient: Gradient(colors: [badge.type.color.opacity(0.8), badge.type.levelColor(badge.level).opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).asAnyShapeStyle()
        case 5:
            return LinearGradient(
                gradient: Gradient(colors: [badge.type.levelColor(badge.level).opacity(0.8), badge.type.color.opacity(0.65)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).asAnyShapeStyle()
        case 6:
            return LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.8), badge.type.color.opacity(0.7), .pink.opacity(0.75)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).asAnyShapeStyle()
        default:
            return badge.type.color.opacity(0.5).asAnyShapeStyle()
        }
    }
}

// ShapeStyle扩展，用于统一返回类型
extension ShapeStyle {
    func asAnyShapeStyle() -> AnyShapeStyle {
        return AnyShapeStyle(self)
    }
}

struct AchievementBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementBadgeView(badge: AchievementBadge(type: .meeting, level: 2))
                .padding()
                .previewLayout(.sizeThatFits)
            
            AchievementBadgeView(badge: AchievementBadge(type: .work, level: 4))
                .padding()
                .previewLayout(.sizeThatFits)
                
            AchievementBadgeView(badge: AchievementBadge(type: .reading, level: 1))
                .padding()
                .previewLayout(.sizeThatFits)
        }
        .environmentObject(ThemeManager())
    }
} 