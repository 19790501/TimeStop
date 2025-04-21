# TimeStop 时间管理应用

TimeStop是一款专注于提高时间管理效率的iOS应用，通过专业的时间追踪、目标设定和成就系统帮助用户更好地管理和利用时间。

![TimeStop Banner](./screenshots/banner.png)

## 概述

TimeStop应用通过任务追踪、专注模式、成就系统和数据分析等功能，帮助用户了解自己的时间使用情况，提高工作效率，养成良好的时间管理习惯。应用支持多种任务类型、自定义主题、数据统计和激励机制，满足不同用户的需求。

## 安装指南

### 系统要求
- iOS 15.0或更高版本
- Xcode 14.0或更高版本
- Swift 5.0

### 安装步骤
1. 克隆仓库到本地：
```bash
git clone https://github.com/yourusername/TimeStop.git
```

2. 打开项目文件：
```bash
cd TimeStop
open TimeStop.xcodeproj
```

3. 在Xcode中构建并运行项目（⌘+R）

## 主要功能

### 1. 任务追踪
- 创建和管理各类任务(工作、会议、思考、阅读、运动、睡觉、生活、休闲)
- 设置任务时长和专注级别
- 查看任务历史记录和完成情况

### 2. 专注模式
- 设置专注计时器，避免分心
- 多种任务验证方式(绘画、朗读、唱歌)确保真正专注
- 自定义铃声提醒，包括多种系统音效选项
- 支持暂停、继续和提前结束任务

### 3. 成就系统
- 8种成就类型，对应不同的任务类别
- 6级成就解锁系统，激励长期使用
- 视觉化的成就展示和进度跟踪
- 成就解锁通知和奖励

### 4. 数据分析
- 每日、每周和每月时间使用统计
- 按任务类型和时间段的数据可视化
- 时间使用趋势分析
- 个性化建议和改进提示

### 5. 个性化设置
- 可选的应用主题(霓光绿、知性紫)
- 自定义倒计时结束铃声
- 按钮音效开关
- 用户账户管理

## 使用说明

### 开始使用
1. 首次启动时，创建用户账户或登录现有账户
2. 在主页面，点击"+"按钮创建新任务
3. 选择任务类型，设置时长，开始专注

### 查看成就
1. 点击导航栏中的"成就"标签
2. 浏览所有可获得的成就和当前进度
3. 点击单个成就查看详细信息和解锁条件

### 统计分析
1. 点击导航栏中的"统计"标签
2. 查看时间使用概览和详细分析
3. 根据提供的建议调整时间管理策略

### 个人设置
1. 点击导航栏中的"设置"标签
2. 选择应用主题和铃声偏好
3. 管理账户信息和应用权限

## 项目结构

```
TimeStop/
├── Models/              # 数据模型
│   ├── Task.swift       # 任务模型
│   ├── User.swift       # 用户模型
│   └── AchievementSystem/ # 成就系统相关模型
├── Views/               # 视图组件
│   ├── AuthView.swift   # 认证视图
│   ├── CreateTaskView.swift # 创建任务视图
│   ├── FocusTimerView.swift # 专注计时器视图
│   └── SettingsView.swift # 设置视图
├── ViewModels/          # 视图模型
│   └── AppViewModel.swift # 主应用程序视图模型
└── Utils/               # 工具类和辅助功能
    ├── ThemeManager.swift # 主题管理器
    └── Notification/     # 通知相关功能
```

## 相关文档

- [成就系统设计文档](./AchievementSystem_README.md) - 详细的成就系统实现和原理
- [脚本说明文档](./scripts/README.md) - 项目相关脚本工具的使用说明

## 最近更新

### 1.2.0 (2023-06-01)
- 添加了五种倒计时结束铃声选择功能
- 优化成就系统页面布局，添加两列式卡片视图
- 改进了设置页面的用户界面和主题一致性
- 修复了若干已知问题和性能优化

## 贡献指南

欢迎为TimeStop项目做出贡献！请遵循以下步骤：

1. Fork项目
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add some amazing feature'`
4. 推送到分支：`git push origin feature/amazing-feature`
5. 开启Pull Request

## 许可证

本项目基于MIT许可证分发 - 详见[LICENSE](./LICENSE)文件

## 联系方式

项目维护者 - 您的姓名 - your.email@example.com

项目链接: [https://github.com/yourusername/TimeStop](https://github.com/yourusername/TimeStop)
