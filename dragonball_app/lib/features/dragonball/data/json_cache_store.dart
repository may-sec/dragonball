import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// =============================================================================
// LEARN (dependency inversion, Phase 6.1 / Module 7.2):
// The repository does not care WHERE cached JSON lives. It talks to the small
// contract below. Android implements it with files, web with browser storage.
// Swapping or adding a backend (IndexedDB, Drift, ...) means writing one new
// class, not touching the repository.
//
// This file has NO dart:io and NO Flutter plugin imports, so it compiles on
// every platform and is easy to test.
// =============================================================================

/// Bump this when the SHAPE of cached bodies changes (e.g. a model gains a
/// field you need). Entries written with another version are ignored and
/// replaced. Entries without a version are treated as version 1, so users of
/// the previous app version keep their cache.
const int kJsonCacheVersion = 1;

@immutable
class CachedJsonResponse {
  const CachedJsonResponse({
    required this.body,
    required this.cachedAt,
    this.etag,
  });

  final String body;
  final DateTime cachedAt;

  /// Server validator for conditional requests (If-None-Match). Stored now,
  /// used by the next step.
  final String? etag;

  bool isFresh(Duration maxAge) {
    final age = DateTime.now().difference(cachedAt);

    return !age.isNegative && age <= maxAge;
  }
}

@immutable
class JsonResponseCacheStats {
  const JsonResponseCacheStats({
    required this.fileCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int totalBytes;
}

abstract interface class JsonCacheStore {
  /// Returns null for a missing, corrupted or outdated-version entry.
  Future<CachedJsonResponse?> read(String key);

  /// Never throws: a cache failure must not break a successful API response.
  Future<void> write(String key, String body, {String? etag});

  Future<void> delete(String key);

  Future<void> clear();

  Future<JsonResponseCacheStats> stats();
}

/// Stable, filesystem-safe and storage-key-safe name for any URL.
String cacheKeyHash(String key) =>
    sha256.convert(utf8.encode(key)).toString();

/// The text stored for one entry.
String encodeCacheEnvelope({
  required String body,
  required DateTime cachedAt,
  String? etag,
}) {
  return jsonEncode({
    'v': kJsonCacheVersion,
    'cachedAt': cachedAt.millisecondsSinceEpoch,
    'body': body,
    if (etag != null) 'etag': etag,
  });
}

/// Inverse of [encodeCacheEnvelope]. Null when the text is not a valid,
/// current-version entry whose body is valid JSON.
CachedJsonResponse? decodeCacheEnvelope(String raw) {
  try {
    final envelope = jsonDecode(raw);
    if (envelope is! Map<String, dynamic>) return null;

    final version = envelope['v'] ?? 1;
    if (version != kJsonCacheVersion) return null;

    final body = envelope['body'];
    final cachedAt = envelope['cachedAt'];
    if (body is! String || cachedAt is! int) return null;

    // Reject corrupted cached JSON.
    jsonDecode(body);

    final etag = envelope['etag'];

    return CachedJsonResponse(
      body: body,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAt),
      etag: etag is String ? etag : null,
    );
  } catch (_) {
    return null;
  }
}