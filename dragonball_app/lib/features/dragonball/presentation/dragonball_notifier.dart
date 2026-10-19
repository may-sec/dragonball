import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/result/result.dart';
import '../models/dragonball_models.dart';
import 'catalog_provider.dart';
import 'dragonball_core_providers.dart';
import 'dragonball_state.dart';

// Existing files import networkNoticeProvider, dragonBallRepositoryProvider and
// DragonBallRequestException from HERE. They now live in a smaller file, but
// are re-exported so no other import has to change.
export 'dragonball_core_providers.dart';

final dragonBallControllerProvider =
    AsyncNotifierProvider<DragonBallController, DragonBallState>(
  DragonBallController.new,
);

final dragonBallFavoritesProvider =
    NotifierProvider<DragonBallFavoritesController, Set<int>>(
  DragonBallFavoritesController.new,
);

// NOTE (next step): profiles are still "cache forever". The same
// stale-while-revalidate idea will be applied to them later.
final characterProfileProvider =
    FutureProvider.family<CharacterProfile, int>((ref, id) async {
  final repository = ref.watch(dragonBallRepositoryProvider);

  final cached = await repository.readCachedCharacterProfile(id);

  if (cached != null) {
    return cached;
  }

  final result = await repository.fetchCharacterProfile(id);

  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw DragonBallRequestException(failure),
  };
});

final planetDetailProvider =
    FutureProvider.family<Planet, int>((ref, id) async {
  final repository = ref.watch(dragonBallRepositoryProvider);

  final cached = await repository.readCachedPlanetDetail(id);

  if (cached != null) {
    return cached;
  }

  final result = await repository.fetchPlanetDetail(id);

  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw DragonBallRequestException(failure),
  };
});

// =============================================================================
// DragonBallController
//
// LEARN (a notifier that is a VIEW of another provider):
//  * The data is owned by catalogProvider. This controller only remembers the
//    FILTERS (plain fields on the Notifier object, which survive rebuilds)
//    and turns "catalog + filters" into the DragonBallState the home screen
//    renders.
//  * It uses ref.listen instead of ref.watch(catalogProvider.future): a watch
//    would rebuild this notifier on every catalog change and flash the loading
//    spinner over the whole home screen. listen just updates `state` quietly.
//  * Public method names are unchanged, so the home screen, splash and
//    settings compile as they are.
// =============================================================================
class DragonBallController extends AsyncNotifier<DragonBallState> {
  String _searchName = '';
  String _gender = 'ALL';
  String _race = 'ALL';
  String _affiliation = 'ALL';

  String _planetSearchName = '';
  bool? _isDestroyed;

  CatalogSnapshot? _snapshot;

  @override
  Future<DragonBallState> build() async {
    _snapshot = null;

    ref.listen<AsyncValue<CatalogSnapshot>>(catalogProvider, (previous, next) {
      final latest = next.asData?.value;
      if (latest == null) return;

      _snapshot = latest;

      // Before the first build finishes there is nothing to update yet:
      // build() reads _snapshot itself.
      if (state.hasValue) {
        state = AsyncData(_compose(latest));
      }
    });

    final first = await ref.read(catalogProvider.future);

    return _compose(_snapshot ?? first);
  }

  DragonBallState _compose(CatalogSnapshot snapshot) {
    final characters = filterCharacters(
      snapshot.characters.items,
      name: _searchName,
      gender: _gender,
      race: _race,
      affiliation: _affiliation,
    );

    final planets = filterPlanets(
      snapshot.planets.items,
      name: _planetSearchName,
      isDestroyed: _isDestroyed,
    );

    return DragonBallState(
      characters: characters,
      characterCurrentPage: 1,
      hasNextCharacters: false,
      // "Loading" means "nothing to show yet". A background check on top of
      // existing data is isRefreshing, so the splash never waits for it.
      isLoadingCharacters:
          snapshot.characters.isEmpty && snapshot.isRefreshing,
      isLoadingMoreCharacters: false,
      characterError: snapshot.characters.failure?.message,
      searchName: _searchName,
      selectedGender: _gender,
      selectedRace: _race,
      selectedAffiliation: _affiliation,
      planets: planets,
      planetCurrentPage: 1,
      hasNextPlanets: false,
      isLoadingPlanets: snapshot.planets.isEmpty && snapshot.isRefreshing,
      isLoadingMorePlanets: false,
      planetError: snapshot.planets.failure?.message,
      planetSearchName: _planetSearchName,
      isDestroyedFilter: _isDestroyed,
      isRefreshing: snapshot.isRefreshing,
      catalogIsComplete: snapshot.isComplete,
      lastValidatedAt: snapshot.lastValidatedAt,
    );
  }

  void _publish() {
    final snapshot = _snapshot;
    if (snapshot == null || !state.hasValue) return;

    state = AsyncData(_compose(snapshot));
  }

