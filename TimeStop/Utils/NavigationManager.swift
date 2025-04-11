import SwiftUI
import Combine

class NavigationManager: ObservableObject {
    @Published var activeScreen: Screen = .home
    @Published var isShowingFocusTimer: Bool = false
    @Published var isShowingCompletion: Bool = false
    @Published var isShowingAchievement: Bool = false
    @Published var isShowingVerification: Bool = false
    @Published var isShowingWelcome: Bool = false
    
    // 新增TabView标签页选择
    @Published var selectedTab: TabViewSelection = .home
    
    enum Screen {
        case home
        case history
        case stats
        case profile
        case focusTimer
        case completion
        case achievement
        case verification
        case welcome
    }
    
    enum TabViewSelection {
        case home
        case timeAnalysis
        case achievements
        case settings
    }
    
    func navigate(to screen: Screen) {
        // 确保在主线程上执行UI更新
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.activeScreen = screen
                
                // 更新模态状态，确保一次只显示一个模态
                switch screen {
                case .focusTimer:
                    self.isShowingFocusTimer = true
                    self.isShowingCompletion = false
                    self.isShowingAchievement = false
                    self.isShowingVerification = false
                    self.isShowingWelcome = false
                case .completion:
                    // 直接切换到成功界面，不需要延迟
                    self.isShowingVerification = false
                    self.isShowingFocusTimer = false
                    self.isShowingCompletion = true
                    self.isShowingAchievement = false
                    self.isShowingWelcome = false
                case .achievement:
                    self.isShowingFocusTimer = false
                    self.isShowingCompletion = false
                    self.isShowingAchievement = true
                    self.isShowingVerification = false
                    self.isShowingWelcome = false
                case .verification:
                    self.isShowingFocusTimer = false
                    self.isShowingCompletion = false
                    self.isShowingAchievement = false
                    self.isShowingVerification = true
                    self.isShowingWelcome = false
                case .welcome:
                    self.isShowingFocusTimer = false
                    self.isShowingCompletion = false
                    self.isShowingAchievement = false
                    self.isShowingVerification = false
                    self.isShowingWelcome = true
                default:
                    // 对于常规标签页，关闭所有模态
                    self.isShowingFocusTimer = false
                    self.isShowingCompletion = false
                    self.isShowingAchievement = false
                    self.isShowingVerification = false
                    self.isShowingWelcome = false
                }
            }
        }
    }
    
    func dismissModals() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // 关闭所有模态
            isShowingFocusTimer = false
            isShowingCompletion = false
            isShowingAchievement = false
            isShowingVerification = false
            isShowingWelcome = false
            
            // 返回上一个标签页屏幕
            if activeScreen == .focusTimer || activeScreen == .completion || activeScreen == .achievement || activeScreen == .verification || activeScreen == .welcome {
                activeScreen = .home
            }
        }
    }
    
    // 新增方法：完成验证
    func completeVerification() {
        DispatchQueue.main.async {
            withAnimation {
                // 关闭验证界面
                self.isShowingVerification = false
                // 直接设置AppViewModel的状态，显示成功界面
                NotificationCenter.default.post(name: NSNotification.Name("ShowSuccessPage"), object: nil)
            }
        }
    }
    
    // 新增方法：导航到首页
    func navigateToHome() {
        DispatchQueue.main.async {
            withAnimation {
                // 关闭所有模态视图
                self.isShowingFocusTimer = false
                self.isShowingCompletion = false
                self.isShowingAchievement = false
                self.isShowingVerification = false
                self.isShowingWelcome = false
                // 切换到首页标签
                self.selectedTab = .home
                self.activeScreen = .home
            }
        }
    }
    
    // 新增方法：关闭所有模态视图
    func closeAllModalViews() {
        DispatchQueue.main.async {
            withAnimation {
                self.isShowingFocusTimer = false
                self.isShowingCompletion = false
                self.isShowingAchievement = false
                self.isShowingVerification = false
            }
        }
    }
}

// Extension to simplify bindings to specific screens
extension Binding where Value == Bool {
    func map<T>(to value: T, from: NavigationManager.Screen) -> Binding<T> where T: Equatable {
        Binding<T>(
            get: { self.wrappedValue ? value : value },
            set: { newValue in
                self.wrappedValue = (newValue == value)
            }
        )
    }
} 