import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/l10n/app_strings.dart';
import 'core/l10n/language_provider.dart';
import 'core/platform/experience_policy.dart';
import 'features/dragonball/presentation/app_settings.dart';
import 'features/dragonball/presentation/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: DragonBallApp()));
}

// LEARN (app root): MaterialApp wires together theme, locale, text scaling
// and the first screen. Everything here reacts to providers, so changing a
// setting restyles / re-translates the whole app live.
//
// LEARN (ref.listen vs ref.listenManual): both run a callback when a provider
// changes, but they are for different places.
//   * ref.listen        : only inside build(). It has NO fireImmediately.
//   * ref.listenManual  : anywhere (initState, event handlers). It HAS
//                         fireImmediately, and the ConsumerState closes the
//                         subscription for you when it is disposed.
// The image-cache size must be applied once at startup AND whenever the policy
// changes, so it uses listenManual with fireImmediately in initState.
//
// LEARN (saved settings vs EFFECTIVE settings): the user's saved choice
// ("animations: on") must not be rewritten just because battery saver is on
// for an hour. So build() makes an EFFECTIVE copy: saved settings + whatever
// the experience policy forces right now. The theme and MediaQuery use the
// effective copy; the Settings screen keeps reading the saved one.
//
// LEARN (system bars): the status bar and the Android navigation bar belong to
// the OS. AnnotatedRegion<SystemUiOverlayStyle> tells the OS what icon
// brightness (and, before Android 15, color) to use for the screen shown.
class DragonBallApp extends ConsumerStatefulWidget {
  const DragonBallApp({super.key});

  @override
  ConsumerState<DragonBallApp> createState() => _DragonBallAppState();
}

class _DragonBallAppState extends ConsumerState<DragonBallApp> {
  @override
  void initState() {
    super.initState();

    // Side effect on a global (Flutter's decoded-image cache): a listener, not
    // build output.
    ref.listenManual<int>(
      experiencePolicyProvider.select((policy) => policy.imageCacheBytes),
      (previous, bytes) {
        PaintingBinding.instance.imageCache.maximumSizeBytes = bytes;
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final policy = ref.watch(experiencePolicyProvider);
    final appLanguage = ref.watch(languageProvider.select((l) => l.app));

    final effective =
        policy.reduceMotion ? settings.copyWith(reducedMotion: true) : settings;

    return MaterialApp(
      title: 'Dragon Ball Universe',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(effective, Brightness.light),
      darkTheme: buildAppTheme(effective, Brightness.dark),
      themeMode: effective.themeMode,

      // Locale drives Flutter's OWN texts too (date pickers, "Copy/Paste"
      // menus, back button tooltips). Needs flutter_localizations in pubspec.
      locale: appLanguage.locale,
      supportedLocales: [for (final l in AppLanguage.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,

      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1.0);

        // This context is INSIDE the Theme, so it already knows whether the
        // light, dark or true-black theme is active.
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final iconBrightness = isDark ? Brightness.light : Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: iconBrightness,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MediaQuery(
            data: media.copyWith(
              // System text size AND the in-app setting multiply together.
              textScaler: TextScaler.linear(systemScale * effective.textScale),
              disableAnimations: effective.disableAnimations,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}