import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/audio_viewmodel.dart';
import '../viewmodels/game_view_model.dart';
import '../viewmodels/settings_view_model.dart';

/// 游戏设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final audioViewModel = context.read<AudioViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 主题设置
          _buildSectionTitle('主题设置'),
          SwitchListTile(
            title: const Text('深色模式'),
            value: settings.darkMode,
            onChanged: (value) => settings.toggleDarkMode(value),
          ),
          const SizedBox(height: 30),

          _buildSectionTitle('声音设置'),
          SwitchListTile(
            title: const Text('启用音效'),
            value: settings.soundEffectsEnabled,
            onChanged: (value) => settings.toggleSoundEffects(value),
          ),
          SwitchListTile(
            title: const Text('启用背景音乐'),
            value: settings.musicEnabled,
            onChanged: (value) {
              // 直接更新设置并同步音频状态
              settings.toggleMusic(value);
              // 立即更新音频状态
              if (value) {
                audioViewModel.resumeMusic();
              }
              else {
                audioViewModel.pauseMusic();
              }
            },
          ),
          const SizedBox(height: 30),

          _buildSectionTitle('游戏设置'),
          SwitchListTile(
            title: const Text('色盲模式'),
            subtitle: const Text('使用图案替代颜色'),
            value: settings.colorBlindMode,
            onChanged: (value) => settings.toggleColorBlindMode(value),
          ),
          ListTile(
            title: const Text('动画速度'),
            subtitle: Slider(
              value: settings.animationSpeed,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(settings.animationSpeed * 100).toInt()}%',
              onChanged: (value) => settings.setAnimationSpeed(value),
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionTitle('数据管理'),
          ListTile(
            title: const Text('清除所有保存的游戏'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmDeleteAllGames(context),
            ),
          ),
          const SizedBox(height: 30),

          // 保存设置按钮
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('保存设置', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _confirmDeleteAllGames(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除所有保存的游戏吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllGames(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllGames(BuildContext context) async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);

    try {
      await viewModel.deleteAllSavedGames();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有保存的游戏已删除')),
        );
      }
    } catch (e) {
      throw Exception('删除所有游戏失败: $e');
    }
  }
}