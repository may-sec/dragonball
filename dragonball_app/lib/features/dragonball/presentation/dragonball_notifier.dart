import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/failure.dart';
import '../../../core/result/result.dart';
import '../data/dragonball_repository.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';
import 'dragonball_state.dart';

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

  Future<void> refresh() async {
    final current = _current;

    if (current == null) {
      ref.invalidateSelf();
      return;
    }

    final characterSequence = ++_characterRequestSequence;
    final planetSequence = ++_planetRequestSequence;

    _update(
      (s) => s.copyWith(
        isLoadingCharacters: true,
        isLoadingPlanets: true,
        characterError: null,
        planetError: null,
      ),
    );

    final results = await Future.wait<Object>([
      _repository.fetchCharacters(
        page: 1,
        limit: 10,
        name: current.searchName,
        gender: current.selectedGender,
        race: current.selectedRace,
        affiliation: current.selectedAffiliation,
      ),
      _repository.fetchPlanets(
        page: 1,
        limit: 10,
        name: current.planetSearchName,
        isDestroyed: current.isDestroyedFilter,
      ),
    ]);

    if (characterSequence == _characterRequestSequence) {
      _applyCharacterPage(
        results[0] as Result<Page<Character>, Failure>,
        replace: true,
      );
    }

    if (planetSequence == _planetRequestSequence) {
      _applyPlanetPage(
        results[1] as Result<Page<Planet>, Failure>,
        replace: true,
      );
    }
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

    _update((_) => next);

    final sequence = ++_characterRequestSequence;

    final result = await _repository.fetchCharacters(
      page: 1,
      limit: 10,
      name: next.searchName,
      gender: next.selectedGender,
      race: next.selectedRace,
      affiliation: next.selectedAffiliation,
    );

    // Ignore a response if a newer search/filter has started.
    if (sequence != _characterRequestSequence) return;

    _applyCharacterPage(result, replace: true);
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

    _update((_) => next);

    final sequence = ++_planetRequestSequence;

    final result = await _repository.fetchPlanets(
      page: 1,
      limit: 10,
      name: next.planetSearchName,
      isDestroyed: next.isDestroyedFilter,
    );

    if (sequence != _planetRequestSequence) return;

    _applyPlanetPage(result, replace: true);
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
        current.hasActiveCharacterFilters ||
        !current.hasNextCharacters ||
        current.isLoadingCharacters ||
        current.isLoadingMoreCharacters) {
      return;
    }

    _update(
      (s) => s.copyWith(
        isLoadingMoreCharacters: true,
        characterError: null,
      ),
    );

    final sequence = ++_characterRequestSequence;

    final result = await _repository.fetchCharacters(
      page: current.characterCurrentPage + 1,
      limit: 10,
    );

    if (sequence != _characterRequestSequence) return;

    _applyCharacterPage(result, replace: false);
  }

  Future<void> loadNextPlanets() async {
    final current = _current;

    if (current == null ||
        current.hasActivePlanetFilters ||
        !current.hasNextPlanets ||
        current.isLoadingPlanets ||
        current.isLoadingMorePlanets) {
      return;
    }

    _update(
      (s) => s.copyWith(
        isLoadingMorePlanets: true,
        planetError: null,
      ),
    );

    final sequence = ++_planetRequestSequence;

    final result = await _repository.fetchPlanets(
      page: current.planetCurrentPage + 1,
      limit: 10,
    );

    if (sequence != _planetRequestSequence) return;

    _applyPlanetPage(result, replace: false);
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
  @override
  Set<int> build() => const <int>{};

  void toggle(int characterId) {
    final next = Set<int>.of(state);

    if (!next.add(characterId)) {
      next.remove(characterId);
    }

    state = Set<int>.unmodifiable(next);
  }

  bool contains(int characterId) => state.contains(characterId);
}