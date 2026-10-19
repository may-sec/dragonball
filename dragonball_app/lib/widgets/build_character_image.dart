import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/language_provider.dart';
import '../core/platform/experience_policy.dart';
import '../core/utils/image_sizing.dart';

// LEARN (one global throttle instead of one set per URL): offline, 20 images
// fail at once. The old code remembered every failed URL forever, so the user
// saw up to 20 different snackbars in a row, and never again for those URLs.
// Now: at most ONE image-error snackbar every 30 seconds, whichever image
// failed. (The catalog banner already says "you are offline".)
const Duration _imageErrorCooldown = Duration(seconds: 30);
DateTime? _lastImageErrorAt;

void _showImageError(BuildContext context, String message) {
  final now = DateTime.now();
  final last = _lastImageErrorAt;

  if (last != null && now.difference(last) < _imageErrorCooldown) return;
  _lastImageErrorAt = now;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  });
}

/// Every call site keeps using this function. It now returns a widget that
/// knows how big it is drawn, so callers do not have to pass sizes.
Widget buildCharacterImage(
  String imageUrl, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? errorWidget,
  bool showLoadingIndicator = false,
}) {
  return CharacterImage(
    imageUrl,
    fit: fit,
    width: width,
    height: height,
    placeholder: placeholder,
    errorWidget: errorWidget,
    showLoadingIndicator: showLoadingIndicator,
  );
}

// =============================================================================
// LEARN (LayoutBuilder + policy):
//  * LayoutBuilder hands us the constraints the parent gives this image, which
//    is exactly "how many logical pixels will this be drawn in". Together with
//    devicePixelRatio that is the number of REAL pixels worth decoding
//    (see core/utils/image_sizing.dart).
//  * The experience policy can scale that down (battery saver): lower memory
//    and less decode work, at the price of slightly softer pictures.
//  * LayoutBuilder cannot answer intrinsic-size questions, so do not put this
//    widget inside IntrinsicHeight / IntrinsicWidth.
// =============================================================================
class CharacterImage extends ConsumerWidget {
  const CharacterImage(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = false,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallbackWidget =
        errorWidget ?? const Icon(Icons.broken_image_outlined);

    if (imageUrl.trim().isEmpty) {
      return fallbackWidget;
    }

    final loadingWidget = showLoadingIndicator
        ? (placeholder ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : const SizedBox.shrink();

    final scale =
        ref.watch(experiencePolicyProvider.select((p) => p.imageDecodeScale));
    final errorMessage = ref.watch(stringsProvider).imageLoadFailed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final target = decodeTargetFor(
          maxWidth: math.min(constraints.maxWidth, width ?? double.infinity),
          maxHeight: math.min(constraints.maxHeight, height ?? double.infinity),
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          scale: scale,
        );

        if (kIsWeb) {
          return Image.network(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: target.width,
            cacheHeight: target.height,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return loadingWidget;
            },
            errorBuilder: (context, error, stackTrace) {
              _showImageError(context, errorMessage);
              return fallbackWidget;
            },
          );
        }

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: target.width,
          memCacheHeight: target.height,
          useOldImageOnUrlChange: true,

          // Hero already animates the image's position and size.
          // Avoid a second fade animation on top of the Hero flight.
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,

          placeholder: (context, url) => loadingWidget,
          errorWidget: (context, url, error) {
            _showImageError(context, errorMessage);
            return fallbackWidget;
          },
        );
      },
    );
  }
}