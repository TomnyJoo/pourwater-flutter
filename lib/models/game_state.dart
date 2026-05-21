import 'package:pourwater/models/tube.dart';
import 'game_difficulty.dart';

/// 游戏状态数据类，用于状态管理和持久化存储
class GameState {
  // region 【属性】
  /// 当前关卡的唯一标识（用于进度保存/加载）
  final int levelId;
  /// 当前游戏的难度等级（对应 [GameDifficulty] 枚举）
  final GameDifficulty difficulty;
  /// 当前所有试管的状态列表（每个 [Tube] 对象包含液体颜色和填充情况）
  final List<Tube> tubes;
  /// 当前选中的试管索引（`null` 表示未选中任何试管）
  int? selectedTubeIndex;
  /// 已进行的操作步数（每次液体转移计为1步）
  final int moves;
  /// 已消耗的游戏时间（单位：毫秒，用于计时模式统计）
  final int timeElapsed;
  /// 游戏是否已完成（所有颜色均正确归类到同一试管）
  final bool isCompleted;
  // endregion

  // region 【构造函数】
  /// 构造函数
  GameState({
    required this.levelId,
    required this.difficulty,
    required this.tubes,
    this.selectedTubeIndex,
    this.moves = 0,
    this.timeElapsed = 0,
    this.isCompleted = false,
  });
  // endregion

  // region 【辅助方法】
  /// 拷贝
  GameState copyWith({
    int? levelId,
    GameDifficulty? difficulty,
    List<Tube>? tubes,
    int? selectedTubeIndex,
    int? moves,
    int? timeElapsed,
    bool? isCompleted,
  }) {
    return GameState(
      levelId: levelId ?? this.levelId,
      difficulty: difficulty ?? this.difficulty,
      tubes: tubes ?? this.tubes,
      selectedTubeIndex: selectedTubeIndex, // 允许为 null
      moves: moves ?? this.moves,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'difficulty': {
      'displayName': difficulty.displayName,
      'numberOfTubes': difficulty.numberOfTubes,
      'tubeCapacity': difficulty.tubeCapacity,
      'numberOfColors': difficulty.numberOfColors,
    },
    'tubes': tubes.map((t) => t.toJson()).toList(),
    'selectedTubeIndex': selectedTubeIndex,
    'moves': moves,
    'timeElapsed': timeElapsed,
    'isCompleted': isCompleted,
  };

  /// 从 JSON 格式还原
  factory GameState.fromJson(Map<String, dynamic> json) {
    final diffData = json['difficulty'] as Map<String, dynamic>;
    final difficulty = GameDifficulty(
      displayName: diffData['displayName'] as String,
      numberOfTubes: diffData['numberOfTubes'] as int,
      tubeCapacity: diffData['tubeCapacity'] as int,
      numberOfColors: diffData['numberOfColors'] as int,
    );

    return GameState(
      levelId: json['levelId'] as int,
      difficulty: difficulty,
      tubes: (json['tubes'] as List).map((t) => Tube.fromJson(t)).toList(),
      selectedTubeIndex: json['selectedTubeIndex'],
      moves: json['moves'] as int,
      timeElapsed: json['timeElapsed'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }
  // endregion
}