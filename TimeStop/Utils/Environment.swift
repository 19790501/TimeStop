import SwiftUI

// 定义禁用TabView滑动的环境键
struct DisableTabSwipeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// 扩展EnvironmentValues以添加我们的自定义键
extension EnvironmentValues {
    var disableTabSwipe: Bool {
        get { self[DisableTabSwipeKey.self] }
        set { self[DisableTabSwipeKey.self] = newValue }
    }
}

// 类型擦除的ViewModifier，用于包装不同类型的ViewModifier
struct AnyViewModifier: ViewModifier {
    private let modifier: (Content) -> any View
    
    init<M: ViewModifier>(_ modifier: M) {
        self.modifier = { content in
            content.modifier(modifier)
        }
    }
    
    func body(content: Content) -> some View {
        AnyView(modifier(content))
    }
}

// 禁用滑动的ViewModifier
struct DisableSwipeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in }
                    .onEnded { _ in }
            )
    }
}

// 空ViewModifier，不做任何操作
struct NoModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

// 添加View的条件修饰符扩展 - 安全版本
extension View {
    @ViewBuilder
    func ifCondition<TrueContent: View>(
        _ condition: Bool,
        then trueContent: (Self) -> TrueContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            self
        }
    }
} 
