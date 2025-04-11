import SwiftUI

// AdaptiveComponents provides view modifiers for adaptive UI components
struct AdaptiveComponents {
    // Simple modifier that does nothing to the content
    struct EmptyModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
        }
    }
    
    // Helper function to create empty modifier
    static func empty() -> EmptyModifier {
        return EmptyModifier()
    }
}

// Extension for View to add convenience modifiers
extension View {
    // Applies an empty modifier that does nothing
    func adaptiveEmpty() -> some View {
        self.modifier(AdaptiveComponents.EmptyModifier())
    }
    
    // Applies a custom modifier with content
    func adaptiveContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        content()
    }
} 