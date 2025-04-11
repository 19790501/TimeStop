# TimeStop成就系统设计文档

## 概述

TimeStop应用中的成就系统是一个激励用户持续使用应用并培养良好习惯的功能。该系统通过记录用户在不同类型活动上花费的时间，提供成就级别和进度跟踪，帮助用户可视化他们的进步和成长。

## 核心组件

### 1. 成就类型 (AchievementType)

成就系统支持多种活动类型，每种类型对应不同的成就：

- 会议 (meeting)：参与会议的时间
- 思考 (thinking)：用于思考和构思的时间
- 工作 (work)：专注于工作任务的时间
- 生活 (life)：日常生活活动的时间
- 锻炼 (exercise)：体育锻炼的时间
- 阅读 (reading)：阅读学习的时间
- 睡眠 (sleep)：休息睡眠的时间
- 休闲 (relax)：放松娱乐的时间

每种成就类型都有独特的图标和颜色标识。

### 2. 成就等级系统

成就等级基于用户在每种活动上累计的时间：

- 基本成就：1-2级，适合初次使用的用户
- 中级成就：3-4级，需要持续使用应用
- 高级成就：5-6级，展示用户的长期投入
- 专家成就：7级以上，表彰高度的专注和坚持

等级进度以百分比显示，直观反映用户距离下一级的进展。

### 3. 月度重置机制

为了保持用户的长期参与度，成就系统采用月度重置机制：

- 每月初（第一天）自动重置所有成就的累计时间
- 重置时会显示提示，鼓励用户在新的一月再创佳绩
- 系统会记录距离下次重置的剩余天数

### 4. 界面组件

成就系统包含以下主要界面组件：

- **成就收集视图**：展示所有可获取的成就及其当前状态
- **成就概览**：总结用户解锁的成就数量和总完成度
- **成就卡片**：显示单个成就的图标、名称、等级和进度
- **成就详情**：提供特定成就的详细信息，包括累计时间、当前等级描述和进度

## 实现文件

成就系统的核心实现分布在以下文件中：

- `AchievementType.swift`：定义成就类型枚举及相关方法
- `AchievementViewModel.swift`：管理成就数据和业务逻辑
- `AchievementResetManager.swift`：处理月度重置逻辑
- `AchievementCollectionView.swift`：成就收集页面UI实现
- `AchievementDetailView.swift`：成就详情页面UI实现
- `AchievementCardView.swift`：成就卡片组件UI实现

## 数据存储

成就数据通过UserDefaults存储在本地，包括：

- 每种成就类型的累计时间
- 上次重置日期
- 已解锁的成就等级

## 拓展计划

未来计划为成就系统添加的功能：

1. 成就徽章系统：为特定里程碑提供独特的视觉奖励
2. 社交分享：允许用户分享他们的成就到社交媒体
3. 成就统计与分析：更丰富的数据可视化和趋势分析
4. 定制化目标：允许用户为每种成就类型设置个人目标

## 使用指南

应用开发者可以通过以下方式整合和扩展成就系统：

1. 在记录用户活动时间的地方调用`AchievementViewModel`相关方法
2. 在导航系统中添加成就收集视图的入口
3. 在应用启动时检查是否需要月度重置
4. 在完成特定活动后显示成就解锁通知

## 注意事项

- 确保应用启动时初始化`AchievementViewModel`
- 每次记录用户活动时间后立即调用相应的成就更新方法
- 注意`AchievementResetManager`需要在每次应用启动时检查是否需要月度重置
- 扩展新的成就类型时，需要在`AchievementType`枚举中添加新的case并实现相应的方法

## 示例代码

### 记录活动时间并更新成就
```swift
// 当用户完成一个专注会话时
func completeSession(type: ActivityType, minutes: Int) {
    // 记录活动时间
    saveActivityTimeToDataStore(type: type, minutes: minutes)
    
    // 更新相应的成就进度
    let achievementViewModel = AchievementViewModel.shared
    
    // 根据活动类型更新相应的成就
    switch type {
    case .meeting:
        achievementViewModel.addMinutes(for: .meeting, minutes: minutes)
    case .work:
        achievementViewModel.addMinutes(for: .work, minutes: minutes)
    // 其他活动类型...
    }
    
    // 检查是否有新的成就等级解锁，如果有则显示通知
    if achievementViewModel.checkForNewAchievements() {
        showAchievementUnlockNotification()
    }
}
```

