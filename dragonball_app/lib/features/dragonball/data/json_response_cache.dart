
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class CachedJsonResponse {
  const CachedJsonResponse({
    required this.body,
    required this.cachedAt,
  });

  final String body;
  final DateTime cachedAt;

  bool isFresh(Duration maxAge) {
    final age = DateTime.now().difference(cachedAt);

    return !age.isNegative && age <= maxAge;
  }
}

class JsonResponseCacheStats {
  const JsonResponseCacheStats({
    required this.fileCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int totalBytes;
}

class JsonResponseCache {
  JsonResponseCache._();

  static final JsonResponseCache instance = JsonResponseCache._();

  static const Duration defaultMaxAge = Duration(hours: 24);

  Directory? _cacheDirectory;

  Future<JsonResponseCacheStats> stats() async {
    try {
      final directory = await _getCacheDirectory();

      if (!await directory.exists()) {
        return const JsonResponseCacheStats(
          fileCount: 0,
          totalBytes: 0,
        );
      }

      var count = 0;
      var bytes = 0;

      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.json')) {
          continue;
        }

        try {
          bytes += await entity.length();
          count++;
        } catch (_) {
          // Ignore a file that disappears during the scan.
        }
      }

      return JsonResponseCacheStats(
        fileCount: count,
        totalBytes: bytes,
      );
    } catch (_) {
      return const JsonResponseCacheStats(
        fileCount: 0,
        totalBytes: 0,
      );
    }
  }
  
  Future<Directory> _getCacheDirectory() async {
    final existing = _cacheDirectory;

    if (existing != null) {
      return existing;
    }

    final appDirectory = await getApplicationSupportDirectory();

    final directory = Directory(
      '${appDirectory.path}${Platform.pathSeparator}'
      'dragonball_api_cache',
    );

    await directory.create(recursive: true);

    _cacheDirectory = directory;
    return directory;
  }

  String _fileName(String key) {
    final hash = sha256.convert(utf8.encode(key)).toString();
    return '$hash.json';
  }

  Future<File> _getFile(String key) async {
    final directory = await _getCacheDirectory();

    return File(
      '${directory.path}${Platform.pathSeparator}'
      '${_fileName(key)}',
    );
  }

  /// Reads a cached response, including stale responses.
  ///
  /// Check [CachedJsonResponse.isFresh] to determine whether
  /// the response is within its freshness period.
  Future<CachedJsonResponse?> read(String key) async {
    try {
      final file = await _getFile(key);

      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final envelope = jsonDecode(contents);

      if (envelope is! Map<String, dynamic>) {
        return null;
      }

      final body = envelope['body'];
      final cachedAtMillis = envelope['cachedAt'];

      if (body is! String || cachedAtMillis is! int) {
        return null;
      }

      // Reject corrupted cached JSON.
      jsonDecode(body);

      return CachedJsonResponse(
        body: body,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(
          cachedAtMillis,
        ),
      );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      // A cache failure must not crash the application.
      return null;
    }
  }

  /// Writes a successful API response to disk.
  Future<void> write(String key, String body) async {
    try {
      // Only persist valid JSON.
      jsonDecode(body);

      final file = await _getFile(key);

      final envelope = jsonEncode({
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'body': body,
      });

      await file.writeAsString(
        envelope,
        flush: true,
      );
    } catch (_) {
      // Cache failures must not turn a successful API response
      // into a failed request.
    }
  }

  Future<void> delete(String key) async {
    try {
      final file = await _getFile(key);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Deleting cache is best-effort.
    }
  }

  Future<void> clear() async {
    final directory = _cacheDirectory;

    try {
      final target = directory ?? await _getCacheDirectory();

      if (await target.exists()) {
        await target.delete(recursive: true);
      }
    } catch (_) {
      // Cache cleanup is best-effort.
    } finally {
      _cacheDirectory = null;
    }
  }
}
