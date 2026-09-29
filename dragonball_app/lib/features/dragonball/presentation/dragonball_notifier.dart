// lib/features/dragonball/presentation/dragonball_notifier.dart
import 'package:dragonball_app/core/errors/failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/result/result.dart';
import '../data/dragonball_repository.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';

// Global provider exposing the DragonBallRepository instance.
// Instantiates an http.Client and registers an onDispose hook to properly close
// the client connection when the provider is destroyed, preventing resource leaks.
final dbRepositoryProvider = Provider<DragonBallRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return DragonBallRepository(client);
});


// Primary NotifierProvider binding DragonBallNotifier to DragonBallState.
// Uses Dart constructor tear-off (`DragonBallNotifier.new`) for initialization.
final dragonBallNotifierProvider =
    NotifierProvider<DragonBallNotifier, DragonBallState>(
  DragonBallNotifier.new,
);

final class DragonBallState {
  final bool isLoading;
  final String? errorMessage;

  // Characters
  final List<Character> characters;
  final int characterCurrentPage;
  final bool hasNextCharacters;
  final bool isLoadingMoreCharacters;
  
  // Character Filters
  final String searchName;
  final String selectedGender;
  final String selectedRace;
  final String selectedAffiliation;

  // Planets
  final List<Planet> planets;
  final int planetCurrentPage;
  final bool hasNextPlanets;
  final bool isLoadingMorePlanets;

  // Planet Filters
  final String planetSearchName;
  final bool? isDestroyedFilter; // null = ALL, true = Destroyed, false = Intact

  const DragonBallState({
    required this.isLoading,
    required this.errorMessage,
    required this.characters,
    required this.characterCurrentPage,
    required this.hasNextCharacters,
    required this.isLoadingMoreCharacters,
    required this.searchName,
    required this.selectedGender,
    required this.selectedRace,
    required this.selectedAffiliation,
    required this.planets,
    required this.planetCurrentPage,
    required this.hasNextPlanets,
    required this.isLoadingMorePlanets,
    required this.planetSearchName,
    required this.isDestroyedFilter,
  });

  bool get hasActiveCharacterFilters =>
      searchName.isNotEmpty ||
      selectedGender != 'ALL' ||
      selectedRace != 'ALL' ||
      selectedAffiliation != 'ALL';

  bool get hasActivePlanetFilters =>
      planetSearchName.isNotEmpty || isDestroyedFilter != null;

  factory DragonBallState.initial() => const DragonBallState(
        isLoading: true,
        errorMessage: null,
        characters: [],
        characterCurrentPage: 1,
        hasNextCharacters: true,
        isLoadingMoreCharacters: false,
        searchName: '',
        selectedGender: 'ALL',
        selectedRace: 'ALL',
        selectedAffiliation: 'ALL',
        planets: [],
        planetCurrentPage: 1,
        hasNextPlanets: true,
        isLoadingMorePlanets: false,
        planetSearchName: '',
        isDestroyedFilter: null,
      );

  DragonBallState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Character>? characters,
    int? characterCurrentPage,
    bool? hasNextCharacters,
    bool? isLoadingMoreCharacters,
    String? searchName,
    String? selectedGender,
    String? selectedRace,
    String? selectedAffiliation,
    List<Planet>? planets,
    int? planetCurrentPage,
    bool? hasNextPlanets,
    bool? isLoadingMorePlanets,
    String? planetSearchName,
    bool? Function()? isDestroyedFilter,
  }) {
    return DragonBallState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      characters: characters ?? this.characters,
      characterCurrentPage: characterCurrentPage ?? this.characterCurrentPage,
      hasNextCharacters: hasNextCharacters ?? this.hasNextCharacters,
      isLoadingMoreCharacters: isLoadingMoreCharacters ?? this.isLoadingMoreCharacters,
      searchName: searchName ?? this.searchName,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedRace: selectedRace ?? this.selectedRace,
      selectedAffiliation: selectedAffiliation ?? this.selectedAffiliation,
      planets: planets ?? this.planets,
      planetCurrentPage: planetCurrentPage ?? this.planetCurrentPage,
      hasNextPlanets: hasNextPlanets ?? this.hasNextPlanets,
      isLoadingMorePlanets: isLoadingMorePlanets ?? this.isLoadingMorePlanets,
      planetSearchName: planetSearchName ?? this.planetSearchName,
      isDestroyedFilter: isDestroyedFilter != null ? isDestroyedFilter() : this.isDestroyedFilter,
    );
  }
}

class DragonBallNotifier extends Notifier<DragonBallState> {
  // Reference to repository injected via ref.watch in build().
  late final DragonBallRepository _repository;

