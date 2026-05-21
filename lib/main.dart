import 'package:flutter/material.dart';
import 'package:pourwater/viewmodels/audio_viewmodel.dart';
import 'package:pourwater/viewmodels/game_view_model.dart';
import 'package:pourwater/viewmodels/record_view_model.dart';
import 'package:pourwater/viewmodels/settings_view_model.dart';
import 'package:pourwater/views/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 手动创建并等待SettingsViewModel初始化完成
  final settingsViewModel = SettingsViewModel();
  await settingsViewModel.loadSettings(); // 等待异步加载完成
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        /// 优先创建设置模型，强制立即初始化，因为游戏模型依赖于设置模型
        ChangeNotifierProvider.value(value: settingsViewModel),
        /// 提供AudioViewModel（依赖已初始化的settings）
        ChangeNotifierProxyProvider<SettingsViewModel, AudioViewModel>(
          create: (context) => AudioViewModel(settings: context.read<SettingsViewModel>()),
          update: (context, settings, audio) {
            audio?.updateSettings(settings);
            return audio ?? AudioViewModel(settings: settings);
          },
        ),
        ChangeNotifierProvider(create: (_) => RecordViewModel()),
        Provider.value(value: prefs),
        ChangeNotifierProvider(create: (_) => GameViewModel()),
      ],
      child: PourWaterApp(),
    ),
  );
}

class PourWaterApp extends StatelessWidget {
  const PourWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsViewModel>(context);

    return MaterialApp(
      title: '倒水游戏',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}