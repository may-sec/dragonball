import 'package:dragonball_app/features/dragonball/models/dragonball_models.dart';
import 'package:dragonball_app/widgets/image_preloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dragonball_home_screen.dart';
import 'dragonball_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigationScheduled = false;
  bool _preloadStarted = false;
  bool _imagesReady = false;

  @override
  Widget build(BuildContext context) {

    // Start loading the catalogues while the splash screen is visible.
    final catalog = ref.watch(dragonBallControllerProvider);
    final data = catalog.asData?.value;

    final isLoadingCharacters =
        data?.isLoadingCharacters ?? true;
    final isLoadingPlanets =
        data?.isLoadingPlanets ?? true;

    Future<void> _prepareInitialImages(
      List<Character> characters,
      List<Planet> planets,
    ) async {
      await preloadImageUrls(
        context,
        [
          ...characters.map((character) => character.imageUrl),
          ...planets.map((planet) => planet.imageUrl),
        ],
      );

      if (mounted) {
        setState(() => _imagesReady = true);
      }
    }    

    // Navigate only after both initial catalogue requests have finished.
    // Failed requests also finish loading, allowing the home screen
    // to display its existing error and retry UI.
    final isReady = data != null &&
        !isLoadingCharacters &&
        !isLoadingPlanets;

    if (isReady && !_preloadStarted) {
      _preloadStarted = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || data == null) return;

        _prepareInitialImages(data.characters, data.planets);
      });
    }

    if (isReady && _imagesReady && !_navigationScheduled) {
      _navigationScheduled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (_, animation, secondaryAnimation) =>
                const DragonBallHomeScreen(),
            transitionsBuilder: (_, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      });
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final String status;
    if (data == null ||
        (isLoadingCharacters && isLoadingPlanets)) {
      status = 'Loading characters and planets...';
    } else if (isLoadingCharacters) {
      status = 'Loading characters...';
    } else if (isLoadingPlanets) {
      status = 'Loading planets...';
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