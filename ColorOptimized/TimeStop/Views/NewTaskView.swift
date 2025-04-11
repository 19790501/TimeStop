import SwiftUI

struct NewTaskView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var taskName: String = ""
    @State private var duration: Int = 25
    @State private var selectedFocusType: Task.FocusType = .general
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 任务名称输入
                TextField("输入任务名称", text: $taskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // 时长选择
                Stepper("专注时长: \(duration)分钟", value: $duration, in: 5...120, step: 5)
                    .padding(.horizontal)
                
                // 专注类型选择
                Picker("专注类型", selection: $selectedFocusType) {
                    ForEach(Task.FocusType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                Spacer()
                
                // 确认按钮
                Button(action: {
                    viewModel.createTask(
                        title: taskName,
                        duration: duration,
                        focusType: selectedFocusType
                    )
                    isPresented = false
                    dismiss()
                }) {
                    Text("确认")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(themeManager.colors.primary)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(taskName.isEmpty)
            }
            .padding(.top)
            .navigationTitle("新建任务")
            .navigationBarItems(leading: Button("取消") {
                isPresented = false
                dismiss()
            })
        }
    }
}

#Preview {
    NewTaskView(isPresented: .constant(true))
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 