import 'package:flutter/material.dart';

import '../../../core/design/app_tokens.dart';

// LEARN (what moved out of this file): it used to hold its OWN favorite button
// (FavoriteToggleButton), its own view toggle and a navigation helper, all
// duplicated elsewhere. Now there is ONE favorite widget (FavoriteHeart in
// widgets/), ONE card per kind of item (widgets/character_card.dart,
// widgets/planet_card.dart) and ONE way to open a character
// (openCharacter + CharacterNavContext). What stays here is the generic
// "scrolling results" machinery and the loading skeletons.

/// Card height for grids. Text grows with the user's text-size setting, so a
/// fixed aspect ratio would overflow; an extent that grows with the scale does
/// not. Same idea Explore already used.
double gridCardExtent(BuildContext context, {double base = 260}) {
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);

  return base * (textScale < 1 ? 1.0 : textScale);
}

/// Pull-to-refresh + grid or list. The builder also receives the index, which
/// is what lets a tapped card open the detail screen with its neighbours (for
/// swiping) and a breadcrumb.
class CatalogResults<T> extends StatelessWidget {
  const CatalogResults({
    super.key,
    required this.items,
    required this.isGridView,
    required this.columns,
    required this.gridMainAxisExtent,
    required this.onRefresh,
    required this.itemBuilder,
    this.controller,
  });

  final List<T> items;
  final bool isGridView;
  final int columns;
  final double gridMainAxisExtent;
  final ScrollController? controller;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isGridView
          ? GridView.builder(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.x3),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpace.x3,
                mainAxisSpacing: AppSpace.x3,
                mainAxisExtent: gridMainAxisExtent,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  itemBuilder(context, items[index], index),
            )
          : ListView.separated(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.x3),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x2),
              itemBuilder: (context, index) =>
                  itemBuilder(context, items[index], index),
            ),
    );
  }
}

/// Loading placeholder. Pass [mainAxisExtent] for the new fixed-extent grids;
/// [gridAspectRatio] is kept so existing callers (Explore) still compile.
class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({
    super.key,
    required this.isGridView,
    required this.columns,
    this.itemCount = 6,
    this.gridAspectRatio = 0.72,
    this.mainAxisExtent,
  });

  final bool isGridView;
  final int columns;
  final int itemCount;
  final double gridAspectRatio;
  final double? mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    if (!isGridView) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpace.x3),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x2),
        itemBuilder: (_, __) => const _SkeletonListItem(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpace.x3),
      itemCount: columns * 3,
      gridDelegate: mainAxisExtent != null
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpace.x3,
              mainAxisSpacing: AppSpace.x3,
              mainAxisExtent: mainAxisExtent,
            )
          : SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpace.x3,
              mainAxisSpacing: AppSpace.x3,
              childAspectRatio: gridAspectRatio,
            ),
      itemBuilder: (_, __) => const CatalogSkeletonCard(),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.height, this.width, this.radius = AppRadius.sm});

  final double? height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class CatalogSkeletonCard extends StatelessWidget {
  const CatalogSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Bone(width: double.infinity, radius: AppRadius.md)),
            SizedBox(height: AppSpace.x3),
            _Bone(height: 14, width: double.infinity),
            SizedBox(height: AppSpace.x2),
            _Bone(height: 10, width: 80),
          ],
        ),
      ),
    );
  }
}

class _SkeletonListItem extends StatelessWidget {
  const _SkeletonListItem();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.x3),
        child: Row(
          children: [
            _Bone(height: 64, width: 64, radius: AppRadius.md),
            SizedBox(width: AppSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(height: 14, width: double.infinity),
                  SizedBox(height: AppSpace.x2),
                  _Bone(height: 10, width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hero tags must be UNIQUE per screen (all tabs stay alive inside an
// IndexedStack) and IDENTICAL on both ends of a flight.
String characterHeroTag(int characterId) {
  return 'character-hero-$characterId';
}

String favoriteCharacterHeroTag(int characterId) {
  return 'favorite-character-$characterId';
}