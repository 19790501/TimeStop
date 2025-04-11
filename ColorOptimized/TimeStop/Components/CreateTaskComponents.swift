import SwiftUI

// 任务类型按钮组件
struct TaskTypeButton: View {
    let type: TaskType
    let isSelected: Bool
    let themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isSelected ? getThemeColor(for: type) : themeManager.colors.secondaryBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: type.icon)
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? .white : getThemeColor(for: type))
                    )
                    .shadow(color: isSelected ? getThemeColor(for: type).opacity(0.3) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? getThemeColor(for: type).opacity(0.3) : Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .blur(radius: 2)
                    )
                
                Text(type.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? getThemeColor(for: type) : themeManager.colors.secondaryText)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
    
    private func getThemeColor(for type: TaskType) -> Color {
        switch type {
        case .thinking:
            return themeManager.colors.primary
        default:
            return type.color
        }
    }
}

// 常用任务按钮组件
struct FavoriteTaskButton: View {
    let task: FavoriteTask
    let onTap: () -> Void
    let onLongPress: () -> Void
    let themeManager: ThemeManager
    
    private var taskType: TaskType {
        TaskType.allCases.first(where: { $0.rawValue == task.taskType }) ?? .work
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: taskType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(task.isEnabled ? .white : .gray)
                    .frame(width: 43, height: 43)
                    .background(
                        Circle()
                            .fill(task.isEnabled ? 
                                AppColors.pureBlack : 
                                AppColors.pureBlack.opacity(0.3))
                    )
                
                Text("\(task.duration)分钟")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .opacity(task.isEnabled ? 1.0 : 0.6)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 2.0)
                .onEnded { _ in onLongPress() }
        )
        .buttonStyle(PlainButtonStyle())
        .disabled(!task.isEnabled)
    }
}

// 时间滑块组件
struct TimeSlider: View {
    let title: String
    let subtitle: String
    let value: Int
    let maxValue: Int
    let isSelected: Bool
    let unit: String
    let step: Int
    let onValueChanged: (DragGesture.Value) -> Void
    let onTap: () -> Void
    let onDragEnded: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppColors.pureBlack.opacity(0.8))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(AppColors.pureBlack.opacity(0.5))
                    .padding(.leading, 4)
                
                Spacer()
                
                Text("\(value)\(unit)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.pureBlack : AppColors.pureBlack.opacity(0.5))
                    .padding(.trailing, 8)
            }
            
            HStack {
                Spacer()
                
                // 滑块组件
                SliderTrack(
                    value: value,
                    maxValue: maxValue,
                    isSelected: isSelected,
                    onValueChanged: onValueChanged,
                    onDragEnded: onDragEnded
                )
                
                Spacer()
            }
        }
        .onTapGesture(perform: onTap)
    }
}

// 分离滑块轨道组件
struct SliderTrack: View {
    let value: Int
    let maxValue: Int
    let isSelected: Bool
    let onValueChanged: (DragGesture.Value) -> Void
    let onDragEnded: () -> Void
    
    var body: some View {
        // 保证滑块和滑块条的垂直居中对齐
        ZStack(alignment: .leading) {
            // 基础滑块轨道
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.7))
                .frame(width: trackWidth, height: 6)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // 填充部分
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.pureBlack)
                .frame(width: sliderWidth(), height: 6)
                .shadow(color: AppColors.pureBlack.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // 最右侧指示点 - 位于轨道最右侧，与轨道居中
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 8, height: 8)
                .offset(x: trackWidth - 4)
            
            // 滑块拖动点
            Circle()
                .fill(AppColors.pureBlack)
                .frame(width: 20, height: 20)
                .offset(x: sliderWidth() - 10)
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(height: 40) // 增加高度以便更好地接收触摸事件
        .contentShape(Rectangle()) // 使整个区域可点击
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged(onValueChanged)
                .onEnded { _ in onDragEnded() }
        )
        .allowsHitTesting(true) // 确保可以接收触摸事件
    }
    
    // 计算轨道宽度
    private var trackWidth: CGFloat {
        return (UIScreen.main.bounds.width - 50) * 0.85
    }
    
    // 计算滑块位置
    private func sliderWidth() -> CGFloat {
        let percentage = CGFloat(value) / CGFloat(maxValue)
        return min(trackWidth * percentage, trackWidth)
    }
} 