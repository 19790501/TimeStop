import SwiftUI

// MARK: - 颜色定义
struct AppColors {
    // 主色 - 荧光绿
    static let neonGreen = Color(hex: "CBDE00") // 荧光绿主色 (HEX #CBDE00)
    static let neonGreenFallback = Color(red: 0.8, green: 0.87, blue: 0.0)
    
    // 翡翠墨绿色 - 倒计时背景色
    static let jadeGreen = Color(hex: "0C4A45") // 翡翠墨绿色 (HEX #0C4A45)
    static let jadeGreenFallback = Color(red: 0.05, green: 0.29, blue: 0.27)
    
    // 荧光绿 - 按钮色
    static let fluorGreen = Color(hex: "00FF00") // 荧光绿 (HEX #00FF00)
    static let fluorGreenFallback = Color(red: 0.0, green: 1.0, blue: 0.0)
    
    // 辅助色1 - 纯黑色
    static let pureBlack = Color(hex: "000000") // 纯黑色 (HEX #000000)
    static let pureBlackFallback = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    // 辅助色2 - 纯白色
    static let pureWhite = Color(hex: "FFFFFF") // 纯白色 (HEX #FFFFFF)
    static let pureWhiteFallback = Color(red: 1.0, green: 1.0, blue: 1.0)
    
    // 辅助色3 - 深灰色
    static let darkGray = Color(hex: "1A1A1A") // 深灰色 (HEX #1A1A1A)
    static let darkGrayFallback = Color(red: 0.1, green: 0.1, blue: 0.1)
    
    // 辅助色4 - 浅灰色
    static let lightGray = Color(hex: "F0F0F0") // 浅灰色 (HEX #F0F0F0)
    static let lightGrayFallback = Color(red: 0.94, green: 0.94, blue: 0.94)
    
    // 背景色 - 亮荧光绿背景
    static let lightNeonGreen = Color(hex: "DBE969") // 亮荧光绿背景 (HEX #DBE969)
    static let lightNeonGreenFallback = Color(red: 0.86, green: 0.91, blue: 0.41)
    
    // 卡片背景色 - 白色卡片
    static let cardBackground = Color(hex: "FFFFFF") // 白色卡片 (HEX #FFFFFF)
    static let cardBackgroundFallback = Color(red: 1.0, green: 1.0, blue: 1.0)
    
    // 卡片背景色2 - 荧光绿卡片
    static let greenCardBackground = Color(hex: "B1CA00") // 荧光绿卡片 (HEX #B1CA00)
    static let greenCardBackgroundFallback = Color(red: 0.69, green: 0.79, blue: 0.0)
    
    // 文本颜色 - 深色文本
    static let darkText = Color(hex: "000000") // 黑色文本 (HEX #000000)
    static let darkTextFallback = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    // 次要文本颜色
    static let secondaryText = Color(hex: "555555") // 灰色文本 (HEX #555555)
    static let secondaryTextFallback = Color(red: 0.33, green: 0.33, blue: 0.33)
    
    // HEX颜色转换扩展
    static func getSafeColor(_ color: Color, fallback: Color) -> Color {
        return color
    }
    
    // 简单的颜色验证方法
    private static func validateColor(_ color: Color) -> Bool {
        // 这里可以添加实际的颜色验证逻辑
        // 例如检查颜色组件是否在有效范围内
        // 目前只是返回 true，表示颜色有效
        return true
    }
    
    // 自定义颜色错误类型
    enum ColorError: Error {
        case invalidColor
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

// MARK: - 主题定义
struct ThemeColors {
    let primary: Color       // 主色调 - 樱粉色
    let secondary: Color     // 辅助色1 - 松石绿
    let accent: Color        // 辅助色2 - 暖灰色
    let background: Color    // 背景色 - 浅粉色
    let secondaryBackground: Color  // 次要背景色
    let text: Color          // 主要文本色
    let secondaryText: Color // 次要文本色
    let buttonText: Color    // 按钮文本色 - 白色
    let buttonBackground: Color // 按钮背景色 - 松石绿
    
