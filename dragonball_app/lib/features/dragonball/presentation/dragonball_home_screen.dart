import 'package:cached_network_image/cached_network_image.dart';
import 'package:dragonball_app/features/dragonball/presentation/character_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dragonball_models.dart';
import 'catalog_components.dart';
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
    final favoritesGridView = useState(true);

    final preferencesLoaded = useState(false);

    final characterSearchFocusNode = useFocusNode();
    final planetSearchFocusNode = useFocusNode();

    final characterSearchController = useTextEditingController();
    final planetSearchController = useTextEditingController();

    final characterScrollController = useScrollController();
    final planetScrollController = useScrollController();

    // Reuse one debouncer for this widget's lifetime.
    final characterDebouncer = useMemoized(SearchDebouncer.new);
    final planetDebouncer = useMemoized(SearchDebouncer.new);


    useEffect(() {
      var cancelled = false;

      Future<void> loadViewPreferences() async {
        final prefs = await SharedPreferences.getInstance();

        if (cancelled) return;

        characterGridView.value =
            prefs.getBool('characters_grid_view') ?? true;

        planetGridView.value =
            prefs.getBool('planets_grid_view') ?? true;

        favoritesGridView.value =
            prefs.getBool('favorites_grid_view') ?? true;

        preferencesLoaded.value = true;
      }

      loadViewPreferences();

      return () {
        cancelled = true;
      };
    }, []);

    useEffect(() {
      if (!preferencesLoaded.value) return null;

      Future<void> saveViewPreferences() async {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool(
          'characters_grid_view',
          characterGridView.value,
        );

        await prefs.setBool(
          'planets_grid_view',
          planetGridView.value,
        );

        await prefs.setBool(
          'favorites_grid_view',
          favoritesGridView.value,
        );
      }

      saveViewPreferences();

      return null;
    }, [
      preferencesLoaded.value,
      characterGridView.value,
      planetGridView.value,
      favoritesGridView.value,
    ]);

    useEffect(() {
      return characterDebouncer.dispose;
    }, [characterDebouncer]);

    useEffect(() {
      return planetDebouncer.dispose;
    }, [planetDebouncer]);

    // Register and clean up scroll listeners with the widget lifecycle.
    useEffect(() {
      void onCharacterScroll() {
        if (characterSearchFocusNode.hasFocus) {
          characterSearchFocusNode.unfocus();
        }

        if (!characterScrollController.hasClients) return;

        final position = characterScrollController.position;

        if (position.pixels >= position.maxScrollExtent - 240) {
          ref
              .read(dragonBallControllerProvider.notifier)
              .loadNextCharacters();
        }
      }

      void onPlanetScroll() {
        if (planetSearchFocusNode.hasFocus) {
          planetSearchFocusNode.unfocus();
        }

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

        final messages = <String>[];

        final characterError = newState.characterError;
        final characterErrorChanged =
            characterError != null &&
            characterError != oldState?.characterError;

        if (characterErrorChanged && newState.characters.isNotEmpty) {
          messages.add('Characters: $characterError');
        }

        final planetError = newState.planetError;
        final planetErrorChanged =
            planetError != null &&
            planetError != oldState?.planetError;

        if (planetErrorChanged && newState.planets.isNotEmpty) {
          messages.add('Planets: $planetError');
        }

        if (messages.isEmpty) return;

        final messenger = ScaffoldMessenger.of(context);

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(messages.join('\n')),
            ),
          );
      },
    );


    final catalogAsync = ref.watch(dragonBallControllerProvider);

    // Only the count is selected from favorites for the app bar.
    final favoriteCount = ref.watch(
      dragonBallFavoritesProvider.select((ids) => ids.length),
    );

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
              searchFocusNode: characterSearchFocusNode,
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
                    characterDebouncer.cancel();
                    characterSearchController.clear();
                    characterQuery.value = '';
                  },
                );
              },
              onRetry: () => ref
                  .read(dragonBallControllerProvider.notifier)
                  .applyCharacterFilters(),
              
              onReset: () {
                characterDebouncer.cancel();
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
              searchFocusNode: planetSearchFocusNode,
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
                planetDebouncer.cancel();
                planetSearchController.clear();
                planetQuery.value = '';

                ref
                    .read(dragonBallControllerProvider.notifier)
                    .resetPlanetFilters();
              },
            ),
            _FavoritesTab(
              isGridView: favoritesGridView.value,
              onViewChanged: (value) => favoritesGridView.value = value,
              onBrowseCharacters: () {
                selectedTab.value = 0;
              },
            ),
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
    final currentState = ref
        .read(dragonBallControllerProvider)
        .asData
        ?.value;

    if (currentState == null) return;

    final controller =
        ref.read(dragonBallControllerProvider.notifier);

    showCharacterFilterSheet(
      context: context,
      selectedRace: currentState.selectedRace,
      selectedGender: currentState.selectedGender,
      selectedAffiliation: currentState.selectedAffiliation,
      races: _races,
      genders: _genders,
      affiliations: _affiliations,
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
    required this.searchFocusNode,
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
  final FocusNode searchFocusNode;

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
                  focusNode: searchFocusNode,
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
            ViewModeSelector(
              isGridView: isGridView,
              onChanged: onViewChanged,
            ),
            const Spacer(),
            if (state.hasActiveCharacterFilters)
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (state.isLoadingCharacters &&
                  state.characters.isEmpty) {
                return CatalogSkeleton(
                  isGridView: isGridView,
                  columns: _gridColumns(constraints.maxWidth),
                  gridAspectRatio: 0.66,
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
                  subtitle: 'Try another search or clear your filters.',
                  onAction: onReset,
                  actionLabel: 'Reset',
                );
              }

              final columns = _gridColumns(constraints.maxWidth);

              return CatalogResults<Character>(
                items: state.characters,
                isGridView: isGridView,
                columns: columns,
                gridAspectRatio: 0.66,
                controller: scrollController,
                isLoadingMore: state.isLoadingMoreCharacters,
                onRefresh: onRetry,
                itemBuilder: (context, character) {
                  return isGridView
                      ? _CharacterTile(character: character)
                      : _CharacterListTile(character: character);
                },
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
    required this.searchFocusNode,
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
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
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
              ViewModeSelector(
                isGridView: isGridView,
                onChanged: onViewChanged,
              ),
              const Spacer(),
              if (state.hasActivePlanetFilters)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Clear filters'),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (state.isLoadingPlanets && state.planets.isEmpty) {
                return CatalogSkeleton(
                  isGridView: isGridView,
                  columns: _gridColumns(constraints.maxWidth),
                  gridAspectRatio: 0.78,
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
                  subtitle: 'Try another search or clear your filters.',
                  onAction: onReset,
                  actionLabel: 'Reset',
                );
              }

              final columns = _gridColumns(constraints.maxWidth);

              return CatalogResults<Planet>(
                items: state.planets,
                isGridView: isGridView,
                columns: columns,
                gridAspectRatio: 0.78,
                controller: scrollController,
                isLoadingMore: state.isLoadingMorePlanets,
                onRefresh: onRetry,
                itemBuilder: (context, planet) {
                  return isGridView
                      ? _PlanetTile(planet: planet)
                      : _PlanetListTile(planet: planet);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCharacterProfile(context, character.id),
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
                      tag: characterHeroTag(character.id),
                      child: CachedNetworkImage(
                        imageUrl: character.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                    child: FavoriteToggleButton(
                      characterId: character.id,
                      overlay: true,
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


class _CharacterListTile extends StatelessWidget {
  const _CharacterListTile({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {

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
            tag: characterHeroTag(character.id),
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
            FavoriteToggleButton(characterId: character.id),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => openCharacterProfile(context, character.id),
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
          FocusManager.instance.primaryFocus?.unfocus();
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
          FocusManager.instance.primaryFocus?.unfocus();
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



class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab({
    required this.isGridView,
    required this.onViewChanged,
    required this.onBrowseCharacters,
  });

  final bool isGridView;
  final ValueChanged<bool> onViewChanged;
  final VoidCallback onBrowseCharacters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(dragonBallFavoritesProvider);
    final ids = favoriteIds.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved characters',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ViewModeSelector(
                isGridView: isGridView,
                onChanged: onViewChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: ids.isEmpty
            ? _EmptyView(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                subtitle:
                    'Tap the heart on a character card to save a warrior.',
                onAction: onBrowseCharacters,
                actionLabel: 'Browse characters',
                actionIcon: Icons.people_outline,
              )
            : isGridView
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = _gridColumns(
                        constraints.maxWidth,
                      );

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ids.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.66,
                        ),
                        itemBuilder: (context, index) {
                          return _FavoriteCharacterTile(
                            characterId: ids[index],
                          );
                        },
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ids.length,
                    itemBuilder: (context, index) {
                      return _FavoriteCharacterListTile(
                        characterId: ids[index],
                      );
                    },
                  ),
        ),
      ],
    );
  }
}



class _FavoriteCharacterListTile extends ConsumerWidget {
  const _FavoriteCharacterListTile({
    required this.characterId,
  });

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      characterProfileProvider(characterId),
    );

    return profileAsync.when(
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: const SizedBox(
          height: 88,
          child: Center(
            child: LinearProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Icon(Icons.cloud_off),
          title: const Text('Unable to load character'),
          trailing: FavoriteToggleButton(characterId: characterId),
        ),
      ),
      data: (character) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          leading: SizedBox(
            width: 64,
            height: 64,
            child: Hero(
              tag: favoriteCharacterHeroTag(character.id),
              child: CachedNetworkImage(
                imageUrl: character.imageUrl,
                fit: BoxFit.contain,
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
          subtitle: Text(
            '${character.race} • ${character.gender}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: FavoriteToggleButton(characterId: characterId),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CharacterProfileView(
                  characterId: characterId,
                  fromFavorites: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

 class _FavoriteCharacterTile extends ConsumerWidget {
  const _FavoriteCharacterTile({required this.characterId});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      characterProfileProvider(characterId),
    );

    return profileAsync.when(
      loading: () => const CatalogSkeletonCard(),
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
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CharacterProfileView(
                  characterId: characterId,
                  fromFavorites: true,
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
                          child: Hero(
                            tag: favoriteCharacterHeroTag(character.id),
                            child: CachedNetworkImage(
                              imageUrl: character.imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, size: 48),
                            ),
                          )
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: FavoriteToggleButton(
                          characterId: characterId,
                          overlay: true,
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
    this.onAction,
    this.actionLabel = 'Reset',
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String actionLabel;
  final IconData? actionIcon;

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
            Text(
              subtitle,
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              if (actionIcon != null)
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                )
              else
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
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
