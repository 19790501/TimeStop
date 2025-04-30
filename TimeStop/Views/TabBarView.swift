import SwiftUI
import AudioToolbox

struct TabBarView: View {
    @Binding var selectedTab: NavigationManager.TabViewSelection
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        if selectedTab != tab {
                            viewModel.playButtonSound()
                            selectedTab = tab
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: getIcon(for: tab))
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? themeManager.colors.primary : themeManager.colors.secondaryText)
                        
                        if selectedTab == tab {
                            Circle()
                                .fill(themeManager.colors.primary)
                                .frame(width: 6, height: 6)
                                .transition(.scale)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(
            themeManager.colors.secondaryBackground
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: -4)
        )
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
            , alignment: .top
        )
        .zIndex(999)
    }
    
    // 所有标签页
    private var tabs: [NavigationManager.TabViewSelection] {
        [.home, .timeAnalysis, .achievements, .settings]
    }
    
    private func getIcon(for tab: NavigationManager.TabViewSelection) -> String {
        switch tab {
        case .home: return "house"
        case .timeAnalysis: return "clock.fill"
        case .achievements: return "trophy.fill"
        case .settings: return "gear"
        }
    }
}

// 创建一个别名，兼容旧代码
typealias CustomTabBar = TabBarView

#Preview {
    TabBarView(selectedTab: .constant(.home))
        .environmentObject(ThemeManager())
        .environmentObject(AppViewModel())
} 