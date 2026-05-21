import 'package:intl/intl.dart';

/// 游戏记录类，用于存储游戏过程中的数据。
class GameRecord {
  final DateTime date;
  final String difficulty;
  final int timeElapsed; // 毫秒
  final int moves;
  final int levelId;

  GameRecord({
    required this.date,
    required this.difficulty,
    required this.timeElapsed,
    required this.moves,
    this.levelId = 0,
  });

  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm').format(date);

  String get formattedTime {
    final seconds = (timeElapsed / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'difficulty': difficulty,
    'timeElapsed': timeElapsed,
    'moves': moves,
    'levelId': levelId,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    date: DateTime.parse(json['date']),
    difficulty: json['difficulty'],
    timeElapsed: json['timeElapsed'],
    moves: json['moves'],
    levelId: json['levelId'] ?? 0,
  );
}