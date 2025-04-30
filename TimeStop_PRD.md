# TimeStop 产品需求文档 (PRD)

## 1. 产品概述

### 1.1 产品愿景
TimeStop是一款专注于提高时间管理效率的iOS应用，旨在帮助用户了解自己的时间使用情况，提高工作效率，养成良好的时间管理习惯。

### 1.2 核心价值
- 可视化时间使用情况，让用户清晰了解时间去向
- 通过专业的时间追踪、任务设定和验证机制提高工作效率
- 游戏化成就系统激励用户持续使用应用
- 个性化体验和数据分析提供针对性的时间管理建议

### 1.3 目标用户
- 时间管理意识强的专业人士
- 需要提高工作学习效率的学生
- 希望培养更好时间管理习惯的个人用户
- 追求高效工作方式的远程工作者

## 2. 功能需求

### 2.1 任务追踪系统
#### 2.1.1 功能描述
提供多种任务类型的创建、管理和追踪功能，支持自定义任务设置和历史记录查询。

#### 2.1.2 详细需求
- 支持8种任务类型：工作、会议、思考、阅读、运动、睡眠、生活、休闲
- 任务创建界面：任务名称、类型选择、时长设定、专注级别选择
- 任务列表：支持按日期、类型、完成状态筛选和排序
- 任务详情：显示任务完成情况、所用时间和专注情况
- 历史记录：查看过去完成的任务记录和统计数据

### 2.2 专注模式
#### 2.2.1 功能描述
专为高效工作设计的专注计时器，通过任务验证确保真实专注，并提供自定义设置满足不同场景需求。

#### 2.2.2 详细需求
- 可视化倒计时界面，显示剩余时间和专注状态
- 多种任务验证方式：绘画、朗读、唱歌等
- 验证机制：确保用户真正专注于任务而非分心
- 暂停/继续功能：支持临时打断和恢复专注
- 自定义铃声：支持多种系统音效选项，提示任务开始和结束
- 按钮音效开关：可开启/关闭交互音效

### 2.3 成就系统
#### 2.3.1 功能描述
游戏化的成就系统，激励用户持续使用应用并培养良好的时间管理习惯。

#### 2.3.2 详细需求
- 8种成就类型，对应8种任务类别
- 7级成就解锁系统：从初级到专家级
- 成就进度显示：直观展示当前等级和进度
- 成就解锁通知：完成阶段目标时提供积极反馈
- 月度重置机制：每月自动重置成就进度，保持挑战性
- 成就收集界面：展示所有成就及解锁状态
- 成就详情页：显示具体解锁条件和奖励说明

### 2.4 数据分析
#### 2.4.1 功能描述
提供详细的时间使用分析和可视化统计，帮助用户了解时间分配和使用效率。

#### 2.4.2 详细需求
- 每日、周度和月度时间使用概览
- 按任务类型的时间分配饼图
- 专注度和完成率趋势图
- 时间使用对比分析：与历史数据比较
- 时间去向分析：直观展示时间分配情况
- 个性化建议：根据数据分析提供改进建议
- 周度总结和月度报告：定期提供时间使用分析报告

### 2.5 个性化设置
#### 2.5.1 功能描述
提供多样化的应用设置选项，让用户根据个人喜好自定义应用体验。

#### 2.5.2 详细需求
- 主题选择：霓光绿(默认)和知性紫两种主题
- 声音设置：倒计时结束铃声选择，按钮音效开关
- 通知设置：任务提醒、成就解锁通知设置
- 账户管理：用户信息设置和数据同步
- 隐私设置：数据收集和使用权限管理

## 3. 技术架构

### 3.1 前端架构
#### 3.1.1 技术栈
- **框架**：SwiftUI
- **编程语言**：Swift 5.9
- **状态管理**：Combine框架 + MVVM架构
- **动画**：SwiftUI内置动画系统
- **导航**：SwiftUI NavigationStack和TabView

