import 'file_json_cache_store.dart';
import 'json_cache_store.dart';

// LEARN (conditional imports): json_response_cache.dart imports EITHER this
// file (when dart:io exists: Android) OR json_cache_platform_web.dart (browser).
// Both expose the same function name, so the caller never knows which one it
// got. The compiler only includes the chosen file, so dart:io never ends up in
// the web build.
JsonCacheStore createPlatformJsonCacheStore() => FileJsonCacheStore();