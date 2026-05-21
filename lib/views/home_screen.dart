import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pourwater/views/record_screen.dart';
import 'package:pourwater/views/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/game_difficulty.dart';
import '../utils/saved_game.dart';
import '../viewmodels/audio_viewmodel.dart';
import '../viewmodels/game_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import 'game_screen.dart';

/// 游戏主界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  List<SavedGame> _savedGames = [];
  bool _isLoading = true;
  String _version = '1.0.0';

  static const List<GameDifficulty> _difficulties = [
    GameDifficulty.easy,
    GameDifficulty.medium,
    GameDifficulty.hard,
    GameDifficulty.expert,
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _loadSavedGames();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  Future<void> _loadSavedGames() async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);

    try {
      _savedGames = await viewModel.getSavedGames();
    } catch (e) {
      debugPrint('加载保存的游戏失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsViewModel>();
      final audioViewModel = context.read<AudioViewModel>();
      if (settings.musicEnabled && !audioViewModel.isMusicPlaying) {
        audioViewModel.resumeMusic();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          ),
        ),
        child: Stack(
          children: [
            _buildMainContent(context, isDarkMode),
            _buildTopBar(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDarkMode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Spacer(),
              _buildTopIconButton(
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecordScreen()),
                ),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildTopIconButton(
                icon: Icons.settings_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildTopIconButton(
                icon: Icons.help_outline_rounded,
                onTap: () => _showRulesDialog(context),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withAlpha(12)
              : Colors.white.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withAlpha(16)
                : Colors.white.withAlpha(80),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Icon(
              icon,
              size: 20,
              color: isDarkMode
                  ? Colors.white.withAlpha(200)
                  : const Color(0xFF3730A3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDarkMode) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 52),
            _buildHeader(isDarkMode),
            const SizedBox(height: 32),
            Expanded(
              child: _buildDifficultySection(context, isDarkMode),
            ),
            if (!_isLoading && _savedGames.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLoadGameCard(context, isDarkMode),
            ],
            const SizedBox(height: 16),
            _buildFooter(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          ).createShader(bounds),
          child: Text(
            '倒水解谜',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDarkMode ? Colors.white : const Color(0xFF312E81),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '将相同颜色的水倒入同一试管',
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white.withAlpha(120) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection(BuildContext context, bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        int crossAxisCount;
        if (screenWidth < 400) {
          crossAxisCount = 1;
        } else if (screenWidth < 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 3;
        }

        final rows = (_difficulties.length / crossAxisCount).ceil();
        final screenHeight = constraints.maxHeight;
        final spacing = screenHeight < 400 ? 8.0 : (screenHeight < 600 ? 10.0 : 12.0);
        final totalSpacingV = spacing * (rows - 1);
        final availableHeight = (screenHeight - totalSpacingV).clamp(0.0, double.infinity);

        const double minCardHeight = 80.0;
        const double maxCardHeight = 220.0;

        double cardHeight = rows > 0 ? (availableHeight / rows) : minCardHeight;
        cardHeight = cardHeight.clamp(minCardHeight, maxCardHeight);

        final cardWidth = (screenWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final childAspectRatio = cardWidth / cardHeight;

        return SizedBox(
          height: screenHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _difficulties.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final difficulty = _difficulties[index];
              return _buildDifficultyCard(context, difficulty, index, isDarkMode);
            },
          ),
        );
      },
    );
  }

  Widget _buildDifficultyCard(
    BuildContext context,
    GameDifficulty difficulty,
    int index,
    bool isDarkMode,
  ) {
    final colors = _getDifficultyGradient(difficulty);

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final delay = index * 0.1;
        final progress = ((_staggerController.value - delay).clamp(0.0, 1.0));
        final curve = Curves.easeOut.transform(progress);

        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Transform.scale(
              scale: 0.95 + 0.05 * curve,
              child: _buildCardContent(context, difficulty, colors),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    GameDifficulty difficulty,
    (Color, Color) colors,
  ) {
    return GestureDetector(
      onTap: () => _startGame(context, difficulty),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.$1, colors.$2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.$1.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    difficulty.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${difficulty.numberOfTubes}试管 · ${difficulty.numberOfColors}色',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _getDifficultyGradient(GameDifficulty difficulty) {
    if (difficulty == GameDifficulty.easy) {
      return (const Color(0xFF22C55E), const Color(0xFF4ADE80));
    } else if (difficulty == GameDifficulty.medium) {
      return (const Color(0xFF3B82F6), const Color(0xFF60A5FA));
    } else if (difficulty == GameDifficulty.hard) {
      return (const Color(0xFFF97316), const Color(0xFFFB923C));
    } else {
      return (const Color(0xFFEF4444), const Color(0xFFF87171));
    }
  }

  Widget _buildLoadGameCard(BuildContext context, bool isDarkMode) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final delay = _difficulties.length * 0.1;
        final progress = ((_staggerController.value - delay).clamp(0.0, 1.0));
        final curve = Curves.easeOut.transform(progress);

        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: Transform.scale(
              scale: 0.95 + 0.05 * curve,
              child: GestureDetector(
                onTap: () => _showSavedGames(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withAlpha(8) : Colors.white.withAlpha(70),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withAlpha(10) : Colors.white.withAlpha(120),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDarkMode ? 20 : 8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline_rounded, size: 24, color: const Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            Text(
                              '继续游戏',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            '版本 $_version',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.white.withAlpha(50) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '天王软件工作室',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.white.withAlpha(50) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, GameDifficulty difficulty) {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    viewModel.startNewGame(difficulty);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  void _showSavedGames(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SavedGamesList(savedGames: _savedGames),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '游戏规则',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E1B4B),
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Text(
            '游戏目标：将相同颜色的液体倒入同一个试管中\n\n'
                '操作规则：\n'
                '1. 只能将液体倒入空试管或顶部颜色相同的试管\n'
                '2. 一次只能倒一种颜色（试管顶部颜色）\n'
                '3. 可以倒部分液体，但必须倒入相同颜色\n'
                '4. 当所有试管都只有一种颜色或为空时，游戏完成\n\n'
                '提示：合理利用空试管来移动液体！',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E1B4B),
            ),
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedGamesList extends StatelessWidget {
  final List<SavedGame> savedGames;

  const SavedGamesList({super.key, required this.savedGames});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final viewModel = Provider.of<GameViewModel>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '保存的游戏',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: savedGames.length,
              itemBuilder: (context, index) {
                final game = savedGames[index];
                final time = game.gameState.timeElapsed;
                final minutes = (time / 60000).floor();
                final seconds = ((time % 60000) / 1000).floor();

                return Card(
                  color: isDarkMode ? const Color(0xFF334155) : Colors.white,
                  child: ListTile(
                    title: Text(
                      game.difficulty.displayName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                    ),
                    subtitle: Text(
                      '${game.gameState.moves}步 - ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white.withAlpha(120) : const Color(0xFF64748B),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[400]),
                      onPressed: () => _deleteGame(context, game),
                    ),
                    onTap: () {
                      viewModel.loadSavedGame(game.gameState);
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _deleteGame(BuildContext context, SavedGame game) async {
    final viewModel = Provider.of<GameViewModel>(context, listen: false);
    try {
      await viewModel.deleteSavedGame(game);
    } catch (e) {
      debugPrint('删除游戏失败: $e');
    }

    if (context.mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '删除成功',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E1B4B),
            ),
          ),
          content: Text(
            '游戏已删除',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E1B4B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}