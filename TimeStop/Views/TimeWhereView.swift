import SwiftUI
import Foundation

// 时间去哪了分析视图
struct TimeWhereView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        TimeWhereDashboardView()
            .environmentObject(userModel)
            .environmentObject(themeManager)
            .environmentObject(appViewModel)
    }
}

// 预览
struct TimeWhereView_Previews: PreviewProvider {
    static var previews: some View {
        TimeWhereView()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
            .environmentObject(AppViewModel())
    }
}
