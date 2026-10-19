import 'package:flutter/material.dart';

import '../core/design/app_icons.dart';
import '../core/design/app_tokens.dart';
import '../core/design/category_style.dart';
import '../features/dragonball/models/dragonball_models.dart';
import 'build_character_image.dart';
import 'favorite_heart.dart';
import 'ki_bar.dart';
import 'motion_hero.dart';
import 'shared_widgets.dart';

/// Hero tags must be UNIQUE per screen and IDENTICAL on both ends of the
/// animation. Centralizing the naming in functions avoids typos.
String exploreHeroTag(int id) => 'explore-character-$id';

// Gradient backdrop keyed to the character's affiliation color.
class _CharacterImage extends StatelessWidget {
  const _CharacterImage({required this.character, required this.heroTag});

  final Character character;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final color = styleForCategory(character.affiliation).color;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.04)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.x2),
        // MotionHero = Hero, except when the user asked for reduced motion.
        child: MotionHero(
          tag: heroTag,
          child: buildCharacterImage(
            character.imageUrl,
            fit: BoxFit.contain,
            showLoadingIndicator: true,
            errorWidget: const Icon(AppIcons.imageBroken, size: 40),
          ),
        ),
      ),
    );
  }
}

/// Card for grid layouts. Its height is fixed by the GRID (mainAxisExtent
/// in ExploreScreen), which scales with the user's text size.
class CharacterGridCard extends StatelessWidget {
  const CharacterGridCard({
    super.key,
    required this.character,
    required this.heroTag,
    required this.onTap,
  });

  final Character character;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = styleForCategory(character.affiliation);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CharacterImage(character: character, heroTag: heroTag),
                  Positioned(
                    top: AppSpace.x1,
                    right: AppSpace.x1,
                    child: FavoriteHeart(characterId: character.id),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.x2),
                  InfoChip(
                    label: character.affiliation,
                    icon: cat.icon,
                    color: cat.color,
                    dense: true,
                  ),
                  const SizedBox(height: AppSpace.x3),
                  KiBar(ki: character.ki, maxKi: character.maxKi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row for list layouts: thumbnail, name, race + affiliation chips, ki bar.
class CharacterRow extends StatelessWidget {
  const CharacterRow({
    super.key,
    required this.character,
    required this.heroTag,
    required this.onTap,
  });

  final Character character;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final race = styleForCategory(character.race);
    final affiliation = styleForCategory(character.affiliation);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.x3),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 88,
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: _CharacterImage(character: character, heroTag: heroTag),
                ),
              ),
              const SizedBox(width: AppSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpace.x2),
                    Wrap(
                      spacing: AppSpace.x2,
                      runSpacing: AppSpace.x1,
                      children: [
                        InfoChip(
                          label: character.race,
                          icon: race.icon,
                          color: race.color,
                          dense: true,
                        ),
                        InfoChip(
                          label: character.affiliation,
                          icon: affiliation.icon,
                          color: affiliation.color,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.x3),
                    KiBar(ki: character.ki, maxKi: character.maxKi),
                  ],
                ),
              ),
              FavoriteHeart(characterId: character.id, overlay: false),
            ],
          ),
        ),
      ),
    );
  }
}