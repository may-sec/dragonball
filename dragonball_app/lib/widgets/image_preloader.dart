import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// LEARN (why the old preloader had to change): precacheImage DECODES the
// picture and stores the bitmap in Flutter's ImageCache under a key that
// includes the requested size. The widgets now ask for right-sized decodes
// (memCacheWidth / memCacheHeight), so a full-size precache would be a
// DIFFERENT cache entry: a big bitmap decoded for nothing, and the card would
// decode its own small one anyway.
//
// What helps now is warming the DISK cache: the bytes are already on the phone,
// so when a card appears only the small, fast decode remains.
//
//  * Android: CachedNetworkImage reads through DefaultCacheManager, so
//    getSingleFile(url) downloads (or reuses) exactly the file it will use.
//  * Web: the browser already keeps images in its own HTTP cache, so there is
//    nothing useful to do here.
//
// The BuildContext parameter is kept only so existing callers compile.
Future<void> preloadImageUrls(
  BuildContext context,
  Iterable<String> urls,
) async {
  if (kIsWeb) return;

  final uniqueUrls = urls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toSet();

  await Future.wait(
    uniqueUrls.map((url) async {
      try {
        await DefaultCacheManager().getSingleFile(url);
      } catch (_) {
        // Loading failures are handled by CharacterImage.
      }
    }),
  );
}