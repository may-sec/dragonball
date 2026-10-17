import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/category_style.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../widgets/character_card.dart';
import '../../../widgets/shared_widgets.dart';
import '../../dragonball/models/dragonball_models.dart';
import '../../dragonball/presentation/catalog_components.dart' show CatalogSkeleton;
import '../../dragonball/presentation/navigation_path.dart';
import 'explore_providers.dart';

// LEARN (the Explore screen touches many topics, each marked below):
//  * ConsumerStatefulWidget: a widget that owns controllers (State) AND reads
//    providers (ref). Controllers must be created in the State and disposed.
//  * ref.watch (rebuild on change) vs ref.listen (run a side effect).
//  * AsyncValue.when: one place that handles loading / error / data.
//  * Two-way binding: typing updates the provider; a breadcrumb tap updates
//    the provider, which updates the text field.
//  * ListView / GridView.builder: build only what is visible.
//  * AnimatedSize: the chip row slides in and out when the mode changes.
//  * LayoutBuilder + mainAxisExtent: responsive columns, and card heights
//    that grow with the user's text size (no overflow at "Largest").
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _grid = false; // local UI state: nobody else needs it

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _open(List<Character> visible, int index, ExploreSelection sel) {
    openCharacter(
      context,
      CharacterNavContext(
        // This is where the breadcrumb "path" is born.
        source: FromExplore(
          mode: sel.mode,
          group: sel.group,
          query: sel.query.trim(),
        ),
        siblingIds: [for (final c in visible) c.id], // enables swipe prev/next
        index: index,
        heroTagFor: exploreHeroTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final controller = ref.read(exploreSelectionProvider.notifier);

    final sel = ref.watch(exploreSelectionProvider);
    final allAsync = ref.watch(allCharactersProvider);
    final groups = ref.watch(exploreGroupsProvider);
    final visible = ref.watch(exploreVisibleProvider);

    // Side effects belong in listen, never in build.
    ref.listen<ExploreSelection>(exploreSelectionProvider, (prev, next) {
      // Keep the text field in sync when the query changed elsewhere.
      if (_search.text != next.query) {
        _search.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
      // A different group/sort means a different list: start from the top.
      final listChanged = prev?.mode != next.mode ||
          prev?.group != next.group ||
          prev?.sort != next.sort;
      if (listChanged && _scroll.hasClients) _scroll.jumpTo(0);
    });

    String sortLabel(ExploreSort sort) => switch (sort) {
          ExploreSort.nameAsc => s.sortNameAsc,
          ExploreSort.nameDesc => s.sortNameDesc,
          ExploreSort.kiDesc => s.sortKiDesc,
        };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
        child: Column(
          children: [
            // ---- search + sort + view toggle --------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x4,
                AppSpace.x3,
                AppSpace.x4,
                AppSpace.x2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: controller.setQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: s.searchHint,
                        prefixIcon: const Icon(AppIcons.search),
                        suffixIcon: sel.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: s.clearSearch,
                                icon: const Icon(AppIcons.close),
                                onPressed: () => controller.setQuery(''),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x2),
                  PopupMenuButton<ExploreSort>(
                    tooltip: s.sortTooltip,
                    icon: const Icon(AppIcons.sort),
                    initialValue: sel.sort,
                    onSelected: controller.setSort,
                    itemBuilder: (_) => [
                      for (final option in ExploreSort.values)
                        PopupMenuItem<ExploreSort>(
                          value: option,
                          child: Text(sortLabel(option)),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: _grid ? s.listTooltip : s.gridTooltip,
                    icon: Icon(_grid ? AppIcons.list : AppIcons.grid),
                    onPressed: () => setState(() => _grid = !_grid),
                  ),
                ],
              ),
            ),

            // ---- mode selector: All | Race | Affiliation --------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ExploreMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ExploreMode.all,
                      icon: const Icon(AppIcons.characters),
                      label: Text(s.modeAll),
                    ),
                    ButtonSegment(
                      value: ExploreMode.race,
                      icon: const Icon(AppIcons.flame),
                      label: Text(s.modeRace),
                    ),
                    ButtonSegment(
                      value: ExploreMode.affiliation,
                      icon: const Icon(AppIcons.shield),
                      label: Text(s.modeAffiliation),
                    ),
                  ],
                  selected: {sel.mode},
                  onSelectionChanged: (set) => controller.setMode(set.first),
                ),
              ),
            ),

            // ---- group chips (same layout for Race and Affiliation) ---------
            AnimatedSize(
              duration: AppMotion.base,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: sel.mode == ExploreMode.all
                  ? const SizedBox(width: double.infinity)
                  : _GroupChips(
                      allLabel: sel.mode == ExploreMode.race
                          ? s.allRaces
                          : s.allAffiliations,
                      groups: groups,
                      selected: sel.group,
                      onSelected: controller.setGroup,
                    ),
            ),

            // ---- count -------------------------------------------------------
            if (allAsync.hasValue)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x4,
                  vertical: AppSpace.x1,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.warriorCount(visible.length),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),

            // ---- the single list --------------------------------------------
            Expanded(
              child: allAsync.when(
                loading: () => LayoutBuilder(
                  builder: (context, c) => CatalogSkeleton(
                    isGridView: _grid,
                    columns: Breakpoints.gridColumns(c.maxWidth),
                    gridAspectRatio: 0.66,
                  ),
                ),
                error: (error, _) => MessageBlock(
                  icon: AppIcons.offline,
                  title: s.loadFailed,
                  message: error.toString(),
                  actionLabel: s.retry,
                  onAction: () => ref.invalidate(allCharactersProvider),
                ),
                data: (_) {
                  if (visible.isEmpty) {
                    return MessageBlock(
                      icon: AppIcons.empty,
                      title: s.noResultsTitle,
                      message: s.noResultsBody,
                      actionLabel: s.resetFilters,
                      onAction: controller.reset,
                    );
                  }
                  return _buildList(context, visible, sel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Character> visible,
    ExploreSelection sel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_grid) {
          final columns = Breakpoints.gridColumns(constraints.maxWidth);

          // Text scale makes the text block taller. A fixed aspect ratio
          // would overflow; a fixed extent that grows with the scale does not.
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final extent = 260 * (textScale < 1 ? 1.0 : textScale);

          return GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpace.x3),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpace.x3,
              mainAxisSpacing: AppSpace.x3,
              mainAxisExtent: extent,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final c = visible[i];
              return CharacterGridCard(
                key: ValueKey<int>(c.id), // keeps state stable when sorting
                character: c,
                heroTag: exploreHeroTag(c.id),
                onTap: () => _open(visible, i, sel),
              );
            },
          );
        }

        return ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpace.x3),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpace.x2),
          itemBuilder: (context, i) {
            final c = visible[i];
            return CharacterRow(
              key: ValueKey<int>(c.id),
              character: c,
              heroTag: exploreHeroTag(c.id),
              onTap: () => _open(visible, i, sel),
            );
          },
        );
      },
    );
  }
}

/// Horizontally scrolling chips. First chip = "all"; the rest come from data.
class _GroupChips extends StatelessWidget {
  const _GroupChips({
    required this.allLabel,
    required this.groups,
    required this.selected,
    required this.onSelected,
  });

  final String allLabel;
  final List<GroupCount> groups;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x4,
          vertical: AppSpace.x2,
        ),
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.x2),
        itemBuilder: (context, i) {
          if (i == 0) {
            return ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }

          final group = groups[i - 1];
          final style = styleForCategory(group.label);

          return ChoiceChip(
            avatar: Icon(style.icon, size: 18, color: style.color),
            label: Text('${group.label} · ${group.count}'),
            selected: selected == group.label,
            onSelected: (_) => onSelected(group.label),
          );
        },
      ),
    );
  }
}