import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_icons.dart';
import '../core/design/app_tokens.dart';
import '../core/l10n/language_provider.dart';
import '../features/dragonball/presentation/dragonball_notifier.dart';

// LEARN (several small topics in one widget):
//  * ConsumerWidget + ref.watch(provider.select(...)): rebuilds ONLY when
//    this one character's favorite flag changes, not when any favorite does.
//  * HapticFeedback: a tiny vibration on tap (mobile only, ignored on web).
//  * TweenAnimationBuilder with a ValueKey: when the key changes, the tween
//    restarts, so the heart "pops" (scale 0.6 -> 1.0 with an elastic curve)
//    every time it is toggled.
class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({
    super.key,
    required this.characterId,
    this.overlay = true,
  });

  final int characterId;

  /// true: round semi-transparent background (on top of images).
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;

    final isFavorite = ref.watch(
      dragonBallFavoritesProvider.select((ids) => ids.contains(characterId)),
    );

    final noMotion = MediaQuery.disableAnimationsOf(context);

    return IconButton(
      tooltip: isFavorite ? s.removeFavorite : s.addFavorite,
      visualDensity: overlay ? VisualDensity.compact : VisualDensity.standard,
      style: overlay
          ? IconButton.styleFrom(
              backgroundColor: scheme.surface.withValues(alpha: 0.85),
              shape: const CircleBorder(),
            )
          : null,
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(dragonBallFavoritesProvider.notifier).toggle(characterId);
      },
      icon: TweenAnimationBuilder<double>(
        key: ValueKey<bool>(isFavorite),
        tween: Tween<double>(begin: isFavorite ? 0.6 : 1.0, end: 1.0),
        duration: noMotion ? Duration.zero : AppMotion.slow,
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Icon(
          isFavorite ? AppIcons.heartFill : AppIcons.heart,
          color: isFavorite ? Colors.redAccent : null,
        ),
      ),
    );
  }
}