#### 3.1.2 前端模块结构
```
TimeStop/
├── Views/
│   ├── Auth/                   # 认证相关视图
│   │   ├── LoginView.swift
│   │   ├── RegisterView.swift
│   │   └── ProfileView.swift
│   ├── Task/                   # 任务管理视图
│   │   ├── TaskListView.swift
│   │   ├── TaskEditorView.swift
│   │   └── TaskDetailView.swift
│   ├── Timer/                  # 计时器相关视图
│   │   ├── TimerView.swift
│   │   ├── TimerControlView.swift
│   │   └── TaskVerificationView.swift
│   ├── Analysis/               # 数据分析视图
│   │   ├── TimeWhereView.swift
│   │   ├── StatisticsView.swift
│   │   └── ReportsView.swift
│   ├── Achievement/            # 成就系统视图
│   │   ├── AchievementView.swift
│   │   ├── AchievementDetailView.swift
│   │   └── AchievementCardView.swift
│   └── Settings/               # 设置视图
│       ├── SettingsView.swift
│       ├── ThemeSettingsView.swift
│       └── NotificationSettingsView.swift
├── Components/                 # 可复用UI组件
│   ├── Cards/
│   │   ├── BaseCardView.swift
│   │   └── InfoCardView.swift
│   ├── Buttons/
│   │   ├── PrimaryButton.swift
│   │   └── SecondaryButton.swift
│   ├── Charts/
│   │   ├── PieChartView.swift
│   │   └── LineChartView.swift
│   └── Feedback/
│       ├── ToastView.swift
│       └── ProgressIndicator.swift
└── Utils/
    ├── Theme/
    │   ├── ThemeManager.swift
    │   └── ColorExtensions.swift
    └── ViewModifiers/
        ├── CardModifier.swift
        └── AnimationModifiers.swift
```

#### 3.1.3 前端开发指南
1. **样式规范**
   - 使用ThemeManager管理所有颜色，不硬编码颜色值
   - 使用预定义的ViewModifiers统一UI风格
   - 卡片样式统一使用CardModifier
   - 文本样式遵循Typography定义的层级

2. **组件复用原则**
   - 创建可重用组件时，确保支持主题和深色模式
   - 组件应接受必要的参数以便灵活配置
   - 复杂UI应拆分为多个子组件提高可维护性

3. **状态管理**
   - 视图内部状态使用@State
   - 跨视图共享状态使用@StateObject和@EnvironmentObject
   - 使用@Published标记需要触发UI更新的属性

4. **性能优化**
   - 使用LazyVGrid/LazyHGrid处理长列表
   - 避免在ScrollView中放置过多视图
   - 图片资源优化和适当缓存
   - 减少不必要的视图刷新

### 3.2 后端架构
#### 3.2.1 数据存储
- **本地存储**
  - **UserDefaults**：存储用户设置和成就数据
  - **CoreData**：任务数据、时间记录的持久化存储
  - **FileManager**：音频文件和资源管理

- **数据模型**
  ```
  Models/
  ├── TaskModel.swift           # 任务数据模型
  ├── UserModel.swift           # 用户数据模型
  ├── AchievementModels/
  │   ├── AchievementType.swift # 成就类型定义
  │   └── AchievementProgress.swift # 成就进度模型
  ├── AnalyticsModels/
  │   ├── TimeUsageData.swift   # 时间使用数据模型
  │   └── StatisticsModel.swift # 统计分析模型
  └── SettingsModel.swift       # 应用设置模型
  ```

#### 3.2.2 业务逻辑
- **视图模型 (ViewModels)**
  ```
  ViewModels/
  ├── AppViewModel.swift        # 应用主视图模型
  ├── TaskViewModel.swift       # 任务管理视图模型
  ├── TimerViewModel.swift      # 计时器功能视图模型
  ├── AchievementViewModel.swift # 成就系统视图模型
  ├── AnalyticsViewModel.swift  # 数据分析视图模型
  └── SettingsViewModel.swift   # 设置管理视图模型
  ```

- **服务层 (Services)**
  ```
  Services/
  ├── DataServices/
  │   ├── CoreDataService.swift # CoreData操作服务
  │   ├── UserDefaultsService.swift # UserDefaults操作服务
  │   └── FileService.swift     # 文件操作服务
  ├── MediaServices/
  │   ├── AudioService.swift    # 音频处理服务
  │   └── NotificationService.swift # 通知服务
  └── UtilityServices/
      ├── DateService.swift     # 日期处理服务
      ├── AnalyticsService.swift # 数据分析服务
      └── LoggingService.swift  # 日志服务
  ```

#### 3.2.3 后端开发指南
1. **数据存储原则**
   - 所有CoreData操作通过CoreDataService进行
   - 用户设置和轻量级数据使用UserDefaults
   - 大文件和媒体资源使用FileManager管理

2. **错误处理与恢复**
   - 实现完整的错误处理机制和日志记录
   - 提供适当的用户反馈和恢复选项
   - 关键操作添加自动备份和恢复机制

3. **性能优化**
   - 批量处理CoreData操作提高效率
   - 适当缓存频繁使用的数据减少读取操作
   - 大型计算任务放在后台线程执行

4. **数据安全**
   - 敏感数据使用KeyChain存储
   - 实现适当的数据验证和清理机制
   - 遵循iOS数据安全最佳实践

## 4. 用户界面设计

### 4.1 设计语言
TimeStop应用采用简洁现代的设计语言，强调清晰的视觉层次和直观的用户体验。

