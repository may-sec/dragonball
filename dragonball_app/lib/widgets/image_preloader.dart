
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> preloadImageUrls(
  BuildContext context,
  Iterable<String> urls,
) async {
  final uniqueUrls = urls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toSet();

  await Future.wait(
    uniqueUrls.map((url) async {
      final ImageProvider provider = kIsWeb
          ? NetworkImage(url)
          : CachedNetworkImageProvider(url);

      try {
        await precacheImage(provider, context);
      } catch (_) {
        // Loading failures are handled by buildCharacterImage.
      }
    }),
  );
}
