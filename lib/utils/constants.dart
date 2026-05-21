import 'dart:math';
import 'dart:ui';

/// 游戏颜色常量
class GameColors {
  /// 基础颜色池，如要降低饱和度，前面增加透明度88（半透明）
  static final baseColors = [
    const Color(0xFFB71C1C),     // 深酒红
    const Color(0xFFFF6D00),     // 鲜艳橙
    const Color(0xFFFFD600),     // 亮金色
    const Color(0xFF76FF03),     // 荧光绿 (新增)
    const Color(0xFF1B5E20),     // 森林绿
    const Color(0xFF0D47A1),     // 海军蓝
    const Color(0xFF00B0FF),     // 电光蓝
    const Color(0xFF6200EA),     // 深紫蓝 (新增)
    const Color(0xFF4A148C),     // 皇家紫
    const Color(0xFFD500F9),     // 霓虹粉
    const Color(0xFF00BFA5),     // 孔雀绿
    const Color(0xFF37474F),     // 炭灰色 (新增)
  ];

  /// 主题颜色 - 使用语义化命名
  static const primaryColor = Color(0xFF6200EE);
  static const primaryDarkColor = Color(0xFF3700B3);
  static const secondaryColor = Color(0xFF03DAC6);
  static const accentColor = Color(0xFF018786);

  /// 获取颜色组合
  static List<Color> getColorsByDifficulty(int numberOfColors) {
    final shuffled = List.of(baseColors)..shuffle();
    return shuffled.sublist(0, numberOfColors);
  }

  /// 动态颜色生成方法
  static Color generateRandomColor() {
    return baseColors[Random().nextInt(baseColors.length)];
  }
}

/// 动画常量
class AnimationConstants {
  AnimationConstants._();

  static const double tiltAngle = 45.0;
  static const int defaultAnimationDurationMs = 1200;
  
  static const int movePhaseDurationMs = 300;
  static const int tiltPhaseDurationMs = 200;
  static const int pourPhaseDurationMs = 500;
  static const int returnPhaseDurationMs = 300;

  static const double tubeSpacing = 4.0;
  static const double horizontalMargin = 8.0;
  static const double verticalMargin = 8.0;

  static const double waveHeight = 2.0;
  static const double waveFrequency = 0.1;
}