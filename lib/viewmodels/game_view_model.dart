import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_difficulty.dart';
import '../models/game_record.dart';
import '../models/game_state.dart';
import '../models/pour_animation_state.dart';
import '../models/tube.dart';
import '../services/repository.dart';
import '../utils/saved_game.dart';
import '../exceptions/game_exception.dart';

/// 游戏视图模型
class GameViewModel with ChangeNotifier {
  // region 【私有属性】
  /// 游戏状态
  GameState? _currentState;
  /// 初始状态
  GameState? _initialState;
  /// 游戏仓库
  final GameRepository _repository;
  /// 记录仓库
  final RecordRepository _recordRepository;
  /// 历史记录
  final List<GameState> _history = [];
  /// 重做功能
  final List<GameState> _redoStack = [];
  /// 计时器
  Timer? _timer;
  /// 倒水超时计时器
  Timer? _pourTimeoutTimer;
  /// 开始时间
  int _startTime = 0;
  /// 正在倒水状态
  bool _isPouring = false;
  /// 倒水动画参数
  int? _pourFromIndex;
  int? _pourToIndex;
  /// 提示信息
  String _message = '';
  /// 倒水动画状态
  PourAnimationState _pourAnimationState = const PourAnimationState();
  // endregion

  // region 【构造函数】
  GameViewModel({
    GameRepository? repository,
    RecordRepository? recordRepository,
  })  : _repository = repository ?? GameRepositoryImpl(),
        _recordRepository = recordRepository ?? RecordRepositoryImpl();
  // endregion

  // region 【公共访问器】
  GameState? get currentState => _currentState;
  bool get isCompleted => _currentState!.isCompleted;
  int? get selectedTubeIndex => _currentState!.selectedTubeIndex;
  bool get hasHistory => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isPouring => _isPouring;
  String get message => _message;
  PourAnimationState get pourAnimationState => _pourAnimationState;
  // endregion

  // region 【游戏控制】
  /// 开始新游戏
  void startNewGame(GameDifficulty difficulty) {
    _history.clear();
    _timer?.cancel();

    try {
      final tubes = _repository.generateGame(difficulty);
      _currentState = GameState(
        levelId: 1,
        difficulty: difficulty,
        tubes: tubes,
      );

      // 保存初始状态
      _initialState = _currentState!.copyWith(
        tubes: _currentState!.tubes.map((t) => t.copy()).toList(),
      );

      _startTime = DateTime.now().millisecondsSinceEpoch;
      _startTimer();
      notifyListeners();
    } catch (e) {
      throw GameOperationException('开始新游戏失败: $e');
    }
  }

  /// 从恢复的游戏状态中加载保存的游戏
  Future<void> loadSavedGame(GameState state) async {
    _history.clear();
    _timer?.cancel();
    _currentState = state;

    if (!state.isCompleted) {
      _startTime = DateTime.now().millisecondsSinceEpoch - state.timeElapsed;
      _startTimer();
    }

    notifyListeners();
  }

