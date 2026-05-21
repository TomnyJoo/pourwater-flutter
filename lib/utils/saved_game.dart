import '../models/game_difficulty.dart';
import '../models/game_state.dart';

/// 保存游戏状态的类
class SavedGame {
  final DateTime saveTime;
  final GameState gameState;
  final GameDifficulty difficulty;

  SavedGame({
    required this.saveTime,
    required this.gameState,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'saveTime': saveTime.toIso8601String(),
    'gameState': gameState.toJson(),
    'difficulty': {
      'displayName': difficulty.displayName,
      'numberOfTubes': difficulty.numberOfTubes,
      'tubeCapacity': difficulty.tubeCapacity,
      'numberOfColors': difficulty.numberOfColors,
    },
  };

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    final diffData = json['difficulty'] as Map<String, dynamic>;
    final difficulty = GameDifficulty(
      displayName: diffData['displayName'] as String,
      numberOfTubes: diffData['numberOfTubes'] as int,
      tubeCapacity: diffData['tubeCapacity'] as int,
      numberOfColors: diffData['numberOfColors'] as int,
    );

    return SavedGame(
      saveTime: DateTime.parse(json['saveTime'] as String),
      gameState: GameState.fromJson(json['gameState'] as Map<String, dynamic>),
      difficulty: difficulty,
    );
  }
}