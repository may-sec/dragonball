import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import 'explore_providers.dart';
import 'character_detail_view.dart';

// LEARN (sealed classes + passing context through navigation):
// "How did the user get here?" is modelled as a SEALED class. The compiler
// knows every possible subtype, so a `switch` over it must handle all cases.
// Each source answers two questions:
//   labels()     -> pure text for the breadcrumb (easy to unit test)
//   onCrumbTap() -> what happens when a crumb is tapped (side effects)
// Keeping them separate is what makes labels() testable without widgets.

/// One tappable piece of the path, e.g. "Frieza Race".
@immutable
class Crumb {
  const Crumb(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;
}

sealed class PathSource {
  const PathSource();

  /// Crumbs BEFORE the character name. Empty list = just the character name.
  List<String> labels(AppStrings s);

  /// Default: go back to the screen that opened this character.
  void onCrumbTap(int index, WidgetRef ref, BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Opened without any group context (All, or the old Characters tab).
final class FromAll extends PathSource {
  const FromAll();

  @override
  List<String> labels(AppStrings s) => const [];
}

/// Opened from the Explore tab. Path examples:
///   mode all                 -> Zarbon
///   race, group Frieza Race  -> Frieza Race › Zarbon
///   race, no chip selected   -> Race › Zarbon
///   with search "za"         -> Frieza Race › “za” › Zarbon
final class FromExplore extends PathSource {
  const FromExplore({required this.mode, this.group, this.query = ''});

  final ExploreMode mode;
  final String? group;
  final String query;

  @override
  List<String> labels(AppStrings s) => [
        if (mode != ExploreMode.all) group ?? mode.label(s),
        if (query.isNotEmpty) '“$query”',
      ];

  @override
  void onCrumbTap(int index, WidgetRef ref, BuildContext context) {
    final isGroupCrumb = mode != ExploreMode.all && index == 0;
    if (isGroupCrumb) {
      // Tapping "Frieza Race" shows that group again, without the search.
      ref.read(exploreSelectionProvider.notifier).jumpTo(mode: mode, group: group);
    }
    // Tapping the search crumb keeps the list exactly as it was.
    Navigator.of(context).pop();
  }
}

final class FromFavorites extends PathSource {
  const FromFavorites();

  @override
  List<String> labels(AppStrings s) => [s.favoritesCrumb];
}

final class FromPlanet extends PathSource {
  const FromPlanet(this.planetName);

  final String planetName;

  @override
  List<String> labels(AppStrings s) => [planetName];
}

/// Everything the detail screen needs: where we came from, which characters
/// sit next to this one (for swiping), and how to build matching Hero tags.
@immutable
class CharacterNavContext {
  const CharacterNavContext({
    required this.source,
    required this.siblingIds,
    required this.index,
    required this.heroTagFor,
  });

  final PathSource source;
  final List<int> siblingIds;
  final int index;
  final String Function(int characterId) heroTagFor;
}

void openCharacter(BuildContext context, CharacterNavContext nav) {
  FocusManager.instance.primaryFocus?.unfocus();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CharacterProfileView(
        characterId: nav.siblingIds[nav.index],
        nav: nav,
      ),
    ),
  );
}