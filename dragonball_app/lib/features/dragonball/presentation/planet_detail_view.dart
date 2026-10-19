import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/category_style.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/result/result.dart';
import '../../../core/utils/text_cleaners.dart';
import '../../../widgets/build_character_image.dart';
import '../../../widgets/planet_card.dart' show kGrayscaleFilter;
import '../../../widgets/shared_widgets.dart';
import 'dragonball_notifier.dart';
import 'navigation_path.dart';

// The grayscale ColorFilter for destroyed planets now lives in planet_card.dart
// (kGrayscaleFilter), shared by the cards and this screen. The "intact" green
// comes from the theme (AppColors), so it is right in every theme variant.
class PlanetDetailView extends ConsumerWidget {
  const PlanetDetailView({super.key, required this.planetId});

  final int planetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final planetAsync = ref.watch(planetDetailProvider(planetId));
    final theme = Theme.of(context);
    final appColors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.planetDossier)),
      body: planetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => MessageBlock(
          icon: AppIcons.offline,
          title: s.loadFailed,
          message: error.toString(),
          actionLabel: s.retry,
          onAction: () => ref.invalidate(planetDetailProvider(planetId)),
        ),
        data: (planet) {
          final statusColor =
              planet.isDestroyed ? theme.colorScheme.error : appColors.intact;

          Widget image = buildCharacterImage(
            planet.imageUrl,
            fit: BoxFit.contain,
            showLoadingIndicator: true,
            errorWidget: const Icon(AppIcons.globe, size: 42),
          );
          if (planet.isDestroyed) {
            image = ColorFiltered(colorFilter: kGrayscaleFilter, child: image);
          }

          final residentIds = [for (final c in planet.characters) c.id];

          return RefreshIndicator(
            onRefresh: () async {
              final repo = ref.read(dragonBallRepositoryProvider);
              final result = await repo.fetchPlanetDetail(planetId);
              if (result case Ok()) {
                ref.invalidate(planetDetailProvider(planetId));
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.x5),
              children: [
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(AppSpace.x4),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lgAll,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        statusColor.withValues(alpha: 0.25),
                        statusColor.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                  child: image,
                ),
                const SizedBox(height: AppSpace.x5),
                Text(planet.name, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpace.x2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InfoChip(
                    label: planet.isDestroyed ? s.destroyed : s.intact,
                    icon: planet.isDestroyed ? AppIcons.destroyed : AppIcons.globe,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: AppSpace.x3),
                Text(
                  planet.description.isEmpty
                      ? s.noPlanetDescription
                      : stripFootnotes(planet.description),
                  style: theme.textTheme.bodyLarge,
                ),

                // Residents: real thumbnails, tappable, with a path.
                if (planet.characters.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    '${s.residents} (${planet.characters.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.x3),
                  for (final (i, character) in planet.characters.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.x2),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(AppSpace.x3),
                          leading: SizedBox(
                            width: 56,
                            height: 56,
                            child: buildCharacterImage(
                              character.imageUrl,
                              fit: BoxFit.contain,
                              errorWidget: const Icon(AppIcons.user),
                            ),
                          ),
                          title: Text(character.name),
                          subtitle: Text(
                            '${character.race} • ${character.affiliation}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            styleForCategory(character.affiliation).icon,
                            color: styleForCategory(character.affiliation).color,
                          ),
                          // Path: "Namek › Piccolo"; swipe moves between residents.
                          onTap: () => openCharacter(
                            context,
                            CharacterNavContext(
                              source: FromPlanet(planet.name),
                              siblingIds: residentIds,
                              index: i,
                              heroTagFor: (id) => 'planet-$planetId-character-$id',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}