#### 4.1.1 主题系统
- **霓光绿主题（默认）**
  - 主色：#36D1DC → #5B86E5（渐变）
  - 背景色：#F7F9FC
  - 卡片背景：#FFFFFF
  - 文本颜色：#333333（主要）/ #707070（次要）
  - 强调色：#5B86E5

- **知性紫主题**
  - 主色：#9D50BB → #6E48AA（渐变）
  - 背景色：#F8F6FC
  - 卡片背景：#FFFFFF
  - 文本颜色：#333333（主要）/ #6A6A6A（次要）
  - 强调色：#9D50BB

#### 4.1.2 组件设计
- **卡片**：圆角矩形，轻微阴影，纯白背景
- **按钮**：圆角设计，渐变背景，点击反馈动画
- **图表**：简洁现代风格，使用主题色系，动画过渡
- **列表**：卡片式设计，支持滑动操作，分组显示

### 4.2 交互设计
- 手势导航：支持滑动返回、下拉刷新
- 流畅动画：元素转场采用自然过渡动画
- 触觉反馈：关键操作提供适当触觉反馈
- 声音反馈：可选的操作音效增强交互体验

### 4.3 屏幕流程
1. **启动流程**：欢迎页 → 登录/注册 → 主界面
2. **任务创建流程**：主界面 → 任务创建 → 设置参数 → 确认创建
3. **专注流程**：任务列表 → 选择任务 → 专注计时 → 任务验证 → 完成反馈
4. **成就查看流程**：成就标签 → 成就列表 → 成就详情
5. **数据分析流程**：统计标签 → 概览页 → 详细分析 → 报告查看

## 5. 非功能需求

### 5.1 性能需求
- 应用启动时间不超过2秒
- UI响应时间不超过100ms
- 动画帧率保持在60fps
- 后台数据处理不影响前台UI流畅度

### 5.2 安全需求
- 用户数据本地加密存储
- 适当的错误处理和异常恢复
- 符合Apple隐私政策要求
- 定期数据备份和恢复机制

### 5.3 兼容性需求
- 支持iOS 16.6及以上版本
- 适配iPhone和iPad不同屏幕尺寸
- 支持深色模式和动态字体大小
- 适配所有iPhone和iPad机型

### 5.4 可访问性需求
- 支持VoiceOver屏幕阅读
- 提供足够的颜色对比度
- 支持动态字体大小调整
- 遵循iOS无障碍设计指南

## 6. 实施计划

### 6.1 开发里程碑
1. **Alpha阶段**
   - 核心功能实现：任务管理、计时器、基础数据存储
   - 基础UI框架搭建
   - 主题系统实现

2. **Beta阶段**
   - 成就系统实现
   - 数据分析功能
   - 设置系统完善
   - UI优化和动画完善

3. **Release阶段**
   - 全面测试和bug修复
   - 性能优化
   - 文档完善
   - App Store发布准备

### 6.2 优先级排序
1. **最高优先级**
   - 任务管理核心功能
   - 专注计时器
   - 数据本地存储

2. **高优先级**
   - 成就系统
   - 基础数据分析
   - 用户界面和体验

3. **中优先级**
   - 高级统计分析
   - 设置和个性化
   - 动画和视觉效果

4. **低优先级**
   - 高级主题定制
   - 导出和分享功能
   - 辅助功能优化

## 7. 评估指标

### 7.1 用户体验指标
- 应用评分目标 ≥ 4.5星
- 用户留存率 ≥ 30%（30天）
- 每日活跃用户增长率 ≥ 5%
- 用户平均使用时长 ≥ 15分钟/天

### 7.2 技术指标
- 应用崩溃率 < 0.5%
- ANR率 < 0.1%
- 平均启动时间 < 1.5秒
- 内存峰值使用 < 150MB

## 8. 附录

### 8.1 术语表
- **专注会话**：用户选择任务并进入计时器模式的时间段
- **任务验证**：确认用户真正完成任务的机制
- **成就等级**：根据累计时间划分的用户成就级别
- **时间去向**：用户时间分配的可视化分析

### 8.2 相关文档
- [成就系统设计文档](./AchievementSystem_README.md)
- [自动备份系统说明](./scripts/README.md)
- [颜色系统优化报告](./color_optimization_report.md)
- [应用优化与漏洞修复报告](./TimeStop/optimization_comprehensive.md)
- [开发者指南](./TimeStop_Developer_Guide.md)

### 8.3 修订历史
| 版本 | 日期 | 修订内容 | 修订人 |
|------|------|----------|--------|
| 1.0 | 2023-05-15 | 初始文档创建 | 产品团队 |
| 1.1 | 2023-08-20 | 添加技术架构详情 | 技术团队 |
| 1.2 | 2023-11-10 | 更新成就系统需求 | 产品团队 |
| 2.0 | 2024-05-15 | 全面整合现有文档，补充前后端架构说明 | 开发团队 | 