import 'package:flutter/material.dart';
import '../models/game_difficulty.dart';

/// 难度选择组件
class DifficultyButton extends StatelessWidget {
  final GameDifficulty difficulty;
  final VoidCallback onPressed;

  static const Map<GameDifficulty, Color> _difficultyColors = {
    GameDifficulty.easy: Color(0xFF66BB6A),      // green[400]
    GameDifficulty.medium: Color(0xFF42A5F5),    // blue[400]
    GameDifficulty.hard: Color(0xFFFFA726),      // orange[400]
    GameDifficulty.expert: Color(0xFFEF5350),    // red[400]
  };

  const DifficultyButton({
    super.key,
    required this.difficulty,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50),
          backgroundColor: _getButtonColor(difficulty),
        ),
        child: Text(
          difficulty.displayName,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  /// 根据难度获取按钮颜色
  Color _getButtonColor(GameDifficulty difficulty) {
    return _difficultyColors[difficulty] ?? const Color(0xFFBDBDBD);
  }
}