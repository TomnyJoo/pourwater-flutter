import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../viewmodels/audio_viewmodel.dart';
import '../viewmodels/game_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/fluid_pour_animation.dart';
import '../widgets/tube_widget.dart';
import 'completion_screen.dart';
import 'settings_screen.dart';

/// 游戏界面
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // region 【私有属性】
  /// 游戏区布局参数
  final GlobalKey _gameAreaKey = GlobalKey(); /// 游戏区域全局键
  Size gameAreaSize = Size.zero;
  late double tubeWidth;
  late double tubeHeight;
  late double horizontalMargin;
  late double horizontalSpacing;
  late double verticalMargin;
  /// 存储试管位置信息的全局键
  final Map<int, GlobalKey> _tubeKeys = {};
  /// 视图模型
  late GameViewModel _viewModel;
  late SettingsViewModel _settings;
  String _previousMessage = ''; /// 上一次提示信息
  // endregion

  // region 【状态监听管理】
  void _onStateChanged() {
    if (mounted) {
      final currentMessage = _viewModel.message;
      if (currentMessage != '' && currentMessage != _previousMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(currentMessage),
                duration: const Duration(seconds: 2),
              )
          );
        });
        _previousMessage = currentMessage;
      }

      final state = _viewModel.currentState;
      if (state != null) {
        for (int i = 0; i < state.tubes.length; i++) {
          _tubeKeys.putIfAbsent(i, () => GlobalKey());
        }
        _tubeKeys.removeWhere((key, _) => key >= state.tubes.length);
      }

      setState(() {});
      _checkGameCompletion();
    }
  }

  void _checkGameCompletion() {
    if (_viewModel.currentState?.isCompleted == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CompletionScreen(
            timeElapsed: _viewModel.currentState!.timeElapsed,
            moves: _viewModel.currentState!.moves,
          ),
        ),
      );
    }
  }
  // endregion

  // region 【生命周期管理】
  /// 初始化状态
  @override
  void initState() {
    super.initState();
    _settings = Provider.of<SettingsViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<GameViewModel>(context, listen: false);
      _viewModel.addListener(_onStateChanged);
      _checkGameCompletion();

      // 进入游戏页面时恢复音乐
      final audioViewModel = context.read<AudioViewModel>();
      if (audioViewModel.settings.musicEnabled && !audioViewModel.isMusicPlaying) {
        audioViewModel.resumeMusic();
      }
    });
  }

  /// 销毁状态
  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  /// 构建视图
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context, listen: true);
    final state = viewModel.currentState;

    if (state == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('游戏未开始')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (!didPop) {
          await viewModel.saveCurrentGame();
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(viewModel),
        body: Stack(
          children: [
            Column(
              children: [
                _buildStatusBar(state), // 状态栏
                _buildGameArea(viewModel), // 游戏区
                _buildControlBar(viewModel), // 控制栏
              ],
            ),
          ],
        ),
      ),
    );
  }
  // endregion

  // region 【应用栏和状态栏视图构建】
  /// 构建应用栏
  AppBar _buildAppBar(GameViewModel viewModel) {
    return AppBar(
      title: Text('${viewModel.currentState?.difficulty.displayName}难度'),
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      actions: _buildAppBarActions(viewModel),
    );
  }

  /// 构建应用栏按钮
  List<Widget> _buildAppBarActions(GameViewModel viewModel) {
    return [
      IconButton(
        icon: const Icon(Icons.save),
        onPressed: () async {
          final currentContext = context;
          await viewModel.saveCurrentGame();
          if (context.mounted) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(content: Text('游戏已保存')),
            );
          }
        },
        tooltip: '保存',
      ),
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.white),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen())
        ),
        tooltip: '设置',
      ),
    ];
  }

  /// 构建状态栏
  Widget _buildStatusBar(GameState state) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.blueGrey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('难度: ${state.difficulty.displayName}'),
          Text('用时: ${_formatTime(state.timeElapsed)}'),
          Text('步数: ${state.moves}'),
        ],
      ),
    );
  }

  /// 构建控制栏
  Widget _buildControlBar(GameViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      color: Colors.blueGrey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: 48,
            height: 40,
            child: IconButton(
              tooltip: '撤销',
              onPressed: viewModel.hasHistory ? viewModel.undo : null,
              icon: const Icon(Icons.undo),
            ),
          ),
          SizedBox(
            width: 48,
            height: 40,
            child: IconButton(
              tooltip: '重做',
              onPressed: viewModel.canRedo ? viewModel.redo : null,
              icon: const Icon(Icons.redo),
            ),
          ),
          SizedBox(
            width: 48,
            height: 40,
            child: IconButton(
              tooltip: '重置',
              onPressed: viewModel.reset,
              icon: const Icon(Icons.refresh),
            ),
          ),
          SizedBox(
            width: 48,
            height: 40,
            child: IconButton(
              tooltip: '新游戏',
              onPressed: () => _confirmNewGame(context, viewModel),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ),
        ],
      ),
    );
  }

  /// 确认新游戏对话框
  void _confirmNewGame(BuildContext context, GameViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始新游戏'),
        content: const Text('确定要放弃当前游戏并开始新游戏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.newGame();
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  // endregion

  // region 【游戏区域视图构建】
  /// 构建游戏区 - 响应式布局
  Widget _buildGameArea(GameViewModel viewModel) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 获取可用空间
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          
          gameAreaSize = Size(availableWidth, availableHeight);
          
          // 动态计算最佳列数（同时考虑宽度和高度）
          final totalTubes = viewModel.currentState!.tubes.length;
          final bestColumns = _calculateBestColumns(totalTubes, availableWidth, availableHeight);
          final rowCount = (totalTubes / bestColumns).ceil();
          
          // 计算试管大小
          _calculateTubeSize(gameAreaSize, bestColumns, rowCount);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              key: _gameAreaKey,
              padding: EdgeInsets.all(horizontalMargin),
              width: availableWidth,
              constraints: BoxConstraints(
                minHeight: availableHeight,
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (int row = 0; row < rowCount; row++)
                        _buildTubeWidget(row, bestColumns, viewModel),
                    ],
                  ),
                  // 倒水动画层
                  if (viewModel.pourAnimationState.isActive)
                    _buildPourAnimationLayer(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 动态计算最佳列数（考虑宽度和高度约束）
  int _calculateBestColumns(int totalTubes, double availableWidth, double availableHeight) {
    // 目标：优先保证行数在 2-3 行范围内（当可能时），列数在 2-6 列之间
    const int minColumns = 2;
    const int maxColumns = 6;
    const int minRowsPreferred = 2;
    const int maxRowsPreferred = 3;

    const double horizontalSpacing = 8.0;
    const double horizontalPadding = 8.0; // 减小左右留白以最大化空间
    const double verticalPadding = 12.0;

    final effectiveWidth = (availableWidth - 2 * horizontalPadding).clamp(0.0, double.infinity);
    final effectiveHeight = (availableHeight - 2 * verticalPadding).clamp(0.0, double.infinity);

    int bestColumns = minColumns;
    double bestScore = -double.infinity;

    final maxColsToTry = min(maxColumns, totalTubes);
    for (int cols = minColumns; cols <= maxColsToTry; cols++) {
      final rows = (totalTubes / cols).ceil();

      // 计算基于宽度的可用单管宽
      final widthForEach = (effectiveWidth - (cols - 1) * horizontalSpacing) / cols;
      final tubeWidthByWidth = widthForEach.clamp(0.0, double.infinity) - 8.0; // 预留内部 margin

      // 计算基于高度的可用单管高度
      final heightForEach = (effectiveHeight - (rows - 1) * verticalPadding) / rows;
      final tubeHeightByHeight = heightForEach.clamp(0.0, double.infinity);

      // 将宽度换算为高度（tubeHeight = tubeWidth * 2）以对比
      final tubeHeightFromWidth = tubeWidthByWidth * 2.0;

      // 实际可用管高受限于两者
      final feasibleTubeHeight = min(tubeHeightByHeight, tubeHeightFromWidth);
      final feasibleTubeWidth = (feasibleTubeHeight / 2.0).clamp(0.0, double.infinity);

      // 评分：优先满足首选行数（2-3），并偏好更大的管宽
      double score = feasibleTubeWidth;
      if (rows >= minRowsPreferred && rows <= maxRowsPreferred) score += 1000.0; // 强烈偏好 2-3 行
      // 惩罚过多行或过少行
      if (rows < minRowsPreferred) score -= 200.0 * (minRowsPreferred - rows);
      if (rows > maxRowsPreferred) score -= 50.0 * (rows - maxRowsPreferred);

      if (score > bestScore) {
        bestScore = score;
        bestColumns = cols;
      }
    }

    // 边界检查，确保至少 1 列且不超过总数
    bestColumns = bestColumns.clamp(1, totalTubes);
    return bestColumns;
  }

  /// 构建试管组件
  Widget _buildTubeWidget(int row, int columns, GameViewModel viewModel) {
    return Container(
      margin: EdgeInsets.only(bottom: verticalMargin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int col = 0; col < columns; col++)
            if (row * columns + col < viewModel.currentState!.tubes.length)
              Container(
                margin: EdgeInsets.only(
                  right: col < columns - 1 ? horizontalSpacing : 0,
                ),
                // === 优化隐藏逻辑 ===
                child: Builder(
                  builder: (context) {
                    final index = row * columns + col;

                    final isAnimatingTube = viewModel.pourAnimationState.isActive &&
                          (viewModel.pourAnimationState.sourceTubeIndex == index ||
                           viewModel.pourAnimationState.targetTubeIndex == index);

                    return AnimatedOpacity(
                      opacity: isAnimatingTube ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: TubeWidget(
                        key: _tubeKeys[index],
                        width: tubeWidth,
                        height: tubeHeight,
                        isSelected: viewModel.selectedTubeIndex == index,
                        isColorBlindMode: _settings.colorBlindMode,
                        onTap: () => _handleTubeTap(index, viewModel),
                        tube: viewModel.currentState!.tubes[index],
                      ),
                    );
                  },
                ),
              )
        ],
      ),
    );
  }

  /// 构建倒水动画层(新方法)
  Widget _buildPourAnimationLayer(GameViewModel viewModel) {
    final state = viewModel.currentState!;
    final animState = viewModel.pourAnimationState;
    
    if (!animState.isActive) return const SizedBox();

    final effectiveTubeWidth = tubeWidth > 0 ? tubeWidth : 60.0;
    final effectiveTubeHeight = tubeHeight > 0 ? tubeHeight : 120.0;

    final sourceIndex = animState.sourceTubeIndex;
    final targetIndex = animState.targetTubeIndex;
    
    if (sourceIndex < 0 || targetIndex < 0) return const SizedBox();

    final fromTube = state.tubes[sourceIndex];
    final toTube = state.tubes[targetIndex];
    final pourVolume = fromTube.topLiquid?.volume ?? 0;
    final liquidColor = fromTube.topLiquid?.color ?? Colors.transparent;

    Offset sourceTopCenter;
    Offset targetTopCenter;

    final sourceKey = _tubeKeys[sourceIndex];
    final targetKey = _tubeKeys[targetIndex];

    if (sourceKey?.currentContext != null &&
        targetKey?.currentContext != null &&
        _gameAreaKey.currentContext != null) {
      final gameAreaRenderBox = _gameAreaKey.currentContext!
          .findRenderObject() as RenderBox;
      final sourceRenderBox = sourceKey!.currentContext!
          .findRenderObject() as RenderBox;
      final targetRenderBox = targetKey!.currentContext!
          .findRenderObject() as RenderBox;

      final sourcePosition = gameAreaRenderBox.globalToLocal(
          sourceRenderBox.localToGlobal(Offset.zero)
      );
      final targetPosition = gameAreaRenderBox.globalToLocal(
          targetRenderBox.localToGlobal(Offset.zero)
      );

      sourceTopCenter = Offset(
          sourcePosition.dx + sourceRenderBox.size.width / 2,
          sourcePosition.dy
      );
      targetTopCenter = Offset(
          targetPosition.dx + targetRenderBox.size.width / 2,
          targetPosition.dy
      );
    } else {
      final gameAreaWidth = MediaQuery.of(context).size.width;
      final columns = (state.tubes.length / 4).ceil();
      final spacing = (gameAreaWidth - effectiveTubeWidth * columns) / (columns + 1);

      final sourceCol = sourceIndex % columns;
      final sourceRow = sourceIndex ~/ columns;
      final targetCol = targetIndex % columns;
      final targetRow = targetIndex ~/ columns;

      sourceTopCenter = Offset(
          spacing + sourceCol * (effectiveTubeWidth + spacing) + effectiveTubeWidth / 2,
          spacing + sourceRow * (effectiveTubeHeight + spacing)
      );
      targetTopCenter = Offset(
          spacing + targetCol * (effectiveTubeWidth + spacing) + effectiveTubeWidth / 2,
          spacing + targetRow * (effectiveTubeHeight + spacing)
      );
    }

    return Positioned.fill(
      child: FluidPourAnimation(
        sourcePosition: sourceTopCenter,
        targetPosition: targetTopCenter,
        liquidColor: liquidColor,
        tubeWidth: effectiveTubeWidth,
        tubeHeight: effectiveTubeHeight,
        fromTube: fromTube,
        toTube: toTube,
        pourVolume: pourVolume,
        sourceIndex: sourceIndex,
        targetIndex: targetIndex,
        onComplete: () {
          viewModel.pourLiquid();
        },
        settings: _settings,
      ),
    );
  }

  /// 计算试管尺寸 - 响应式布局
  void _calculateTubeSize(Size gameAreaSize, int columns, int rows) {
    // 固定边距和间距（尽量减小以最大化可用空间）
    const minHorizontalMargin = 8.0;
    const minVerticalMargin = 12.0;
    const minHorizontalSpacing = 6.0;
    const minTubeWidth = 50.0;
    const maxTubeWidth = 120.0;
    const minTubeHeight = 80.0;
    const tubeWidgetMargin = 4.0; // TubeWidget 内部的 margin

    // 使用较小的边距以最大化空间利用
    horizontalMargin = minHorizontalMargin;
    verticalMargin = minVerticalMargin;
    horizontalSpacing = minHorizontalSpacing;

    // 计算可用宽度（减去左右边距）
    final availableWidth = gameAreaSize.width - 2 * horizontalMargin;

    // 计算试管宽度（在最小和最大之间）
    // 公式：总宽度 = 列数 * (tubeWidth + 2*tubeWidgetMargin) + (列数 - 1) * horizontalSpacing
    // => tubeWidth = (总宽度 - (列数 - 1) * horizontalSpacing) / 列数 - 2*tubeWidgetMargin
    tubeWidth = ((availableWidth - (columns - 1) * horizontalSpacing) / columns - 2 * tubeWidgetMargin)
        .clamp(minTubeWidth, maxTubeWidth);
    tubeHeight = tubeWidth * 2;

    // 计算所需高度（考虑 TubeWidget 的内部边距）
    final requiredHeight = (rows * (tubeHeight + 2 * tubeWidgetMargin)) + 
                          ((rows - 1) * verticalMargin) + 2 * verticalMargin;


    // 根据高度等比缩放（如果高度不足），允许更低的缩放以适应窄屏
    if (requiredHeight > gameAreaSize.height) {
      final scale = (gameAreaSize.height / requiredHeight).clamp(0.4, 1.0);

      tubeWidth *= scale;
      tubeHeight *= scale;
    }

    // 确保试管尺寸在有效范围内
    tubeWidth = tubeWidth.clamp(minTubeWidth, maxTubeWidth);
    tubeHeight = tubeHeight.clamp(minTubeHeight, double.infinity);
  }

  /// 处理试管点击
  void _handleTubeTap(int index, GameViewModel viewModel) {
    viewModel.selectTube(index);
  }
  // endregion
}