import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_record.dart';
import 'game_view_model.dart';

/// 游戏记录视图模型
class RecordViewModel with ChangeNotifier {
  List<GameRecord> _records = [];

  List<GameRecord> get records => _records;

  RecordViewModel() {
    _initRecords();
  }

  Future<void> _initRecords() async {
    try {
      // 这里不能直接获取context，需要在RecordScreen中调用loadRecords
      _records = [];
      notifyListeners();
    } catch (e) {
      throw Exception('初始化记录失败: $e');
    }
  }

  /// 加载游戏记录
  Future<void> loadRecords(BuildContext context) async {
    try {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      _records = await gameViewModel.getRecords();
      notifyListeners();
    } catch (e) {
      throw Exception('加载记录失败: $e');
    }
  }

  /// 删除游戏记录
  Future<void> deleteRecord(BuildContext context, GameRecord record) async {
    try {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      await gameViewModel.deleteRecord(record);
      _records.remove(record);
      notifyListeners();
    } catch (e) {
      throw Exception('删除记录失败: $e');
    }
  }

  /// 清空游戏记录
  Future<void> clearRecords(BuildContext context) async {
    try {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      await gameViewModel.clearRecords();
      _records.clear();
      notifyListeners();
    } catch (e) {
      throw Exception('清空记录失败: $e');
    }
  }
}