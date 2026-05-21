# pour water

彩色倒水游戏Flutter项目.

## 入门指南

本项目是Flutter应用程序的起点。

如果您是第一次创建Flutter项目，以下资源可以帮助您入门：

- [实验教程：编写第一个Flutter应用](https://docs.flutter.dev/get-started/codelab)
- [实用手册：Flutter示例代码集](https://docs.flutter.dev/cookbook)

要获取Flutter开发帮助，请查阅：
[在线文档](https://docs.flutter.dev/)，其中包含教程、示例代码、移动开发指南以及完整的API参考。

### 项目结构
lib/
├── main.dart
├── models/
│   ├── game_colors.dart
│   ├── game_difficulty.dart
│   ├── game_state.dart
│   ├── liquid.dart
│   └── tube.dart
├── repositories/
│   └── game_repository.dart
├── viewmodels/
│   └── game_view_model.dart
├── views/
│   ├── completion_screen.dart
│   ├── game_screen.dart
│   ├── home_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── difficulty_button.dart
    ├── liquid_painter.dart
    ├── tube_widget.dart
    └── wave_animation.dart
