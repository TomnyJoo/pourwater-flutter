import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_record.dart';
import '../viewmodels/record_view_model.dart';

/// 记录屏幕
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = RecordViewModel();
        viewModel.loadRecords(context);
        return viewModel;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('游戏记录'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClearRecords(context),
              tooltip: '清空记录',
            ),
          ],
        ),
        body: Consumer<RecordViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.records.isEmpty) {
              return const Center(
                child: Text('暂无游戏记录', style: TextStyle(fontSize: 18)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: viewModel.records.length,
              itemBuilder: (context, index) {
                final record = viewModel.records[index];
                return _buildRecordCard(context, record, viewModel);
              },
            );
          },
        ),
      ),
    );
  }

  /// 构建记录卡片
  Widget _buildRecordCard(BuildContext context, GameRecord record, RecordViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${record.difficulty}难度',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  record.formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('用时', record.formattedTime),
                const SizedBox(width: 20),
                _buildStatItem('步数', '${record.moves}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteRecord(context, record, viewModel),
                  tooltip: '删除记录',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 确认删除记录
  void _confirmDeleteRecord(BuildContext context, GameRecord record, RecordViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条游戏记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteRecord(context, record);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 确认清空记录
  void _confirmClearRecords(BuildContext context) {
    final viewModel = Provider.of<RecordViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空记录'),
        content: const Text('确定要清空所有游戏记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearRecords(context);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}