import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/dragonball_models.dart';
import 'character_detail_view.dart';
import 'dragonball_notifier.dart';
import 'dragonball_state.dart';
import 'planet_detail_view.dart';
import 'search_debouncer.dart';

class DragonBallHomeScreen extends HookConsumerWidget {
  const DragonBallHomeScreen({super.key});

  static const _races = [
    'ALL',
    'Saiyan',
    'Human',
    'Namekian',
    'Majin',
    'Frieza Race',
    'Android',
    'Jiren Race',
    'God',
    'Angel',
    'Evil',
  ];

  static const _genders = [
    'ALL',
    'Male',
    'Female',
    'Unknown',
  ];

  static const _affiliations = [
    'ALL',
    'Z Fighter',
    'Red Ribbon Army',
    'Namekian Warrior',
    'Freelancer',
    'Army of Frieza',
    'Pride Troopers',
    'Villain',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local UI state: it does not need to be shared across the application.
    final selectedTab = useState(0);
    final characterQuery = useState('');
    final planetQuery = useState('');

    final characterGridView = useState(true);
    final planetGridView = useState(true);

    final characterSearchController = useTextEditingController();
    final planetSearchController = useTextEditingController();

    final characterScrollController = useScrollController();
    final planetScrollController = useScrollController();

    // Reuse one debouncer for this widget's lifetime.
    final characterDebouncer = useMemoized(SearchDebouncer.new);
    final planetDebouncer = useMemoized(SearchDebouncer.new);

    useEffect(() {
      return characterDebouncer.dispose;
    }, [characterDebouncer]);

    useEffect(() {
      return planetDebouncer.dispose;
    }, [planetDebouncer]);

    // Register and clean up scroll listeners with the widget lifecycle.
    useEffect(() {
      void onCharacterScroll() {
        if (!characterScrollController.hasClients) return;

        final position = characterScrollController.position;

        if (position.pixels >= position.maxScrollExtent - 240) {
          ref
              .read(dragonBallControllerProvider.notifier)
              .loadNextCharacters();
        }
      }

      void onPlanetScroll() {
        if (!planetScrollController.hasClients) return;

        final position = planetScrollController.position;

        if (position.pixels >= position.maxScrollExtent - 240) {
          ref
              .read(dragonBallControllerProvider.notifier)
              .loadNextPlanets();
        }
      }

      characterScrollController.addListener(onCharacterScroll);
      planetScrollController.addListener(onPlanetScroll);

      return () {
        characterScrollController.removeListener(onCharacterScroll);
        planetScrollController.removeListener(onPlanetScroll);
      };
    }, [characterScrollController, planetScrollController]);

    // Side effects belong in a listener, not in the rendering logic.
    ref.listen<AsyncValue<DragonBallState>>(
      dragonBallControllerProvider,
      (previous, next) {
        final oldState = previous?.asData?.value;
        final newState = next.asData?.value;

        if (newState == null) return;

        final messenger = ScaffoldMessenger.of(context);

        if (newState.characterError != null &&
            newState.characterError != oldState?.characterError) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Characters: ${newState.characterError}'),
              ),
            );
        }

