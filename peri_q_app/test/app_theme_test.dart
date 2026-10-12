import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/app_theme.dart';

void main() {
  group('AppTheme accessibility', () {
    for (final entry in <String, ThemeData>{
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
    }.entries) {
      test('${entry.key} theme foreground pairs meet WCAG AAA', () {
        final theme = entry.value;
        final scheme = theme.colorScheme;
        final semantic = theme.extension<AppSemanticColors>()!;
        final pairs = <(Color, Color)>[
          (scheme.onSurface, scheme.surface),
          (scheme.onPrimary, scheme.primary),
          (scheme.onPrimaryContainer, scheme.primaryContainer),
          (scheme.onSecondary, scheme.secondary),
          (scheme.onSecondaryContainer, scheme.secondaryContainer),
          (scheme.onError, scheme.error),
          (scheme.onErrorContainer, scheme.errorContainer),
          (semantic.onAccent, semantic.accent),
          (semantic.onAccentContainer, semantic.accentContainer),
          (semantic.onSuccess, semantic.success),
          (semantic.onSuccessContainer, semantic.successContainer),
          (semantic.onWarning, semantic.warning),
          (semantic.onWarningContainer, semantic.warningContainer),
          (semantic.onInfo, semantic.info),
          (semantic.onInfoContainer, semantic.infoContainer),
          (semantic.onDangerContainer, semantic.dangerContainer),
          (semantic.heroOnSurface, semantic.heroSurface),
        ];

        for (final pair in pairs) {
          expect(
            _contrastRatio(pair.$1, pair.$2),
            greaterThanOrEqualTo(7),
            reason: '${entry.key} pair ${pair.$1} on ${pair.$2} must meet AAA',
          );
        }
      });
    }

    testWidgets('light and dark themes render at large text without errors', (
      tester,
    ) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Peri-Q', style: TextStyle(fontSize: 36)),
                      TextField(decoration: InputDecoration(labelText: 'Name')),
                      Card(child: ListTile(title: Text('Accessible meal'))),
                      ElevatedButton(onPressed: null, child: Text('Continue')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}
