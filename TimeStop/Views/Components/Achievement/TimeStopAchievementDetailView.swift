import SwiftUI

struct TimeStopAchievementDetailView: View {
    let type: AchievementType
    let level: Int
    let minutes: Int
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animateProgress = false
    
    // 计算下一级所需分钟数
    var minutesToNextLevel: Int {
        if level >= type.levelThresholds.count {
            return 0 // 已达最高级
        }
        return type.minutesToNextLevel(for: minutes)
    }
    
    // 计算等级进度百分比
    var progressPercentage: Double {
        return type.progressPercentage(for: minutes)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 成就图标和标题
                VStack(spacing: 16) {
                    // 成就图标
                    ZStack {
                        Circle()
                            .fill(type.color.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .shadow(color: type.color.opacity(0.5), radius: 8, x: 0, y: 4)
                        
                        Circle()
                            .stroke(type.levelColor(level), lineWidth: 3)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: type.icon)
                            .font(.system(size: 50))
                            .foregroundColor(type.color)
                    }
                    
                    // 成就名称和等级
                    VStack(spacing: 8) {
                        Text(type.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(getTextColor())
                        
                        Text(type.levelDescription(level))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(type.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(type.color.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.top)
                
                // 等级指示器
                HStack(spacing: 12) {
                    ForEach(0..<6) { index in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(index < level ? type.color : Color.gray.opacity(0.3))
                                .frame(width: 16, height: 16)
                            
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(index < level ? type.color : .gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 进度卡片
                VStack(spacing: 16) {
                    // 当前进度
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("当前累计时间")
                                .font(.headline)
                                .foregroundColor(getTextColor())
                            
                            if minutes >= 60 {
                                Text("\(minutes / 60)小时\(minutes % 60)分钟")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(type.color)
                            } else {
                                Text("\(minutes)分钟")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(type.color)
                            }
                        }
                        
                        Spacer()
                        
                        // 累计时间图标
                        Image(systemName: "clock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(getTextColor().opacity(0.7))
                    }
                    
                    // 进度条
                    VStack(alignment: .leading, spacing: 8) {
                        // 进度百分比
                        HStack {
                            Text("等级进度")
                                .font(.subheadline)
                                .foregroundColor(getTextColor().opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(Int(progressPercentage * 100))%")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(type.color)
                        }
                        
                        // 自定义进度条
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                            
                            // 进度
                            RoundedRectangle(cornerRadius: 6)
                                .fill(type.color)
                                .frame(width: animateProgress ? 
                                      CGFloat(progressPercentage) * UIScreen.main.bounds.width * 0.8 : 0, 
                                      height: 12)
                                .animation(.easeInOut(duration: 1.0), value: animateProgress)
                        }
                        
                        // 时间里程碑标记
                        HStack {
                            if level > 0 && level < type.levelThresholds.count {
                                Text("\(type.levelThresholds[level-1])分钟")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(type.levelThresholds[level])分钟")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
                .background(getCardBackgroundColor())
                .cornerRadius(16)
                .shadow(color: type.color.opacity(0.2), radius: 5, x: 0, y: 2)
                
                // 下一等级信息
                if level < type.levelThresholds.count {
                    VStack(spacing: 12) {
                        Text("距离下一等级")
                            .font(.headline)
                            .foregroundColor(getTextColor())
                        
                        HStack {
                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(type.color)
                            
                            Text(type.levelDescription(level + 1))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(type.color)
                        }
                        
                        if minutesToNextLevel > 0 {
                            HStack {
                                Text("还需")
                                    .font(.subheadline)
                                    .foregroundColor(getTextColor().opacity(0.7))
                                
                                if minutesToNextLevel >= 60 {
                                    Text("\(minutesToNextLevel / 60)小时\(minutesToNextLevel % 60)分钟")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(type.color)
                                } else {
                                    Text("\(minutesToNextLevel)分钟")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(type.color)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(getCardBackgroundColor())
                    .cornerRadius(16)
                    .shadow(color: type.color.opacity(0.2), radius: 5, x: 0, y: 2)
                } else {
                    // 最高等级提示
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.yellow)
                            .shadow(color: Color.orange.opacity(0.5), radius: 5, x: 0, y: 2)
                        
                        Text("恭喜！")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(getTextColor())
                        
                        Text("已达到最高等级")
                            .font(.headline)
                            .foregroundColor(getTextColor().opacity(0.7))
                    }
                    .padding()
                    .background(getCardBackgroundColor())
                    .cornerRadius(16)
                    .shadow(color: type.color.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                
                // 成就提示
                Text(type.levelSuggestion(level))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(getTextColor().opacity(0.7))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(getCardBackgroundColor())
                    .cornerRadius(16)
                    .shadow(color: type.color.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationBarTitle("\(type.name)成就", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton(color: .white))
        .background(
            // 用主题响应背景
            getBackgroundGradient()
            .edgesIgnoringSafeArea(.all)
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(type.name)成就")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(getHeaderColor(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width > 100 {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.dismiss(animated: true)
                        }
                    }
                }
        )
        .preferredColorScheme(themeManager.currentTheme == .classic ? .dark : .light)
        .onAppear {
            // 延迟动画以创建更好的效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateProgress = true
            }
        }
    }
    
    // 获取页眉背景颜色
    private func getHeaderColor() -> Color {
        switch themeManager.currentTheme {
        case .classic:
            return Color(hexCode: "0C4A45")  // 墨绿色
        case .elegantPurple:
            return Color(hexCode: "483D8B")  // 深紫色
        }
    }
    
    // 根据主题获取背景渐变
    private func getBackgroundGradient() -> LinearGradient {
        switch themeManager.currentTheme {
        case .classic:
            return LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color.black,
                        Color.black.opacity(0.9)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        case .elegantPurple:
            return LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(hexCode: "E6E6FA"),  // 淡紫色
                        Color(hexCode: "F8F7FF")   // 淡雅白紫色
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 根据主题获取卡片背景色
    private func getCardBackgroundColor() -> Color {
        switch themeManager.currentTheme {
        case .classic:
            return Color(hexCode: "222222")  // 深灰色
        case .elegantPurple:
            return Color.white  // 纯白色
        }
    }
    
    // 根据主题获取文本颜色
    private func getTextColor() -> Color {
        switch themeManager.currentTheme {
        case .classic:
            return .white
        case .elegantPurple:
            return Color(hexCode: "483D8B")  // 暗紫色
        }
    }
    
    // 获取返回按钮颜色
    private func getButtonColor() -> Color {
        switch themeManager.currentTheme {
        case .classic:
            return .black
        case .elegantPurple:
            return Color(hexCode: "8A2BE2")  // 深紫色
        }
    }
}

// 自定义返回按钮
struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    var color: Color = .black
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("返回")
            }
            .foregroundColor(color)
        }
    }
}

// 颜色扩展，用于创建十六进制颜色
extension Color {
    // 使用不同的方法名以避免冲突
    init(hexCode: String) {
        let hex = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 为了兼容性保留原来的类型别名
typealias AchievementDetailView = TimeStopAchievementDetailView

struct TimeStopAchievementDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimeStopAchievementDetailView(type: AchievementType.work, level: 3, minutes: 150)
                .environmentObject(ThemeManager())
            
            TimeStopAchievementDetailView(type: AchievementType.reading, level: 1, minutes: 40)
                .environmentObject(ThemeManager())
                
            TimeStopAchievementDetailView(type: AchievementType.meeting, level: 5, minutes: 1000)
                .environmentObject(ThemeManager())
        }
    }
} 