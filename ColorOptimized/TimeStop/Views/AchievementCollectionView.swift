import SwiftUI

struct AchievementCollectionView: View {
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: AchievementType? = nil
    
    private var filteredAchievements: [AchievementBadge] {
        // 获取每种类型的最高等级成就
        let highestAchievements: [AchievementBadge] = AchievementType.allCases.compactMap { type in
            // 获取该类型的所有成就
            let typeAchievements = userModel.achievements.filter { $0.type == type }
            // 找出最高等级的成就
            return typeAchievements.max(by: { $0.level < $1.level })
        }
        
        // 根据筛选条件过滤
        if let filter = selectedFilter {
            return highestAchievements.filter { $0.type == filter }
        } else {
            return highestAchievements
        }
    }
    
    private var totalUnlocked: Int {
        return userModel.achievements.count
    }
    
    // 固定的8种核心任务类型
    private let coreTypes: [AchievementType] = [
        .meeting,
        .thinking,
        .work,
        .life,
        .exercise,
        .reading,
        .sleep,
        .relax
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            // 顶部额外间距，将整个成就收集模块往下移
            Spacer()
                .frame(height: 10)
                
            // 标题和统计
            HStack {
                Text("成就收集")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.colors.primary)
                
                Spacer()
                
                Text("已解锁: \(totalUnlocked)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.colors.secondaryText)
                
                // 测试数据下拉菜单
                Menu {
                    Button(action: {
                        userModel.generateTestData()
                    }) {
                        Label("标准测试数据", systemImage: "wand.and.stars")
                    }
                    
                    Button(action: {
                        userModel.generateAllLevelsTestData()
                    }) {
                        Label("全部等级数据", systemImage: "sparkles.rectangle.stack")
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(themeManager.colors.primary)
                        .font(.system(size: 18))
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal)
            
            // 添加额外的顶部间距，将图标模块往下移
            Spacer()
                .frame(height: 12)
            
            // 类型网格 - 2行4列布局
            VStack(spacing: 12) {
                // 第一行
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        let type = coreTypes[index]
                        TypeButton(
                            type: type,
                            isSelected: selectedFilter == type,
                            level: userModel.highestLevel(for: type)
                        ) {
                            if selectedFilter == type {
                                selectedFilter = nil
                            } else {
                                selectedFilter = type
                            }
                        }
                    }
                }
                
                // 第二行
                HStack(spacing: 8) {
                    ForEach(4..<8) { index in
                        let type = coreTypes[index]
                        TypeButton(
                            type: type,
                            isSelected: selectedFilter == type,
                            level: userModel.highestLevel(for: type)
                        ) {
                            if selectedFilter == type {
                                selectedFilter = nil
                            } else {
                                selectedFilter = type
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 5)
            
            // 显示"全部"按钮
            Button(action: {
                selectedFilter = nil
            }) {
                Text("显示全部")
                    .font(.subheadline)
                    .foregroundColor(selectedFilter == nil ? themeManager.colors.primary : themeManager.colors.secondaryText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .strokeBorder(selectedFilter == nil ? themeManager.colors.primary : Color.clear, lineWidth: 1.5)
                    )
            }
            .padding(.top, 5)
            
            // 成就列表
            if filteredAchievements.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "star.slash")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.colors.secondaryText.opacity(0.5))
                    
                    Text("暂无成就")
                        .font(.headline)
                        .foregroundColor(themeManager.colors.secondaryText)
                    
                    Text("继续努力，完成更多专注时间来解锁成就")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(themeManager.colors.text.opacity(0.7))
                        .padding(.horizontal)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 当前选中类型的下一等级预览
                        if let selectedType = selectedFilter {
                            let minutes = userModel.achievementProgress[selectedType] ?? 0
                            let currentLevel = selectedType.achievementLevel(for: minutes)
                            let nextLevel = currentLevel < 6 ? currentLevel + 1 : currentLevel
                            
                            // 为满级徽章增加额外的间距，将徽章往下移动50点
                            if currentLevel >= 6 {
                                Spacer()
                                    .frame(height: 50)
                            } else {
                                // 非满级时不添加间距，整体向上移动50点
                                // 完全移除间距
                            }
                                
                            if currentLevel < 6 {
                                VStack(spacing: 16) {
                                    // 进度标题
                                    HStack {
                                        Text("下一等级预览")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(selectedType.progressPercentage(for: minutes) * 100))%")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    HStack(spacing: 20) {
                                        // 当前等级徽章
                                        VStack {
                                            ZStack {
                                                // 背景
                                                Circle()
                                                    .fill(selectedType.color.opacity(0.15))
                                                    .frame(width: 80, height: 80)
                                                
                                                // 内圈
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 65, height: 65)
                                                
                                                // 图标
                                                VStack(spacing: 0) {
                                                    Image(systemName: selectedType.icon)
                                                        .font(.system(size: 30, weight: .bold))
                                                        .foregroundColor(selectedType.color)
                                                    
                                                    Text("Level \(romanNumeralFor(currentLevel))")
                                                        .font(.system(size: 9, weight: .medium))
                                                        .foregroundColor(.black)
                                                }
                                            }
                                            
                                            Text("当前")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        // 进度箭头
                                        VStack {
                                            Image(systemName: "arrow.right")
                                                .font(.title3)
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Text("还需\(selectedType.minutesToNextLevel(for: minutes))分钟")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                        }
                                        
                                        // 下一等级徽章
                                        VStack {
                                            ZStack {
                                                // 背景
                                                Circle()
                                                    .fill(selectedType.color.opacity(0.15))
                                                    .frame(width: 80, height: 80)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(selectedType.color.opacity(0.3), lineWidth: 2)
                                                    )
                                                
                                                // 内圈
                                                Circle()
                                                    .fill(Color.white.opacity(0.9))
                                                    .frame(width: 65, height: 65)
                                                
                                                // 图标
                                                VStack(spacing: 0) {
                                                    Image(systemName: selectedType.icon)
                                                        .font(.system(size: 30, weight: .bold))
                                                        .foregroundColor(selectedType.levelColor(nextLevel))
                                                    
                                                    Text("Level \(romanNumeralFor(nextLevel))")
                                                        .font(.system(size: 9, weight: .medium))
                                                        .foregroundColor(.black)
                                                }
                                            }
                                            .opacity(0.85)
                                            
                                            Text(selectedType.levelDescription(nextLevel))
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    // 进度条
                                    ProgressView(value: selectedType.progressPercentage(for: minutes))
                                        .progressViewStyle(LinearProgressViewStyle(tint: selectedType.color))
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            } else {
                                // 满级成就徽章显示 - 放大50%并下移50点
                                AchievementBadgeView(badge: AchievementBadge(type: selectedType, level: currentLevel))
                                    .scaleEffect(1.5) // 放大成就徽章
                                    .frame(width: 210, height: 210) // 增加框架尺寸
                                    .padding(.bottom, 50) // 增加底部间距
                            }
                            
                            // 如果是满级成就，不显示下面的成就列表，而是显示底部间距
                            if currentLevel >= 6 {
                                Spacer(minLength: 150)
                            }
                        }
                        
                        // 当没有选中特定类型或当前选中的类型不是满级时，才显示成就列表
                        if selectedFilter == nil || (selectedFilter != nil && 
                            selectedFilter!.achievementLevel(for: userModel.achievementProgress[selectedFilter!] ?? 0) < 6) {
                            // 第一行显示3个
                            if filteredAchievements.count > 0 {
                                HStack(spacing: 12) {
                                    ForEach(0..<min(3, filteredAchievements.count), id: \.self) { index in
                                        NavigationLink(destination: AchievementDetailView(type: filteredAchievements[index].type, level: filteredAchievements[index].level, minutes: userModel.achievementProgress[filteredAchievements[index].type] ?? 0)) {
                                            AchievementBadgeView(badge: filteredAchievements[index])
                                                .frame(width: (UIScreen.main.bounds.width - 50) / 3)
                                        }
                                    }
                                }
                            }
                            
                            // 第二行显示3个
                            if filteredAchievements.count > 3 {
                                HStack(spacing: 12) {
                                    ForEach(3..<min(6, filteredAchievements.count), id: \.self) { index in
                                        NavigationLink(destination: AchievementDetailView(type: filteredAchievements[index].type, level: filteredAchievements[index].level, minutes: userModel.achievementProgress[filteredAchievements[index].type] ?? 0)) {
                                            AchievementBadgeView(badge: filteredAchievements[index])
                                                .frame(width: (UIScreen.main.bounds.width - 50) / 3)
                                        }
                                    }
                                    // 如果不足3个，添加占位视图
                                    if filteredAchievements.count < 6 {
                                        ForEach(0..<(6 - filteredAchievements.count), id: \.self) { _ in
                                            Spacer()
                                                .frame(width: (UIScreen.main.bounds.width - 50) / 3)
                                        }
                                    }
                                }
                            }
                            
                            // 第三行显示2个
                            if filteredAchievements.count > 6 {
                                HStack(spacing: 20) {
                                    ForEach(6..<min(8, filteredAchievements.count), id: \.self) { index in
                                        NavigationLink(destination: AchievementDetailView(type: filteredAchievements[index].type, level: filteredAchievements[index].level, minutes: userModel.achievementProgress[filteredAchievements[index].type] ?? 0)) {
                                            AchievementBadgeView(badge: filteredAchievements[index])
                                                .frame(width: (UIScreen.main.bounds.width - 50) / 2.5)
                                        }
                                    }
                                    // 如果不足2个，添加占位视图
                                    if filteredAchievements.count == 7 {
                                        Spacer()
                                            .frame(width: (UIScreen.main.bounds.width - 50) / 2.5)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .padding(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func showAchievementDetails(type: AchievementType) -> some View {
        let minutes = userModel.achievementProgress[type] ?? 0
        let level = type.achievementLevel(for: minutes)
        let levelName = type.levelDescription(level)
        let nextLevel = level < 6 ? level + 1 : level
        let nextLevelName = level < 6 ? type.levelDescription(nextLevel) : "已达最高级"
        let _ = level < 6 ? type.levelThresholds[level - 1] : 0
        let progress = type.progressPercentage(for: minutes)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(type.color.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                    )
                
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("当前等级: \(levelName)")
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            Text("累计时间: \(minutes) 分钟")
                .font(.subheadline)
            
            if level < 6 {
                Text("下一等级: \(nextLevelName)")
                    .font(.subheadline)
                
                Text("还需 \(type.minutesToNextLevel(for: minutes)) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: type.color))
                    .frame(height: 8)
            } else {
                Text("已达最高等级!")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // 将数字转换为罗马数字
    private func romanNumeralFor(_ number: Int) -> String {
        let romanValues = ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ"]
        let index = min(number - 1, romanValues.count - 1)
        return index >= 0 ? romanValues[index] : ""
    }
}

// 任务类型按钮
struct TypeButton: View {
    let type: AchievementType
    let isSelected: Bool
    let level: Int
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var userModel: UserModel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // 圆形背景
                    Circle()
                        .fill(isSelected ? type.color.opacity(0.25) : Color.white.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    // 图标
                    Image(systemName: type.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? type.color : Color.black)
                }
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? themeManager.colors.primary : Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    showingDetail = true
                }
        )
        .sheet(isPresented: $showingDetail) {
            DetailView(type: type)
        }
    }
    
    // 详情视图
    struct DetailView: View {
        let type: AchievementType
        @EnvironmentObject var userModel: UserModel
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 基本信息
                        let minutes = userModel.achievementProgress[type] ?? 0
                        let level = type.achievementLevel(for: minutes)
                        
                        // 进度信息
                        HStack(spacing: 20) {
                            // 左侧图标
                            ZStack {
                                Circle()
                                    .fill(type.color.opacity(0.2))
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: type.icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(type.color)
                            }
                            
                            // 右侧信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("当前等级: \(type.levelDescription(level))")
                                    .font(.headline)
                                
                                Text("累计时间: \(minutes) 分钟")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(type.color.opacity(0.15))
                        .cornerRadius(12)
                        
                        // 进度条
                        VStack(alignment: .leading, spacing: 8) {
                            if level < 6 {
                                let nextLevel = level + 1
                                let progress = type.progressPercentage(for: minutes)
                                let minutesNeeded = type.minutesToNextLevel(for: minutes)
                                
                                Text("距离下一等级: \(type.levelDescription(nextLevel))")
                                    .font(.headline)
                                
                                HStack {
                                    Text("还需\(minutesNeeded)分钟")
                                    
                                    Spacer()
                                    
                                    Text("\(Int(progress * 100))%")
                                        .foregroundColor(type.color)
                                }
                                .font(.subheadline)
                                
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: type.color))
                                    .frame(height: 10)
                            } else {
                                Text("恭喜！已达到最高等级")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(type.color.opacity(0.15))
                        .cornerRadius(12)
                        
                        // 等级指示器
                        HStack(spacing: 15) {
                            ForEach(1...6, id: \.self) { i in
                                Circle()
                                    .fill(i <= level ? type.color : type.color.opacity(0.2))
                                    .frame(width: 25, height: 25)
                                    .overlay(
                                        Text("\(i)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 等级列表
                        VStack(alignment: .leading, spacing: 12) {
                            Text("等级详情")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            ForEach(1...6, id: \.self) { i in
                                HStack {
                                    // 等级图标
                                    Circle()
                                        .fill(i <= level ? type.levelColor(i) : type.levelColor(i).opacity(0.3))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text("\(i)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                    
                                    // 等级名称
                                    Text(type.levelDescription(i))
                                        .font(.body)
                                        .fontWeight(level == i ? .bold : .regular)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // 所需时间
                                    if i == 1 {
                                        Text("≥ \(type.levelThresholds[i-1]) 分钟")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else if i <= 6 {
                                        Text("≥ \(type.levelThresholds[i-1]) 分钟")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // 解锁状态
                                    if level >= i {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.vertical, 6)
                                
                                if i < 6 {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                }
                            }
                        }
                        .padding()
                        .background(type.color.opacity(0.15))
                        .cornerRadius(12)
                        
                        // 鼓励文字
                        if level < 6 {
                            Text("再接再厉，继续积累时间提升等级！")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            Text("恭喜！你已经达到最高等级，成为了真正的大师！")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    }
                    .padding()
                    .foregroundColor(.white)
                }
                .background(Color.black)
                .navigationTitle("\(type.rawValue)成就")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("返回")
                            }
                            .foregroundColor(type.color)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(type.color)
                    }
                }
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .foregroundColor(.white)
                .gesture(
                    DragGesture()
                        .onEnded { gesture in
                            if gesture.translation.width > 100 {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct AchievementCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AchievementCollectionView()
                .environmentObject(UserModel())
                .environmentObject(ThemeManager())
        }
    }
}
