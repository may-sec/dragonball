import 'package:dragonball_app/widgets/build_character_image.dart';
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
    this.pageNotifier,
    this.onBeforePop,
  }) : assert(images.length > 0);

  final List<FullScreenImageItem> images;
  final int initialIndex;
  final VoidCallback? onBeforePop;
  

  // Shared with the transformation carousel.
  final ValueNotifier<int>? pageNotifier;

  @override
  State<FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentPageIndex;
  late int _currentIndex;

  int get _initialIndex =>
      widget.initialIndex.clamp(0, widget.images.length - 1);

  bool get _hasMultipleImages => widget.images.length > 1;

  @override
  void initState() {
    super.initState();

    _currentIndex = _initialIndex;

    final initialPage = widget.pageNotifier?.value ??
        (_hasMultipleImages
            ? widget.images.length * 1000 + _currentIndex
            : 0);

    _currentPageIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);

    widget.pageNotifier?.addListener(_syncToSharedPage);
  }

  Future<void> _closeViewer() async {
    final target = widget.pageNotifier?.value;

    if (target != null) {
      widget.pageNotifier!.value = target;
    }

    widget.onBeforePop?.call();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _syncToSharedPage() {
    if (!mounted || !_pageController.hasClients) return;

    final target = widget.pageNotifier?.value;
    if (target == null) return;

    final current = _pageController.page;

    if (current != null && (current - target).abs() < 0.01) {
      return;
    }

    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    widget.pageNotifier?.removeListener(_syncToSharedPage);
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(int index, int pageIndex) {
    final image = widget.images[index];

    final imageWidget = buildCharacterImage(
      image.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
      showLoadingIndicator: true,
      errorWidget: const Icon(
        Icons.broken_image_outlined,
        color: Colors.white70,
        size: 64,
      ),
    );

    // Only the currently visible page should own this Hero tag.
    if (pageIndex == _currentPageIndex) {
      return Center(
        child: Hero(
          tag: image.heroTag,
          child: imageWidget,
        ),
      );
    }

    return Center(child: imageWidget);
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
                          _currentPageIndex = pageIndex;
                          _currentIndex = pageIndex % widget.images.length;
                        });

                        final notifier = widget.pageNotifier;

                        if (notifier != null && notifier.value != pageIndex) {
                          notifier.value = pageIndex;
                        }
                      },
                      itemBuilder: (context, pageIndex) {
                        final index =
                            pageIndex % widget.images.length;
                        return _buildImage(index, pageIndex);
                      },
                    )
                  : _buildImage(0, 0),
            ),

            Positioned(
              top: 8,
              left: 12,
              child: IconButton.filledTonal(
                tooltip: 'Close image viewer',
                onPressed: _closeViewer,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  item.title,
                  key: ValueKey(item.title),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
