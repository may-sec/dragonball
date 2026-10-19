import 'package:dragonball_app/core/design/app_colors.dart';
import 'package:dragonball_app/core/design/app_theme.dart';
import 'package:dragonball_app/features/dragonball/presentation/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// LEARN (testing a theme): a ThemeData is just a value. buildAppTheme is a pure
// function of (settings, brightness), so you can assert on the result without
// pumping a single widget.

void main() {
  const trueBlackSettings = AppSettings(trueBlack: true);
  const normalSettings = AppSettings();

  group('true black', () {
    test('dark + trueBlack makes the scaffold and surface pure black', () {
      final theme = buildAppTheme(trueBlackSettings, Brightness.dark);

      expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(theme.colorScheme.surface, const Color(0xFF000000));
    });

    test('the surface ladder gets lighter at each level', () {
      final scheme = buildAppTheme(trueBlackSettings, Brightness.dark).colorScheme;

      final levels = [
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ].map((c) => c.computeLuminance()).toList();

      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThanOrEqualTo(levels[i - 1]));
      }

      // Cards must not vanish into the page.
      expect(levels[1], greaterThan(levels[0]));
    });

    test('cards use the lifted level, not pure black', () {
      final theme = buildAppTheme(trueBlackSettings, Brightness.dark);

      expect(theme.cardTheme.color, isNot(const Color(0xFF000000)));
    });

    test('dark without trueBlack keeps the dark grey background', () {
      final theme = buildAppTheme(normalSettings, Brightness.dark);

      expect(theme.scaffoldBackgroundColor, const Color(0xFF14161C));
    });

    test('trueBlack has no effect on the light theme', () {
      final theme = buildAppTheme(trueBlackSettings, Brightness.light);

      expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFAF5));
    });
  });

  group('AppColors extension', () {
    test('every theme variant registers one', () {
      expect(
        buildAppTheme(normalSettings, Brightness.light).extension<AppColors>(),
        isNotNull,
      );
      expect(
        buildAppTheme(trueBlackSettings, Brightness.dark).extension<AppColors>(),
        AppColors.trueBlack,
      );
    });

    test('the viewer is pure black only in true black', () {
      expect(AppColors.dark.viewerBackground, isNot(const Color(0xFF000000)));
      expect(AppColors.trueBlack.viewerBackground, const Color(0xFF000000));
    });

    test('lerp blends and handles a foreign extension', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);

      expect(mid.favorite, Color.lerp(AppColors.light.favorite, AppColors.dark.favorite, 0.5));
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });
  });

  group('settings', () {
    test('trueBlack defaults to off and copyWith changes only it', () {
      expect(normalSettings.trueBlack, isFalse);

      final changed = normalSettings.copyWith(trueBlack: true);

      expect(changed.trueBlack, isTrue);
      expect(changed.themeMode, normalSettings.themeMode);
      expect(changed.accentColor, normalSettings.accentColor);
    });

    test('animations are disabled by either toggle', () {
      expect(normalSettings.disableAnimations, isFalse);
      expect(normalSettings.copyWith(reducedMotion: true).disableAnimations, isTrue);
      expect(
        normalSettings.copyWith(animationsEnabled: false).disableAnimations,
        isTrue,
      );
    });
  });
}