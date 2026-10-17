import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/result/result.dart';
import '../../../core/utils/ki_parser.dart';
import '../../dragonball/models/dragonball_models.dart';
import '../../dragonball/models/paginated_response.dart';
import '../../dragonball/presentation/dragonball_notifier.dart';

// LEARN (Riverpod, the big idea of this file): ONE source of truth, then
// small DERIVED providers on top of it.
//
//   allCharactersProvider      (network/cache, all 58 characters, loaded once)
//        |
//        +--> exploreGroupsProvider   (race/affiliation chips + counts)
//        +--> exploreVisibleProvider  (filtered + searched + sorted list)
//             ^
//   exploreSelectionProvider (mode, group, query, sort chosen by the user)
//
// Groups come from the REAL data, so a new race added to the API appears as
// a chip automatically. A hardcoded list can never get out of sync.

enum ExploreMode { all, race, affiliation }

extension ExploreModeLabel on ExploreMode {
  String label(AppStrings s) => switch (this) {
        ExploreMode.all => s.modeAll,
        ExploreMode.race => s.modeRace,
        ExploreMode.affiliation => s.modeAffiliation,
      };
}

enum ExploreSort { nameAsc, nameDesc, kiDesc }

// ---------------------------------------------------------------------------
// 1) Load every character (all pages), with offline fallback
// ---------------------------------------------------------------------------

final allCharactersProvider = FutureProvider<List<Character>>((ref) async {
  final repo = ref.watch(dragonBallRepositoryProvider);

  // A Map keyed by id removes duplicates if pages overlap.
  final byId = <int, Character>{};
  Failure? lastFailure;

  // The upper bound (50 pages) protects against an infinite loop if the API
  // ever keeps answering hasNext = true.
  for (var pageNumber = 1; pageNumber <= 50; pageNumber++) {
    final result = await repo.fetchCharacters(page: pageNumber, limit: 10);

    Page<Character>? page;
    switch (result) {
      case Ok(:final value):
        page = value;
      case Err(:final failure):
        lastFailure = failure;
    }

    // Offline fallback: the repository already wrote every successful page
    // to the JSON cache, so a failed request can be served from disk.
    page ??= await repo.readCachedCharacters(page: pageNumber, limit: 10);

    if (page == null) {
      if (byId.isEmpty) {
        throw DragonBallRequestException(
          lastFailure ?? const UnknownFailure('No data is available.'),
        );
      }
      break; // keep the pages we already have
    }

    for (final character in page.items) {
      byId[character.id] = character;
    }
    if (!page.hasNext) break;
  }

  return byId.values.toList(growable: false);
});

// ---------------------------------------------------------------------------
// 2) What the user selected
// ---------------------------------------------------------------------------

@immutable
class ExploreSelection {
  const ExploreSelection({
    this.mode = ExploreMode.all,
    this.group, // null = "all races" / "all affiliations"
    this.query = '',
    this.sort = ExploreSort.nameAsc,
  });

  final ExploreMode mode;
  final String? group;
  final String query;
  final ExploreSort sort;

  // `group` is nullable on purpose, so "keep the old value" and "set to
  // null" need different signals: that is what clearGroup is for.
  ExploreSelection copyWith({
    ExploreMode? mode,
    String? group,
    bool clearGroup = false,
    String? query,
    ExploreSort? sort,
  }) {
    return ExploreSelection(
      mode: mode ?? this.mode,
      group: clearGroup ? null : (group ?? this.group),
      query: query ?? this.query,
      sort: sort ?? this.sort,
    );
  }
}

final exploreSelectionProvider =
    NotifierProvider<ExploreSelectionController, ExploreSelection>(
  ExploreSelectionController.new,
);

class ExploreSelectionController extends Notifier<ExploreSelection> {
  @override
  ExploreSelection build() => const ExploreSelection();

  /// Changing the mode resets the group (a "Saiyan" chip means nothing
  /// under Affiliation) but keeps the search text and the sort.
  void setMode(ExploreMode mode) {
    state = ExploreSelection(mode: mode, query: state.query, sort: state.sort);
  }

  void setGroup(String? group) {
    state = state.copyWith(group: group, clearGroup: group == null);
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSort(ExploreSort sort) => state = state.copyWith(sort: sort);

  /// Used by breadcrumb taps: show exactly this group, search cleared.
  void jumpTo({required ExploreMode mode, String? group}) {
    state = ExploreSelection(mode: mode, group: group, sort: state.sort);
  }

  void reset() => state = ExploreSelection(sort: state.sort);
}

// ---------------------------------------------------------------------------
// 3) Derived data
// ---------------------------------------------------------------------------

typedef GroupCount = ({String label, int count}); // a Dart 3 record

/// Chips for the current mode: label + how many characters.
final exploreGroupsProvider = Provider<List<GroupCount>>((ref) {
  final all = ref.watch(allCharactersProvider).asData?.value ??
      const <Character>[];
  final mode = ref.watch(exploreSelectionProvider.select((s) => s.mode));

  if (mode == ExploreMode.all) return const [];

  final counts = <String, int>{};
  for (final c in all) {
    final key = mode == ExploreMode.race ? c.race : c.affiliation;
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final groups = [
    for (final e in counts.entries) (label: e.key, count: e.value),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.label.compareTo(b.label);
    });

  return groups;
});

/// The list shown on screen. Riverpod caches the result: sorting runs only
/// when the data or the selection changes, NOT on every widget rebuild
/// (the old home screen sorted inside build()).
final exploreVisibleProvider = Provider<List<Character>>((ref) {
  final all = ref.watch(allCharactersProvider).asData?.value ??
      const <Character>[];
  final sel = ref.watch(exploreSelectionProvider);
  final query = sel.query.trim().toLowerCase();

  final list = all.where((c) {
    final inGroup = switch (sel.mode) {
      ExploreMode.all => true,
      ExploreMode.race => sel.group == null || c.race == sel.group,
      ExploreMode.affiliation =>
        sel.group == null || c.affiliation == sel.group,
    };
    return inGroup && (query.isEmpty || c.name.toLowerCase().contains(query));
  }).toList();

  switch (sel.sort) {
    case ExploreSort.nameAsc:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case ExploreSort.nameDesc:
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case ExploreSort.kiDesc:
      // Parse each ki string ONCE, not on every comparison.
      final power = {for (final c in list) c.id: powerOf(c.ki, c.maxKi)};
      list.sort((a, b) => power[b.id]!.compareTo(power[a.id]!));
  }

  return list;
});