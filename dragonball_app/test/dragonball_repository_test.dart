import 'dart:convert';
import 'dart:io';

import 'package:dragonball_app/core/errors/failure.dart';
import 'package:dragonball_app/core/network/api_endpoints.dart';
import 'package:dragonball_app/core/result/result.dart';
import 'package:dragonball_app/features/dragonball/data/dragonball_repository.dart';
import 'package:dragonball_app/features/dragonball/data/json_response_cache.dart';
import 'package:dragonball_app/features/dragonball/models/dragonball_models.dart';
import 'package:dragonball_app/features/dragonball/models/paginated_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// LEARN (testing HTTP without a server): package:http/testing gives MockClient,
// a client whose answers are a function you write. The repository receives the
// client and the cache through its constructor, so a test replaces both:
// nothing touches the network or the disk.

class MemoryStore implements JsonCacheStore {
  final Map<String, CachedJsonResponse> entries = {};

  @override
  Future<CachedJsonResponse?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, String body, {String? etag}) async {
    entries[key] = CachedJsonResponse(
      body: body,
      cachedAt: DateTime.now(),
      etag: etag,
    );
  }

  @override
  Future<void> delete(String key) async => entries.remove(key);

  @override
  Future<void> clear() async => entries.clear();

  @override
  Future<JsonResponseCacheStats> stats() async => JsonResponseCacheStats(
        fileCount: entries.length,
        totalBytes: entries.values.fold(0, (sum, e) => sum + e.body.length),
      );
}

String charactersBody() => jsonEncode({
      'items': [
        {
          'id': 1,
          'name': 'Goku',
          'ki': '60.000.000',
          'maxKi': '90 Septillion',
          'race': 'Saiyan',
          'gender': 'Male',
          'description': 'x',
          'image': 'u',
          'affiliation': 'Z Fighter',
        },
      ],
      'meta': {'currentPage': 1, 'totalPages': 1},
      'links': {'next': ''},
    });

Page<Character> pageOrFail(Result<Page<Character>, Failure> result) {
  return result.fold<Page<Character>>(
    onSuccess: (page) => page,
    onFailure: (failure) => fail('Expected success, got ${failure.message}'),
  );
}

Failure failureOrFail(Result<Page<Character>, Failure> result) {
  return result.fold<Failure>(
    onSuccess: (_) => fail('Expected a failure'),
    onFailure: (failure) => failure,
  );
}

void main() {
  late MemoryStore store;
  late String key;

  setUp(() {
    store = MemoryStore();
    key = ApiEndpoints.characters({'page': '1', 'limit': '10'}).toString();
  });

  DragonBallRepository makeRepository(MockClient client, {bool isWeb = false}) {
    return DragonBallRepository(
      client,
      cache: JsonResponseCache(store),
      isWeb: isWeb,
    );
  }

  group('conditional requests (Android)', () {
    test('stores the ETag, sends it back, and reuses the body on 304', () async {
      final requests = <http.Request>[];

      final client = MockClient((request) async {
        requests.add(request);

        if (request.headers.containsKey('If-None-Match')) {
          return http.Response('', 304);
        }

        return http.Response(
          charactersBody(),
          200,
          headers: {'etag': 'W/"abc"'},
        );
      });

      final repository = makeRepository(client);

      final first = pageOrFail(await repository.fetchCharacters());
      final second = pageOrFail(await repository.fetchCharacters());

      expect(requests.length, 2);
      expect(requests[0].headers.containsKey('If-None-Match'), isFalse);
      expect(requests[1].headers['If-None-Match'], 'W/"abc"');

      expect(first.items.single.name, 'Goku');
      expect(second.items.single.name, 'Goku');
      expect(store.entries[key]?.etag, 'W/"abc"');
    });

    test('a 200 after a changed ETag replaces the cached body', () async {
      var version = 1;

      final client = MockClient((request) async {
        final name = version == 1 ? 'Goku' : 'Kakarot';
        final body = charactersBody().replaceFirst('Goku', name);

        return http.Response(body, 200, headers: {'etag': 'W/"v$version"'});
      });

      final repository = makeRepository(client);

      await repository.fetchCharacters();
      version = 2;
      final updated = pageOrFail(await repository.fetchCharacters());

      expect(updated.items.single.name, 'Kakarot');
      expect(store.entries[key]?.etag, 'W/"v2"');
    });
  });

  group('web mode', () {
    test('sends no validator, bypasses the browser cache, keeps a clean key',
        () async {
      late http.Request seen;

      final client = MockClient((request) async {
        seen = request;
        return http.Response(charactersBody(), 200);
      });

      // Seed an ETag: web must still NOT send it.
      await store.write(key, charactersBody(), etag: 'W/"old"');

      final repository = makeRepository(client, isWeb: true);
      await repository.fetchCharacters();

      expect(seen.headers.containsKey('If-None-Match'), isFalse);
      expect(seen.url.queryParameters.containsKey(kWebCacheBusterParam), isTrue);
      expect(seen.url.queryParameters['page'], '1');

      // The cache key never contains the buster.
      expect(store.entries.keys.single, key);
    });
  });

  group('failures', () {
    test('an HTTP 500 is a ServerFailure and nothing is cached', () async {
      final client = MockClient((_) async => http.Response('oops', 500));
      final repository = makeRepository(client);

      final failure = failureOrFail(await repository.fetchCharacters());

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
      expect(store.entries, isEmpty);
    });

    test('invalid JSON is a ParseFailure and is never cached', () async {
      final client = MockClient((_) async => http.Response('{bad', 200));
      final repository = makeRepository(client);

      final failure = failureOrFail(await repository.fetchCharacters());

      expect(failure, isA<ParseFailure>());
      expect(failure.message, contains('not valid JSON'));
      expect(store.entries, isEmpty);
    });

    test('a wrong shape says so instead of blaming JSON syntax', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'items': 5}), 200),
      );
      final repository = makeRepository(client);

      final failure = failureOrFail(await repository.fetchCharacters());

      expect(failure, isA<ParseFailure>());
      expect(failure.message, contains('items list'));
    });

    test('a socket error is a NetworkFailure', () async {
      final client = MockClient((_) async => throw const SocketException('down'));
      final repository = makeRepository(client);

      final failure = failureOrFail(await repository.fetchCharacters());

      expect(failure, isA<NetworkFailure>());
    });
  });

  group('cache-only reads', () {
    test('readCachedCharacters parses what a fetch stored, without network',
        () async {
      var calls = 0;

      final client = MockClient((_) async {
        calls++;
        return http.Response(charactersBody(), 200);
      });

      final repository = makeRepository(client);
      await repository.fetchCharacters();

      final cached = await repository.readCachedCharacters();

      expect(calls, 1);
      expect(cached?.items.single.name, 'Goku');
    });

    test('a cache miss is null, not an error', () async {
      final repository = makeRepository(MockClient((_) async => fail('no call')));

      expect(await repository.readCachedCharacters(), isNull);
    });
  });
}