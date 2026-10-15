import 'dart:async';

import 'package:dragonball_app/core/result/result.dart';
import 'package:dragonball_app/features/dragonball/presentation/full_screen_image_viewer.dart';
import 'package:dragonball_app/widgets/build_character_image.dart';
import 'package:dragonball_app/widgets/image_preloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planet_detail_view.dart';
import 'dragonball_notifier.dart';
import '../models/dragonball_models.dart';
import 'catalog_components.dart';

class CharacterProfileView extends ConsumerWidget {
  const CharacterProfileView({
    super.key,
    required this.characterId,
    this.fromFavorites = false,
  });

  final int characterId;
  final bool fromFavorites;

@override
Widget build(BuildContext context, WidgetRef ref) {
  final profileProvider = characterProfileProvider(characterId);

  // Listen for profile data arriving or refreshing.
  ref.listen<AsyncValue<CharacterProfile>>(
    profileProvider,
    (previous, next) {
      next.whenData((character) {
        preloadImageUrls(
          context,
          [
            character.imageUrl,
            if (character.originPlanet != null)
              character.originPlanet!.imageUrl,
            ...character.transformations.map(
              (transformation) => transformation.imageUrl,
            ),
          ],
        );
      });
    },
  );

  final profileAsync = ref.watch(profileProvider);

  // Also handle profile data that was already loaded before this build.
  final character = profileAsync.asData?.value;

  if (character != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      preloadImageUrls(
        context,
        [
          character.imageUrl,
          if (character.originPlanet != null)
            character.originPlanet!.imageUrl,
          ...character.transformations.map(
            (transformation) => transformation.imageUrl,
          ),
        ],
      );
    });
  }

  return Scaffold(
    // Keep your existing Scaffold code here.
      appBar: AppBar(title: const Text('Character dossier')),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(characterProfileProvider(characterId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (character) => RefreshIndicator(
          onRefresh: () async {
            final repository = ref.read(dragonBallRepositoryProvider);

            final result = await repository.fetchCharacterProfile(characterId);

            if (result case Ok()) {
              ref.invalidate(characterProfileProvider(characterId));
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          final tag = fromFavorites
                              ? favoriteCharacterHeroTag(character.id)
                              : characterHeroTag(character.id);

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FullScreenImageViewer(
                                images: [
                                  FullScreenImageItem(
                                    imageUrl: character.imageUrl,
                                    heroTag: tag,
                                    title: character.name,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: fromFavorites
                              ? favoriteCharacterHeroTag(character.id)
                              : characterHeroTag(character.id),
                          child: buildCharacterImage(
                            character.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: const Icon(Icons.person, size: 80),
                            showLoadingIndicator: true,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface.withValues(
                              alpha: 0.92,
                            ),
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: FavoriteToggleButton(
                          characterId: character.id,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                character.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(character.race)),
                  Chip(label: Text(character.gender)),
                  Chip(label: Text(character.affiliation)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Current Ki',
                      value: character.ki,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Maximum Ki',
                      value: character.maxKi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                character.description.isEmpty
                    ? 'No description is available.'
                    : character.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (character.originPlanet != null) ...[
                const SizedBox(height: 28),
                Text(
                  'Origin planet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final planet = character.originPlanet!;

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlanetDetailView(
                          planetId: planet.id,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: buildCharacterImage(
                          character.originPlanet!.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: const Icon(Icons.public),
                        ),
                      ),
                      title: Text(character.originPlanet!.name),
                      subtitle: Text(
                        character.originPlanet!.isDestroyed
                            ? 'Destroyed'
                            : 'Intact',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
              ],
              if (character.transformations.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Transformations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _TransformationCarousel(
                  transformations: character.transformations,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _TransformationCarousel extends StatefulWidget {
  const _TransformationCarousel({
    required this.transformations,
  });

  final List<Transformation> transformations;

  @override
  State<_TransformationCarousel> createState() =>
      _TransformationCarouselState();
}


class _TransformationCarouselState
    extends State<_TransformationCarousel> {
  late final PageController _controller;
  late final ValueNotifier<int> _sharedPage;
  Timer? _autoPlayTimer;
  bool _isAnimatingToNextPage = false;
  int _currentPageIndex = 0;
  bool _isFullScreenOpen = false;

  @override
  void initState() {
    super.initState();

    final count = widget.transformations.length;
    final initialPage = count * 1000;
    _currentPageIndex = initialPage;

    _sharedPage = ValueNotifier<int>(initialPage);
    _controller = PageController(initialPage: initialPage);

    _sharedPage.addListener(_syncToSharedPage);

    if (count > 1) {
      _scheduleAutoPlay();
    }
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();

    if (!mounted || widget.transformations.length <= 1) return;

    _autoPlayTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      // One timer, one shared page index.
      _sharedPage.value = _sharedPage.value + 1;
    });
  }

  void _syncToSharedPage() {
    if (!mounted || !_controller.hasClients) return;

    final target = _sharedPage.value;
    final current = _controller.page;

    if (current != null && (current - target).abs() < 0.01) {
      _scheduleAutoPlay();
      return;
    }

    if (_isFullScreenOpen) {
      // Fullscreen covers the carousel. Prepare the correct Hero
      // destination before the fullscreen route is popped.
      _controller.jumpToPage(target);
    } else {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }

    _scheduleAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _sharedPage.removeListener(_syncToSharedPage);
    _sharedPage.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transformations = widget.transformations;
    final count = transformations.length;

    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _controller,
        itemBuilder: (context, pageIndex) {
          final index = pageIndex % count;
          final transformation = transformations[index];
          final image = buildCharacterImage(
            transformation.imageUrl,
            fit: BoxFit.contain,
            placeholder: const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
              ),
            ),
            showLoadingIndicator: true,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Material(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: InkWell(
                            onTap: () async {
                              // Stop the timer from changing the tapped page while opening.
                              _autoPlayTimer?.cancel();

                              // Capture the exact page the user tapped, not a stale index.
                              _isFullScreenOpen = true;
                              _sharedPage.value = pageIndex;

                              // Ensure the carousel is on this exact page before Hero starts.
                              if (_controller.hasClients) {
                                _controller.jumpToPage(pageIndex);
                              }

                              try {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FullScreenImageViewer(
                                      images: transformations.map((item) {
                                        return FullScreenImageItem(
                                          imageUrl: item.imageUrl,
                                          heroTag: 'transformation-image-${item.imageUrl}',
                                          title: item.name,
                                        );
                                      }).toList(),
                                      initialIndex: index,
                                      pageNotifier: _sharedPage,
                                      onBeforePop: () {
                                        _isFullScreenOpen = false;

                                        // Prepare the underlying carousel for the selected image.
                                        if (_controller.hasClients) {
                                          _controller.jumpToPage(_sharedPage.value);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  _isFullScreenOpen = false;
                                  _scheduleAutoPlay();
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Hero(
                                tag: 'transformation-image-${transformation.imageUrl}',
                                child: image,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                '${index + 1} / $count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      transformation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}




class TransformationGalleryScreen extends StatefulWidget {
  const TransformationGalleryScreen({
    super.key,
    required this.transformations,
    this.initialIndex = 0,
  });

  final List<Transformation> transformations;
  final int initialIndex;

  @override
  State<TransformationGalleryScreen> createState() =>
      _TransformationGalleryScreenState();
}

class _TransformationGalleryScreenState
    extends State<TransformationGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    final count = widget.transformations.length;

    final safeIndex = count == 0
        ? 0
        : widget.initialIndex.clamp(0, count - 1);

    _currentIndex = safeIndex;

    _pageController = PageController(
      initialPage: count > 0 ? count * 1000 + safeIndex : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    if (widget.transformations.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF090B12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090B12),
          foregroundColor: Colors.white,
          title: const Text('Transformations'),
        ),
        body: const Center(
          child: Text(
            'No transformations available.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final count = widget.transformations.length;
    final transformation = widget.transformations[_currentIndex % count];

    return Scaffold(
      backgroundColor: const Color(0xFF090B12),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Close gallery',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Text(
                    '${(_currentIndex % count) + 1} / $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: null,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % count;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.transformations[index % count];

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: buildCharacterImage(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        showLoadingIndicator: true,
                        errorWidget: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white70,
                              size: 64,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Image could not be loaded',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transformation.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Previous transformation',
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Swipe to explore transformations',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Next transformation',
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}