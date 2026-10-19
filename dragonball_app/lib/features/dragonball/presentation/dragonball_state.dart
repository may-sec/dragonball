import 'package:flutter/foundation.dart';

import '../models/dragonball_models.dart';

const Object _unset = Object();

/// What the home screen renders. Since the catalog refactor this is a VIEW of
/// the catalog (already filtered), not the place where data is loaded.
@immutable
final class DragonBallState {
  const DragonBallState({
    required this.characters,
    required this.characterCurrentPage,
    required this.hasNextCharacters,
    required this.isLoadingCharacters,
    required this.isLoadingMoreCharacters,
    required this.characterError,
    required this.searchName,
    required this.selectedGender,
    required this.selectedRace,
    required this.selectedAffiliation,
    required this.planets,
    required this.planetCurrentPage,
    required this.hasNextPlanets,
    required this.isLoadingPlanets,
    required this.isLoadingMorePlanets,
    required this.planetError,
    required this.planetSearchName,
    required this.isDestroyedFilter,
    this.isRefreshing = false,
    this.catalogIsComplete = true,
    this.lastValidatedAt,
  });

  final List<Character> characters;
  final int characterCurrentPage;
  final bool hasNextCharacters;
  final bool isLoadingCharacters;
  final bool isLoadingMoreCharacters;
  final String? characterError;

  final String searchName;
  final String selectedGender;
  final String selectedRace;
  final String selectedAffiliation;

  final List<Planet> planets;
  final int planetCurrentPage;
  final bool hasNextPlanets;
  final bool isLoadingPlanets;
  final bool isLoadingMorePlanets;
  final String? planetError;

  final String planetSearchName;
  final bool? isDestroyedFilter;

  /// A background check against the server is running.
  final bool isRefreshing;

  /// false = some pages are missing (offline / failed), data is partial.
  final bool catalogIsComplete;

  /// When the server last confirmed the data. null = not this install yet.
  final DateTime? lastValidatedAt;

  bool get hasActiveCharacterFilters =>
      searchName.trim().isNotEmpty ||
      selectedGender != 'ALL' ||
      selectedRace != 'ALL' ||
      selectedAffiliation != 'ALL';

  bool get hasActivePlanetFilters =>
      planetSearchName.trim().isNotEmpty || isDestroyedFilter != null;

  factory DragonBallState.initial() {
    return const DragonBallState(
      characters: [],
      characterCurrentPage: 1,
      hasNextCharacters: false,
      isLoadingCharacters: false,
      isLoadingMoreCharacters: false,
      characterError: null,
      searchName: '',
      selectedGender: 'ALL',
      selectedRace: 'ALL',
      selectedAffiliation: 'ALL',
      planets: [],
      planetCurrentPage: 1,
      hasNextPlanets: false,
      isLoadingPlanets: false,
      isLoadingMorePlanets: false,
      planetError: null,
      planetSearchName: '',
      isDestroyedFilter: null,
    );
  }

  DragonBallState copyWith({
    List<Character>? characters,
    int? characterCurrentPage,
    bool? hasNextCharacters,
    bool? isLoadingCharacters,
    bool? isLoadingMoreCharacters,
    Object? characterError = _unset,
    String? searchName,
    String? selectedGender,
    String? selectedRace,
    String? selectedAffiliation,
    List<Planet>? planets,
    int? planetCurrentPage,
    bool? hasNextPlanets,
    bool? isLoadingPlanets,
    bool? isLoadingMorePlanets,
    Object? planetError = _unset,
    String? planetSearchName,
    Object? isDestroyedFilter = _unset,
    bool? isRefreshing,
    bool? catalogIsComplete,
    Object? lastValidatedAt = _unset,
  }) {
    return DragonBallState(
      characters: characters ?? this.characters,
      characterCurrentPage: characterCurrentPage ?? this.characterCurrentPage,
      hasNextCharacters: hasNextCharacters ?? this.hasNextCharacters,
      isLoadingCharacters: isLoadingCharacters ?? this.isLoadingCharacters,
      isLoadingMoreCharacters:
          isLoadingMoreCharacters ?? this.isLoadingMoreCharacters,
      characterError: identical(characterError, _unset)
          ? this.characterError
          : characterError as String?,
      searchName: searchName ?? this.searchName,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedRace: selectedRace ?? this.selectedRace,
      selectedAffiliation: selectedAffiliation ?? this.selectedAffiliation,
      planets: planets ?? this.planets,
      planetCurrentPage: planetCurrentPage ?? this.planetCurrentPage,
      hasNextPlanets: hasNextPlanets ?? this.hasNextPlanets,
      isLoadingPlanets: isLoadingPlanets ?? this.isLoadingPlanets,
      isLoadingMorePlanets: isLoadingMorePlanets ?? this.isLoadingMorePlanets,
      planetError: identical(planetError, _unset)
          ? this.planetError
          : planetError as String?,
      planetSearchName: planetSearchName ?? this.planetSearchName,
      isDestroyedFilter: identical(isDestroyedFilter, _unset)
          ? this.isDestroyedFilter
          : isDestroyedFilter as bool?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      catalogIsComplete: catalogIsComplete ?? this.catalogIsComplete,
      lastValidatedAt: identical(lastValidatedAt, _unset)
          ? this.lastValidatedAt
          : lastValidatedAt as DateTime?,
    );
  }
}