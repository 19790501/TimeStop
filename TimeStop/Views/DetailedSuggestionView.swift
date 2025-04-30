import SwiftUI

struct DetailedSuggestionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    var taskType: String
    var suggestion: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            HStack {
                Text("\(taskType) 详细建议")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.text)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.colors.secondaryText)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Divider
            Divider()
                .padding(.horizontal)
            
            // Suggestion content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(suggestion)
                        .font(.body)
                        .foregroundColor(themeManager.colors.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.colors.secondaryBackground)
                        )
                    
                    // Example action buttons if needed
                    HStack(spacing: 12) {
                        Button(action: {
                            // Apply suggestion action
                            isPresented = false
                        }) {
                            Text("应用建议")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                        }
                        
                        Button(action: {
                            // Ignore suggestion action
                            isPresented = false
                        }) {
                            Text("忽略")
                                .font(.headline)
                                .foregroundColor(themeManager.colors.text)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(themeManager.colors.secondaryText.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
            }
        }
        .padding(.bottom)
        .background(themeManager.colors.background)
    }
}

#Preview {
    DetailedSuggestionView(
        isPresented: .constant(true), taskType: "工作",
        suggestion: "您在工作任务上花费了太多时间，建议采用番茄工作法提高效率。每25分钟工作后休息5分钟，可以减少疲劳并保持注意力。此外，也可以考虑将部分任务委派给团队成员，或使用任务管理工具提高工作效率。"
    )
    .environmentObject(ThemeManager())
} 
