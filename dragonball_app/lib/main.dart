import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/app_theme.dart';
import 'core/l10n/app_strings.dart';
import 'core/l10n/language_provider.dart';
import 'features/dragonball/presentation/app_settings.dart';
import 'features/dragonball/presentation/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: DragonBallApp()));
}

// LEARN (app root): MaterialApp wires together theme, locale, text scaling
// and the first screen. Everything here reacts to providers, so changing a
// setting restyles / re-translates the whole app live.
class DragonBallApp extends ConsumerWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final appLanguage = ref.watch(languageProvider.select((l) => l.app));

    return MaterialApp(
      title: 'Dragon Ball Universe',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(settings, Brightness.light),
      darkTheme: buildAppTheme(settings, Brightness.dark),
      themeMode: settings.themeMode,

      // Locale drives Flutter's OWN texts too (date pickers, "Copy/Paste"
      // menus, back button tooltips). Needs flutter_localizations in pubspec.
      locale: appLanguage.locale,
      supportedLocales: [for (final l in AppLanguage.values) l.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,

      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1.0);

        return MediaQuery(
          data: media.copyWith(
            // System text size AND the in-app setting multiply together.
            textScaler: TextScaler.linear(systemScale * settings.textScale),
            disableAnimations: settings.disableAnimations,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}