  /// 选择试管
  void selectTube(int index) {
    if (_currentState == null || _currentState!.isCompleted) {
      return;
    }

    if (_isPouring) {
      if (!_pourAnimationState.isActive) {
        _isPouring = false;
      } else {
        return;
      }
    }

    final selectedIndex = _currentState!.selectedTubeIndex;
    if (selectedIndex == index) {
      _currentState = _currentState!.copyWith(selectedTubeIndex: null);
      notifyListeners();
      return;
    }
    if (selectedIndex == null) {
      if (!_currentState!.tubes[index].isEmpty) {
        _currentState = _currentState!.copyWith(selectedTubeIndex: index);
        notifyListeners();
      }
      return;
    }

    final fromTube = _currentState!.tubes[selectedIndex];
    final toTube = _currentState!.tubes[index];
    if (fromTube.isEmpty ||
        !toTube.canAcceptLiquid(fromTube.topLiquid!.color)) {
      _message = '无法倒水';
      return;
    }

    _message = '';
    _isPouring = true;
    _pourFromIndex = selectedIndex;
    _pourToIndex = index;

    _pourAnimationState = PourAnimationState(
      phase: PourAnimationPhase.movingToTarget,
      sourceTubeIndex: selectedIndex,
      targetTubeIndex: index,
    );

    _pourTimeoutTimer?.cancel();
    _pourTimeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isPouring) {
        cancelPour();
      }
    });

    notifyListeners();
  }

  /// 倒水操作
  void pourLiquid() {
    _pourTimeoutTimer?.cancel();
    _pourAnimationState = const PourAnimationState();

    if (_pourFromIndex == null || _pourToIndex == null) {
      _isPouring = false;
      notifyListeners();
      return;
    }

    final fromIndex = _pourFromIndex!;
    final toIndex = _pourToIndex!;
    final fromTube = _currentState!.tubes[fromIndex];
    final toTube = _currentState!.tubes[toIndex];

    // 保存历史状态（包含当前选中状态）
    _history.add(GameState(
      levelId: _currentState!.levelId,
      difficulty: _currentState!.difficulty,
      tubes: _currentState!.tubes.map((t) => t.copy()).toList(),
      selectedTubeIndex: _currentState!.selectedTubeIndex,
      moves: _currentState!.moves,
      timeElapsed: _currentState!.timeElapsed,
      isCompleted: _currentState!.isCompleted,
    ));

    // 计算可倒的最大量
    final maxAmount = min(fromTube.topLiquid!.volume, toTube.remainingCapacity);

    // 执行倒水
    final liquid = fromTube.removeLiquid(maxAmount)!;
    toTube.addLiquid(liquid);

    // 更新状态
    final newTubes = List<Tube>.from(_currentState!.tubes);
    newTubes[fromIndex] = fromTube;
    newTubes[toIndex] = toTube;
    _currentState = _currentState!.copyWith(
      tubes: newTubes,
      selectedTubeIndex: null, // 倒水后取消选中
      moves: _currentState!.moves + 1,
    );

    // 重置倒水状态
    _isPouring = false;
    _pourFromIndex = null;
    _pourToIndex = null;
    // 检查游戏是否完成
    _checkCompletion();
    notifyListeners();
  }

  /// 取消倒水（动画失败时调用）
  void cancelPour() {
    _pourTimeoutTimer?.cancel();
    _isPouring = false;
    _pourFromIndex = null;
    _pourToIndex = null;
    _pourAnimationState = const PourAnimationState();
    notifyListeners();
  }

  /// 检查游戏是否完成
  void _checkCompletion() {
    final completedTubes = _currentState!.tubes
        .where((tube) => tube.isCompleted || tube.isEmpty)
        .length;

    if (completedTubes == _currentState!.tubes.length) {
      _currentState = _currentState!.copyWith(isCompleted: true);
      _timer?.cancel();
    }
  }

  /// 撤销操作
  void undo() {
    if (_history.isEmpty) return;

    // 保存当前状态到重做栈
    _redoStack.add(GameState(
      levelId: _currentState!.levelId,
      difficulty: _currentState!.difficulty,
      tubes: _currentState!.tubes.map((t) => t.copy()).toList(),
      selectedTubeIndex: _currentState!.selectedTubeIndex,
      moves: _currentState!.moves,
      timeElapsed: _currentState!.timeElapsed,
      isCompleted: _currentState!.isCompleted,
    ));

    // 恢复上一个状态
    final previousState = _history.removeLast();
    _currentState = previousState.copyWith(
      tubes: previousState.tubes.map((t) => t.copy()).toList(),
    );

    notifyListeners();
  }

  /// 重做操作
  void redo() {
    if (_redoStack.isEmpty) return;

    // 保存当前状态到撤销栈
    _history.add(GameState(
      levelId: _currentState!.levelId,
      difficulty: _currentState!.difficulty,
      tubes: _currentState!.tubes.map((t) => t.copy()).toList(),
      selectedTubeIndex: _currentState!.selectedTubeIndex,
      moves: _currentState!.moves,
      timeElapsed: _currentState!.timeElapsed,
      isCompleted: _currentState!.isCompleted,
    ));

    // 恢复重做状态
    final nextState = _redoStack.removeLast();
    _currentState = nextState;

    notifyListeners();
  }

  /// 重置游戏
  void reset() {
    if (_initialState == null) return;

    _history.clear();
    _redoStack.clear();
    _timer?.cancel();

    _currentState = _initialState!.copyWith(
      tubes: _initialState!.tubes.map((t) => t.copy()).toList(),
    );

    if (!_currentState!.isCompleted) {
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _startTimer();
    }
    notifyListeners();
  }

  /// 新游戏
  void newGame() {
    if (_currentState == null) return;
    startNewGame(_currentState!.difficulty);
  }

  /// 保存当前游戏
  Future<void> saveCurrentGame() async {
    if (_currentState == null) return;

    try {
      await _repository.saveGame(SavedGame(
        saveTime: DateTime.now(),
        gameState: _currentState!,
        difficulty: _currentState!.difficulty,
      ));
    } catch (e) {
      throw GameOperationException('保存游戏失败: $e');
    }
  }

  /// 获取保存的游戏
  Future<List<SavedGame>> getSavedGames() async {
    try {
      return await _repository.getSavedGames();
    } catch (e) {
      throw GameOperationException('获取保存的游戏失败: $e');
    }
  }

  /// 删除保存的游戏
  Future<void> deleteSavedGame(SavedGame game) async {
    try {
      await _repository.deleteSavedGame(game);
    } catch (e) {
      throw GameOperationException('删除游戏失败: $e');
    }
  }

  /// 清除所有保存的游戏
  Future<void> deleteAllSavedGames() async {
    try {
      await _repository.deleteAllSavedGames();
    } catch (e) {
      throw GameOperationException('清除所有游戏失败: $e');
    }
  }
  // endregion

  // region 【游戏记录管理】
  /// 保存游戏记录
  Future<void> saveRecord() async {
    if (_currentState == null || !_currentState!.isCompleted) return;

    try {
      final record = GameRecord(
        date: DateTime.now(),
        difficulty: _currentState!.difficulty.displayName,
        timeElapsed: _currentState!.timeElapsed,
        moves: _currentState!.moves,
        levelId: _currentState!.levelId,
      );

      await _recordRepository.saveRecord(record);
    } catch (e) {
      throw GameOperationException('保存记录失败: $e');
    }
  }

  /// 获取游戏记录
  Future<List<GameRecord>> getRecords() async {
    try {
      return await _recordRepository.getRecords();
    } catch (e) {
      throw GameOperationException('获取记录失败: $e');
    }
  }

  /// 删除游戏记录
  Future<void> deleteRecord(GameRecord record) async {
    try {
      await _recordRepository.deleteRecord(record);
    } catch (e) {
      throw GameOperationException('删除记录失败: $e');
    }
  }

  /// 清除所有游戏记录
  Future<void> clearRecords() async {
    try {
      await _recordRepository.clearRecords();
    } catch (e) {
      throw GameOperationException('清除记录失败: $e');
    }
  }
  // endregion

  // region 【辅助方法】
  /// 开始计时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _startTime;

      // 使用当前选中状态创建新状态
      _currentState = _currentState!.copyWith(
        timeElapsed: elapsed,
        selectedTubeIndex: _currentState!.selectedTubeIndex,
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pourTimeoutTimer?.cancel();
    super.dispose();
  }
  // endregion
}