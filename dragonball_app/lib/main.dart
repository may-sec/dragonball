
import 'package:dragonball_app/features/dragonball/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dragonball/presentation/app_settings.dart';
import 'features/dragonball/presentation/dragonball_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: DragonBallApp()));
}

class DragonBallApp extends ConsumerWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'Dragon Ball Universe',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(settings, Brightness.light),
      darkTheme: _buildTheme(settings, Brightness.dark),
      themeMode: settings.themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1.0);

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              systemScale * settings.textScale,
            ),
            disableAnimations: settings.disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme(
    AppSettings settings,
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: settings.seedColor,
      brightness: brightness,
      contrastLevel: settings.highContrast ? 0.7 : 0.0,
    );

    final background = isLight
        ? const Color(0xFFFFFAF5)
        : const Color(0xFF171717);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: settings.compactCards
          ? VisualDensity.compact
          : VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            settings.compactCards ? 12 : 18,
          ),
          side: settings.highContrast
              ? BorderSide(color: scheme.outline, width: 1.2)
              : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: settings.highContrast
            ? scheme.outline
            : scheme.outlineVariant,
        thickness: settings.highContrast ? 1.2 : 0.7,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? Colors.white
            : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: settings.highContrast
                ? scheme.outline
                : scheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
        ),
      ),
    );
  }
}
