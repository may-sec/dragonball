import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failure.dart';
import '../../../core/platform/experience_policy.dart';
import '../../../core/result/result.dart';
import '../data/dragonball_repository.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';
import 'dragonball_core_providers.dart';

// =============================================================================
// LEARN (the idea of this file): ONE source of truth for characters + planets.
//
//   * The whole catalogue (~58 characters, a few planets) is small, so we load
//     ALL of it once and filter/search LOCALLY. Typing in a search box makes
//     zero network calls, and there is no infinite scroll to retry in a loop.
//   * Stale-while-revalidate: show what is on disk immediately, then check the
//     server in the background, at most once every kCatalogRevalidateInterval.
//   * The data carries its own metadata (isComplete, failure, lastValidatedAt)
//     so the UI can be honest instead of silently showing partial data.
//   * The loading logic is a PURE function (loadCatalogSection) that receives
//     its dependencies as arguments, so it can be unit tested without a
//     network, a disk or Riverpod.
// =============================================================================

/// If the API accepts a larger `limit`, raise this: fewer pages, fewer requests.
const int kCatalogPageSize = 10;

/// Safety cap against an API that keeps claiming there are more pages.
const int kCatalogMaxPages = 50;

/// How many page requests run at the same time (polite to the API: 429s).
const int kCatalogParallelism = 4;

/// Automatic background checks happen at most this often.
/// Pull-to-refresh and retry buttons always check immediately.
const Duration kCatalogRevalidateInterval = Duration(hours: 3);

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

@immutable
final class CatalogSection<T> {
  const CatalogSection({
    this.items = const [],
    this.loadedPages = 0,
    this.expectedPages = 0,
    this.failure,
  });

  final List<T> items;
  final int loadedPages;

  /// What the API said (meta.totalPages). 0 = we never reached any page.
  final int expectedPages;

  /// Last problem met while loading. Data can exist AND a failure can be set:
  /// that means "showing saved data, could not check the server".
  final Failure? failure;

  bool get isEmpty => items.isEmpty;

  bool get isComplete => expectedPages > 0 && loadedPages >= expectedPages;

  CatalogSection<T> withFailure(Failure? value) => CatalogSection<T>(
        items: items,
        loadedPages: loadedPages,
        expectedPages: expectedPages,
        failure: value,
      );
}

@immutable
final class CatalogSnapshot {
  const CatalogSnapshot({
    required this.characters,
    required this.planets,
    this.isRefreshing = false,
    this.lastValidatedAt,
  });

  const CatalogSnapshot.empty()
      : characters = const CatalogSection<Character>(),
        planets = const CatalogSection<Planet>(),
        isRefreshing = false,
        lastValidatedAt = null;

  final CatalogSection<Character> characters;
  final CatalogSection<Planet> planets;

  /// A background check is running right now.
  final bool isRefreshing;

  /// When the server last confirmed the data (null = never, this install).
  final DateTime? lastValidatedAt;

  bool get hasAnyData => characters.items.isNotEmpty || planets.items.isNotEmpty;

  bool get isComplete => characters.isComplete && planets.isComplete;

  bool get hasFailure => characters.failure != null || planets.failure != null;

