import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../widgets/catalog_status_banner.dart';
import '../../../widgets/character_card.dart';
import '../../../widgets/planet_card.dart';
import '../../../widgets/shared_widgets.dart';
import '../models/dragonball_models.dart';
import 'app_settings.dart';
import 'catalog_components.dart';
import 'catalog_provider.dart';
import 'catalog_views.dart';
import 'character_filter_sheet.dart';
import 'dragonball_notifier.dart';
import 'dragonball_state.dart';
import 'explore_screen.dart';
import 'navigation_path.dart';
import 'planet_detail_view.dart';
import 'settings_screen.dart';

// =============================================================================
// DragonBallHomeScreen (migrated to the design system)
//
// LEARN (what changed and why):
//  * Every visible word comes from AppStrings, every icon from AppIcons, every
//    spacing from AppSpace, every column count from Breakpoints. Switching the
//    app language now changes THIS screen too.
//  * One FavoriteHeart, one card per kind of item (character_card.dart,
//    planet_card.dart), one MessageBlock for empty / error states. The private
//    duplicates that used to live in this file are gone (~600 lines).
//  * Search filters LOCALLY (the whole catalogue is already loaded), so it
//    needs no debouncer and makes no request.
//  * Sorting no longer happens inside build(): see catalog_views.dart.
//  * Characters and Favorites open the detail screen WITH a nav context:
//    swipe to the next / previous character and a breadcrumb path.
//  * Hooks: useRef remembers "did I already apply the default tab?" across
//    rebuilds without causing one.
// =============================================================================
class DragonBallHomeScreen extends HookConsumerWidget {
  const DragonBallHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local UI state: it does not need to be shared across the application.
    final characterQuery = useState('');
    final planetQuery = useState('');

    final characterSearchFocusNode = useFocusNode();
    final planetSearchFocusNode = useFocusNode();

    final characterSearchController = useTextEditingController();
    final planetSearchController = useTextEditingController();

    final characterScrollController = useScrollController();
    final planetScrollController = useScrollController();

    final settings = ref.watch(appSettingsProvider);
    final s = ref.watch(stringsProvider);

    final selectedTab = useState(0);

    // Apply the saved "default tab" ONCE, when settings finish loading.
    // (Before, the effect also depended on settings.defaultTab, so changing
    // that setting in the Settings screen switched the tab behind it.)
    final appliedDefaultTab = useRef(false);

    useEffect(() {
      if (settings.isLoaded && !appliedDefaultTab.value) {
        appliedDefaultTab.value = true;
        selectedTab.value = settings.defaultTab;
      }

      return null;
    }, [settings.isLoaded]);

    // Scrolling a list dismisses the keyboard. Registered and removed with the
    // widget lifecycle.
    useEffect(() {
      void onCharacterScroll() {
        if (characterSearchFocusNode.hasFocus) {
          characterSearchFocusNode.unfocus();
        }
      }

      void onPlanetScroll() {
        if (planetSearchFocusNode.hasFocus) {
          planetSearchFocusNode.unfocus();
        }
      }

      characterScrollController.addListener(onCharacterScroll);
      planetScrollController.addListener(onPlanetScroll);

      return () {
        characterScrollController.removeListener(onCharacterScroll);
        planetScrollController.removeListener(onPlanetScroll);
      };
    }, [
      characterScrollController,
      planetScrollController,
      characterSearchFocusNode,
      planetSearchFocusNode,
    ]);

