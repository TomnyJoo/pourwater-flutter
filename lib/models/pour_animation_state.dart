import 'dart:ui';

/// 倒水动画阶段
enum PourAnimationPhase {
  idle,
  movingToTarget,
  tilting,
  pouring,
  returning,
}

/// 倒水动画状态
class PourAnimationState {
  final PourAnimationPhase phase;
  final int sourceTubeIndex;
  final int targetTubeIndex;
  final Offset sourceOriginalPosition;
  final Offset targetPosition;
  final Offset currentPosition;
  final double tiltAngle;
  final double pourProgress;
  final bool isTargetOnLeft;
  final Offset rotationOrigin;
  final Offset pourStartPoint;
  final Offset pourEndPoint;

  const PourAnimationState({
    this.phase = PourAnimationPhase.idle,
    this.sourceTubeIndex = -1,
    this.targetTubeIndex = -1,
    this.sourceOriginalPosition = Offset.zero,
    this.targetPosition = Offset.zero,
    this.currentPosition = Offset.zero,
    this.tiltAngle = 0.0,
    this.pourProgress = 0.0,
    this.isTargetOnLeft = false,
    this.rotationOrigin = Offset.zero,
    this.pourStartPoint = Offset.zero,
    this.pourEndPoint = Offset.zero,
  });

  PourAnimationState copyWith({
    PourAnimationPhase? phase,
    int? sourceTubeIndex,
    int? targetTubeIndex,
    Offset? sourceOriginalPosition,
    Offset? targetPosition,
    Offset? currentPosition,
    double? tiltAngle,
    double? pourProgress,
    bool? isTargetOnLeft,
    Offset? rotationOrigin,
    Offset? pourStartPoint,
    Offset? pourEndPoint,
  }) {
    return PourAnimationState(
      phase: phase ?? this.phase,
      sourceTubeIndex: sourceTubeIndex ?? this.sourceTubeIndex,
      targetTubeIndex: targetTubeIndex ?? this.targetTubeIndex,
      sourceOriginalPosition: sourceOriginalPosition ?? this.sourceOriginalPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      tiltAngle: tiltAngle ?? this.tiltAngle,
      pourProgress: pourProgress ?? this.pourProgress,
      isTargetOnLeft: isTargetOnLeft ?? this.isTargetOnLeft,
      rotationOrigin: rotationOrigin ?? this.rotationOrigin,
      pourStartPoint: pourStartPoint ?? this.pourStartPoint,
      pourEndPoint: pourEndPoint ?? this.pourEndPoint,
    );
  }

  bool get isActive => phase != PourAnimationPhase.idle;
  bool get isAnimating => phase != PourAnimationPhase.idle;
}