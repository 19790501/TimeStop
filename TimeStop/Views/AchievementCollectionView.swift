import SwiftUI

struct AchievementCollectionView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // 标题
                Text("成就收集")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 45)
                
                // 内容区域 - 目前为空白，等待后续开发
                VStack {
                    Text("成就收集页面")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("此页面将显示用户获得的成就")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.05))
                                    
                                    Spacer()
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
    }
}
