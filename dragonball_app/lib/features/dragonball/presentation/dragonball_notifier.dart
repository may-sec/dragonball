import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../core/errors/failure.dart';
import '../../../core/result/result.dart';
import '../data/dragonball_repository.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';
import 'dragonball_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dragonBallRepositoryProvider =
    Provider<DragonBallRepository>((ref) {
  final client = http.Client();

  ref.onDispose(client.close);

  return DragonBallRepository(client);
});

final dragonBallControllerProvider =
    AsyncNotifierProvider<DragonBallController, DragonBallState>(
  DragonBallController.new,
);

final dragonBallFavoritesProvider =
    NotifierProvider<DragonBallFavoritesController, Set<int>>(
  DragonBallFavoritesController.new,
);

final characterProfileProvider =
    FutureProvider.family<CharacterProfile, int>((ref, id) async {
  final repository = ref.watch(dragonBallRepositoryProvider);
  final result = await repository.fetchCharacterProfile(id);

  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw DragonBallRequestException(failure),
  };
});

final planetDetailProvider = FutureProvider.family<Planet, int>(
  (ref, id) async {
    final repository = ref.watch(dragonBallRepositoryProvider);
    final result = await repository.fetchPlanetDetail(id);

    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw DragonBallRequestException(failure),
    };
  },
);

final class DragonBallRequestException implements Exception {
  const DragonBallRequestException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}

class DragonBallController extends AsyncNotifier<DragonBallState> {
  int _characterRequestSequence = 0;
  int _planetRequestSequence = 0;

  @override
  Future<DragonBallState> build() async {
    // `watch` declares the repository as a provider dependency.
    final repository = ref.watch(dragonBallRepositoryProvider);

    final results = await Future.wait<Object>([
      repository.fetchCharacters(page: 1, limit: 10),
      repository.fetchPlanets(page: 1, limit: 10),
    ]);

    final characterResult =
        results[0] as Result<Page<Character>, Failure>;
    final planetResult =
        results[1] as Result<Page<Planet>, Failure>;

    final characterPage = switch (characterResult) {
      Ok(:final value) => value,
      Err() => const Page<Character>.empty(),
    };

    final planetPage = switch (planetResult) {
      Ok(:final value) => value,
      Err() => const Page<Planet>.empty(),
    };

    return DragonBallState.initial().copyWith(
      characters: characterPage.items,
      characterCurrentPage: characterPage.currentPage,
      hasNextCharacters: characterPage.hasNext,
      characterError: switch (characterResult) {
        Ok() => null,
        Err(:final failure) => failure.message,
      },
      planets: planetPage.items,
      planetCurrentPage: planetPage.currentPage,
      hasNextPlanets: planetPage.hasNext,
      planetError: switch (planetResult) {
        Ok() => null,
        Err(:final failure) => failure.message,
      },
    );
  }

  DragonBallState? get _current => state.asData?.value;

  void _update(
    DragonBallState Function(DragonBallState current) transform,
  ) {
    final current = _current;

    if (current != null) {
      state = AsyncData(transform(current));
    }
  }

  Future<void> _runCharacterRequest({
    required int sequence,
    required bool replace,
    required Future<Result<Page<Character>, Failure>> Function() request,
  }) async {
    try {
      final result = await request();

      // Only the latest character request owns the current state.
      if (sequence != _characterRequestSequence) return;

      _applyCharacterPage(
        result,
        replace: replace,
      );
    } catch (error) {
      if (sequence != _characterRequestSequence) return;

      _update(
        (s) => s.copyWith(
          isLoadingCharacters: false,
          isLoadingMoreCharacters: false,
          characterError: error.toString(),
        ),
      );
    }
  }

  Future<void> _runPlanetRequest({
  required int sequence,
  required bool replace,
  required Future<Result<Page<Planet>, Failure>> Function() request,
}) async {
  try {
    final result = await request();

    // Only the latest planet request owns the current state.
    if (sequence != _planetRequestSequence) return;

    _applyPlanetPage(
      result,
      replace: replace,
    );
  } catch (error) {
    if (sequence != _planetRequestSequence) return;

    _update(
      (s) => s.copyWith(
        isLoadingPlanets: false,
        isLoadingMorePlanets: false,
        planetError: error.toString(),
      ),
    );
  }
}


  Future<void> refresh() async {
    final current = _current;

    if (current == null) {
      ref.invalidateSelf();
      return;
    }

    // A refresh supersedes any in-flight request for each catalogue.
    final characterSequence = ++_characterRequestSequence;
    final planetSequence = ++_planetRequestSequence;

    _update(
      (s) => s.copyWith(
        isLoadingCharacters: true,
        isLoadingPlanets: true,
        isLoadingMoreCharacters: false,
        isLoadingMorePlanets: false,
        characterError: null,
        planetError: null,
      ),
    );

    await Future.wait<void>([
      _runCharacterRequest(
        sequence: characterSequence,
        replace: true,
        request: () => _repository.fetchCharacters(
          page: 1,
          limit: 10,
          name: current.searchName,
          gender: current.selectedGender,
          race: current.selectedRace,
          affiliation: current.selectedAffiliation,
        ),
      ),
      _runPlanetRequest(
        sequence: planetSequence,
        replace: true,
        request: () => _repository.fetchPlanets(
          page: 1,
          limit: 10,
          name: current.planetSearchName,
          isDestroyed: current.isDestroyedFilter,
        ),
      ),
    ]);
  }

