import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tube.dart';
import '../models/liquid.dart';
import '../models/pour_animation_state.dart';
import '../viewmodels/settings_view_model.dart';
import 'tube_widget.dart';
import '../controllers/pour_animation_controller.dart';
import 'liquid_flow_painter.dart';

/// 液体倒水动画
class FluidPourAnimation extends StatefulWidget {
  final Offset sourcePosition;
  final Offset targetPosition;
  final Color liquidColor;
  final double tubeWidth;
  final double tubeHeight;
  final Tube fromTube;
  final Tube toTube;
  final VoidCallback onComplete;
  final int pourVolume;
  final SettingsViewModel settings;
  final int sourceIndex;
  final int targetIndex;

  const FluidPourAnimation({
    super.key,
    required this.sourcePosition,
    required this.targetPosition,
    required this.liquidColor,
    required this.tubeWidth,
    required this.tubeHeight,
    required this.fromTube,
    required this.toTube,
    required this.onComplete,
    required this.pourVolume,
    required this.settings,
    required this.sourceIndex,
    required this.targetIndex,
  });

  @override
  State<FluidPourAnimation> createState() => _FluidPourAnimationState();
}

class _FluidPourAnimationState extends State<FluidPourAnimation>
    with TickerProviderStateMixin {
  late PourAnimationController _animationController;
  PourAnimationState _animState = const PourAnimationState();
  Tube? _animatedFromTube;
  Tube? _animatedToTube;

  @override
  void initState() {
    super.initState();
    
    _animationController = PourAnimationController(
      vsync: this,
      animationSpeed: widget.settings.animationSpeed,
      onStateChanged: _onAnimationStateChanged,
      onComplete: widget.onComplete,
    );

    _animatedFromTube = widget.fromTube.copy();
    _animatedToTube = widget.toTube.copy();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.startAnimation(
        sourceIndex: widget.sourceIndex,
        targetIndex: widget.targetIndex,
        sourcePosition: widget.sourcePosition,
        targetPosition: widget.targetPosition,
        tubeWidth: widget.tubeWidth,
        tubeHeight: widget.tubeHeight,
      );
    });
  }

  void _onAnimationStateChanged(PourAnimationState state) {
    if (state.phase == PourAnimationPhase.pouring) {
      _updateLiquidVolumes(state.pourProgress);
    }
    setState(() {
      _animState = state;
    });
  }

  void _updateLiquidVolumes(double progress) {
    if (_animatedFromTube == null || _animatedToTube == null) return;

    final volumeToTransfer = (widget.pourVolume * progress).round();
    final currentFromVolume = widget.fromTube.topLiquid?.volume ?? 0;
    final targetFromVolume = currentFromVolume - volumeToTransfer;

    // 更新源试管液体
    if (_animatedFromTube!.liquids.isNotEmpty) {
      if (targetFromVolume > 0) {
        _animatedFromTube!.liquids.last.volume = targetFromVolume;
      } else {
        _animatedFromTube!.liquids.removeLast();
      }
    }

    // 更新目标试管液体，确保不超过容量
    if (volumeToTransfer > 0) {
      // 计算目标试管当前总容量
      final currentTargetVolume = _animatedToTube!.liquids.fold(0, (sum, liquid) => sum + liquid.volume);
      // 计算可添加的最大容量
      final maxAddable = _animatedToTube!.capacity - currentTargetVolume;
      final actualTransfer = volumeToTransfer > maxAddable ? maxAddable : volumeToTransfer;
      
      if (actualTransfer > 0) {
        if (_animatedToTube!.liquids.isNotEmpty &&
            _animatedToTube!.liquids.last.color == widget.liquidColor) {
          _animatedToTube!.liquids.last.volume += actualTransfer;
        } else {
          _animatedToTube!.liquids.add(Liquid(
            color: widget.liquidColor,
            volume: actualTransfer,
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: widget.sourcePosition.dx - widget.tubeWidth / 2,
          top: widget.sourcePosition.dy,
          child: _buildSourceTube(),
        ),
        Positioned(
          left: widget.targetPosition.dx - widget.tubeWidth / 2,
          top: widget.targetPosition.dy,
          child: _buildTargetTube(),
        ),
        if (_animState.phase == PourAnimationPhase.pouring)
          _buildLiquidFlow(),
      ],
    );
  }

  Widget _buildTargetTube() {
    return TubeWidget(
      width: widget.tubeWidth,
      height: widget.tubeHeight,
      tube: _animatedToTube ?? widget.toTube,
      isSelected: false,
      isColorBlindMode: widget.settings.colorBlindMode,
      onTap: () {},
    );
  }

  Widget _buildSourceTube() {
    final position = _animState.currentPosition;
    final tiltAngle = _animState.tiltAngle;
    final rotationOrigin = _animState.rotationOrigin;

    // 使用动画位置，如果没有则使用原始位置
    final effectivePosition = position == Offset.zero
        ? widget.sourcePosition
        : position;

    final offset = Offset(
      effectivePosition.dx - widget.sourcePosition.dx,
      effectivePosition.dy - widget.sourcePosition.dy,
    );

    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: tiltAngle * pi / 180,
        origin: rotationOrigin,
        child: TubeWidget(
          width: widget.tubeWidth,
          height: widget.tubeHeight,
          tube: _animatedFromTube ?? widget.fromTube,
          isSelected: false,
          isColorBlindMode: widget.settings.colorBlindMode,
          onTap: () {},
        ),
      ),
    );
  }

  Widget _buildLiquidFlow() {
    final sourcePoint = _animState.pourStartPoint;
    final targetPoint = _animState.pourEndPoint;

    double actualSourceX = sourcePoint.dx;
    double actualSourceY = sourcePoint.dy;
    
    if (_animState.tiltAngle != 0) {
      final angleRad = _animState.tiltAngle * pi / 180;
      if (_animState.isTargetOnLeft) {
        actualSourceY = sourcePoint.dy + widget.tubeWidth * sin(angleRad).abs();
      } else {
        actualSourceY = sourcePoint.dy + widget.tubeWidth * sin(angleRad).abs();
      }
    }

    final paintSize = Size(
      (targetPoint.dx - actualSourceX).abs() + widget.tubeWidth * 2,
      (targetPoint.dy - actualSourceY).abs() + widget.tubeWidth * 2,
    );

    return Positioned(
      left: min(actualSourceX, targetPoint.dx) - widget.tubeWidth,
      top: min(actualSourceY, targetPoint.dy) - widget.tubeWidth,
      child: CustomPaint(
        size: paintSize.isEmpty ? const Size(100, 100) : paintSize,
        painter: LiquidFlowPainter(
          liquidColor: widget.liquidColor,
          sourcePoint: Offset(actualSourceX - min(actualSourceX, targetPoint.dx) + widget.tubeWidth, actualSourceY - min(actualSourceY, targetPoint.dy) + widget.tubeWidth),
          targetPoint: Offset(targetPoint.dx - min(actualSourceX, targetPoint.dx) + widget.tubeWidth, targetPoint.dy - min(actualSourceY, targetPoint.dy) + widget.tubeWidth),
          progress: _animState.pourProgress,
          tubeWidth: widget.tubeWidth,
        ),
      ),
    );
  }
}