### 检查月度成就重置
```swift
// 在应用启动时调用
func checkMonthlyReset() {
    // 检查是否需要月度重置
    if AchievementResetManager.shared.checkAndResetIfNeeded() {
        // 显示月度重置通知
        showMonthlyResetNotification()
        
        // 重新初始化成就视图模型
        AchievementViewModel.shared.loadAchievements()
    }
    
    // 更新距离下次重置的天数
    updateDaysUntilNextReset()
}

// 更新距离下次重置的天数的方法实现
func updateDaysUntilNextReset() {
    let daysRemaining = AchievementResetManager.shared.daysUntilNextReset()
    daysUntilReset = daysRemaining
}
```

### 在导航中添加成就收集视图
```swift
// 在TabView中添加成就收集视图
TabView {
    // 其他标签页...
    
    // 成就收集视图
    AchievementCollectionView()
        .tabItem {
            Label {
                Image(systemName: "trophy")
                Text("成就收集")
            }
        }
}
```

## 自定义主题与成就系统

为了确保成就系统与应用的主题系统保持一致，成就视图应使用`ThemeManager`提供的颜色：

```swift
struct AchievementCollectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    // 其他属性...
    
    var body: some View {
        VStack {
            // 标题栏使用主题的主色调
            Text("成就收集")
                .font(.largeTitle.bold())
                .foregroundColor(themeManager.colors.primary)
            
            // 成就概览使用主题的次要色调
            HStack {
                // 成就统计卡片
                VStack {
                    Text("总完成率")
                        .foregroundColor(themeManager.colors.secondary)
                    // 其他内容...
                }
                .padding()
                .background(themeManager.colors.cardBackground)
                .cornerRadius(10)
            }
            
            // 成就列表
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AchievementType.allCases, id: \.self) { achievement in
                        // 使用主题颜色创建成就卡片
                        AchievementCardView(achievement: achievement)
                            .environmentObject(themeManager)
                    }
                }
                .padding()
            }
        }
        // 使用主题背景色
        .background(themeManager.colors.background)
    }
}
```

同样，成就卡片也应使用主题颜色：

```swift
struct AchievementCardView: View {
    let achievement: AchievementType
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var viewModel: AchievementViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            // 成就图标使用主题的主色调
            Image(systemName: achievement.icon)
                .font(.system(size: 30))
                .foregroundColor(themeManager.colors.primary)
            
            // 成就名称使用主题的文本颜色
            Text(achievement.name)
                .font(.headline)
                .foregroundColor(themeManager.colors.text)
            
            // 进度条使用主题的次要色调
            ProgressView(value: achievement.progressPercentage())
                .tint(themeManager.colors.secondary)
        }
        .padding()
        // 使用主题的卡片背景色
        .background(themeManager.colors.cardBackground)
        .cornerRadius(10)
    }
}
```

## 结语

成就系统为TimeStop应用增加了游戏化元素，鼓励用户更有效地管理时间并持续使用应用。通过合理设计的成就等级、视觉反馈和月度重置机制，用户可以获得成就感并保持长期使用的动力。

该系统的设计遵循了以下原则：

1. **简洁明了**：成就系统的界面简洁易懂，用户可以一目了然地了解自己的成就状态
2. **渐进式挑战**：成就等级设计合理，给用户带来持续的挑战感和成就感
3. **视觉反馈**：通过颜色、图标和进度条等视觉元素，为用户提供直观的反馈
4. **主题一致性**：成就系统与应用的整体主题保持一致，提供统一的用户体验
5. **周期性重置**：月度重置机制让用户保持长期挑战的动力

通过遵循本文档中的设计和实现指南，开发者可以顺利地集成、扩展和维护TimeStop应用的成就系统，为用户提供更加丰富和激励性的使用体验。

未来计划的功能包括：

- 成就历史记录：记录用户过去几个月的成就完成情况
- 分享功能：允许用户分享自己的成就到社交媒体
- 徽章解锁动画：为成就解锁添加更生动的动画效果
- 复合成就：需要同时满足多个条件的高级成就
- 年度成就回顾：每年底为用户生成一个成就总结报告

---
文档最后更新：2023年11月
版本：1.0
