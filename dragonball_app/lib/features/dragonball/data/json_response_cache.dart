import 'json_cache_platform_web.dart'
    if (dart.library.io) 'json_cache_platform_io.dart' as platform;
import 'json_cache_store.dart';

// Re-exported so existing imports of this file keep seeing these types
// (settings_screen.dart uses JsonResponseCacheStats).
export 'json_cache_store.dart'
    show CachedJsonResponse, JsonCacheStore, JsonResponseCacheStats;

// LEARN (facade): callers keep using JsonResponseCache.instance exactly as
// before (repository, settings screen). Underneath, it now delegates to the
// store chosen for the current platform:
//   Android -> files (FileJsonCacheStore)
//   web     -> browser storage (PrefsJsonCacheStore)
// The constructor is public so a test can inject a fake store.
class JsonResponseCache {
  JsonResponseCache(this._store);

  static final JsonResponseCache instance =
      JsonResponseCache(platform.createPlatformJsonCacheStore());

  static const Duration defaultMaxAge = Duration(hours: 24);

  final JsonCacheStore _store;

  Future<CachedJsonResponse?> read(String key) => _store.read(key);

  /// [etag] is stored for conditional requests (next step); optional today.
  Future<void> write(String key, String body, {String? etag}) =>
      _store.write(key, body, etag: etag);

  Future<void> delete(String key) => _store.delete(key);

  Future<void> clear() => _store.clear();

  Future<JsonResponseCacheStats> stats() => _store.stats();
}