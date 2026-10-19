import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/experience_policy.dart';
import '../../../widgets/image_preloader.dart';
import 'dragonball_home_screen.dart';
import 'dragonball_notifier.dart';
import 'dragonball_state.dart';

// =============================================================================
// LEARN (what a splash screen may wait for):
// Only what is needed to draw the first useful frame. Here that is the catalog
// from DISK (instant) or, on a first launch with nothing saved, one network
// attempt. It must NOT wait for:
//   * the background "is the server data newer?" check (isRefreshing), or
//   * every image on a slow connection.
// Image preloading is a nicety, so it gets a TIME BUDGET: Future.timeout throws
// a TimeoutException when the budget is spent, we ignore it and move on. The
// downloads keep running; the cards simply show their own placeholders.
// =============================================================================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _imageBudget = Duration(seconds: 2);

  // Only what is visible on the first screen is worth waiting for.
  static const int _preloadCharacters = 12;
  static const int _preloadPlanets = 4;

  bool _continueStarted = false;

  Future<void> _preloadThenContinue(DragonBallState data) async {
    // Battery saver: skip warming the image cache. Cards load their own
    // images, just a moment later.
    final preload = ref.read(experiencePolicyProvider).preloadImages;

    final urls = <String>[
      if (preload) ...[
        for (final c in data.characters.take(_preloadCharacters)) c.imageUrl,
        for (final p in data.planets.take(_preloadPlanets)) p.imageUrl,
      ],
    ];

    try {
      await preloadImageUrls(context, urls).timeout(_imageBudget);
    } on TimeoutException {
      // Slow or offline: carry on without waiting.
    }

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const DragonBallHomeScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(dragonBallControllerProvider);
    final data = catalog.asData?.value;

    // "Loading" only means "nothing to show yet" (see DragonBallController),
    // so a stale-but-usable catalog does not hold the splash.
    final isReady =
        data != null && !data.isLoadingCharacters && !data.isLoadingPlanets;

    if (isReady && !_continueStarted) {
      _continueStarted = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_preloadThenContinue(data));
      });
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final String status;
    if (data == null) {
      status = 'Loading characters and planets...';
    } else if (data.characters.isEmpty && data.characterError != null) {
      status = 'No connection. Opening...';
    } else {
      status = 'Preparing your universe...';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show the complete image without a circular crop.
                Image.asset(
                  'assets/dragonball-8.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Splash image error: $error');

                    return const Text('Unable to load image');
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Dragon Ball Explorer',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Explore characters and planets',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}