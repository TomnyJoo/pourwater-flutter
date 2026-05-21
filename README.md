# Pour Water Game

一个基于 Flutter 开发的彩色倒水益智游戏。

## 🎮 游戏简介

Pour Water 是一款经典的益智游戏，玩家需要通过将不同颜色的液体倒入试管中，将相同颜色的液体分类整理到同一个试管里。

## ✨ 功能特点

- 🎨 **多种难度级别**：简单、中等、困难、专家四种难度
- 🎯 **智能提示系统**：帮助玩家解决难题
- 📊 **游戏记录**：记录最佳成绩
- 🔊 **音效支持**：沉浸式游戏体验
- 🌙 **深色模式**：支持明暗主题切换
- 💾 **自动保存**：随时保存游戏进度

## 🛠️ 技术栈

- **框架**: Flutter 3.0+
- **语言**: Dart 3.0+
- **状态管理**: Provider
- **数据库**: Hive (本地存储)

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app_theme.dart            # 主题配置
├── controllers/              # 控制器层
│   └── pour_animation_controller.dart
├── exceptions/               # 异常处理
│   └── game_exception.dart
├── models/                   # 数据模型
│   ├── game_difficulty.dart  # 难度配置
│   ├── game_record.dart      # 游戏记录
│   ├── game_state.dart       # 游戏状态
│   ├── liquid.dart           # 液体模型
│   ├── pour_animation_state.dart
│   └── tube.dart             # 试管模型
├── services/                 # 服务层
│   └── repository.dart       # 数据仓库
├── utils/                    # 工具类
│   ├── constants.dart        # 常量定义
│   └── saved_game.dart       # 存档管理
├── viewmodels/               # 视图模型
│   ├── audio_viewmodel.dart  # 音频控制
│   ├── game_view_model.dart  # 游戏逻辑
│   ├── record_view_model.dart # 记录管理
│   └── settings_view_model.dart # 设置管理
├── views/                    # 页面视图
│   ├── completion_screen.dart # 完成页面
│   ├── game_screen.dart      # 游戏页面
│   ├── home_screen.dart      # 首页
│   ├── record_screen.dart    # 记录页面
│   └── settings_screen.dart  # 设置页面
└── widgets/                  # 自定义组件
    ├── difficulty_button.dart # 难度选择按钮
    ├── fluid_pour_animation.dart # 倒水动画
    ├── liquid_flow_painter.dart # 液体绘制
    ├── tube_painter.dart     # 试管绘制
    └── tube_widget.dart      # 试管组件
```

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode (根据目标平台)

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/TomnyJoo/pourwater-flutter.git
cd pourwater-flutter
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行项目**
```bash
flutter run
```

### 构建发布版本

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## 🎯 游戏玩法

1. 点击选择一个试管，选中的试管会高亮显示
2. 点击另一个试管将液体倒入（目标试管必须有足够空间）
3. 只能将相同颜色的液体倒入同一试管
4. 将所有颜色分类完成即可获胜
5. 尝试用最少的步骤完成挑战！

## 📱 截图展示

| 首页 | 游戏页面 | 完成页面 |
|------|----------|----------|
| ![首页](docs/screenshots/home.png) | ![游戏页面](docs/screenshots/game.png) | ![完成页面](docs/screenshots/completion.png) |

## 📝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发规范

- 使用 `dart format` 格式化代码
- 遵循 Flutter 官方编码规范
- 提交信息使用中文描述

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 📧 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues: [提交问题](https://github.com/TomnyJoo/pourwater-flutter/issues)

---

🎮 享受游戏！
