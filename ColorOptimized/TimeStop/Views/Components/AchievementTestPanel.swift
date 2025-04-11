import SwiftUI

struct AchievementTestPanel: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: AchievementType = .work
    @State private var minutes: Double = 30
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("成就测试面板")
                    .font(.title)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Picker("成就类型", selection: $selectedType) {
                    ForEach(AchievementType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("添加分钟数: \(Int(minutes))")
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Slider(value: $minutes, in: 1...500, step: 1)
                        .accentColor(themeManager.currentTheme.primaryColor)
                }
                .padding()
                
                Button(action: {
                    userModel.addMinutes(Int(minutes), for: selectedType)
                    dismiss()
                }) {
                    Text("添加")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.currentTheme.primaryColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("关闭") {
                dismiss()
            })
        }
    }
}

struct AchievementTestPanel_Previews: PreviewProvider {
    static var previews: some View {
        AchievementTestPanel()
            .environmentObject(UserModel())
            .environmentObject(ThemeManager())
    }
} 