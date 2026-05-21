import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_view_model.dart';

/// 游戏完成页面
class CompletionScreen extends StatelessWidget {
  final int timeElapsed;
  final int moves;

  const CompletionScreen({super.key, required this.timeElapsed, required this.moves});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('游戏完成')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                '恭喜完成游戏！',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildStatCard('用时', _formatTime(timeElapsed)),
              const SizedBox(height: 15),
              _buildStatCard('步数', '$moves'),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveScore(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                    ),
                    child: const Text('保存成绩'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.reset();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 50),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('返回主菜单'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建统计卡片组件
  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// 保存成绩到数据库
  void _saveScore(BuildContext context) async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    await viewModel.saveRecord();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
    }
  }

  /// 格式化时间显示为 MM:SS
  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}