  /// Checks the server now (Settings > "Retry API requests", pull to refresh).
  Future<void> refresh() {
    return ref.read(catalogProvider.notifier).refresh(force: true);
  }

  /// Filters run locally: no request, instant, nothing to cancel or debounce.
  ///
  /// COMPATIBILITY: the current home screen calls this with NO arguments for
  /// its "Try again" button and pull-to-refresh, so a call without arguments
  /// means "check the server again". This goes away when the home screen is
  /// migrated to call refresh() directly.
  Future<void> applyCharacterFilters({
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {
    final isReapply =
        name == null && gender == null && race == null && affiliation == null;

    if (isReapply) {
      await refresh();
      return;
    }

    _searchName = name ?? _searchName;
    _gender = gender ?? _gender;
    _race = race ?? _race;
    _affiliation = affiliation ?? _affiliation;

    _publish();
  }

  Future<void> applyPlanetFilters({
    String? name,
    bool? isDestroyedFilter,
    bool clearDestroyedFilter = false,
  }) async {
    final isReapply =
        name == null && isDestroyedFilter == null && !clearDestroyedFilter;

    if (isReapply) {
      await refresh();
      return;
    }

    _planetSearchName = name ?? _planetSearchName;

    if (clearDestroyedFilter) {
      _isDestroyed = null;
    } else if (isDestroyedFilter != null) {
      _isDestroyed = isDestroyedFilter;
    }

    _publish();
  }

  void resetCharacterFilters() {
    _searchName = '';
    _gender = 'ALL';
    _race = 'ALL';
    _affiliation = 'ALL';

    _publish();
  }

  void resetPlanetFilters() {
    _planetSearchName = '';
    _isDestroyed = null;

    _publish();
  }

  // The whole catalogue is already loaded, so there is no "next page".
  // Kept as no-ops because the home screen's scroll listener still calls them.
  Future<void> loadNextCharacters() async {}

  Future<void> loadNextPlanets() async {}
}

class DragonBallFavoritesController extends Notifier<Set<int>> {
  static const _storageKey = 'dragonball_favorite_character_ids';

  bool _loaded = false;
  bool _restoreStarted = false;

  // IDs toggled while saved favorites are being restored.
  // Each ID's presence represents an odd number of toggles.
  final Set<int> _pendingToggles = {};

  // Serializes persistence writes so an older snapshot cannot
  // overwrite a newer snapshot after completing out of order.
  Future<void> _writeQueue = Future<void>.value();

  @override
  Set<int> build() {
    _startRestore();
    return const <int>{};
  }

  void _startRestore() {
    if (_loaded || _restoreStarted) return;

    _restoreStarted = true;
    _restoreFavorites();
  }

  void replaceAll(Set<int> characterIds) {
    final validIds = characterIds.where((id) => id > 0).toSet();

    _loaded = true;
    _restoreStarted = false;
    _pendingToggles.clear();

    state = Set<int>.unmodifiable(validIds);
    _enqueueSave();
  }

  Future<void> _restoreFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_loaded) return;

      final savedIds = (prefs.getStringList(_storageKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

      final hadPendingToggles = _pendingToggles.isNotEmpty;

      // Merge taps that occurred while storage was loading.
      // Toggle semantics mean each pending ID must be inverted once.
      for (final id in _pendingToggles) {
        if (!savedIds.add(id)) {
          savedIds.remove(id);
        }
      }

      _pendingToggles.clear();

      state = Set<int>.unmodifiable(savedIds);
      _loaded = true;
      _restoreStarted = false;

      // No write is needed if restoration did not change anything.
      // If the user toggled during restoration, persist the merged set.
      if (hadPendingToggles) {
        _enqueueSave();
      }
    } catch (error) {
      _restoreStarted = false;

      // Keep pending toggles so a later toggle can retry restoration.
      debugPrint('Failed to restore Dragon Ball favorites: $error');
    }
  }

  void toggle(int characterId) {
    final next = Set<int>.of(state);

    if (!next.add(characterId)) {
      next.remove(characterId);
    }

    // Update the UI immediately; persistence happens asynchronously.
    state = Set<int>.unmodifiable(next);

    if (!_loaded) {
      if (!_pendingToggles.add(characterId)) {
        _pendingToggles.remove(characterId);
      }

      // Retry restoration if a previous attempt failed.
      _startRestore();
      return;
    }

    _enqueueSave();
  }

  void _enqueueSave() {
    // Capture this state snapshot now. The queue guarantees snapshots
    // are written in the same order in which they were enqueued.
    final ids = state.toList();

    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setStringList(
          _storageKey,
          ids.map((id) => id.toString()).toList(),
        );
      } catch (error) {
        debugPrint('Failed to save Dragon Ball favorites: $error');
      }
    });
  }

  bool contains(int characterId) => state.contains(characterId);
}