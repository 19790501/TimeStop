import SwiftUI

struct AchievementTestButton: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingTestPanel = false
    
    var body: some View {
        Button(action: {
            showingTestPanel = true
        }) {
            Image(systemName: "wand.and.stars")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(themeManager.currentTheme.primaryColor)
                .clipShape(Circle())
        }
        .sheet(isPresented: $showingTestPanel) {
            AchievementTestPanel()
                .environmentObject(userModel)
                .environmentObject(themeManager)
        }
    }
}

struct AchievementTestButton_Previews: PreviewProvider {
    static var previews: some View {
        AchievementTestButton()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
    }
} 