    // Side effects belong in a listener, not in the rendering logic.
    ref.listen<AsyncValue<DragonBallState>>(
      dragonBallControllerProvider,
      (previous, next) {
        final oldState = previous?.asData?.value;
        final newState = next.asData?.value;

        if (newState == null) return;

        final strings = ref.read(stringsProvider);
        final messages = <String>[];

        final characterError = newState.characterError;
        if (characterError != null &&
            characterError != oldState?.characterError &&
            newState.characters.isNotEmpty) {
          messages.add(strings.charactersError(characterError));
        }

        final planetError = newState.planetError;
        if (planetError != null &&
            planetError != oldState?.planetError &&
            newState.planets.isNotEmpty) {
          messages.add(strings.planetsError(planetError));
        }

        if (messages.isEmpty) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(messages.join('\n'))));
      },
    );

    final catalogAsync = ref.watch(dragonBallControllerProvider);

    // Only the count is selected from favorites for the app bar.
    final favoriteCount = ref.watch(
      dragonBallFavoritesProvider.select((ids) => ids.length),
    );

    final titles = <(String, String)>[
      (s.charactersTitle, s.charactersSubtitle),
      (s.exploreTitle, s.exploreSubtitle),
      (s.planetsTitle, s.planetsSubtitle),
      (s.favoritesTitle, s.favoritesSubtitle),
    ];

    final (title, subtitle) = titles[selectedTab.value];

    final controller = ref.read(dragonBallControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          Tooltip(
            message: s.favoritesCountTooltip,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.x1),
              child: Center(
                child: Chip(
                  avatar: Icon(
                    AppIcons.heartFill,
                    color: AppColors.of(context).favorite,
                    size: 16,
                  ),
                  label: Text('$favoriteCount'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.settingsTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(AppIcons.settings),
          ),
          const SizedBox(width: AppSpace.x1),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab.value,
        onDestinationSelected: (index) => selectedTab.value = index,
        destinations: [
          NavigationDestination(
            icon: const Icon(AppIcons.characters),
            selectedIcon: const Icon(AppIcons.charactersFill),
            label: s.tabCharacters,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.explore),
            selectedIcon: const Icon(AppIcons.exploreFill),
            label: s.tabExplore,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.planet),
            selectedIcon: const Icon(AppIcons.planetFill),
            label: s.tabPlanets,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.favorites),
            selectedIcon: const Icon(AppIcons.favoritesFill),
            label: s.tabFavorites,
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => MessageBlock(
          icon: AppIcons.offline,
          title: s.loadFailed,
          message: error.toString(),
          actionLabel: s.retry,
          onAction: () => ref.invalidate(dragonBallControllerProvider),
        ),
        data: (state) => IndexedStack(
          index: selectedTab.value,
          children: [
            _CharacterTab(
              state: state,
              isGridView: settings.charactersGridView,
              searchFocusNode: characterSearchFocusNode,
              searchController: characterSearchController,
              searchQuery: characterQuery.value,
              scrollController: characterScrollController,
              // Local filter: instant, no request, nothing to debounce.
              onSearchChanged: (query) {
                characterQuery.value = query;
                controller.applyCharacterFilters(name: query);
              },
              onOpenFilters: () => _showCharacterFilterSheet(
                context,
                ref,
                onResetSearch: () {
                  characterSearchController.clear();
                  characterQuery.value = '';
                },
              ),
              onRetry: controller.refresh,
              onReset: () {
                characterSearchController.clear();
                characterQuery.value = '';
                controller.resetCharacterFilters();
              },
            ),
            const ExploreScreen(),
            _PlanetTab(
              state: state,
              isGridView: settings.planetsGridView,
              searchFocusNode: planetSearchFocusNode,
              searchController: planetSearchController,
              searchQuery: planetQuery.value,
              scrollController: planetScrollController,
              onSearchChanged: (query) {
                planetQuery.value = query;
                controller.applyPlanetFilters(name: query);
              },
              onDestroyedChanged: (bool? destroyed) {
                if (destroyed == null) {
                  controller.applyPlanetFilters(clearDestroyedFilter: true);
                } else {
                  controller.applyPlanetFilters(isDestroyedFilter: destroyed);
                }
              },
              onRetry: controller.refresh,
              onReset: () {
                planetSearchController.clear();
                planetQuery.value = '';
                controller.resetPlanetFilters();
              },
            ),
            _FavoritesTab(
              isGridView: settings.favoritesGridView,
              onBrowseCharacters: () => selectedTab.value = 0,
            ),
          ],
        ),
      ),
    );
  }

  /// Option lists come from the catalog itself, so a new race / affiliation
  /// in the API appears here without editing a hard-coded list.
  void _showCharacterFilterSheet(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onResetSearch,
  }) {
    final currentState = ref.read(dragonBallControllerProvider).asData?.value;
    if (currentState == null) return;

    final all = ref.read(catalogProvider).asData?.value.characters.items ??
        const <Character>[];

    List<String> options(String Function(Character c) pick) => [
          kFilterAll,
          ...({for (final c in all) pick(c)}.toList()..sort()),
        ];

    final controller = ref.read(dragonBallControllerProvider.notifier);

    showCharacterFilterSheet(
      context: context,
      strings: ref.read(stringsProvider),
      selectedRace: currentState.selectedRace,
      selectedGender: currentState.selectedGender,
      selectedAffiliation: currentState.selectedAffiliation,
      races: options((c) => c.race),
      genders: options((c) => c.gender),
      affiliations: options((c) => c.affiliation),
      onResetSearch: onResetSearch,
      onApply: ({
        required String race,
        required String gender,
        required String affiliation,
        required bool resetSearch,
      }) {
        controller.applyCharacterFilters(
          name: resetSearch ? '' : null,
          race: race,
          gender: gender,
          affiliation: affiliation,
        );
      },
    );
  }
}

/// Keeps content readable on wide screens (web, tablets).
class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
        child: child,
      ),
    );
  }
}

/// Search field with a clear button. Shared by the Characters and Planets tabs.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.clearTooltip,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String clearTooltip;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(AppIcons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: clearTooltip,
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(AppIcons.close),
              ),
      ),
    );
  }
}

