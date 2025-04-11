import SwiftUI

// AdaptiveComponents provides view modifiers for adaptive UI components
struct AdaptiveComponents {
    
    // EmptyViewModifier is a proper implementation of ViewModifier
    struct EmptyViewModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
        }
    }
    
    // ContentView uses EmptyView<Content> which should be:
    struct EmptyView<Content: View>: ViewModifier {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        func body(content: Content) -> some View {
            content
        }
    }
    
    // Helper function to create empty modifier
    static func emptyModifier() -> EmptyViewModifier {
        return EmptyViewModifier()
    }
    
    // Helper function to create content-based modifier
    static func emptyView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> EmptyView<Content> {
        return EmptyView(content: content)
    }
}

// Extension for View to add convenience modifiers
extension View {
    func adaptiveEmptyModifier() -> some View {
        self.modifier(AdaptiveComponents.EmptyViewModifier())
    }
    
    func adaptiveEmptyView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(AdaptiveComponents.EmptyView(content: content))
    }
} 