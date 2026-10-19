import 'json_cache_store.dart';
import 'prefs_json_cache_store.dart';

// Web counterpart of json_cache_platform_io.dart (same function name).
JsonCacheStore createPlatformJsonCacheStore() => PrefsJsonCacheStore();