void _openCharacterWithPath(
  BuildContext context, {
  required PathSource source,
  required List<Character> list,
  required int index,
  required String Function(int id) heroTagFor,
}) {
  openCharacter(
    context,
    CharacterNavContext(
      source: source,
      siblingIds: [for (final c in list) c.id], // enables swipe prev / next
      index: index,
      heroTagFor: heroTagFor,
    ),
  );
}

void _openPlanet(BuildContext context, int planetId) {
  FocusManager.instance.primaryFocus?.unfocus();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlanetDetailView(planetId: planetId),
    ),
  );
}

// -----------------------------------------------------------------------------
// Characters tab
// -----------------------------------------------------------------------------
class _CharacterTab extends ConsumerWidget {
  const _CharacterTab({
    required this.state,
    required this.isGridView,
    required this.searchController,
    required this.searchQuery,
    required this.scrollController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onRetry,
    required this.onReset,
  });

  final DragonBallState state;
  final bool isGridView;
  final TextEditingController searchController;
  final String searchQuery;
  final ScrollController scrollController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Future<void> Function() onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final characters = ref.watch(sortedCharactersProvider);

    // Unfiltered emptiness: an active filter with no match is NOT an error.
    final hasCatalogData = ref.watch(
      catalogProvider.select(
        (a) => a.asData?.value.characters.items.isNotEmpty ?? false,
      ),
    );

