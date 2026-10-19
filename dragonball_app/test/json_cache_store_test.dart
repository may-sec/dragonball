import 'dart:convert';
import 'dart:io';

import 'package:dragonball_app/features/dragonball/data/file_json_cache_store.dart';
import 'package:dragonball_app/features/dragonball/data/json_cache_store.dart';
import 'package:dragonball_app/features/dragonball/data/prefs_json_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LEARN (testing a storage backend): both stores must obey the SAME contract,
// so several tests below are the same idea run against each. The clock is
// injected, so "older" and "newer" are exact instead of depending on how fast
// the test machine writes.

String body(int n) => jsonEncode({'value': n});

void main() {
  group('envelope', () {
    test('round trip keeps body, time and etag', () {
      final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final raw = encodeCacheEnvelope(body: body(1), cachedAt: at, etag: 'abc');

      final decoded = decodeCacheEnvelope(raw)!;

      expect(decoded.body, body(1));
      expect(decoded.cachedAt, at);
      expect(decoded.etag, 'abc');
    });

    test('an entry without a version is treated as version 1', () {
      final legacy = jsonEncode({'cachedAt': 1, 'body': body(2)});

      expect(decodeCacheEnvelope(legacy), isNotNull);
    });

    test('another version is rejected', () {
      final future = jsonEncode({'v': 99, 'cachedAt': 1, 'body': body(3)});

      expect(decodeCacheEnvelope(future), isNull);
    });

    test('garbage and invalid bodies are rejected', () {
      expect(decodeCacheEnvelope('not json'), isNull);
      expect(
        decodeCacheEnvelope(jsonEncode({'cachedAt': 1, 'body': '{oops'})),
        isNull,
      );
    });
  });

  group('PrefsJsonCacheStore (web)', () {
    late DateTime now;

    setUp(() {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      now = DateTime(2026, 1, 1);
    });

    PrefsJsonCacheStore makeStore({int maxEntries = 300}) {
      return PrefsJsonCacheStore(
        maxEntries: maxEntries,
        clock: () {
          now = now.add(const Duration(seconds: 1));
          return now;
        },
      );
    }

    test('write then read returns the body and etag', () async {
      final store = makeStore();

      await store.write('k', body(1), etag: 'v1');
      final read = await store.read('k');

      expect(read?.body, body(1));
      expect(read?.etag, 'v1');
    });

    test('invalid JSON is never stored', () async {
      final store = makeStore();

      await store.write('k', '{broken');

      expect(await store.read('k'), isNull);
    });

    test('an entry of another version is dropped on read', () async {
      final storageKey = '${PrefsJsonCacheStore.keyPrefix}${cacheKeyHash('k')}';

      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues(<String, Object>{
        storageKey: jsonEncode({'v': 99, 'cachedAt': 1, 'body': body(1)}),
      });

      final store = makeStore();

      expect(await store.read('k'), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(storageKey), isFalse);
    });

    test('evicts the oldest entries when over the entry budget', () async {
      final store = makeStore(maxEntries: 3);

      for (var i = 0; i < 5; i++) {
        await store.write('k$i', body(i));
      }

      expect(await store.read('k0'), isNull);
      expect(await store.read('k1'), isNull);
      expect(await store.read('k2'), isNotNull);
      expect(await store.read('k3'), isNotNull);
      expect(await store.read('k4'), isNotNull);
    });

    test('clear removes cache entries but not other preferences', () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_theme_mode': 'dark',
      });

      final store = makeStore();
      await store.write('k', body(1));

      await store.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(await store.read('k'), isNull);
      expect(prefs.getString('app_theme_mode'), 'dark');
      expect((await store.stats()).fileCount, 0);
    });
  });

  group('FileJsonCacheStore (Android)', () {
    late Directory temp;
    late DateTime now;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('json_cache_test');
      now = DateTime(2026, 1, 1);
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    FileJsonCacheStore makeStore({int maxFiles = 400}) {
      return FileJsonCacheStore(
        directoryProvider: () async => temp,
        maxFiles: maxFiles,
        pruneEvery: 1,
        clock: () {
          now = now.add(const Duration(seconds: 1));
          return now;
        },
      );
    }

    test('write then read returns the body and etag', () async {
      final store = makeStore();

      await store.write('k', body(1), etag: 'v1');
      final read = await store.read('k');

      expect(read?.body, body(1));
      expect(read?.etag, 'v1');
    });

    test('leaves no temporary file behind (atomic write)', () async {
      final store = makeStore();

      await store.write('k', body(1));

      final names = [
        for (final e in temp.listSync()) e.path.split(Platform.pathSeparator).last,
      ];

      expect(names.any((n) => n.endsWith('.tmp')), isFalse);
      expect(names.where((n) => n.endsWith('.json')).length, 1);
    });

    test('a corrupted file reads as null and is deleted', () async {
      final store = makeStore();
      await store.write('k', body(1));

      final file = temp
          .listSync()
          .whereType<File>()
          .firstWhere((f) => f.path.endsWith('.json'));
      await file.writeAsString('{{{ not json');

      expect(await store.read('k'), isNull);
      expect(file.existsSync(), isFalse);
    });

    test('prunes the oldest files when over the file budget', () async {
      final store = makeStore(maxFiles: 5);

      for (var i = 0; i < 6; i++) {
        await store.write('k$i', body(i));
      }

      // 6 files > 5 allowed: trimmed to 80% of 5 = 4, oldest first.
      expect(await store.read('k0'), isNull);
      expect(await store.read('k1'), isNull);
      expect(await store.read('k5'), isNotNull);
      expect((await store.stats()).fileCount, 4);
    });

    test('clear deletes everything and the store keeps working', () async {
      final store = makeStore();
      await store.write('k', body(1));

      await store.clear();
      expect(await store.read('k'), isNull);

      await store.write('k2', body(2));
      expect((await store.read('k2'))?.body, body(2));
    });
  });
}