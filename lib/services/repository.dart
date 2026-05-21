import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/game_difficulty.dart';
import '../models/game_record.dart';
import '../models/liquid.dart';
import '../models/tube.dart';
import '../utils/saved_game.dart';
import '../exceptions/game_exception.dart';

// ==================== 游戏仓库接口 ====================

abstract class GameRepository {
  List<Tube> generateGame(GameDifficulty difficulty);
  Future<void> saveGame(SavedGame game);
  Future<List<SavedGame>> getSavedGames();
  Future<void> deleteSavedGame(SavedGame game);
  Future<void> deleteAllSavedGames();
}

// ==================== 游戏仓库实现 ====================

class GameRepositoryImpl implements GameRepository {
  static const String _savedGamesKey = 'saved_games';

  @override
  List<Tube> generateGame(GameDifficulty difficulty) {
    final tubes = List.generate(
      difficulty.numberOfTubes,
      (id) => Tube(id: id, capacity: difficulty.tubeCapacity),
    );

    final colors = GameColors.getColorsByDifficulty(difficulty.numberOfColors);

    final colorVolumes = { for (var color in colors) color : difficulty.tubeCapacity };

    final totalVolume = (difficulty.numberOfTubes - 2) * difficulty.tubeCapacity;
    int allocatedVolume = colors.length * difficulty.tubeCapacity;

    if (totalVolume > allocatedVolume) {
      final remainingVolume = totalVolume - allocatedVolume;
      final fullTubesToAdd = remainingVolume ~/ difficulty.tubeCapacity;

      final random = Random();
      for (int i = 0; i < fullTubesToAdd; i++) {
        final color = colors[random.nextInt(colors.length)];
        colorVolumes[color] = colorVolumes[color]! + difficulty.tubeCapacity;
      }

      final remainingAfterFullTubes = remainingVolume % difficulty.tubeCapacity;
      if (remainingAfterFullTubes > 0) {
        final color = colors[random.nextInt(colors.length)];
        colorVolumes[color] = colorVolumes[color]! + difficulty.tubeCapacity;
      }
    }

    final liquids = <Liquid>[];
    colorVolumes.forEach((color, volume) {
      final fullTubes = volume ~/ difficulty.tubeCapacity;
      for (int i = 0; i < fullTubes; i++) {
        for (int j = 0; j < difficulty.tubeCapacity; j++) {
          liquids.add(Liquid(color: color, volume: 1));
        }
      }
    });

    liquids.shuffle();

    int liquidIndex = 0;
    for (int i = 0; i < tubes.length - 2; i++) {
      final tube = tubes[i];
      while (tube.remainingCapacity > 0 && liquidIndex < liquids.length) {
        final liquid = liquids[liquidIndex];
        tube.addLiquid(liquid.copy());
        liquidIndex++;
      }
    }

    return tubes;
  }

  @override
  Future<void> saveGame(SavedGame game) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGames = await getSavedGames();

      final existingIndex = savedGames.indexWhere(
            (g) => g.difficulty.displayName == game.difficulty.displayName,
      );

      if (existingIndex != -1) {
        savedGames[existingIndex] = game;
      } else {
        savedGames.add(game);
      }

      final jsonList = savedGames.map((g) => g.toJson()).toList();
      await prefs.setString(_savedGamesKey, json.encode(jsonList));
    } catch (e) {
      throw GameDataException('保存游戏失败: $e');
    }
  }

  @override
  Future<List<SavedGame>> getSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_savedGamesKey);

      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((item) => SavedGame.fromJson(item)).toList();
    } catch (e) {
      throw GameDataException('解析保存的游戏失败: $e');
    }
  }

  @override
  Future<void> deleteSavedGame(SavedGame game) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGames = await getSavedGames();
      savedGames.removeWhere(
            (g) => g.saveTime == game.saveTime &&
            g.difficulty.displayName == game.difficulty.displayName,
      );

      final jsonList = savedGames.map((g) => g.toJson()).toList();
      await prefs.setString(_savedGamesKey, json.encode(jsonList));
    } catch (e) {
      throw GameDataException('删除游戏失败: $e');
    }
  }

  @override
  Future<void> deleteAllSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedGamesKey);
    } catch (e) {
      throw GameDataException('清除所有游戏失败: $e');
    }
  }
}

// ==================== 记录仓库接口 ====================

abstract class RecordRepository {
  Future<void> saveRecord(GameRecord record);
  Future<List<GameRecord>> getRecords();
  Future<void> deleteRecord(GameRecord record);
  Future<void> clearRecords();
}

// ==================== 记录仓库实现 ====================

class RecordRepositoryImpl implements RecordRepository {
  static const String _recordsKey = 'game_records';

  @override
  Future<void> saveRecord(GameRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getRecords();
      records.add(record);

      final jsonList = records.map((r) => r.toJson()).toList();
      await prefs.setString(_recordsKey, json.encode(jsonList));
    } catch (e) {
      throw GameDataException('保存记录失败: $e');
    }
  }

  @override
  Future<List<GameRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recordsKey);

      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List;
      return jsonList.map((item) => GameRecord.fromJson(item)).toList();
    } catch (e) {
      throw GameDataException('解析记录失败: $e');
    }
  }

  @override
  Future<void> deleteRecord(GameRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getRecords();
      records.removeWhere((r) => r.date == record.date);

      final jsonList = records.map((r) => r.toJson()).toList();
      await prefs.setString(_recordsKey, json.encode(jsonList));
    } catch (e) {
      throw GameDataException('删除记录失败: $e');
    }
  }

  @override
  Future<void> clearRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recordsKey);
    } catch (e) {
      throw GameDataException('清除记录失败: $e');
    }
  }
}