    return _ContentWidth(
      child: Column(
        children: [
          if (state.isLoadingCharacters) const LinearProgressIndicator(),
          const CatalogStatusBanner(),
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
                  child: _SearchField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hint: s.searchHint,
                    clearTooltip: s.clearSearch,
                    query: searchQuery,
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpace.x2),
                Badge(
                  isLabelVisible: state.hasActiveCharacterFilters,
                  child: IconButton.filledTonal(
                    tooltip: s.filterTooltip,
                    onPressed: onOpenFilters,
                    icon: const Icon(AppIcons.filter),
                  ),
                ),
                if (searchQuery.isNotEmpty || state.hasActiveCharacterFilters)
                  IconButton(
                    tooltip: s.clearFiltersTooltip,
                    onPressed: onReset,
                    icon: const Icon(AppIcons.filterClear),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = Breakpoints.gridColumns(constraints.maxWidth);
                final extent = gridCardExtent(context);

                if (state.isLoadingCharacters && !hasCatalogData) {
                  return CatalogSkeleton(
                    isGridView: isGridView,
                    columns: columns,
                    mainAxisExtent: extent,
                  );
                }

                if (!hasCatalogData && state.characterError != null) {
                  return MessageBlock(
                    icon: AppIcons.offline,
                    title: s.loadFailed,
                    message: state.characterError,
                    actionLabel: s.retry,
                    onAction: () => onRetry(),
                  );
                }

                if (characters.isEmpty) {
                  return MessageBlock(
                    icon: AppIcons.empty,
                    title: s.noResultsTitle,
                    message: s.noResultsBody,
                    actionLabel: s.resetFilters,
                    onAction: onReset,
                  );
                }

                return CatalogResults<Character>(
                  items: characters,
                  isGridView: isGridView,
                  columns: columns,
                  gridMainAxisExtent: extent,
                  controller: scrollController,
                  onRefresh: onRetry,
                  itemBuilder: (context, character, index) {
                    void open() => _openCharacterWithPath(
                          context,
                          source: const FromAll(),
                          list: characters,
                          index: index,
                          heroTagFor: characterHeroTag,
                        );

                    return isGridView
                        ? CharacterGridCard(
                            key: ValueKey<int>(character.id),
                            character: character,
                            heroTag: characterHeroTag(character.id),
                            onTap: open,
                          )
                        : CharacterRow(
                            key: ValueKey<int>(character.id),
                            character: character,
                            heroTag: characterHeroTag(character.id),
                            onTap: open,
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Planets tab
// -----------------------------------------------------------------------------
class _PlanetTab extends ConsumerWidget {
  const _PlanetTab({
    required this.state,
    required this.isGridView,
    required this.searchController,
    required this.searchQuery,
    required this.scrollController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onDestroyedChanged,
    required this.onRetry,
    required this.onReset,
  });

  final DragonBallState state;
  final bool isGridView;
  final TextEditingController searchController;
  final String searchQuery;
  final ScrollController scrollController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onDestroyedChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final planets = ref.watch(sortedPlanetsProvider);

    final hasCatalogData = ref.watch(
      catalogProvider.select(
        (a) => a.asData?.value.planets.items.isNotEmpty ?? false,
      ),
    );

    return _ContentWidth(
      child: Column(
        children: [
          if (state.isLoadingPlanets) const LinearProgressIndicator(),
          const CatalogStatusBanner(),
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
                  child: _SearchField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    hint: s.searchPlanetsHint,
                    clearTooltip: s.clearSearch,
                    query: searchQuery,
                    onChanged: onSearchChanged,
                  ),
                ),
                if (searchQuery.isNotEmpty || state.hasActivePlanetFilters)
                  IconButton(
                    tooltip: s.clearFiltersTooltip,
                    onPressed: onReset,
                    icon: const Icon(AppIcons.filterClear),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpace.x2,
                children: [
                  ChoiceChip(
                    label: Text(s.allWorlds),
                    selected: state.isDestroyedFilter == null,
                    onSelected: (_) => onDestroyedChanged(null),
                  ),
                  ChoiceChip(
                    label: Text(s.intact),
                    selected: state.isDestroyedFilter == false,
                    onSelected: (_) => onDestroyedChanged(false),
                  ),
                  ChoiceChip(
                    label: Text(s.destroyed),
                    selected: state.isDestroyedFilter == true,
                    onSelected: (_) => onDestroyedChanged(true),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = Breakpoints.gridColumns(constraints.maxWidth);
                final extent = gridCardExtent(context, base: 230);

                if (state.isLoadingPlanets && !hasCatalogData) {
                  return CatalogSkeleton(
                    isGridView: isGridView,
                    columns: columns,
                    mainAxisExtent: extent,
                  );
                }

                if (!hasCatalogData && state.planetError != null) {
                  return MessageBlock(
                    icon: AppIcons.offline,
                    title: s.planetsLoadFailed,
                    message: state.planetError,
                    actionLabel: s.retry,
                    onAction: () => onRetry(),
                  );
                }

                if (planets.isEmpty) {
                  return MessageBlock(
                    icon: AppIcons.planet,
                    title: s.noPlanetsTitle,
                    message: s.noResultsBody,
                    actionLabel: s.resetFilters,
                    onAction: onReset,
                  );
                }

                return CatalogResults<Planet>(
                  items: planets,
                  isGridView: isGridView,
                  columns: columns,
                  gridMainAxisExtent: extent,
                  controller: scrollController,
                  onRefresh: onRetry,
                  itemBuilder: (context, planet, index) {
                    void open() => _openPlanet(context, planet.id);

                    return isGridView
                        ? PlanetGridCard(
                            key: ValueKey<int>(planet.id),
                            planet: planet,
                            onTap: open,
                          )
                        : PlanetRow(
                            key: ValueKey<int>(planet.id),
                            planet: planet,
                            onTap: open,
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Favorites tab
// -----------------------------------------------------------------------------
class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({
    required this.isGridView,
    required this.onBrowseCharacters,
  });

  final bool isGridView;
  final VoidCallback onBrowseCharacters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final favorites = ref.watch(favoriteCharactersProvider);
    final savedCount = ref.watch(
      dragonBallFavoritesProvider.select((ids) => ids.length),
    );

    // Saved ids the catalog does not know (yet).
    final missing = savedCount - favorites.length;

    Future<void> refresh() =>
        ref.read(dragonBallControllerProvider.notifier).refresh();

    return _ContentWidth(
      child: Column(
        children: [
          const CatalogStatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x4,
              AppSpace.x3,
              AppSpace.x4,
              AppSpace.x2,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.savedCharacters,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          if (missing > 0 && favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.favoritesNotLoaded(missing),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (savedCount == 0) {
                  return MessageBlock(
                    icon: AppIcons.favorites,
                    title: s.noFavoritesTitle,
                    message: s.noFavoritesBody,
                    actionLabel: s.browseCharacters,
                    onAction: onBrowseCharacters,
                  );
                }

                // Saved favorites exist but the catalog has none of them yet.
                if (favorites.isEmpty) {
                  return MessageBlock(
                    icon: AppIcons.offline,
                    title: s.favoritesUnavailable,
                    actionLabel: s.retry,
                    onAction: () => refresh(),
                  );
                }

                return CatalogResults<Character>(
                  items: favorites,
                  isGridView: isGridView,
                  columns: Breakpoints.gridColumns(constraints.maxWidth),
                  gridMainAxisExtent: gridCardExtent(context),
                  onRefresh: refresh,
                  itemBuilder: (context, character, index) {
                    void open() => _openCharacterWithPath(
                          context,
                          source: const FromFavorites(),
                          list: favorites,
                          index: index,
                          heroTagFor: favoriteCharacterHeroTag,
                        );

                    return isGridView
                        ? CharacterGridCard(
                            key: ValueKey<int>(character.id),
                            character: character,
                            heroTag: favoriteCharacterHeroTag(character.id),
                            onTap: open,
                          )
                        : CharacterRow(
                            key: ValueKey<int>(character.id),
                            character: character,
                            heroTag: favoriteCharacterHeroTag(character.id),
                            onTap: open,
                          );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}