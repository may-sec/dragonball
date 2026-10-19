import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dragonball_models.dart';
import 'app_settings.dart';
import 'catalog_provider.dart';
import 'dragonball_notifier.dart';

// LEARN (derived providers instead of work inside build()):
// The old home screen sorted its lists INSIDE build(), so every rebuild
// (typing, a heart tap, a scroll-driven rebuild) re-sorted everything. A
// derived provider recomputes ONLY when one of the providers it watches
// changes, and every screen that needs the same view shares the result.
//
//   dragonBallControllerProvider (filtered characters / planets)
//   appSettingsProvider (sort order)            ->  sorted lists
//
//   dragonBallFavoritesProvider (ids)
//   catalogProvider (all characters)            ->  favorite characters
//
// Favorites used to fetch ONE FULL PROFILE PER FAVORITE just to show a name
// and a picture. The catalog already holds every character, so favorites are
// now a lookup in memory: no requests, instant, and they work offline.

List<T> _sortedByName<T>(
  List<T> items,
  String order,
  String Function(T item) nameOf,
) {
  switch (order) {
    case 'name_asc':
      return [...items]
        ..sort((a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()));
    case 'name_desc':
      return [...items]
        ..sort((a, b) => nameOf(b).toLowerCase().compareTo(nameOf(a).toLowerCase()));
    default:
      return items;
  }
}

final sortedCharactersProvider = Provider<List<Character>>((ref) {
  final characters = ref.watch(
        dragonBallControllerProvider.select((a) => a.asData?.value.characters),
      ) ??
      const <Character>[];
  final order = ref.watch(appSettingsProvider.select((s) => s.catalogSortOrder));

  return _sortedByName<Character>(characters, order, (c) => c.name);
});

final sortedPlanetsProvider = Provider<List<Planet>>((ref) {
  final planets = ref.watch(
        dragonBallControllerProvider.select((a) => a.asData?.value.planets),
      ) ??
      const <Planet>[];
  final order = ref.watch(appSettingsProvider.select((s) => s.catalogSortOrder));

  return _sortedByName<Planet>(planets, order, (p) => p.name);
});

/// Favorites that exist in the catalog, in the order chosen in Settings.
/// An id that is not in the catalog (catalog incomplete, or an imported
/// backup with an unknown id) is skipped here; the Favorites tab compares
/// counts to tell the user.
final favoriteCharactersProvider = Provider<List<Character>>((ref) {
  final ids = ref.watch(dragonBallFavoritesProvider);
  final catalog = ref.watch(
        catalogProvider.select((a) => a.asData?.value.characters.items),
      ) ??
      const <Character>[];
  final order = ref.watch(appSettingsProvider.select((s) => s.favoritesSortOrder));

  final byId = {for (final c in catalog) c.id: c};

  final favorites = [
    for (final id in ids)
      if (byId[id] case final character?) character,
  ];

  switch (order) {
    case 'id_asc':
      favorites.sort((a, b) => a.id.compareTo(b.id));
    case 'id_desc':
      favorites.sort((a, b) => b.id.compareTo(a.id));
  }

  return favorites;
});