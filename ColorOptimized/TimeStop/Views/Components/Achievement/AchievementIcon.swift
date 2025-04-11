import SwiftUI

struct AchievementIcon: View {
    let type: AchievementType
    let level: Int
    
    var body: some View {
        Image(systemName: type.icon)
            .font(.system(size: 30))
            .foregroundColor(type.levelColor(level))
            .padding()
            .background(Color.white.opacity(0.9))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(type.levelColor(level), lineWidth: 2)
            )
            .shadow(radius: 2)
    }
}

struct AchievementIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach([0, 1, 2, 3, 4, 5, 6], id: \.self) { level in
                HStack(spacing: 20) {
                    AchievementIcon(type: AchievementType.meeting, level: level)
                    AchievementIcon(type: AchievementType.thinking, level: level)
                    AchievementIcon(type: AchievementType.work, level: level)
                    AchievementIcon(type: AchievementType.exercise, level: level)
                    AchievementIcon(type: AchievementType.reading, level: level)
                }
            }
        }
    }
}

// MARK: - 会议图标
struct MeetingIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 会议桌
            Rectangle()
                .frame(width: 20, height: 12)
                .cornerRadius(2)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // 椅子
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .offset(x: CGFloat(index - 1) * 8, y: 6)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 0.5).delay(0.1 * Double(index)), value: isAnimating)
            }
        }
    }
}

// MARK: - 思考图标
struct ThinkingIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 灯泡
            Circle()
                .frame(width: 16, height: 16)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // 灯泡底部
            Rectangle()
                .frame(width: 4, height: 6)
                .offset(y: 8)
            
            // 思考气泡
            Path { path in
                path.move(to: CGPoint(x: 12, y: -4))
                path.addQuadCurve(to: CGPoint(x: -4, y: -4),
                                control: CGPoint(x: 4, y: -8))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            .rotationEffect(.degrees(isAnimating ? 5 : -5))
        }
    }
}

// MARK: - 工作图标
struct WorkIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 笔记本电脑
            Rectangle()
                .frame(width: 18, height: 12)
                .cornerRadius(2)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // 屏幕
            Rectangle()
                .frame(width: 16, height: 8)
                .cornerRadius(1)
                .offset(y: -2)
                .opacity(isAnimating ? 0.8 : 1.0)
            
            // 键盘
            Rectangle()
                .frame(width: 16, height: 2)
                .offset(y: 4)
        }
    }
}

// MARK: - 生活图标
struct LifeIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 房子主体
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addLine(to: CGPoint(x: -8, y: 0))
                path.addLine(to: CGPoint(x: 8, y: 0))
                path.closeSubpath()
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // 房子底部
            Rectangle()
                .frame(width: 12, height: 8)
                .offset(y: 4)
                .opacity(isAnimating ? 0.9 : 1.0)
        }
    }
}

// MARK: - 运动图标
struct ExerciseIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        // 跑步的人形
        Path { path in
            // 头部
            path.addEllipse(in: CGRect(x: -4, y: -8, width: 8, height: 8))
            
            // 身体
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 8))
            
            // 手臂
            path.move(to: CGPoint(x: 0, y: 2))
            path.addLine(to: CGPoint(x: -6, y: 0))
            path.move(to: CGPoint(x: 0, y: 2))
            path.addLine(to: CGPoint(x: 6, y: 4))
            
            // 腿部
            path.move(to: CGPoint(x: 0, y: 8))
            path.addLine(to: CGPoint(x: -4, y: 12))
            path.move(to: CGPoint(x: 0, y: 8))
            path.addLine(to: CGPoint(x: 4, y: 12))
        }
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .rotationEffect(.degrees(isAnimating ? 5 : -5))
    }
}

// MARK: - 阅读图标
struct ReadingIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 书本
            Rectangle()
                .frame(width: 16, height: 12)
                .cornerRadius(1)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // 书页
            Path { path in
                path.move(to: CGPoint(x: -6, y: -4))
                path.addLine(to: CGPoint(x: 0, y: -4))
                path.move(to: CGPoint(x: -6, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.move(to: CGPoint(x: -6, y: 4))
                path.addLine(to: CGPoint(x: 0, y: 4))
            }
            .stroke(style: StrokeStyle(lineWidth: 1))
        }
    }
}

// MARK: - 睡眠图标
struct SleepIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 月亮
            Circle()
                .frame(width: 16, height: 16)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // 月亮阴影
            Circle()
                .frame(width: 16, height: 16)
                .offset(x: 4)
                .foregroundColor(.clear)
                .overlay(
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                )
            
            // ZZZ
            Text("Z")
                .font(.system(size: 8, weight: .bold))
                .offset(x: -4, y: 4)
                .opacity(isAnimating ? 0.5 : 1.0)
        }
    }
}

// MARK: - 休闲图标
struct RelaxIcon: View {
    let level: Int
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 游戏手柄
            Rectangle()
                .frame(width: 16, height: 12)
                .cornerRadius(2)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            // 按钮
            ForEach(0..<2) { index in
                Circle()
                    .frame(width: 4, height: 4)
                    .offset(x: CGFloat(index == 0 ? -4 : 4), y: -2)
                    .opacity(isAnimating ? 0.8 : 1.0)
            }
        }
    }
} 