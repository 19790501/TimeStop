# TimeStop 开发者指南

## 1. 项目概述

TimeStop是一个专注于时间管理的iOS应用，旨在帮助用户更好地管理他们的时间，提高工作和学习效率。应用采用SwiftUI构建，支持iOS 15.0及以上版本。

### 1.1 核心价值
- 帮助用户培养时间管理习惯
- 提供直观的时间追踪体验
- 通过成就系统激励用户持续使用
- 支持个性化主题定制

## 2. 核心功能模块

### 2.1 任务管理
- 位置：`Views/TaskManagement/`
- 关键文件：
  - `TaskListView.swift`: 任务列表主视图
  - `TaskDetailView.swift`: 任务详情视图
  - `TaskEditorView.swift`: 任务编辑视图
- 数据模型：`Models/Task.swift`

### 2.2 时间追踪
- 位置：`Views/Timer/`
- 关键文件：
  - `TimerView.swift`: 计时器主视图
  - `TimerControlView.swift`: 计时器控制组件
- 核心功能：
  - 可视化计时器
  - 任务切换
  - 时间统计

### 2.3 成就系统
- 位置：`Views/Achievement/` 和 `Models/AchievementSystem/`
- 关键文件：
  - `AchievementView.swift`: 成就系统主视图
  - `AchievementType.swift`: 成就类型定义
  - `AchievementProgress.swift`: 成就进度管理
- 特点：
  - 基于时间的等级系统
  - 8种任务类型
  - 7个成就等级
  - 月度重置机制

### 2.4 主题系统
- 位置：`Utils/Theme/`
- 关键文件：
  - `ThemeManager.swift`: 主题管理器
  - `ThemeColors.swift`: 主题颜色定义
- 支持主题：
  - 霓光绿（默认）
  - 知性紫
  - 暗黑模式

## 3. 技术架构

### 3.1 架构模式
- MVVM架构
- 响应式编程（Combine）
- 依赖注入

### 3.2 数据管理
- UserDefaults: 存储用户设置和成就数据
- CoreData: 任务数据持久化
- 状态管理：@State, @StateObject, @EnvironmentObject

### 3.3 关键优化
1. **性能优化**
   - 使用LazyVGrid优化列表性能
   - 图片资源优化和缓存
   - 减少不必要的视图刷新

2. **内存管理**
   - 及时释放不需要的资源
   - 使用弱引用避免循环引用
   - 优化图片加载策略

3. **用户体验**
   - 流畅的动画过渡
   - 直观的交互设计
   - 即时的反馈机制

## 4. 开发指南

### 4.1 环境要求
- Xcode 13.0+
- iOS 15.0+
- Swift 5.5+

### 4.2 代码规范
- 遵循Swift官方代码规范
- 使用SwiftLint进行代码检查
- 编写清晰的注释和文档

### 4.3 开发流程
1. 功能开发
   - 创建新的功能分支
   - 实现功能
   - 编写单元测试
   - 代码审查
   - 合并到主分支

2. 发布流程
   - 版本号更新
   - 更新日志编写
   - 测试验证
   - App Store提交

## 5. 常见问题

### 5.1 成就系统
Q: 成就进度如何保存？
A: 使用UserDefaults存储，键名为"achievement_progress"

Q: 月度重置如何实现？
A: 通过AchievementResetManager检查上次重置时间，每月1日自动重置

### 5.2 主题系统
Q: 如何添加新主题？
A: 在ThemeManager中添加新的主题枚举，并定义对应的颜色配置

Q: 暗黑模式如何实现？
A: 使用系统的颜色适配器，结合自定义主题颜色

### 5.3 性能问题
Q: 列表滚动卡顿？
A: 使用LazyVGrid替代普通列表，优化视图刷新逻辑

Q: 内存占用过高？
A: 检查图片资源加载，使用适当的缓存策略

## 6. 未来规划

### 6.1 功能扩展
- 数据导出功能
- 成就分享
- 自定义主题
- 多设备同步

### 6.2 性能优化
- 进一步优化列表性能
- 减少内存占用
- 提升启动速度

### 6.3 用户体验
- 添加更多动画效果
- 优化交互流程
- 增加新手引导

## 7. 联系方式

如有任何问题或建议，请联系：
- 邮箱：developer@timestop.app
- GitHub：https://github.com/timestop 