import SwiftUI
import AudioToolbox

struct CustomButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isPrimary: Bool
    let soundType: ButtonSoundType
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: AppViewModel
    
    enum ButtonSoundType {
        case normal
        case success
        case cancel
        case none
    }
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void, isPrimary: Bool = true, soundType: ButtonSoundType = .normal) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isPrimary = isPrimary
        self.soundType = soundType
    }
    
    var body: some View {
        Button(action: {
            playButtonSound()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isPrimary ? themeManager.colors.buttonText : themeManager.colors.text)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPrimary ? themeManager.colors.buttonBackground : themeManager.colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : themeManager.colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func playButtonSound() {
        switch soundType {
        case .normal:
            viewModel.playButtonSound()
        case .success:
            viewModel.playSuccessSound()
        case .cancel:
            viewModel.playCancelSound()
        case .none:
            break
        }
    }
}

#Preview {
    CustomButton(title: "按钮", icon: "play.fill", action: {})
} 