  CatalogSnapshot copyWith({
    CatalogSection<Character>? characters,
    CatalogSection<Planet>? planets,
    bool? isRefreshing,
    DateTime? lastValidatedAt,
  }) {
    return CatalogSnapshot(
      characters: characters ?? this.characters,
      planets: planets ?? this.planets,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastValidatedAt: lastValidatedAt ?? this.lastValidatedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Pure functions (unit tested in test/catalog_loader_test.dart)
// ---------------------------------------------------------------------------

bool isCatalogStale(
  DateTime? lastValidatedAt, {
  DateTime? now,
  Duration maxAge = kCatalogRevalidateInterval,
}) {
  if (lastValidatedAt == null) return true;

  final age = (now ?? DateTime.now()).difference(lastValidatedAt);

  // A negative age means the clock moved backwards: do not trust the stamp.
  return age.isNegative || age > maxAge;
}

/// Loads every page of one list.
///
/// * network = true : ask the server; a page that fails falls back to disk.
/// * network = false: disk only (a missing page is NOT an error).
///
/// Once a NetworkFailure happens, the remaining pages skip the network, so an
/// offline launch does not wait for six timeouts in a row.
Future<CatalogSection<T>> loadCatalogSection<T>({
  required Future<Result<Page<T>, Failure>> Function(int page) fetch,
  required Future<Page<T>?> Function(int page) readCached,
  required int Function(T item) idOf,
  required bool network,
  int parallelism = kCatalogParallelism,
}) async {
  Failure? failure;
  var networkDown = false;

  Future<Page<T>?> load(int page) async {
    if (!network || networkDown) return readCached(page);

    final result = await fetch(page);

    switch (result) {
      case Ok(:final value):
        return value;
      case Err(failure: final problem):
        failure ??= problem;
        if (problem is NetworkFailure) networkDown = true;
        return readCached(page);
    }
  }

  final first = await load(1);

  if (first == null) {
    return CatalogSection<T>(failure: failure);
  }

  final totalPages = first.totalPages.clamp(1, kCatalogMaxPages).toInt();

  // A Map keyed by id removes duplicates if pages overlap and keeps the
  // insertion (= page) order.
  final byId = <int, T>{
    for (final item in first.items) idOf(item): item,
  };
  var loadedPages = 1;

  final remaining = [for (var page = 2; page <= totalPages; page++) page];

  for (var i = 0; i < remaining.length; i += parallelism) {
    final batch = remaining.skip(i).take(parallelism);
    final pages = await Future.wait(batch.map(load));

    for (final page in pages) {
      if (page == null) continue;

      loadedPages++;
      for (final item in page.items) {
        byId[idOf(item)] = item;
      }
    }
  }

  return CatalogSection<T>(
    items: List<T>.unmodifiable(byId.values),
    loadedPages: loadedPages,
    expectedPages: totalPages,
    failure: failure,
  );
}

List<Character> filterCharacters(
  List<Character> all, {
  String name = '',
  String gender = 'ALL',
  String race = 'ALL',
  String affiliation = 'ALL',
}) {
  final query = name.trim().toLowerCase();

  bool matches(String value, String wanted) =>
      wanted == 'ALL' || value.toLowerCase() == wanted.toLowerCase();

  return [
    for (final c in all)
      if ((query.isEmpty || c.name.toLowerCase().contains(query)) &&
          matches(c.gender, gender) &&
          matches(c.race, race) &&
          matches(c.affiliation, affiliation))
        c,
  ];
}

List<Planet> filterPlanets(
  List<Planet> all, {
  String name = '',
  bool? isDestroyed,
}) {
  final query = name.trim().toLowerCase();

  return [
    for (final p in all)
      if ((query.isEmpty || p.name.toLowerCase().contains(query)) &&
          (isDestroyed == null || p.isDestroyed == isDestroyed))
        p,
  ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final catalogProvider =
    AsyncNotifierProvider<CatalogController, CatalogSnapshot>(
  CatalogController.new,
);

class CatalogController extends AsyncNotifier<CatalogSnapshot> {
  static const _validatedKey = 'catalog_last_validated_ms';

  // While a check is running, every caller shares the same Future. Two quick
  // taps on "retry" can never start two parallel waves of requests.
  Future<void>? _inFlight;

  DragonBallRepository get _repository =>
      ref.read(dragonBallRepositoryProvider);

  @override
  Future<CatalogSnapshot> build() async {
    final lastValidated = await _readLastValidated();

    // 1) Disk first: instant, works offline.
    final cached = (await _load(network: false))
        .copyWith(lastValidatedAt: lastValidated);

    if (cached.hasAnyData) {
      // Battery saver: do not START a background check for data that is
      // complete. An incomplete cache still checks, and a manual refresh
      // (pull to refresh, retry button) always works.
      final autoCheck = ref.read(experiencePolicyProvider).autoRevalidate;
      final needsCheck =
          !cached.isComplete || (autoCheck && isCatalogStale(lastValidated));

      if (needsCheck) {
        // Start after build() has returned, so we never write `state`
        // while build is still running.
        Future<void>.delayed(Duration.zero, () {
          if (ref.mounted) unawaited(_revalidate());
        });
      }

      return cached.copyWith(isRefreshing: needsCheck);
    }

    // 2) First launch (nothing on disk): we must wait for the network.
    final fresh = await _load(network: true);
    final validated = fresh.isComplete && !fresh.hasFailure;
    final now = DateTime.now();

    if (validated) await _writeLastValidated(now);

    final failure = fresh.characters.failure ?? fresh.planets.failure;
    if (failure != null) {
      ref.read(networkNoticeProvider.notifier).show(failure.message);
    }

    return validated ? fresh.copyWith(lastValidatedAt: now) : fresh;
  }

  /// Checks the server now.
  ///
  /// force = false: skipped when the data is complete and recently validated.
  /// force = true : pull-to-refresh / retry buttons.
  Future<void> refresh({bool force = true}) async {
    final current = state.asData?.value;

    // First launch is still loading: that request is already the refresh.
    if (current == null) return;

    if (!force &&
        current.isComplete &&
        !current.hasFailure &&
        !isCatalogStale(current.lastValidatedAt)) {
      return;
    }

    await _revalidate();
  }

  Future<void> _revalidate() {
    final running = _inFlight;
    if (running != null) return running;

    final future = _runRevalidate().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<void> _runRevalidate() async {
    if (!ref.mounted) return;

    final before = state.asData?.value ?? const CatalogSnapshot.empty();

    // Clear the old failure so a repeated failure is a visible CHANGE.
    state = AsyncData(
      before.copyWith(
        characters: before.characters.withFailure(null),
        planets: before.planets.withFailure(null),
        isRefreshing: true,
      ),
    );

    final fresh = await _load(network: true);

    if (!ref.mounted) return;

    final merged = CatalogSnapshot(
      characters: _pick(before.characters, fresh.characters),
      planets: _pick(before.planets, fresh.planets),
      lastValidatedAt: before.lastValidatedAt,
    );

    // Only a COMPLETE, failure-free pass proves "same as the server".
    final validated = merged.isComplete && !merged.hasFailure;
    final validatedAt = validated ? DateTime.now() : before.lastValidatedAt;

    if (validated && validatedAt != null) {
      await _writeLastValidated(validatedAt);
      if (!ref.mounted) return;
    }

    state = AsyncData(merged.copyWith(lastValidatedAt: validatedAt));

    final failure = merged.characters.failure ?? merged.planets.failure;
    if (failure != null && before.hasAnyData) {
      ref.read(networkNoticeProvider.notifier).show(failure.message);
    }
  }

  /// Never replace more data with less because a request failed.
  CatalogSection<T> _pick<T>(
    CatalogSection<T> previous,
    CatalogSection<T> fresh,
  ) {
    if (fresh.isComplete && fresh.failure == null) return fresh;

    final useFresh = fresh.items.length >= previous.items.length;
    final base = useFresh ? fresh : previous;

    return base.withFailure(fresh.failure);
  }

  Future<CatalogSnapshot> _load({required bool network}) async {
    // Start both lists at once, then wait for both.
    final charactersFuture = loadCatalogSection<Character>(
      network: network,
      idOf: (c) => c.id,
      fetch: (page) =>
          _repository.fetchCharacters(page: page, limit: kCatalogPageSize),
      readCached: (page) =>
          _repository.readCachedCharacters(page: page, limit: kCatalogPageSize),
    );

    final planetsFuture = loadCatalogSection<Planet>(
      network: network,
      idOf: (p) => p.id,
      fetch: (page) =>
          _repository.fetchPlanets(page: page, limit: kCatalogPageSize),
      readCached: (page) =>
          _repository.readCachedPlanets(page: page, limit: kCatalogPageSize),
    );

    return CatalogSnapshot(
      characters: await charactersFuture,
      planets: await planetsFuture,
    );
  }

  Future<DateTime?> _readLastValidated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_validatedKey);

      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLastValidated(DateTime value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_validatedKey, value.millisecondsSinceEpoch);
    } catch (_) {
      // Losing the stamp only means one extra background check later.
    }
  }
}