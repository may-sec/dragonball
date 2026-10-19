import 'package:dragonball_app/core/errors/failure.dart';
import 'package:dragonball_app/core/result/result.dart';
import 'package:dragonball_app/features/dragonball/models/dragonball_models.dart';
import 'package:dragonball_app/features/dragonball/models/paginated_response.dart';
import 'package:dragonball_app/features/dragonball/presentation/catalog_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// LEARN (testing without a network, a disk or Riverpod): loadCatalogSection
// receives `fetch` and `readCached` as ARGUMENTS, so a test passes tiny fake
// functions. That is dependency injection at its simplest: no mocking library.

Character char(
  int id,
  String name, {
  String race = 'Saiyan',
  String affiliation = 'Z Fighter',
  String gender = 'Male',
}) {
  return Character(
    id: id,
    name: name,
    ki: '0',
    maxKi: '0',
    race: race,
    gender: gender,
    description: '',
    imageUrl: '',
    affiliation: affiliation,
  );
}

Page<Character> pageOf(int page, int total, List<Character> items) {
  return Page<Character>(
    items: items,
    currentPage: page,
    totalPages: total,
    hasNext: page < total,
  );
}

Result<Page<Character>, Failure> ok(Page<Character> page) =>
    Ok<Page<Character>, Failure>(page);

Result<Page<Character>, Failure> err(Failure failure) =>
    Err<Page<Character>, Failure>(failure);

void main() {
  group('loadCatalogSection', () {
    test('loads every page in order and reports complete', () async {
      final section = await loadCatalogSection<Character>(
        network: true,
        idOf: (c) => c.id,
        fetch: (page) async => ok(pageOf(page, 3, [char(page * 10, 'C$page')])),
        readCached: (_) async => null,
      );

      expect(section.items.map((c) => c.id), [10, 20, 30]);
      expect(section.isComplete, isTrue);
      expect(section.failure, isNull);
    });

    test('removes duplicates when pages overlap', () async {
      final section = await loadCatalogSection<Character>(
        network: true,
        idOf: (c) => c.id,
        fetch: (page) async => ok(
          pageOf(page, 2, [char(1, 'Same'), char(page + 1, 'P$page')]),
        ),
        readCached: (_) async => null,
      );

      expect(section.items.map((c) => c.id), [1, 2, 3]);
    });

    test('a failed page with no cache makes the section incomplete', () async {
      final section = await loadCatalogSection<Character>(
        network: true,
        idOf: (c) => c.id,
        fetch: (page) async => page == 2
            ? err(const ServerFailure('boom', 500))
            : ok(pageOf(page, 3, [char(page * 10, 'C$page')])),
        readCached: (_) async => null,
      );

      expect(section.items.map((c) => c.id), [10, 30]);
      expect(section.isComplete, isFalse);
      expect(section.failure, isA<ServerFailure>());
    });

    test('after a NetworkFailure the remaining pages skip the network',
        () async {
      var fetchCalls = 0;

      final section = await loadCatalogSection<Character>(
        network: true,
        idOf: (c) => c.id,
        fetch: (page) async {
          fetchCalls++;
          return err(const NetworkFailure('offline'));
        },
        readCached: (page) async => pageOf(page, 3, [char(page * 10, 'C$page')]),
      );

      expect(fetchCalls, 1);
      expect(section.items.map((c) => c.id), [10, 20, 30]);
      expect(section.isComplete, isTrue);
      expect(section.failure, isA<NetworkFailure>());
    });

    test('cache-only mode never calls fetch and a miss is not an error',
        () async {
      var fetchCalls = 0;

      final section = await loadCatalogSection<Character>(
        network: false,
        idOf: (c) => c.id,
        fetch: (page) async {
          fetchCalls++;
          return err(const NetworkFailure('should not be called'));
        },
        readCached: (_) async => null,
      );

      expect(fetchCalls, 0);
      expect(section.isEmpty, isTrue);
      expect(section.failure, isNull);
      expect(section.isComplete, isFalse);
    });
  });

  group('filters', () {
    final all = [
      char(1, 'Goku'),
      char(2, 'Piccolo', race: 'Namekian', affiliation: 'Z Fighter'),
      char(3, 'Frieza', race: 'Frieza Race', affiliation: 'Army of Frieza'),
      char(4, 'Bulma', race: 'Human', gender: 'Female'),
    ];

    test('no filters returns everything', () {
      expect(filterCharacters(all).length, 4);
    });

    test('name search is case-insensitive and trimmed', () {
      expect(filterCharacters(all, name: '  GOK ').map((c) => c.id), [1]);
    });

    test('race and gender combine with AND', () {
      final result = filterCharacters(all, race: 'human', gender: 'Female');
      expect(result.map((c) => c.id), [4]);
    });

    test('planet destroyed filter', () {
      const planets = [
        Planet(
          id: 1,
          name: 'Namek',
          isDestroyed: true,
          description: '',
          imageUrl: '',
        ),
        Planet(
          id: 2,
          name: 'Earth',
          isDestroyed: false,
          description: '',
          imageUrl: '',
        ),
      ];

      expect(filterPlanets(planets, isDestroyed: true).map((p) => p.id), [1]);
      expect(filterPlanets(planets, name: 'ear').map((p) => p.id), [2]);
    });
  });

  group('isCatalogStale', () {
    final now = DateTime(2026, 10, 17, 12);

    test('never validated is stale', () {
      expect(isCatalogStale(null, now: now), isTrue);
    });

    test('recent is fresh, old is stale', () {
      expect(
        isCatalogStale(now.subtract(const Duration(hours: 1)), now: now),
        isFalse,
      );
      expect(
        isCatalogStale(now.subtract(const Duration(hours: 4)), now: now),
        isTrue,
      );
    });

    test('a timestamp in the future (clock changed) is not trusted', () {
      expect(
        isCatalogStale(now.add(const Duration(hours: 1)), now: now),
        isTrue,
      );
    });
  });
}