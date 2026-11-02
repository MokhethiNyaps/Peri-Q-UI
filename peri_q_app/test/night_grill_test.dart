import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/app_theme.dart';
import 'package:peri_q_app/src/models/app_preferences.dart';
import 'package:peri_q_app/src/widgets/flame_progress.dart';
import 'package:peri_q_app/src/widgets/plate_entrance.dart';

void main() {
  group('Night Grill theme defaults', () {
    test('new installs start in the dark brand theme', () {
      expect(const AppPreferences().themeMode, ThemeMode.dark);
      expect(AppPreferences.fromJson(const {}).themeMode, ThemeMode.dark);
    });

    test('a saved theme choice is always respected', () {
      expect(
        AppPreferences.fromJson(const {'themeMode': 'system'}).themeMode,
        ThemeMode.system,
      );
      expect(
        AppPreferences.fromJson(const {'themeMode': 'light'}).themeMode,
        ThemeMode.light,
      );
      final saved = AppPreferences.fromJson(
        const AppPreferences(themeMode: ThemeMode.system).toJson(),
      );
      expect(saved.themeMode, ThemeMode.system);
    });

    test('headlines use the display face, body text stays Roboto', () {
      final theme = AppTheme.darkTheme;
      expect(
        theme.textTheme.displayLarge?.fontFamily,
        AppTheme.displayFontFamily,
      );
      expect(
        theme.textTheme.headlineMedium?.fontFamily,
        AppTheme.displayFontFamily,
      );
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        isNot(AppTheme.displayFontFamily),
      );
    });
  });

  group('Motion widgets', () {
    testWidgets('plate entrance settles upright and skips reduced motion', (
      tester,
    ) async {
      const key = Key('plate');
      await tester.pumpWidget(
        const MaterialApp(
          home: PlateEntrance(
            child: SizedBox(key: key, width: 80, height: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PlateEntrance(
              child: SizedBox(key: key, width: 80, height: 80),
            ),
          ),
        ),
      );
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    });

    testWidgets('flame progress reports its value to assistive tech', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: FlameProgress(progress: 0.5, label: 'In the kitchen'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('In the kitchen'), findsOneWidget);
    });
  });
}
