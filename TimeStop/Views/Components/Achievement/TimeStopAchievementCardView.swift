import SwiftUI

struct TimeStopAchievementCardView: View {
    let type: AchievementType
    let level: Int
    let minutes: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 成就图标
            Image(systemName: type.icon)
                .font(.system(size: 40))
                .foregroundColor(themeManager.colors.primary)
            
            // 成就名称和等级
            VStack(spacing: 4) {
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.text)
                
                Text("Lv.\(level)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
            }
            
            // 进度条
            ProgressView(value: type.progressPercentage(for: minutes))
                .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                .frame(height: 8)
                .padding(.horizontal)
            
            // 时间信息
            Text("\(minutes)分钟")
                .font(.caption)
                .foregroundColor(themeManager.colors.secondaryText)
        }
        .padding()
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// Alias the old name to the new name for compatibility
typealias AchievementCardView = TimeStopAchievementCardView

struct TimeStopAchievementCardView_Previews: PreviewProvider {
    static var previews: some View {
        TimeStopAchievementCardView(type: AchievementType.work, level: 2, minutes: 90)
            .environmentObject(ThemeManager())
    }
} 