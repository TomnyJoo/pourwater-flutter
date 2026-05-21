import 'package:flutter/material.dart';
import '../models/tube.dart';
import 'tube_painter.dart';

/// 试管组件
class TubeWidget extends StatelessWidget {
  final Tube tube;
  final bool isSelected;
  final double width;
  final double height;
  final bool isColorBlindMode;
  final VoidCallback onTap;

  const TubeWidget({
    super.key,
    required this.tube,
    required this.isSelected,
    required this.width,
    required this.height,
    required this.isColorBlindMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // 添加动画效果
        transform: Matrix4.translationValues(0, isSelected ? -height * 0.1 : 0, 0),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        margin: const EdgeInsets.all(4.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            margin: const EdgeInsets.only(bottom: 2), // 底部留白
            child: CustomPaint(
              size: Size(width, height),
              painter: TubePainter(tube: tube, isColorBlindMode:isColorBlindMode),
            ),
          ),
        ),
      ),
    );
  }
}