    // 渐变颜色数组 - 用于界面中需要渐变的地方
    var gradientColors: [Color] {
        [background, background.opacity(0.8)]
    }
    
    // 创建一个显示颜色错误的主题
    static var errorTheme: ThemeColors {
        ThemeColors(
            primary: Color.red,
            secondary: Color.red.opacity(0.7),
            accent: Color.red.opacity(0.5),
            background: Color(red: 0.1, green: 0.1, blue: 0.1),
            secondaryBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
            text: Color.white,
            secondaryText: Color.gray,
            buttonText: Color.white,
            buttonBackground: Color.red
        )
    }
}

class ThemeManager: ObservableObject {
    static let themeChangeNotification = Notification.Name("ThemeDidChange")
    
    @Published var currentTheme: AppTheme = .classic {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
            // 发送主题改变通知
            NotificationCenter.default.post(name: ThemeManager.themeChangeNotification, object: nil)
        }
    }
    
    @Published var colors: ThemeColors
    @Published var hasError: Bool = false
    
    // 用于跟踪颜色使用情况的字典
    private var colorUsageCount: [String: Int] = [:]
    
    // 记录颜色使用的方法
    func recordColorUsage(_ color: Color) {
        let colorKey = color.description
        colorUsageCount[colorKey, default: 0] += 1
    }
    
    // 重置颜色使用计数
    func resetColorUsage() {
        colorUsageCount = [:]
    }
    
    // 应用主题枚举
    enum AppTheme: String, CaseIterable {
        case classic = "霓光绿"
        case elegantPurple = "知性紫"
        
        // 直接访问的属性
        var textColor: Color {
            return colors.text
        }
        
        var secondaryTextColor: Color {
            return colors.secondaryText
        }
        
        var cardBackgroundColor: Color {
            return colors.secondaryBackground
        }
        
        var primaryColor: Color {
            return colors.primary
        }
        
        var backgroundColor: Color {
            return colors.background
        }
        
        var colors: ThemeColors {
            switch self {
            case .classic:
                return ThemeColors(
                    primary: AppColors.getSafeColor(AppColors.neonGreen, fallback: AppColors.neonGreenFallback),
                    secondary: AppColors.getSafeColor(AppColors.pureBlack, fallback: AppColors.pureBlackFallback),
                    accent: AppColors.getSafeColor(AppColors.pureWhite, fallback: AppColors.pureWhiteFallback),
                    background: AppColors.getSafeColor(AppColors.lightNeonGreen, fallback: AppColors.lightNeonGreenFallback),
                    secondaryBackground: AppColors.getSafeColor(AppColors.cardBackground, fallback: AppColors.cardBackgroundFallback),
                    text: AppColors.getSafeColor(AppColors.darkText, fallback: AppColors.darkTextFallback),
                    secondaryText: AppColors.getSafeColor(AppColors.secondaryText, fallback: AppColors.secondaryTextFallback),
                    buttonText: Color.white,
                    buttonBackground: AppColors.getSafeColor(AppColors.pureBlack, fallback: AppColors.pureBlackFallback)
                )
            case .elegantPurple:
                return ThemeColors(
                    primary: Color(hex: "8A2BE2"),     // 深紫色（主题色）
                    secondary: Color(hex: "D8BFD8"),   // 淡紫色（辅助色，从E6E6FA调深）
                    accent: Color(hex: "FFD700"),      // 金色（点缀色）
                    background: Color(hex: "F0E6FF"),  // 淡雅白紫色背景（从F5F0FF调深）
                    secondaryBackground: Color.white,  // 纯白色（次要背景色）
                    text: Color(hex: "3A2A6D"),        // 暗紫色文本（更深）
                    secondaryText: Color(hex: "7A7A8E"), // 灰紫色（次要文本色，从8B8B9E调深）
                    buttonText: Color.white,           // 白色（按钮文本色）
                    buttonBackground: Color(hex: "7928CA") // 深紫色（按钮背景色，更鲜明）
                )
            }
        }
    }
    
