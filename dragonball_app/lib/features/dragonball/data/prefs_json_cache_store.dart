import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'json_cache_store.dart';

// =============================================================================
// LEARN (web storage reality):
//  * On web, shared_preferences is the browser's localStorage. It is
//    synchronous under the hood, string-only, and shared by the WHOLE origin
//    with a small quota (about 5 MB in most browsers, counted in UTF-16, so
//    roughly 2.5 million characters). Your favorites and settings live there
//    too.
//  * So this store must stay SMALL and must expect writes to fail. It keeps a
//    character budget and evicts the oldest entries first (a simple LRU-like
//    policy), and if a write still fails it evicts harder and retries once.
//  * IndexedDB (async, hundreds of MB) is the heavier tool for bigger data.
//    Good later exercise, behind this same JsonCacheStore interface.
//
// It uses no dart:io, so it also runs on Android and in unit tests.
// =============================================================================
class PrefsJsonCacheStore implements JsonCacheStore {
  PrefsJsonCacheStore({
    this.maxTotalChars = 1200000,
    this.maxEntries = 300,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Every key written by this store starts with this, so clear() and stats()
  /// never touch favorites or settings.
  static const String keyPrefix = 'jc1:';

  final int maxTotalChars;
  final int maxEntries;
  final DateTime Function() _clock;

  String _storageKey(String key) => '$keyPrefix${cacheKeyHash(key)}';

  @override
  Future<CachedJsonResponse?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _storageKey(key);
      final raw = prefs.getString(storageKey);

      if (raw == null) return null;

      final decoded = decodeCacheEnvelope(raw);

      // Corrupted or from another cache version: drop it.
      if (decoded == null) await prefs.remove(storageKey);

      return decoded;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String body, {String? etag}) async {
    try {
      // Only persist valid JSON.
      jsonDecode(body);

      final prefs = await SharedPreferences.getInstance();
      final storageKey = _storageKey(key);
      final raw = encodeCacheEnvelope(
        body: body,
        cachedAt: _clock(),
        etag: etag,
      );

      try {
        await prefs.setString(storageKey, raw);
      } catch (_) {
        // Most likely the browser quota. Make real room, then retry once.
        await _prune(prefs, force: true);
        await prefs.setString(storageKey, raw);
      }

      await _prune(prefs);
    } catch (_) {
      // Cache failures must not turn a successful API response into a
      // failed request.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(key));
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final key in prefs.getKeys().where(_isCacheKey).toList()) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  @override
  Future<JsonResponseCacheStats> stats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var count = 0;
      var chars = 0;

      for (final key in prefs.getKeys().where(_isCacheKey)) {
        final raw = prefs.getString(key);
        if (raw == null) continue;

        count++;
        chars += raw.length;
      }

      return JsonResponseCacheStats(fileCount: count, totalBytes: chars);
    } catch (_) {
      return const JsonResponseCacheStats(fileCount: 0, totalBytes: 0);
    }
  }

  bool _isCacheKey(String key) => key.startsWith(keyPrefix);

  int _cachedAtOf(String raw) {
    try {
      final envelope = jsonDecode(raw);
      if (envelope is Map<String, dynamic>) {
        final at = envelope['cachedAt'];
        if (at is int) return at;
      }
    } catch (_) {}

    // Unreadable entries sort first, so they are evicted first.
    return 0;
  }

  /// Evicts oldest entries until the store is at 80% of its budget
  /// (50% when [force] is true because a write just failed).
  Future<void> _prune(SharedPreferences prefs, {bool force = false}) async {
    final entries = <({String key, int size, int cachedAt})>[];

    for (final key in prefs.getKeys().where(_isCacheKey)) {
      final raw = prefs.getString(key);
      if (raw == null) continue;

      entries.add((key: key, size: raw.length, cachedAt: _cachedAtOf(raw)));
    }

    var total = entries.fold<int>(0, (sum, e) => sum + e.size);
    var count = entries.length;

    final overBudget = total > maxTotalChars || count > maxEntries;
    if (!overBudget && !force) return;

    final fraction = force ? 0.5 : 0.8;
    final targetChars = (maxTotalChars * fraction).floor();
    final targetEntries = (maxEntries * fraction).floor();

    entries.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));

    for (final entry in entries) {
      if (total <= targetChars && count <= targetEntries) break;

      await prefs.remove(entry.key);
      total -= entry.size;
      count--;
    }
  }
}