import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_icons.dart';
import '../core/design/app_tokens.dart';
import '../core/l10n/language_provider.dart';
import '../features/dragonball/models/dragonball_models.dart';
import 'build_character_image.dart';
import 'shared_widgets.dart';

// LEARN (ColorFilter): a destroyed planet is drawn in grayscale. A color
// matrix multiplies [R G B A] rows; equal rows for R, G and B = gray.
const ColorFilter kGrayscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

Widget _planetImage(Planet planet) {
  final image = buildCharacterImage(
    planet.imageUrl,
    fit: BoxFit.contain,
    errorWidget: const Icon(AppIcons.globe, size: 36),
  );

  return planet.isDestroyed
      ? ColorFiltered(colorFilter: kGrayscaleFilter, child: image)
      : image;
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.planet});

  final Planet planet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return InfoChip(
      label: planet.isDestroyed ? s.destroyed : s.intact,
      icon: planet.isDestroyed ? AppIcons.destroyed : AppIcons.globe,
      color: planet.isDestroyed ? scheme.error : AppColors.of(context).intact,
      dense: true,
    );
  }
}

/// Card for grid layouts (height fixed by the grid's mainAxisExtent).
class PlanetGridCard extends StatelessWidget {
  const PlanetGridCard({super.key, required this.planet, required this.onTap});

  final Planet planet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainer,
                padding: const EdgeInsets.all(AppSpace.x3),
                child: _planetImage(planet),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x2),
                  _StatusChip(planet: planet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row for list layouts.
class PlanetRow extends StatelessWidget {
  const PlanetRow({super.key, required this.planet, required this.onTap});

  final Planet planet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.x3),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: _planetImage(planet),
              ),
              const SizedBox(width: AppSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpace.x2),
                    _StatusChip(planet: planet),
                  ],
                ),
              ),
              const Icon(AppIcons.caretRight),
            ],
          ),
        ),
      ),
    );
  }
}