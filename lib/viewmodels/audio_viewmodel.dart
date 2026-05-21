import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pourwater/viewmodels/settings_view_model.dart';

/// 音频视图模型
class AudioViewModel extends ChangeNotifier {
  // region 私有字段
  final AudioPlayer _audioPlayer = AudioPlayer(); // 音乐播放器
  final AudioPlayer _soundEffectPlayer = AudioPlayer(); // 音效播放器
  SettingsViewModel settings; // 通过构造函数注入SettingsViewModel
  bool _isMusicPlaying = false;
  bool _isSoundEffectPlaying = false; // 音效播放状态跟踪
  double _originalVolume = 1.0;
  // endregion

  // region 设置读取
  /// 直接读取SettingsViewModel的状态
  bool get isMusicEnabled => settings.musicEnabled;
  bool get isSoundEffectEnabled => settings.soundEffectsEnabled; // 新增显式getter
  bool get isMusicPlaying => _isMusicPlaying;
  // endregion

  /// 构造函数，初始化音乐播放器
  AudioViewModel({required this.settings}) {_initializeAudio();}

  // region 生命周期管理
  /// 初始化音频播放器
  Future<void> _initializeAudio() async {
    // 添加空安全检查和异常处理
    try {
      if (settings.musicEnabled && !_isMusicPlaying) {
        await resumeMusic();
      }
    } catch (e) {
      throw Exception("音频播放器初始化错误: $e");
    }

  }

  /// 销毁音频播放器
  Future<void> disposeAudio() async {
    _audioPlayer.dispose();
    _soundEffectPlayer.dispose();
  }
  // endregion

  // region 状态同步机制
  /// 更新设置方法
  void updateSettings(SettingsViewModel newSettings) {
    final oldMusicEnabled = settings.musicEnabled;
    settings = newSettings;

    // 检查音乐设置是否改变
    if (oldMusicEnabled != newSettings.musicEnabled) {
      if (newSettings.musicEnabled) {resumeMusic();}
      else {pauseMusic();}
    }
  }
  // endregion

  /// 恢复播放背景音乐（统一入口）
  Future<void> resumeMusic() async {
    // 状态检查
    if (!settings.musicEnabled || _isMusicPlaying) return;

    try {
      // 源检查，避免重复设置
      if (_audioPlayer.source == null) {
        await _audioPlayer.setSource(AssetSource('music/background.mp3'));
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      }
      await _audioPlayer.resume();
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint("放背景音乐复播错误: $e");
      _isMusicPlaying = false;
    }
    notifyListeners();
  }

  /// 暂停播放背景音乐（统一入口）
  Future<void> pauseMusic() async {
    if (!_isMusicPlaying) return;
    await _audioPlayer.pause();
    _isMusicPlaying = false;
    notifyListeners();
  }

  /// 音乐控制方法
  Future<void> setMusicEnabled(bool enabled) async {
    if (enabled) {
      await resumeMusic();
    } else {
      await pauseMusic();
    }
    notifyListeners();
  }

  /// 处理游戏状态变化（根据游戏状态和设置控制音乐）
  void handleGameStateChanged(bool isPlaying) {
    if (isPlaying && isMusicEnabled && !_isMusicPlaying) {
      resumeMusic();
    } else if (!isPlaying && _isMusicPlaying) {
      pauseMusic();
    }
  }

  /// 播放音效（直接使用注入的settings检查状态）
  Future<void> playSoundEffect(String assetPath) async {
    if (!isSoundEffectEnabled || _isSoundEffectPlaying) return;

    try {
      _isSoundEffectPlaying = true;

      // 保存原始音量并降低音乐音量
      if (_isMusicPlaying) {
        _originalVolume = _audioPlayer.volume;
        await _audioPlayer.setVolume(0.3);
      }

      await _soundEffectPlayer.stop();
      await _soundEffectPlayer.play(AssetSource(assetPath));

      _soundEffectPlayer.onPlayerComplete.listen((_) async {
        _isSoundEffectPlaying = false;
        // 恢复音乐音量
        if (_isMusicPlaying) {await _audioPlayer.setVolume(_originalVolume);}
      });
    } catch (e) {
      debugPrint("播放音效失败: $e");
      _isSoundEffectPlaying = false;
      // 异常时恢复音量
      if (_isMusicPlaying) {await _audioPlayer.setVolume(_originalVolume);}
    }
  }
}