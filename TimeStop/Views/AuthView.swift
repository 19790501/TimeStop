import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var isShowingRegister: Bool = false
    @State private var username: String = ""
    @State private var hasColorError: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            getBackgroundColor()
                .edgesIgnoringSafeArea(.all)
            
            // Error Indicator
            if hasColorError {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("颜色系统错误，已使用备用颜色")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 30) {
                // Logo and welcome text
                VStack(spacing: 16) {
                    Text("TimeStop")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(getPrimaryColor())
                    
                    Image(systemName: "rocket")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(getPrimaryColor())
                    
                    Text("欢迎来到")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(getTextColor())
                    
                    Text("量化以提高你的专注之旅")
                        .font(.subheadline)
                        .foregroundColor(getSecondaryTextColor())
                }
                .padding(.bottom, 30)
                
                // Login fields
                VStack(spacing: 16) {
                    CustomTextField(
                        placeholder: "请输入手机号",
                        icon: "phone",
                        text: $phoneNumber
                    )
                    
                    CustomTextField(
                        placeholder: "请输入输密码",
                        icon: "lock",
                        text: $password,
                        isSecure: true
                    )
                    
                    if isShowingRegister {
                        CustomTextField(
                            placeholder: "请输入用户名",
                            icon: "person",
                            text: $username
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                HStack {
                    Text(isShowingRegister ? "已有账号?" : "忘记密码?")
                        .foregroundColor(getSecondaryTextColor())
                    
                    Button(isShowingRegister ? "去登录" : "快速注册") {
                        // 播放按钮音效
                        viewModel.playButtonSound()
                        
                        withAnimation {
                            isShowingRegister.toggle()
                        }
                    }
                    .foregroundColor(getPrimaryColor())
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Login button
                CustomButton(
                    title: isShowingRegister ? "注册" : "登录",
                    action: {
                        if isShowingRegister {
                            viewModel.signIn(username: username, password: password)
                        } else {
                            viewModel.signIn(username: phoneNumber, password: password)
                        }
                    },
                    soundType: .success // 使用成功类型的声音
                )
                .padding(.bottom, 16)
                
                // Social login options
                HStack(spacing: 40) {
                    socialLoginButton(icon: "message")
                    socialLoginButton(icon: "person.2")
                }
                .padding(.bottom, 16)
                
                // Terms text
                Text("登录即表示同意我们的服务条款和隐私政策")
                    .font(.caption)
                    .foregroundColor(getSecondaryTextColor())
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .onAppear {
            // 检查颜色系统状态
            hasColorError = themeManager.hasError
        }
        .onChange(of: themeManager.hasError) { oldValue, newValue in
            hasColorError = newValue
        }
    }
    
    // 安全获取背景颜色
    private func getBackgroundColor() -> Color {
        if themeManager.hasError {
            return AppColors.lightNeonGreenFallback
        }
        return AppColors.lightNeonGreen
    }
    
    // 安全获取主色
    private func getPrimaryColor() -> Color {
        if themeManager.hasError {
            return AppColors.neonGreenFallback
        }
        return themeManager.colors.primary
    }
    
    // 安全获取文本颜色
    private func getTextColor() -> Color {
        if themeManager.hasError {
            return AppColors.darkTextFallback
        }
        return themeManager.colors.text
    }
    
    // 安全获取次要文本颜色
    private func getSecondaryTextColor() -> Color {
        if themeManager.hasError {
            return AppColors.secondaryTextFallback
        }
        return themeManager.colors.secondaryText
    }
    
    @ViewBuilder
    private func socialLoginButton(icon: String) -> some View {
        Button(action: {
            // 播放按钮音效
            viewModel.playButtonSound()
        }) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(getTextColor())
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(themeManager.hasError ? 
                              AppColors.cardBackgroundFallback.opacity(0.5) : 
                              themeManager.colors.secondaryBackground.opacity(0.5))
                )
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 