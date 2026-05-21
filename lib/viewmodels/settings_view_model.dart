import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 游戏设置视图模型
class SettingsViewModel with ChangeNotifier {
  // region 【私有属性】
  bool _darkMode = false; // 深色模式
  bool _musicEnabled = false; // 背景音乐
  bool _soundEffectsEnabled = true; // 游戏音效
  bool _autoSaveEnabled = true; // 自动保存
  bool _colorBlindMode = false; // 色盲模式
  double _animationSpeed = 0.5; // 动画速度
  // endregion

  // region 【用于保存游戏的键名】
  static const String _darkModeKey = 'pourwater_dark_mode';
  static const String _musicKey = 'pourwater_music';
  static const String _soundEffectsKey = 'pourwater_sound_effects';
  static const String _autoSaveKey = 'pourwater_auto_save';
  static const String _colorBlindModeKey = 'pourwater_color_blind_mode';
  static const String _animationSpeedKey = 'pourwater_animation_speed';
  // endregion

  // region 【公共访问器】
  bool get darkMode => _darkMode;
  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get autoSaveEnabled => _autoSaveEnabled;
  bool get colorBlindMode => _colorBlindMode;
  double get animationSpeed => _animationSpeed;
  // 系统主题检测
  bool get _systemIsDark => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  // endregion

  // region 【设置切换方法】
  /// 加载本地设置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // 默认跟随系统主题
    _darkMode = prefs.getBool(_darkModeKey) ?? _systemIsDark;
    _musicEnabled = prefs.getBool(_musicKey) ?? false;
    _soundEffectsEnabled = prefs.getBool(_soundEffectsKey) ?? true;
    _autoSaveEnabled = prefs.getBool(_autoSaveKey) ?? true;
    _colorBlindMode = prefs.getBool(_colorBlindModeKey) ?? false;
    _animationSpeed = prefs.getDouble(_animationSpeedKey) ?? 0.5;
    notifyListeners();
  }

  /// 切换深色模式
  void toggleDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value); // 持久化
    notifyListeners();
  }

  /// 切换背景音乐
  void toggleMusic(bool value) async {
    _musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
    notifyListeners();
  }

  /// 切换游戏音效
  void toggleSoundEffects(bool value) async {
    _soundEffectsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, value);
    notifyListeners();
  }

  /// 切换自动保存
  void toggleAutoSave(bool value) async {
    _autoSaveEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, value);
    notifyListeners();
  }

  /// 切换色盲模式
  void toggleColorBlindMode(bool value) async {
    _colorBlindMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorBlindModeKey, value);
    notifyListeners();
  }

  /// 设置动画速度
  void setAnimationSpeed(double value) async {
    _animationSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_animationSpeedKey, value);
    notifyListeners();
  }

  /// 统一更新设置
  void updateSettings({
    bool? darkMode,
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? autoSaveEnabled,
    bool? colorBlindMode,
    double? animationSpeed,
  }) {
    if (darkMode != null) toggleDarkMode(darkMode);
    if (musicEnabled != null) toggleMusic(musicEnabled);
    if (soundEffectsEnabled != null) toggleSoundEffects(soundEffectsEnabled);
    if (autoSaveEnabled != null) toggleAutoSave(autoSaveEnabled);
    if (colorBlindMode != null) toggleColorBlindMode(colorBlindMode);
    if (animationSpeed != null) setAnimationSpeed(animationSpeed);
  }
  // endregion
}