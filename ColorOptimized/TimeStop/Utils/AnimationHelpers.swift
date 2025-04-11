import SwiftUI

// Animation timing constants
struct AnimationDuration {
    static let quick: Double = 0.2
    static let standard: Double = 0.35
    static let long: Double = 0.5
    static let veryLong: Double = 0.8
}

// Helpful animation presets
extension Animation {
    static var quickSpring: Animation {
        .spring(response: AnimationDuration.quick, dampingFraction: 0.7)
    }
    
    static var standardSpring: Animation {
        .spring(response: AnimationDuration.standard, dampingFraction: 0.7)
    }
    
    static var longSpring: Animation {
        .spring(response: AnimationDuration.long, dampingFraction: 0.7)
    }
    
    static var bouncy: Animation {
        .spring(response: AnimationDuration.standard, dampingFraction: 0.5, blendDuration: 0.3)
    }
    
    static var celebration: Animation {
        .spring(response: AnimationDuration.long, dampingFraction: 0.5, blendDuration: 0.5)
            .delay(0.1)
            .repeatCount(1, autoreverses: true)
    }
}

// View extension for common animation patterns
extension View {
    func popOnAppear() -> some View {
        modifier(PopOnAppearModifier())
    }
    
    func slideInFromBottom() -> some View {
        modifier(SlideInFromBottomModifier())
    }
    
    func pulseAnimation(active: Bool) -> some View {
        scaleEffect(active ? 1.05 : 1.0)
            .animation(
                active ? 
                Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                .default,
                value: active
            )
    }
}

// Modifiers for reusable animations
struct PopOnAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.standardSpring) {
                    hasAppeared = true
                }
            }
    }
}

struct SlideInFromBottomModifier: ViewModifier {
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: hasAppeared ? 0 : 100)
            .opacity(hasAppeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.standardSpring) {
                    hasAppeared = true
                }
            }
    }
}

// For the circular progress animation
extension View {
    func circleOverlay(progress: Double, lineWidth: CGFloat = 8, color: Color = Color(UIColor.systemPink)) -> some View {
        self.overlay(
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(progress, 1))))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
        )
    }
} 