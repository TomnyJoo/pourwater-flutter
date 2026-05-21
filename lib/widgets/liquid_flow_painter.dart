import 'dart:math';
import 'package:flutter/material.dart';

/// 液体流动效果绘制器
class LiquidFlowPainter extends CustomPainter {
  final Color liquidColor;
  final Offset sourcePoint;
  final Offset targetPoint;
  final double progress;
  final double tubeWidth;

  LiquidFlowPainter({
    required this.liquidColor,
    required this.sourcePoint,
    required this.targetPoint,
    required this.progress,
    required this.tubeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final streamWidth = tubeWidth * 0.3;
    final controlPoint = Offset(
      (sourcePoint.dx + targetPoint.dx) / 2,
      sourcePoint.dy + (targetPoint.dy - sourcePoint.dy) * 0.3,
    );

    path.moveTo(sourcePoint.dx - streamWidth / 2, sourcePoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx - streamWidth / 2,
      controlPoint.dy,
      targetPoint.dx - streamWidth / 2,
      targetPoint.dy,
    );
    path.lineTo(targetPoint.dx + streamWidth / 2, targetPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx + streamWidth / 2,
      controlPoint.dy,
      sourcePoint.dx + streamWidth / 2,
      sourcePoint.dy,
    );
    path.close();

    canvas.drawPath(path, paint);

    _drawDroplets(canvas, paint);
  }

  void _drawDroplets(Canvas canvas, Paint paint) {
    final random = Random(42);
    final dropletCount = (progress * 5).floor();

    for (int i = 0; i < dropletCount; i++) {
      final t = (i / dropletCount + progress * 0.5) % 1.0;
      final x = sourcePoint.dx + (targetPoint.dx - sourcePoint.dx) * t;
      final y = sourcePoint.dy + (targetPoint.dy - sourcePoint.dy) * t;
      final radius = 2.0 + random.nextDouble() * 2.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidFlowPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        sourcePoint != oldDelegate.sourcePoint ||
        targetPoint != oldDelegate.targetPoint;
  }
}
