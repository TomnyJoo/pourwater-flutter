import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pour_animation_state.dart';
import '../utils/constants.dart';

/// 多阶段倒水动画控制器
class PourAnimationController {
  final TickerProvider vsync;
  final Function(PourAnimationState) onStateChanged;
  final VoidCallback onComplete;
  final double animationSpeed;

  late AnimationController _controller;

  PourAnimationState _state = const PourAnimationState();

  // 动画阶段边界（0-1）
  final double _moveEnd = 0.25;       // 0.0 - 0.25: 移动到目标位置 (25%)
  final double _tiltEnd = 0.4;        // 0.25 - 0.4: 倾斜阶段 (15%)
  final double _pourEnd = 0.9;        // 0.4 - 0.9: 倒水阶段 (50%)
  final double _returnEnd = 1.0;      // 0.9 - 1.0: 返回阶段 (10%)

  PourAnimationController({
    required this.vsync,
    required this.onStateChanged,
    required this.onComplete,
    this.animationSpeed = 1.0,
  }) {
    _initController();
  }

  void _initController() {
    final duration = Duration(
      milliseconds: (AnimationConstants.defaultAnimationDurationMs * animationSpeed * 1.5).toInt(),
    );

    _controller = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    _controller.addListener(_onAnimationUpdate);
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void startAnimation({
    required int sourceIndex,
    required int targetIndex,
    required Offset sourcePosition,
    required Offset targetPosition,
    required double tubeWidth,
    required double tubeHeight,
  }) {
    final isTargetOnLeft = targetIndex < sourceIndex;

    // 目标试管开口位置 = 左上角（无偏移，因为目标试管未选中，不上移）
    final Offset targetOpening = Offset(
      targetPosition.dx - tubeWidth / 2,      // 左边缘 X
      targetPosition.dy - tubeHeight / 2,     // 顶部 Y
    );

    // 旋转原点：源试管的右上角（相对于源试管自身的中心点）
    final Offset rotationOrigin = Offset(tubeWidth / 2, -tubeHeight / 2);

    // 移动目标位置：使源试管的右上角与 targetOpening 重合
    final Offset sourceTargetCenter = Offset(
      targetOpening.dx - rotationOrigin.dx,
      targetOpening.dy - rotationOrigin.dy,
    );

    // 倒水接触点（固定旋转中心）
    final Offset pourContactPoint = targetOpening;

    _state = PourAnimationState(
      phase: PourAnimationPhase.movingToTarget,
      sourceTubeIndex: sourceIndex,
      targetTubeIndex: targetIndex,
      sourceOriginalPosition: sourcePosition,
      targetPosition: sourceTargetCenter,
      currentPosition: sourcePosition,
      isTargetOnLeft: isTargetOnLeft,
      rotationOrigin: rotationOrigin,
      pourStartPoint: pourContactPoint,
      pourEndPoint: pourContactPoint,
    );

    onStateChanged(_state);
    _controller.forward(from: 0);
  }

  void _onAnimationUpdate() {
    final totalProgress = _controller.value;
    PourAnimationPhase phase;
    double tiltAngle = 0;
    double pourProgress = 0;
    Offset currentPosition = _state.sourceOriginalPosition;

    if (totalProgress < _moveEnd) {
      // 移动阶段
      phase = PourAnimationPhase.movingToTarget;
      final progress = totalProgress / _moveEnd;
      final easedProgress = _easeInOutCubic(progress);
      currentPosition = Offset(
        _state.sourceOriginalPosition.dx +
            (_state.targetPosition.dx - _state.sourceOriginalPosition.dx) * easedProgress,
        _state.sourceOriginalPosition.dy +
            (_state.targetPosition.dy - _state.sourceOriginalPosition.dy) * easedProgress,
      );
    } else if (totalProgress < _tiltEnd) {
      // 倾斜阶段
      phase = PourAnimationPhase.tilting;
      currentPosition = _state.targetPosition;
      final progress = (totalProgress - _moveEnd) / (_tiltEnd - _moveEnd);
      final easedProgress = _easeInOutCubic(progress);
      tiltAngle = AnimationConstants.tiltAngle * easedProgress;
    } else if (totalProgress < _pourEnd) {
      // 倒水阶段
      phase = PourAnimationPhase.pouring;
      currentPosition = _state.targetPosition;
      tiltAngle = AnimationConstants.tiltAngle;
      final progress = (totalProgress - _tiltEnd) / (_pourEnd - _tiltEnd);
      pourProgress = progress;
    } else {
      // 返回阶段
      phase = PourAnimationPhase.returning;
      final progress = (totalProgress - _pourEnd) / (_returnEnd - _pourEnd);

      if (progress < 0.5) {
        final tiltProgress = progress / 0.5;
        tiltAngle = AnimationConstants.tiltAngle * (1 - tiltProgress);
        currentPosition = _state.targetPosition;
      } else {
        tiltAngle = 0;
        final moveProgress = (progress - 0.5) / 0.5;
        final easedProgress = _easeInOutCubic(moveProgress);
        currentPosition = Offset(
          _state.targetPosition.dx +
              (_state.sourceOriginalPosition.dx - _state.targetPosition.dx) * easedProgress,
          _state.targetPosition.dy +
              (_state.sourceOriginalPosition.dy - _state.targetPosition.dy) * easedProgress,
        );
      }
    }

    _state = _state.copyWith(
      phase: phase,
      currentPosition: currentPosition,
      tiltAngle: tiltAngle,
      pourProgress: pourProgress,
    );

    onStateChanged(_state);
  }

  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _state = const PourAnimationState();
      onComplete();
    }
  }

  void dispose() {
    _controller.removeListener(_onAnimationUpdate);
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
  }

  PourAnimationState get state => _state;
}