    init() {
        // 先初始化所有存储属性，以便可以使用 self
        self.hasError = false
        
        // 从UserDefaults加载保存的主题
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            // 先设置 currentTheme 和默认 colors 值
            self.currentTheme = theme
            self.colors = theme.colors
            
            // 然后进行验证
            do {
                // 现在可以安全地调用 validateThemeColors 方法，因为所有属性都已初始化
                if !validateThemeColors(theme.colors) {
                    throw ThemeError.invalidThemeColors
                }
                // 如果验证通过，则保持当前设置
            } catch {
                // 如果验证失败，使用错误主题
                print("主题加载错误，使用默认主题: \(error.localizedDescription)")
                self.currentTheme = .classic
                self.colors = ThemeColors.errorTheme
                self.hasError = true
            }
        } else {
            // 默认使用紫色主题
            self.currentTheme = .classic
            self.colors = AppTheme.classic.colors
        }
    }
    
    // 验证主题颜色
    private func validateThemeColors(_ colors: ThemeColors) -> Bool {
        // 这里可以添加实际的主题颜色验证逻辑
        // 例如检查所有颜色是否有效
        return true
    }
    
    // 主题错误类型
    enum ThemeError: Error {
        case invalidThemeColors
    }
    
    // 切换主题的方法
    func switchTheme(to theme: AppTheme) {
        do {
            // 验证目标主题
            if !validateThemeColors(theme.colors) {
                throw ThemeError.invalidThemeColors
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTheme = theme
                self.colors = theme.colors
                self.hasError = false
            }
        } catch {
            print("主题切换错误: \(error.localizedDescription)")
            self.hasError = true
            self.colors = ThemeColors.errorTheme
        }
    }
    
    func updateColors(_ colors: ThemeColors) {
        withAnimation {
            self.colors = colors
        }
    }
    
    // 生成当前主题使用报告
    func generateThemeUsageReport() -> String {
        return """
        当前主题: \(currentTheme.rawValue)
        主要颜色: \(colorDescription(colors.primary))
        次要颜色: \(colorDescription(colors.secondary))
        强调色: \(colorDescription(colors.accent))
        背景色: \(colorDescription(colors.background))
        次要背景色: \(colorDescription(colors.secondaryBackground))
        文本颜色: \(colorDescription(colors.text))
        次要文本颜色: \(colorDescription(colors.secondaryText))
        按钮文本颜色: \(colorDescription(colors.buttonText))
        按钮背景色: \(colorDescription(colors.buttonBackground))
        """
    }
    
    // 辅助函数，描述颜色
    private func colorDescription(_ color: Color) -> String {
        // 对比颜色相似度的逻辑
        func isSimilarColor(_ c1: Color, _ c2: Color) -> Bool {
            // 在实际应用中，这里应该比较颜色的RGB分量
            // 这里简化处理，直接比较颜色对象
            return c1 == c2
        }
        
        // 识别颜色
        if isSimilarColor(color, AppColors.neonGreen) {
            return "荧光绿主色 (neonGreen)"
        } else if isSimilarColor(color, AppColors.pureBlack) {
            return "纯黑色辅助色 (pureBlack)"
        } else if isSimilarColor(color, AppColors.pureWhite) {
            return "纯白色辅助色 (pureWhite)"
        } else if isSimilarColor(color, AppColors.darkGray) {
            return "深灰色辅助色 (darkGray)"
        } else if isSimilarColor(color, AppColors.lightGray) {
            return "浅灰色辅助色 (lightGray)"
        } else if isSimilarColor(color, AppColors.lightNeonGreen) {
            return "亮荧光绿背景 (lightNeonGreen)"
        } else if isSimilarColor(color, AppColors.cardBackground) {
            return "白色卡片 (cardBackground)"
        } else if isSimilarColor(color, AppColors.greenCardBackground) {
            return "荧光绿卡片 (greenCardBackground)"
        } else if isSimilarColor(color, AppColors.darkText) {
            return "黑色文本 (darkText)"
        } else if isSimilarColor(color, AppColors.secondaryText) {
            return "灰色文本 (secondaryText)"
        } else if isSimilarColor(color, Color.red) {
            return "错误红色 (fallback)"
        } else {
            return "自定义颜色"
        }
    }
    
