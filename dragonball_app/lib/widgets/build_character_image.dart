
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final Set<String> _reportedImageErrors = <String>{};

void _showImageError(
  BuildContext context,
  String imageUrl,
) {
  if (!_reportedImageErrors.add(imageUrl)) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load an image. Check your connection and try again.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
  });
}

Widget buildCharacterImage(
  String imageUrl, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? errorWidget,
  bool showLoadingIndicator = false,
}) {
  final loadingWidget = showLoadingIndicator
      ? (placeholder ??
          const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ))
      : const SizedBox.shrink();

  final fallbackWidget =
      errorWidget ?? const Icon(Icons.broken_image_outlined);

  if (imageUrl.trim().isEmpty) {
    return fallbackWidget;
  }

  if (kIsWeb) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: child,
          );
        }

        return loadingWidget;
      },
      errorBuilder: (context, error, stackTrace) {
        _showImageError(context, imageUrl);
        return fallbackWidget;
      },
    );
  }

  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: fit,
    width: width,
    height: height,
    useOldImageOnUrlChange: true,
    fadeInDuration: const Duration(milliseconds: 150),
    fadeOutDuration: Duration.zero,
    placeholder: (context, url) => loadingWidget,
    errorWidget: (context, url, error) {
      _showImageError(context, url);
      return fallbackWidget;
    },
  );
}