        if (newState.planetError != null &&
            newState.planetError != oldState?.planetError) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Planets: ${newState.planetError}'),
              ),
            );
        }
      },
    );

    final catalogAsync = ref.watch(dragonBallControllerProvider);

    // Only the count is selected from favorites for the app bar.
    final favoriteCount = ref.watch(
      dragonBallFavoritesProvider.select((ids) => ids.length),
    );

    final favoriteIds = ref.watch(dragonBallFavoritesProvider);

    final isCharacterTab = selectedTab.value == 0;
    final isPlanetTab = selectedTab.value == 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCharacterTab
                  ? 'Warrior database'
                  : isPlanetTab
                      ? 'Cosmic atlas'
                      : 'Favorite warriors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              isCharacterTab
                  ? 'Explore fighters and villains'
                  : isPlanetTab
                      ? 'Explore worlds across the universe'
                      : 'Your saved characters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Favorite characters in the current catalogue',
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Chip(
                  avatar: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
                  label: Text('$favoriteCount'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh catalogue',
            onPressed: () {
              ref.read(dragonBallControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab.value,
        onDestinationSelected: (index) {
          selectedTab.value = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Characters',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Planets',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
      body: catalogAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, _) => _FullErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(dragonBallControllerProvider);
          },
        ),
        data: (state) => IndexedStack(
          index: selectedTab.value,
          children: [
            _CharacterTab(
              state: state,
              isGridView: characterGridView.value,
              onViewChanged: (value) => characterGridView.value = value,
              searchController: characterSearchController,
              searchQuery: characterQuery.value,
              scrollController: characterScrollController,
              onSearchChanged: (query) {
                characterQuery.value = query;
                characterDebouncer.run(
                  const Duration(milliseconds: 350),
                  () {
                    ref
                        .read(dragonBallControllerProvider.notifier)
                        .applyCharacterFilters(name: query);
                  },
                );
              },
              onOpenFilters: () {
                _showCharacterFilterSheet(
                  context,
                  ref,
                  onResetSearch: () {
                    characterSearchController.clear();
                    characterQuery.value = '';
                  },
                );
              },
              onRetry: () => ref
                  .read(dragonBallControllerProvider.notifier)
                  .applyCharacterFilters(),
              onReset: () {
                characterSearchController.clear();
                characterQuery.value = '';
                ref
                    .read(dragonBallControllerProvider.notifier)
                    .resetCharacterFilters();
              },
            ),
            _PlanetTab(
              state: state,
              isGridView: planetGridView.value,
              onViewChanged: (value) => planetGridView.value = value,
              searchController: planetSearchController,
              searchQuery: planetQuery.value,
              scrollController: planetScrollController,
              onSearchChanged: (query) {
                planetQuery.value = query;
                planetDebouncer.run(
                  const Duration(milliseconds: 350),
                  () {
                    ref
                        .read(dragonBallControllerProvider.notifier)
                        .applyPlanetFilters(name: query);
                  },
                );
              },
              onDestroyedChanged: (bool? destroyed) {
                final controller =
                    ref.read(dragonBallControllerProvider.notifier);

                if (destroyed == null) {
                  controller.applyPlanetFilters(clearDestroyedFilter: true);
                } else {
                  controller.applyPlanetFilters(isDestroyedFilter: destroyed);
                }
              },
              onRetry: () => ref
                  .read(dragonBallControllerProvider.notifier)
                  .applyPlanetFilters(),
              onReset: () {
                planetSearchController.clear();
                planetQuery.value = '';
                ref
                    .read(dragonBallControllerProvider.notifier)
                    .resetPlanetFilters();
              },
            ),
            _FavoritesTab(favoriteIds: favoriteIds),
          ],
        ),
      ),
    );
  }

  void _showCharacterFilterSheet(
    BuildContext context,
    WidgetRef ref, {
    required VoidCallback onResetSearch,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref
                  .watch(dragonBallControllerProvider)
                  .asData
                  ?.value;

              if (state == null) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final controller =
                  ref.read(dragonBallControllerProvider.notifier);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter characters',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onResetSearch();
                            controller.resetCharacterFilters();
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Reset all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Race',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _races.map((race) {
                        return ChoiceChip(
                          label: Text(race),
                          selected: state.selectedRace == race,
                          onSelected: (_) {
                            controller.applyCharacterFilters(race: race);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: state.selectedGender,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                            ),
                            items: _genders.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.applyCharacterFilters(
                                  gender: value,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: state.selectedAffiliation,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Affiliation',
                              border: OutlineInputBorder(),
                            ),
                            items: _affiliations.map((affiliation) {
                              return DropdownMenuItem(
                                value: affiliation,
                                child: Text(
                                  affiliation,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.applyCharacterFilters(
                                  affiliation: value,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Apply and close'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}


class _CharacterTab extends StatelessWidget {
  const _CharacterTab({
    required this.state,
    required this.isGridView,
    required this.onViewChanged,
    required this.searchController,
    required this.searchQuery,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onRetry,
    required this.onReset,
  });

  final DragonBallState state;
  final bool isGridView;
  final ValueChanged<bool> onViewChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final Future<void> Function() onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search warriors...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: state.hasActiveCharacterFilters,
                child: IconButton.filledTonal(
                  onPressed: onOpenFilters,
                  icon: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Text('View'),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
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
                onSelectionChanged: (selection) {
                  onViewChanged(selection.first);
                },
              ),
            ],
          ),
        ),
        if (state.isLoadingCharacters &&
            state.characters.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        if (state.hasActiveCharacterFilters)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear filters'),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (state.isLoadingCharacters &&
                  state.characters.isEmpty) {
                return _SkeletonGrid(
                  columns: _gridColumns(constraints.maxWidth),
                );
              }

              if (state.characterError != null &&
                  state.characters.isEmpty) {
                return _InlineError(
                  message: state.characterError!,
                  onRetry: onRetry,
                );
              }

              if (state.characters.isEmpty) {
                return _EmptyView(
                  icon: Icons.person_search,
                  title: 'No warriors found',
                  subtitle:
                      'Try another search or clear your filters.',
                  onReset: onReset,
                );
              }

              final columns = _gridColumns(constraints.maxWidth);

              return RefreshIndicator(
                onRefresh: onRetry,
                child: isGridView
                    ? GridView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                        itemCount: state.characters.length +
                            (state.isLoadingMoreCharacters ? columns : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.characters.length) {
                            return const _SkeletonCard();
                          }

                          return _CharacterTile(
                            character: state.characters[index],
                          );
                        },
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: state.characters.length +
                            (state.isLoadingMoreCharacters ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.characters.length) {
                            return const _LoadingMore();
                          }

                          return _CharacterListTile(
                            character: state.characters[index],
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class _PlanetTab extends StatelessWidget {
  const _PlanetTab({
    required this.state,
    required this.isGridView,
    required this.onViewChanged,
    required this.searchController,
    required this.searchQuery,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onDestroyedChanged,
    required this.onRetry,
    required this.onReset,
  });

  final DragonBallState state;
  final bool isGridView;
  final ValueChanged<bool> onViewChanged;
  final TextEditingController searchController;
  final String searchQuery;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onDestroyedChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search planets...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All worlds'),
                selected: state.isDestroyedFilter == null,
                onSelected: (_) => onDestroyedChanged(null),
              ),
              ChoiceChip(
                label: const Text('Intact'),
                selected: state.isDestroyedFilter == false,
                onSelected: (_) => onDestroyedChanged(false),
              ),
              ChoiceChip(
                label: const Text('Destroyed'),
                selected: state.isDestroyedFilter == true,
                onSelected: (_) => onDestroyedChanged(true),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Text('View'),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
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
                onSelectionChanged: (selection) {
                  onViewChanged(selection.first);
                },
              ),
            ],
          ),
        ),
        if (state.isLoadingPlanets && state.planets.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        if (state.hasActivePlanetFilters)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Clear filters'),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (state.isLoadingPlanets &&
                  state.planets.isEmpty) {
                return _SkeletonGrid(
                  columns: _gridColumns(constraints.maxWidth),
                );
              }

              if (state.planetError != null &&
                  state.planets.isEmpty) {
                return _InlineError(
                  message: state.planetError!,
                  onRetry: onRetry,
                );
              }

              if (state.planets.isEmpty) {
                return _EmptyView(
                  icon: Icons.public_off,
                  title: 'No planets found',
                  subtitle:
                      'Try another search or clear your filters.',
                  onReset: onReset,
                );
              }

              final columns = _gridColumns(constraints.maxWidth);

              return RefreshIndicator(
                onRefresh: onRetry,
                child: isGridView
                    ? GridView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: state.planets.length +
                            (state.isLoadingMorePlanets ? columns : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.planets.length) {
                            return const _SkeletonCard();
                          }

                          return _PlanetTile(
                            planet: state.planets[index],
                          );
                        },
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: state.planets.length +
                            (state.isLoadingMorePlanets ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.planets.length) {
                            return const _LoadingMore();
                          }

                          return _PlanetListTile(
                            planet: state.planets[index],
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}


class _CharacterTile extends ConsumerWidget {
  const _CharacterTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      dragonBallFavoritesProvider.select(
        (ids) => ids.contains(character.id),
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CharacterProfileView(
                characterId: character.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Theme.of(context)
                        .colorScheme.surfaceContainer,
                    padding: const EdgeInsets.all(8),
                    child: Hero(
                      tag: 'character-${character.id}',
                      child: CachedNetworkImage(
                        imageUrl: character.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Theme.of(context)
                          .colorScheme.surface
                          .withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite
                            ? 'Remove favorite'
                            : 'Add favorite',
                        onPressed: () {
                          ref
                              .read(dragonBallFavoritesProvider.notifier)
                              .toggle(character.id);
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${character.race} • ${character.gender}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          character.ki,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
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


class _CharacterListTile extends ConsumerWidget {
  const _CharacterListTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      dragonBallFavoritesProvider.select(
        (ids) => ids.contains(character.id),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        leading: SizedBox(
          width: 64,
          height: 76,
          child: Hero(
            tag: 'character-${character.id}',
            child: CachedNetworkImage(
              imageUrl: character.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.person_outline),
            ),
          ),
        ),
        title: Text(
          character.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${character.race} • ${character.gender}\nKi: ${character.ki}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
              onPressed: () {
                ref
                    .read(dragonBallFavoritesProvider.notifier)
                    .toggle(character.id);
              },
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CharacterProfileView(
                characterId: character.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanetListTile extends StatelessWidget {
  const _PlanetListTile({required this.planet});

  final Planet planet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        leading: SizedBox(
          width: 64,
          height: 64,
          child: CachedNetworkImage(
            imageUrl: planet.imageUrl,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) =>
                const Icon(Icons.public_off),
          ),
        ),
        title: Text(
          planet.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(
              planet.isDestroyed
                  ? Icons.broken_image_outlined
                  : Icons.check_circle_outline,
              size: 16,
              color: planet.isDestroyed
                  ? colorScheme.error
                  : Colors.green,
            ),
            const SizedBox(width: 6),
            Text(planet.isDestroyed ? 'Destroyed' : 'Intact'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlanetDetailView(
                planetId: planet.id,
              ),
            ),
          );
        },
      ),
    );
  }
}


class _PlanetTile extends StatelessWidget {
  const _PlanetTile({required this.planet});

  final Planet planet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlanetDetailView(
                planetId: planet.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: colorScheme.surfaceContainer,
                padding: const EdgeInsets.all(12),
                child: CachedNetworkImage(
                  imageUrl: planet.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: Icon(Icons.public, size: 36),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.public_off, size: 36),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        planet.isDestroyed
                            ? Icons.broken_image_outlined
                            : Icons.check_circle_outline,
                        size: 16,
                        color: planet.isDestroyed
                            ? colorScheme.error
                            : Colors.green,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          planet.isDestroyed ? 'Destroyed' : 'Intact',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
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


class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab({required this.favoriteIds});

  final Set<int> favoriteIds;

  @override
  Widget build(BuildContext context) {
    if (favoriteIds.isEmpty) {
      return const _EmptyView(
        icon: Icons.favorite_border,
        title: 'No favorites yet',
        subtitle: 'Tap the heart on a character card to save a warrior.',
        onReset: _doNothing,
      );
    }

    final ids = favoriteIds.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _gridColumns(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ids.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.66,
          ),
          itemBuilder: (context, index) {
            return _FavoriteCharacterTile(characterId: ids[index]);
          },
        );
      },
    );
  }
}

void _doNothing() {}

class _FavoriteCharacterTile extends ConsumerWidget {
  const _FavoriteCharacterTile({required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      characterProfileProvider(characterId),
    );

    return profileAsync.when(
      loading: () => const _SkeletonCard(),
      error: (_, __) => Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 30),
                const SizedBox(height: 8),
                const Text('Unable to load character'),
                TextButton(
                  onPressed: () {
                    ref.invalidate(
                      characterProfileProvider(characterId),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (character) {
        final isFavorite = ref.watch(
          dragonBallFavoritesProvider.select(
            (ids) => ids.contains(characterId),
          ),
        );

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CharacterProfileView(
                    characterId: characterId,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme.surfaceContainer,
                          padding: const EdgeInsets.all(8),
                          child: CachedNetworkImage(
                            imageUrl: character.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 48),
                          )
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filledTonal(
                          onPressed: () {
                            ref
                                .read(
                                  dragonBallFavoritesProvider.notifier,
                                )
                                .toggle(characterId);
                          },
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    character.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _LoadingMore extends StatelessWidget {
  const _LoadingMore();

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

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullErrorView extends StatelessWidget {
  const _FullErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onReset,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReset,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}


int _gridColumns(double width) {
  if (width < 600) return 2;
  if (width < 900) return 3;
  if (width < 1200) return 4;
  return 5;
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: columns * 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

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
