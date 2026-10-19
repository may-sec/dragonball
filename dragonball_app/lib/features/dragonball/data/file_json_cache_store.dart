import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'json_cache_store.dart';

// =============================================================================
// LEARN (files on Android):
//  * Atomic write: write to "<name>.tmp", then rename over the real file.
//    rename is atomic on the same filesystem, so a crash mid-write can never
//    leave a half-written JSON file that later parses as garbage.
//  * Pruning: a cache with unbounded growth is a leak. When the folder exceeds
//    maxFiles or maxTotalBytes, the oldest files are deleted until it is back
//    at 80% of the limit. It runs on the first write of a session and then
//    every [pruneEvery] writes, not on every write.
//  * Several pages are written in PARALLEL now, so pruning only deletes stray
//    ".tmp" files older than a minute (a younger one may be a write in flight).
//  * directoryProvider and clock are injectable so tests can use a temp folder
//    and a fake time.
//
// This file imports dart:io, so it must only be reached through the platform
// factory (json_cache_platform_io.dart), never imported by web code.
// =============================================================================
class FileJsonCacheStore implements JsonCacheStore {
  FileJsonCacheStore({
    Future<Directory> Function()? directoryProvider,
    this.maxTotalBytes = 20 * 1024 * 1024,
    this.maxFiles = 400,
    this.pruneEvery = 25,
    DateTime Function()? clock,
  })  : _directoryProvider = directoryProvider ?? _defaultDirectory,
        _clock = clock ?? DateTime.now;

  final int maxTotalBytes;
  final int maxFiles;
  final int pruneEvery;
  final Future<Directory> Function() _directoryProvider;
  final DateTime Function() _clock;

  Directory? _cachedDirectory;
  int _writes = 0;

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationSupportDirectory();

    return Directory(
      '${base.path}${Platform.pathSeparator}dragonball_api_cache',
    );
  }

  Future<Directory> _directory() async {
    final existing = _cachedDirectory;
    if (existing != null) return existing;

    final directory = await _directoryProvider();
    await directory.create(recursive: true);

    _cachedDirectory = directory;
    return directory;
  }

  Future<File> _file(String key) async {
    final directory = await _directory();

    return File(
      '${directory.path}${Platform.pathSeparator}${cacheKeyHash(key)}.json',
    );
  }

  @override
  Future<CachedJsonResponse?> read(String key) async {
    try {
      final file = await _file(key);

      if (!await file.exists()) return null;

      final decoded = decodeCacheEnvelope(await file.readAsString());

      // Corrupted or from another cache version: drop it.
      if (decoded == null) await _safeDelete(file);

      return decoded;
    } catch (_) {
      // A cache failure must not crash the application.
      return null;
    }
  }

  @override
  Future<void> write(String key, String body, {String? etag}) async {
    try {
      // Only persist valid JSON.
      jsonDecode(body);

      final file = await _file(key);
      final temp = File('${file.path}.tmp');
      final now = _clock();

      await temp.writeAsString(
        encodeCacheEnvelope(body: body, cachedAt: now, etag: etag),
        flush: true,
      );
      await temp.rename(file.path);

      // Pruning sorts by modified time; make it match the entry's own clock.
      await file.setLastModified(now);

      _writes++;
      if (_writes == 1 || _writes % pruneEvery == 0) {
        await _prune();
      }
    } catch (_) {
      // Cache failures must not turn a successful API response into a
      // failed request.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final directory = _cachedDirectory ?? await _directory();

      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // Cache cleanup is best-effort.
    } finally {
      _cachedDirectory = null;
    }
  }

  @override
  Future<JsonResponseCacheStats> stats() async {
    try {
      final directory = await _directory();
      var count = 0;
      var bytes = 0;

      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;

        try {
          bytes += await entity.length();
          count++;
        } catch (_) {
          // The file disappeared during the scan.
        }
      }

      return JsonResponseCacheStats(fileCount: count, totalBytes: bytes);
    } catch (_) {
      return const JsonResponseCacheStats(fileCount: 0, totalBytes: 0);
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      await file.delete();
    } catch (_) {}
  }

  Future<void> _prune() async {
    final directory = await _directory();
    final now = _clock();
    final entries = <({File file, int size, DateTime modified})>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;

      try {
        final stat = await entity.stat();

        if (entity.path.endsWith('.tmp')) {
          // Leftover of a crashed write, but never touch a fresh one.
          if (now.difference(stat.modified) > const Duration(minutes: 1)) {
            await _safeDelete(entity);
          }
          continue;
        }

        if (!entity.path.endsWith('.json')) continue;

        entries.add((file: entity, size: stat.size, modified: stat.modified));
      } catch (_) {
        // Ignore a file that disappears during the scan.
      }
    }

    var total = entries.fold<int>(0, (sum, e) => sum + e.size);
    var count = entries.length;

    if (total <= maxTotalBytes && count <= maxFiles) return;

    final targetBytes = (maxTotalBytes * 0.8).floor();
    final targetFiles = (maxFiles * 0.8).floor();

    entries.sort((a, b) => a.modified.compareTo(b.modified));

    for (final entry in entries) {
      if (total <= targetBytes && count <= targetFiles) break;

      await _safeDelete(entry.file);
      total -= entry.size;
      count--;
    }
  }
}