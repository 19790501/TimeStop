import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var taskType: String
    
    var body: some View {
        VStack {
            Text("Task Detail: \(taskType)")
                .font(.title)
                .padding()
            
            // Placeholder for task details
            Text("This view will show details for the \(taskType) task type")
                .padding()
            
            Spacer()
        }
        .padding()
        .background(themeManager.colors.background)
    }
}

#Preview {
    TaskDetailView(taskType: "工作")
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 