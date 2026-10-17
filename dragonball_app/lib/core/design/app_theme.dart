import 'package:flutter/material.dart';

import '../../features/dragonball/presentation/app_settings.dart';
import 'app_tokens.dart';

/// LEARN (fonts): declare this family in pubspec.yaml (see INTEGRATION.md).
/// If the font files are missing, Flutter silently uses the default font,
/// so nothing breaks while you are still downloading them.
const String kHeadingFont = 'Rajdhani';

// LEARN (theming): ThemeData is built ONCE here, not styled widget by widget.
// Steps: 1) ColorScheme  2) TextTheme  3) per-component themes.
// Widgets then read Theme.of(context) and automatically match.
ThemeData buildAppTheme(AppSettings settings, Brightness brightness) {
  final isLight = brightness == Brightness.light;

  // 1) Colors. The seed (orange by default) generates a full Material 3
  // scheme; then we override two roles by hand so the app has a deliberate
  // second identity color (Saiyan blue) and an accent (aura gold).
  final generated = ColorScheme.fromSeed(
    seedColor: settings.seedColor,
    brightness: brightness,
    contrastLevel: settings.highContrast ? 0.7 : 0.0,
  );
  final scheme = generated.copyWith(
    secondary: isLight ? const Color(0xFF1F6FEB) : const Color(0xFF6CA8FF),
    tertiary: isLight ? const Color(0xFFB7791F) : const Color(0xFFFFC94D),
  );

  final background =
      isLight ? const Color(0xFFFFFAF5) : const Color(0xFF14161C);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  // 2) Typography: only the big headings use the display font.
  TextStyle heading(TextStyle? style) => (style ?? const TextStyle()).copyWith(
        fontFamily: kHeadingFont,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );
  final text = base.textTheme;

  final cardRadius = settings.compactCards ? AppRadius.md : AppRadius.lg;
  final borderColor =
      settings.highContrast ? scheme.outline : scheme.outlineVariant;

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: color, width: width),
      );

  // 3) Component themes.
  return base.copyWith(
    scaffoldBackgroundColor: background,
    visualDensity:
        settings.compactCards ? VisualDensity.compact : VisualDensity.standard,
    textTheme: text.copyWith(
      headlineLarge: heading(text.headlineLarge),
      headlineMedium: heading(text.headlineMedium),
      headlineSmall: heading(text.headlineSmall),
      titleLarge: heading(text.titleLarge),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        // A subtle border gives cards hierarchy on the flat background.
        side: BorderSide(color: borderColor),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: borderColor,
      thickness: settings.highContrast ? 1.2 : 0.7,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: borderColor),
      showCheckmark: false,
      selectedColor: scheme.primary.withValues(alpha: 0.18),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.white : scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: inputBorder(Colors.transparent),
      enabledBorder: inputBorder(borderColor),
      focusedBorder: inputBorder(scheme.primary, 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
  );
}