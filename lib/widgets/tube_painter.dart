import 'dart:math';
import 'package:flutter/material.dart';
import '../models/liquid.dart';
import '../models/tube.dart';

/// 绘制试管组件
class TubePainter extends CustomPainter {
  final Tube tube;
  final double waveHeight = 0.3;
  final double waveFrequency = 0.2;
  final bool isColorBlindMode;

  TubePainter({required this.tube, required this.isColorBlindMode});

  @override
  void paint(Canvas canvas, Size size) {
    final widthRatio = size.width / 64;
    final heightRatio = size.height / 128;

    _drawTube(canvas, size, widthRatio, heightRatio);
    if (tube.liquids.isNotEmpty) {
      _drawLiquids(canvas, size, widthRatio, heightRatio);
    }
  }

  /// 绘制试管边框 - 优化圆角连接
  void _drawTube(Canvas canvas, Size size, double widthRatio, double heightRatio) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final tubePath = Path();

    // 定义尺寸常量
    const double leftX = 8;
    const double rightX = 56;
    const double bottomY = 118;
    const double topInnerY = 5;
    const double topOuterY = 5;
    
    // 圆角半径 - 调整为与线条平滑连接
    final double topRadiusX = 12 * widthRatio;
    final double topRadiusY = 8 * heightRatio;
    final double bottomRadiusX = 24 * widthRatio;
    final double bottomRadiusY = 10 * heightRatio;

    // 从左侧底部开始
    tubePath.moveTo(leftX * widthRatio, bottomY * heightRatio);
    
    // 左侧垂直线 - 到顶部内边缘
    tubePath.lineTo(leftX * widthRatio, topInnerY * heightRatio);
    
    // 左上翻边圆弧 - 使用 moveTo 确保起点正确连接
    tubePath.moveTo(leftX * widthRatio, topInnerY * heightRatio);
    tubePath.arcToPoint(
      Offset(topOuterY, topOuterY),
      radius: Radius.elliptical(topRadiusX, topRadiusY),
      clockwise: false,
    );
    
    // 顶部水平线
    tubePath.lineTo(64 * widthRatio, topOuterY);
    
    // 右上翻边圆弧
    tubePath.arcToPoint(
      Offset(rightX * widthRatio, topInnerY * heightRatio),
      radius: Radius.elliptical(topRadiusX, topRadiusY),
      clockwise: true,
    );
    
    // 右侧垂直线
    tubePath.lineTo(rightX * widthRatio, bottomY * heightRatio);
    
    // 底部圆弧
    tubePath.arcToPoint(
      Offset(leftX * widthRatio, bottomY * heightRatio),
      radius: Radius.elliptical(bottomRadiusX, bottomRadiusY),
      clockwise: true,
    );

    canvas.drawPath(tubePath, paint);
  }

  /// 绘制液体
  void _drawLiquids(Canvas canvas, Size size, double widthRatio, double heightRatio) {
    final bottomMargin = 10 * heightRatio;
    final topMargin = 5 * heightRatio;
    double currentHeight = size.height - bottomMargin;

    final liquidWidth = 48 * widthRatio;
    final liquidLeft = 8 * widthRatio;

    for (var i = 0; i < tube.liquids.length; i++) {
      final liquid = tube.liquids[i];
      final availableHeight = size.height - bottomMargin - topMargin;
      final liquidHeight = (liquid.volume / tube.capacity) * availableHeight;
      currentHeight -= liquidHeight;

      final paint = Paint()
        ..color = liquid.color
        ..style = PaintingStyle.fill;
      final path = Path();

      path.moveTo(liquidLeft, currentHeight);
      if (liquid == tube.topLiquid) {
        for (double x = 0; x <= liquidWidth; x += 1) {
          final y = currentHeight +
              sin(x * waveFrequency * widthRatio) * waveHeight * heightRatio;
          path.lineTo(liquidLeft + x, y);
        }
      } else {
        path.lineTo(liquidLeft + liquidWidth, currentHeight);
      }

      path.lineTo(liquidLeft + liquidWidth, currentHeight + liquidHeight);
      if (i == 0) {
        path.arcToPoint(
          Offset(liquidLeft, currentHeight + liquidHeight),
          radius: Radius.elliptical(24 * widthRatio, 10 * heightRatio),
          clockwise: true,
        );
      } else {
        path.lineTo(liquidLeft, currentHeight + liquidHeight);
      }

      path.close();
      canvas.drawPath(path, paint);
      
      if (isColorBlindMode) {
        _drawPattern(canvas, liquid,
            liquidLeft, currentHeight, liquidWidth, liquidHeight);
      }
    }
  }

  void _drawPattern(Canvas canvas, Liquid liquid,
      double left, double top, double width, double height) {
    final hash = liquid.color.hashCode;
    final patternType = hash % 4;
    
    final patternPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    switch (patternType) {
      case 0:
        for (double y = top; y < top + height; y += 4) {
          canvas.drawLine(
            Offset(left, y),
            Offset(left + width, y),
            patternPaint,
          );
        }
        break;
      case 1:
        for (double x = left; x < left + width; x += 4) {
          canvas.drawLine(
            Offset(x, top),
            Offset(x, top + height),
            patternPaint,
          );
        }
        break;
      case 2:
        for (double y = top; y < top + height; y += 6) {
          canvas.drawLine(
            Offset(left, y),
            Offset(left + width, y),
            patternPaint,
          );
        }
        for (double x = left; x < left + width; x += 6) {
          canvas.drawLine(
            Offset(x, top),
            Offset(x, top + height),
            patternPaint,
          );
        }
        break;
      case 3:
        for (double y = top; y < top + height; y += 5) {
          for (double x = left; x < left + width; x += 5) {
            if ((x + y).toInt() % 10 < 5) {
              canvas.drawCircle(Offset(x, y), 1.2, patternPaint);
            }
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) {
    if (isColorBlindMode != oldDelegate.isColorBlindMode) return true;
    if (tube.liquids.length != oldDelegate.tube.liquids.length) return true;
    
    for (int i = 0; i < tube.liquids.length; i++) {
      final currentLiquid = tube.liquids[i];
      final oldLiquid = oldDelegate.tube.liquids[i];
      if (currentLiquid.color != oldLiquid.color ||
          currentLiquid.volume != oldLiquid.volume) {
        return true;
      }
    }
    
    return false;
  }
}