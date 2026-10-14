
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullScreenImageItem {
  const FullScreenImageItem({
    required this.imageUrl,
    required this.heroTag,
    required this.title,
  });

  final String imageUrl;
  final String heroTag;
  final String title;
}

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0);

  final List<FullScreenImageItem> images;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  int get _initialIndex =>
      widget.initialIndex.clamp(0, widget.images.length - 1);

  bool get _hasMultipleImages => widget.images.length > 1;

  @override
  void initState() {
    super.initState();

    _currentIndex = _initialIndex;

    _pageController = PageController(
      initialPage: _hasMultipleImages
          ? widget.images.length * 1000 + _currentIndex
          : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(int index) {
    final image = widget.images[index];

    final imageWidget = CachedNetworkImage(
      imageUrl: image.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white70,
        size: 56,
      ),
    );

    return Center(
      child: index == _initialIndex
          ? Hero(
              tag: image.heroTag,
              child: imageWidget,
            )
          : imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.images[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _hasMultipleImages
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (pageIndex) {
                        setState(() {
                          _currentIndex =
                              pageIndex % widget.images.length;
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        final index =
                            pageIndex % widget.images.length;
                        return _buildImage(index);
                      },
                    )
                  : _buildImage(0),
            ),

            Positioned(
              top: 8,
              left: 12,
              child: IconButton.filledTonal(
                tooltip: 'Close image viewer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),

            if (_hasMultipleImages)
              Positioned(
                top: 20,
                right: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
