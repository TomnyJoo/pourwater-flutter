import 'package:flutter_test/flutter_test.dart';
import 'package:pourwater/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pourwater/viewmodels/settings_view_model.dart';
import 'package:pourwater/viewmodels/audio_viewmodel.dart';
import 'package:pourwater/viewmodels/record_view_model.dart';
import 'package:pourwater/viewmodels/game_view_model.dart';

void main() {
  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsViewModel = SettingsViewModel();
    await settingsViewModel.loadSettings();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsViewModel),
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
        child: const PourWaterApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('倒水解谜'), findsOneWidget);
    expect(find.text('将相同颜色的水倒入同一试管'), findsOneWidget);
  });
}
