import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design/app_tokens.dart';
import '../core/utils/ki_parser.dart';

// LEARN (implicit animation + accessibility):
//  * TweenAnimationBuilder animates a value from begin to end with no
//    AnimationController and no dispose(). The bar "fills in" when it appears.
//  * MediaQuery.disableAnimationsOf respects the user's reduce-motion setting
//    (system or the app's own toggle, which main.dart merges in).
//  * Semantics gives screen readers ONE sentence instead of two colored
//    rectangles they cannot describe.
//
// Two layers: faint bar = max ki, solid bar = current ki (both log scale).
class KiBar extends StatelessWidget {
  const KiBar({
    super.key,
    required this.ki,
    required this.maxKi,
    this.height = 6,
    this.showLabels = false,
    this.kiLabel = 'Ki',
    this.maxLabel = 'Max',
  });

  final String ki;
  final String maxKi;
  final double height;
  final bool showLabels;
  final String kiLabel;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final kiValue = parseKi(ki);
    final maxValue = parseKi(maxKi);

    final kiFraction = kiScale(kiValue);
    // Max can never look smaller than current (bad API data happens).
    final maxFraction = math.max(kiScale(maxValue), kiFraction);

    final duration =
        MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.slow;

    final bar = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.curve,
      builder: (context, t, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: maxFraction * t,
                  child: ColoredBox(
                    color: scheme.secondary.withValues(alpha: 0.45),
                    child: const SizedBox.expand(),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: kiFraction * t,
                  child: ColoredBox(
                    color: scheme.primary,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      label: '$kiLabel ${formatKi(kiValue)}, $maxLabel ${formatKi(maxValue)}',
      child: ExcludeSemantics(
        child: showLabels
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  bar,
                  const SizedBox(height: AppSpace.x2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$kiLabel ${formatKi(kiValue)}',
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        '$maxLabel ${formatKi(maxValue)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : bar,
      ),
    );
  }
}