  // Lifecycle build method: called when provider is first initialized.
  @override
  DragonBallState build() {
    _repository = ref.watch(dbRepositoryProvider);
    Future.microtask(loadInitial);
    return DragonBallState.initial();
  }

  // Orchestrates parallel initial fetch of both characters and planets using Dart records.
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final (charResult, planetResult) = await (
      _repository.fetchCharacters(page: 1, limit: 10),
      _repository.fetchPlanets(page: 1, limit: 10),
    ).wait;

    if (charResult case Err(:final failure)) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
      return;
    }

    final charData = (charResult as Ok<Page<Character>, Failure>).value;
    final planetData = switch (planetResult) {
      Ok(:final value) => value,
      Err() => Page<Planet>.empty(),
    };

    state = state.copyWith(
      isLoading: false,
      characters: charData.items,
      characterCurrentPage: charData.currentPage,
      hasNextCharacters: charData.hasNext,
      planets: planetData.items,
      planetCurrentPage: planetData.currentPage,
      hasNextPlanets: planetData.hasNext,
    );
  }

  // Refetches characters when search or filter chips change
  Future<void> applyCharacterFilters({
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {
    final updatedState = state.copyWith(
      searchName: name ?? state.searchName,
      selectedGender: gender ?? state.selectedGender,
      selectedRace: race ?? state.selectedRace,
      selectedAffiliation: affiliation ?? state.selectedAffiliation,
      isLoading: true,
      errorMessage: null,
    );
    state = updatedState;

    final result = await _repository.fetchCharacters(
      page: 1,
      limit: 10,
      name: updatedState.searchName,
      gender: updatedState.selectedGender,
      race: updatedState.selectedRace,
      affiliation: updatedState.selectedAffiliation,
    );

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          isLoading: false,
          characters: value.items,
          characterCurrentPage: value.currentPage,
          hasNextCharacters: value.hasNext,
        );
      case Err(:final failure):
        state = state.copyWith(
          isLoading: false,
          characters: [],
          hasNextCharacters: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> applyPlanetFilters({
    String? name,
    bool? Function()? isDestroyed,
  }) async {
    final updatedState = state.copyWith(
      planetSearchName: name ?? state.planetSearchName,
      isDestroyedFilter: isDestroyed,
      isLoading: true,
      errorMessage: null,
    );
    state = updatedState;

    final result = await _repository.fetchPlanets(
      page: 1,
      limit: 10,
      name: updatedState.planetSearchName,
      isDestroyed: updatedState.isDestroyedFilter,
    );

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          isLoading: false,
          planets: value.items,
          planetCurrentPage: value.currentPage,
          hasNextPlanets: value.hasNext,
        );
      case Err(:final failure):
        state = state.copyWith(
          isLoading: false,
          planets: [],
          hasNextPlanets: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadNextCharacters() async {
    // Stop if filtering is active (backend returns full list with no pagination)
    if (state.hasActiveCharacterFilters) return;
    if (!state.hasNextCharacters || state.isLoadingMoreCharacters) return;

    state = state.copyWith(isLoadingMoreCharacters: true);
    final nextPage = state.characterCurrentPage + 1;
    final result = await _repository.fetchCharacters(page: nextPage, limit: 10);

    if (result case Ok(:final value)) {
      state = state.copyWith(
        characters: [...state.characters, ...value.items],
        characterCurrentPage: value.currentPage,
        hasNextCharacters: value.hasNext,
        isLoadingMoreCharacters: false,
      );
    } else {
      state = state.copyWith(isLoadingMoreCharacters: false);
    }
  }

  Future<void> loadNextPlanets() async {
    // Stop if filtering is active (backend returns full list with no pagination)
    if (state.hasActivePlanetFilters) return;
    if (!state.hasNextPlanets || state.isLoadingMorePlanets) return;

    state = state.copyWith(isLoadingMorePlanets: true);
    final nextPage = state.planetCurrentPage + 1;
    final result = await _repository.fetchPlanets(page: nextPage, limit: 10);

    if (result case Ok(:final value)) {
      state = state.copyWith(
        planets: [...state.planets, ...value.items],
        planetCurrentPage: value.currentPage,
        hasNextPlanets: value.hasNext,
        isLoadingMorePlanets: false,
      );
    } else {
      state = state.copyWith(isLoadingMorePlanets: false);
    }
  }

  void resetCharacterFilters() {
    applyCharacterFilters(name: '', gender: 'ALL', race: 'ALL', affiliation: 'ALL');
  }

  void resetPlanetFilters() {
    applyPlanetFilters(name: '', isDestroyed: () => null);
  }
}

final CharacterProfileProvider =
    FutureProvider.family<CharacterProfile, int>((ref, id) async {
  final repo = ref.watch(dbRepositoryProvider);
  final result = await repo.fetchCharacterProfile(id);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw Exception(failure.message),
  };
});