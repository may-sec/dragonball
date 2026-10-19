import 'package:flutter/material.dart';

import '../../features/dragonball/presentation/app_settings.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

/// LEARN (fonts): declare this family in pubspec.yaml (see INTEGRATION.md).
/// If the font files are missing, Flutter silently uses the default font,
/// so nothing breaks while you are still downloading them.
const String kHeadingFont = 'Rajdhani';

// LEARN (route transitions are part of the THEME): every page push uses the
// PageTransitionsBuilder registered for the current platform. Returning the
// child unchanged means "no slide, no fade": the new page just appears.
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

final PageTransitionsTheme _instantTransitions = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const _InstantPageTransitionsBuilder(),
  },
);

// LEARN (true black is a LADDER, not one color): Material 3 shows depth with
// surface tones: background < card < dialog < menu. If everything becomes
// #000000 the hierarchy disappears and cards vanish into the page. So the
// scaffold is pure black (those pixels are OFF on an OLED screen) and each
// container level above it is a slightly lighter near-black. The steps are
// small on purpose: very bright content next to #000 on OLED can "smear" when
// scrolling, and the nearly-black steps keep cards readable without being
// bright.
const Color _blackBackground = Color(0xFF000000);

ColorScheme _applyTrueBlack(ColorScheme scheme) {
  return scheme.copyWith(
    surface: _blackBackground,
    surfaceDim: _blackBackground,
    surfaceBright: const Color(0xFF1F1F1F),
    surfaceContainerLowest: _blackBackground,
    surfaceContainerLow: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF111111),
    surfaceContainerHigh: const Color(0xFF181818),
    surfaceContainerHighest: const Color(0xFF202020),
  );
}

// LEARN (theming): ThemeData is built ONCE here, not styled widget by widget.
// Steps: 1) ColorScheme  2) TextTheme  3) per-component themes.
// Widgets then read Theme.of(context) and automatically match.
ThemeData buildAppTheme(AppSettings settings, Brightness brightness) {
  final isLight = brightness == Brightness.light;

  // True black only exists in the DARK theme.
  final trueBlack = !isLight && settings.trueBlack;

  // 1) Colors. The seed (orange by default) generates a full Material 3
  // scheme; then we override two roles by hand so the app has a deliberate
  // second identity color (Saiyan blue) and an accent (aura gold).
  final generated = ColorScheme.fromSeed(
    seedColor: settings.seedColor,
    brightness: brightness,
    contrastLevel: settings.highContrast ? 0.7 : 0.0,
  ).copyWith(
    secondary: isLight ? const Color(0xFF1F6FEB) : const Color(0xFF6CA8FF),
    tertiary: isLight ? const Color(0xFFB7791F) : const Color(0xFFFFC94D),
  );

  final scheme = trueBlack ? _applyTrueBlack(generated) : generated;

  final background = trueBlack
      ? _blackBackground
      : isLight
          ? const Color(0xFFFFFAF5)
          : const Color(0xFF14161C);

  final appColors = isLight
      ? AppColors.light
      : trueBlack
          ? AppColors.trueBlack
          : AppColors.dark;

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
    extensions: <ThemeExtension<dynamic>>[appColors],
    visualDensity:
        settings.compactCards ? VisualDensity.compact : VisualDensity.standard,
    // null keeps the platform defaults. This only knows the IN-APP toggles;
    // widgets that read MediaQuery also honour the Android system setting.
    pageTransitionsTheme:
        settings.disableAnimations ? _instantTransitions : null,
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
        // A subtle border gives cards hierarchy on the flat background. On
        // true black this border does most of the work.
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