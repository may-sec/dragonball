import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'character_detail_view.dart';
import 'dragonball_notifier.dart';

void openCharacterProfile(BuildContext context, int characterId) {
  FocusManager.instance.primaryFocus?.unfocus();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CharacterProfileView(
        characterId: characterId,
      ),
    ),
  );
}

class ViewModeSelector extends StatelessWidget {
  const ViewModeSelector({
    super.key,
    required this.isGridView,
    required this.onChanged,
  });

  final bool isGridView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment<bool>(
          value: true,
          icon: Icon(Icons.grid_view_rounded),
          label: Text('Grid'),
        ),
        ButtonSegment<bool>(
          value: false,
          icon: Icon(Icons.view_list_rounded),
          label: Text('List'),
        ),
      ],
      selected: {isGridView},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class FavoriteToggleButton extends ConsumerWidget {
  const FavoriteToggleButton({
    super.key,
    required this.characterId,
    this.overlay = false,
  });

  final int characterId;
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      dragonBallFavoritesProvider.select(
        (ids) => ids.contains(characterId),
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      visualDensity:
          overlay ? VisualDensity.compact : VisualDensity.standard,
      style: overlay
          ? IconButton.styleFrom(
              backgroundColor:
                  colorScheme.surface.withValues(alpha: 0.9),
              shape: const CircleBorder(),
            )
          : null,
      tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
      onPressed: () {
        ref
            .read(dragonBallFavoritesProvider.notifier)
            .toggle(characterId);
      },
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
    );
  }
}

class CatalogResults<T> extends StatelessWidget {
  const CatalogResults({
    super.key,
    required this.items,
    required this.isGridView,
    required this.columns,
    required this.gridAspectRatio,
    required this.controller,
    required this.isLoadingMore,
    required this.onRefresh,
    required this.itemBuilder,
  });

  final List<T> items;
  final bool isGridView;
  final int columns;
  final double gridAspectRatio;
  final ScrollController controller;
  final bool isLoadingMore;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isGridView
          ? GridView.builder(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: gridAspectRatio,
              ),
              itemCount: items.length + (isLoadingMore ? columns : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const CatalogSkeletonCard();
                }

                return itemBuilder(context, items[index]);
              },
            )
          : ListView.builder(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: items.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const CatalogLoadingMore();
                }

                return itemBuilder(context, items[index]);
              },
            ),
    );
  }
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({
    super.key,
    required this.isGridView,
    required this.columns,
    this.itemCount = 6,
    this.gridAspectRatio = 0.72,
  });

  final bool isGridView;
  final int columns;
  final int itemCount;
  final double gridAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (!isGridView) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _SkeletonListItem(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: columns * 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: gridAspectRatio,
      ),
      itemBuilder: (_, __) => const CatalogSkeletonCard(),
    );
  }
}

class CatalogSkeletonCard extends StatelessWidget {
  const CatalogSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class CatalogLoadingMore extends StatelessWidget {
  const CatalogLoadingMore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _SkeletonListItem extends StatelessWidget {
  const _SkeletonListItem();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
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