  Future<void> applyCharacterFilters({
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {
    final current = _current;
    if (current == null) return;

    final next = current.copyWith(
      searchName: name ?? current.searchName,
      selectedGender: gender ?? current.selectedGender,
      selectedRace: race ?? current.selectedRace,
      selectedAffiliation: affiliation ?? current.selectedAffiliation,
      isLoadingCharacters: true,
      isLoadingMoreCharacters: false,
      characterError: null,
    );

    // Increment before starting the request. This invalidates older
    // searches, refreshes, and pagination requests for characters.
    final sequence = ++_characterRequestSequence;

    _update((_) => next);

    await _runCharacterRequest(
      sequence: sequence,
      replace: true,
      request: () => _repository.fetchCharacters(
        page: 1,
        limit: 10,
        name: next.searchName,
        gender: next.selectedGender,
        race: next.selectedRace,
        affiliation: next.selectedAffiliation,
      ),
    );
  }

  Future<void> applyPlanetFilters({
    String? name,
    bool? isDestroyedFilter,
    bool clearDestroyedFilter = false,
  }) async {
    final current = _current;
    if (current == null) return;

    final next = current.copyWith(
      planetSearchName: name ?? current.planetSearchName,
      isDestroyedFilter: clearDestroyedFilter
          ? null
          : (isDestroyedFilter ?? current.isDestroyedFilter),
      isLoadingPlanets: true,
      isLoadingMorePlanets: false,
      planetError: null,
    );

    final sequence = ++_planetRequestSequence;

    _update((_) => next);

    await _runPlanetRequest(
      sequence: sequence,
      replace: true,
      request: () => _repository.fetchPlanets(
        page: 1,
        limit: 10,
        name: next.planetSearchName,
        isDestroyed: next.isDestroyedFilter,
      ),
    );
  }

  void _applyCharacterPage(
    Result<Page<Character>, Failure> result, {
    required bool replace,
  }) {
    switch (result) {
      case Ok(:final value):
        _update(
          (s) => s.copyWith(
            characters: replace
                ? value.items
                : List.unmodifiable([...s.characters, ...value.items]),
            characterCurrentPage: value.currentPage,
            hasNextCharacters: value.hasNext,
            isLoadingCharacters: false,
            isLoadingMoreCharacters: false,
            characterError: null,
          ),
        );

      case Err(:final failure):
        _update(
          (s) => s.copyWith(
            isLoadingCharacters: false,
            isLoadingMoreCharacters: false,
            characterError: failure.message,
          ),
        );
    }
  }

  void _applyPlanetPage(
    Result<Page<Planet>, Failure> result, {
    required bool replace,
  }) {
    switch (result) {
      case Ok(:final value):
        _update(
          (s) => s.copyWith(
            planets: replace
                ? value.items
                : List.unmodifiable([...s.planets, ...value.items]),
            planetCurrentPage: value.currentPage,
            hasNextPlanets: value.hasNext,
            isLoadingPlanets: false,
            isLoadingMorePlanets: false,
            planetError: null,
          ),
        );

      case Err(:final failure):
        _update(
          (s) => s.copyWith(
            isLoadingPlanets: false,
            isLoadingMorePlanets: false,
            planetError: failure.message,
          ),
        );
    }
  }

  Future<void> loadNextCharacters() async {
    final current = _current;

    if (current == null ||
        !current.hasNextCharacters ||
        current.isLoadingCharacters ||
        current.isLoadingMoreCharacters) {
      return;
    }

    final sequence = ++_characterRequestSequence;

    _update(
      (s) => s.copyWith(
        isLoadingMoreCharacters: true,
        characterError: null,
      ),
    );

    await _runCharacterRequest(
      sequence: sequence,
      replace: false,
      request: () => _repository.fetchCharacters(
        page: current.characterCurrentPage + 1,
        limit: 10,
        name: current.searchName,
        gender: current.selectedGender,
        race: current.selectedRace,
        affiliation: current.selectedAffiliation,
      ),
    );
  }

  Future<void> loadNextPlanets() async {
    final current = _current;

    if (current == null ||
        !current.hasNextPlanets ||
        current.isLoadingPlanets ||
        current.isLoadingMorePlanets) {
      return;
    }

    final sequence = ++_planetRequestSequence;

    _update(
      (s) => s.copyWith(
        isLoadingMorePlanets: true,
        planetError: null,
      ),
    );

    await _runPlanetRequest(
      sequence: sequence,
      replace: false,
      request: () => _repository.fetchPlanets(
        page: current.planetCurrentPage + 1,
        limit: 10,
        name: current.planetSearchName,
        isDestroyed: current.isDestroyedFilter,
      ),
    );
  }

  void resetCharacterFilters() {
    applyCharacterFilters(
      name: '',
      gender: 'ALL',
      race: 'ALL',
      affiliation: 'ALL',
    );
  }

  void resetPlanetFilters() {
    applyPlanetFilters(
      name: '',
      clearDestroyedFilter: true,
    );
  }

  DragonBallRepository get _repository =>
      ref.read(dragonBallRepositoryProvider);
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

  Future<void> _restoreFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

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
    final ids = state.toList()..sort();

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