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
        _buildTargetTube(),
        _buildSourceTube(),
        if (_animState.phase == PourAnimationPhase.pouring)
          _buildLiquidFlow(),
      ],
    );
  }

  Widget _buildTargetTube() {
    return Positioned(
      left: widget.targetPosition.dx - widget.tubeWidth / 2,
      top: widget.targetPosition.dy,
      child: TubeWidget(
        width: widget.tubeWidth,
        height: widget.tubeHeight,
        tube: _animatedToTube ?? widget.toTube,
        isSelected: false,
        isColorBlindMode: widget.settings.colorBlindMode,
        onTap: () {},
      ),
    );
  }

  Widget _buildSourceTube() {
    final position = _animState.currentPosition;
    final tiltAngle = _animState.tiltAngle;
    final rotationOrigin = _animState.rotationOrigin;

    return Positioned(
      left: position.dx - widget.tubeWidth / 2,
      top: position.dy,
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
    // 使用状态中预计算的倒水点
    final sourcePoint = _animState.pourStartPoint;
    final targetPoint = _animState.pourEndPoint;

    // 计算倾斜后的实际倒水起点
    double actualSourceX = sourcePoint.dx;
    double actualSourceY = sourcePoint.dy;
    
    if (_animState.tiltAngle != 0) {
      final angleRad = _animState.tiltAngle * pi / 180;
      // 倾斜时，以接触点为轴心旋转，计算实际倒水点位置
      if (_animState.isTargetOnLeft) {
        // 向左倾斜：左上角向下移动
        actualSourceY = sourcePoint.dy + widget.tubeWidth * sin(angleRad).abs();
      } else {
        // 向右倾斜：右上角向下移动
        actualSourceY = sourcePoint.dy + widget.tubeWidth * sin(angleRad).abs();
      }
    }

    return Positioned(
      left: 0,
      top: 0,
      child: CustomPaint(
        size: Size.infinite,
        painter: LiquidFlowPainter(
          liquidColor: widget.liquidColor,
          sourcePoint: Offset(actualSourceX, actualSourceY),
          targetPoint: targetPoint,
          progress: _animState.pourProgress,
          tubeWidth: widget.tubeWidth,
        ),
      ),
    );
  }
}