    // 生成颜色使用报告，列出所有使用特定颜色的界面
    func generateColorUsageReport() -> String {
        var report = "当前主题：\(currentTheme.rawValue)\n\n"
        report += "系统内色彩使用情况：\n"
        report += "- 主色: 荧光绿 - 使用次数: \(colorUsageCount[AppColors.neonGreen.description] ?? 0)\n"
        report += "- 辅助色1: 纯黑色 - 使用次数: \(colorUsageCount[AppColors.pureBlack.description] ?? 0)\n"
        report += "- 辅助色2: 纯白色 - 使用次数: \(colorUsageCount[AppColors.pureWhite.description] ?? 0)\n"
        report += "- 辅助色3: 深灰色 - 使用次数: \(colorUsageCount[AppColors.darkGray.description] ?? 0)\n"
        report += "- 辅助色4: 浅灰色 - 使用次数: \(colorUsageCount[AppColors.lightGray.description] ?? 0)\n"
        report += "- 背景色: 亮荧光绿背景 - 使用次数: \(colorUsageCount[AppColors.lightNeonGreen.description] ?? 0)\n"
        report += "- 卡片背景色: 白色卡片 - 使用次数: \(colorUsageCount[AppColors.cardBackground.description] ?? 0)\n"
        report += "- 卡片背景色2: 荧光绿卡片 - 使用次数: \(colorUsageCount[AppColors.greenCardBackground.description] ?? 0)\n"
        report += "- 文本色: 黑色文本 - 使用次数: \(colorUsageCount[AppColors.darkText.description] ?? 0)\n"
        report += "- 次要文本色: 灰色文本 - 使用次数: \(colorUsageCount[AppColors.secondaryText.description] ?? 0)\n\n"
        
        report += "非主题颜色使用情况（可能需要检查）：\n"
        for (colorDesc, count) in colorUsageCount {
            if !isThemeColor(colorDesc) && count > 0 {
                report += "- \(colorDesc) - 使用次数: \(count)\n"
            }
        }
        
        return report
    }
    
    private func isThemeColor(_ colorDesc: String) -> Bool {
        let themeColorDescriptions = [
            AppColors.neonGreen.description,
            AppColors.pureBlack.description,
            AppColors.pureWhite.description,
            AppColors.darkGray.description,
            AppColors.lightGray.description,
            AppColors.lightNeonGreen.description,
            AppColors.cardBackground.description,
            AppColors.greenCardBackground.description,
            AppColors.darkText.description,
            AppColors.secondaryText.description,
            // 备用颜色
            AppColors.neonGreenFallback.description,
            AppColors.pureBlackFallback.description,
            AppColors.pureWhiteFallback.description,
            AppColors.darkGrayFallback.description,
            AppColors.lightGrayFallback.description,
            AppColors.lightNeonGreenFallback.description,
            AppColors.cardBackgroundFallback.description,
            AppColors.greenCardBackgroundFallback.description,
            AppColors.darkTextFallback.description,
            AppColors.secondaryTextFallback.description
        ]
        
        return themeColorDescriptions.contains(colorDesc)
    }
    
    // 检查全局颜色系统的健康状态
    func checkColorSystemHealth() -> Bool {
        var isHealthy = true
        
        // 检查是否有错误状态
        if hasError {
            isHealthy = false
        }
        
        // 检查主题颜色是否有效
        if !validateThemeColors(colors) {
            isHealthy = false
        }
        
        // 检查特定颜色是否可用
        let colorsToCheck: [Color] = [
            colors.primary,
            colors.secondary,
            colors.accent,
            colors.background,
            colors.secondaryBackground,
            colors.text,
            colors.secondaryText,
            colors.buttonText,
            colors.buttonBackground
        ]
        
        for color in colorsToCheck {
            if !checkColorAvailability(color) {
                isHealthy = false
            }
        }
        
        return isHealthy
    }
    
    // 检查颜色是否可用
    private func checkColorAvailability(_ color: Color) -> Bool {
        // 在实际应用中，可以添加更多逻辑来检查颜色是否真的可用
        return color != Color.clear
    }
} 
