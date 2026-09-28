// lib/features/dragonball/presentation/dragonball_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dragonball_notifier.dart';
import 'character_detail_view.dart';

class DragonBallHomeScreen extends ConsumerStatefulWidget {
  const DragonBallHomeScreen({super.key});

  @override
  ConsumerState<DragonBallHomeScreen> createState() => _DragonBallHomeScreenState();
}

class _DragonBallHomeScreenState extends ConsumerState<DragonBallHomeScreen> {
  int _currentTabIndex = 0;
  late final ScrollController _charactersScrollController;
  late final ScrollController _planetsScrollController;
  late final TextEditingController _charSearchController;
  late final TextEditingController _planetSearchController;

  static const _races = [
    'ALL', 'Saiyan', 'Human', 'Namekian', 'Majin', 'Frieza Race',
    'Android', 'Jiren Race', 'God', 'Angel', 'Evil', 'Nucleico', 'Nucleico benigno'
  ];
  static const _genders = ['ALL', 'Male', 'Female', 'Unknown'];
  static const _affiliations = [
    'ALL', 'Z Fighter', 'Red Ribbon Army', 'Namekian Warrior',
    'Freelancer', 'Army of Frieza', 'Pride Troopers', 'Villain', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _charSearchController = TextEditingController();
    _planetSearchController = TextEditingController();
    _charactersScrollController = ScrollController()..addListener(_onCharactersScroll);
    _planetsScrollController = ScrollController()..addListener(_onPlanetsScroll);
  }

  void _onCharactersScroll() {
    if (_charactersScrollController.position.pixels >=
        _charactersScrollController.position.maxScrollExtent - 200) {
      ref.read(dragonBallNotifierProvider.notifier).loadNextCharacters();
    }
  }

  void _onPlanetsScroll() {
    if (_planetsScrollController.position.pixels >=
        _planetsScrollController.position.maxScrollExtent - 200) {
      ref.read(dragonBallNotifierProvider.notifier).loadNextPlanets();
    }
  }

  @override
  void dispose() {
    _charSearchController.dispose();
    _planetSearchController.dispose();
    _charactersScrollController.dispose();
    _planetsScrollController.dispose();
    super.dispose();
  }

  void _showCharacterFilterSheet() {
    final state = ref.read(dragonBallNotifierProvider);
    final notifier = ref.read(dragonBallNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(dragonBallNotifierProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Characters', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          notifier.resetCharacterFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset All'),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Race', style: Theme.of(context).textTheme.titleSmall),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: _races.map((race) {
                      return ChoiceChip(
                        label: Text(race),
                        selected: race == currentState.selectedRace,
                        onSelected: (_) => notifier.applyCharacterFilters(race: race),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentState.selectedGender,
                          decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.applyCharacterFilters(gender: val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentState.selectedAffiliation,
                          decoration: const InputDecoration(labelText: 'Affiliation', border: OutlineInputBorder()),
                          items: _affiliations.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            if (val != null) notifier.applyCharacterFilters(affiliation: val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dragonBallNotifierProvider);
    final notifier = ref.read(dragonBallNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTabIndex == 0 ? 'Z-Fighters & Villains' : 'Cosmic Realms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.loadInitial,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) => setState(() => _currentTabIndex = index),
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
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // ================= VIEW 1: CHARACTERS =================
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _charSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search characters...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _charSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _charSearchController.clear();
                                    notifier.applyCharacterFilters(name: '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (val) => notifier.applyCharacterFilters(name: val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: state.hasActiveCharacterFilters,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.tune),
                        onPressed: _showCharacterFilterSheet,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : state.characters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_off, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No warriors found.'),
                                TextButton(
                                  onPressed: () {
                                    _charSearchController.clear();
                                    notifier.resetCharacterFilters();
                                  },
                                  child: const Text('Reset Filters'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _charactersScrollController,
                            itemCount: state.characters.length + (state.isLoadingMoreCharacters ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.characters.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  ),
                                );
                              }
                              final character = state.characters[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CachedNetworkImage(
                                      imageUrl: character.imageUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => const Icon(Icons.downloading, size: 24),
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  ),
                                  title: Text(character.name),
                                  subtitle: Text(
                                    '${character.race} • ${character.gender}\nAffiliation: ${character.affiliation}',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CharacterDetailView(characterId: character.id),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),

          // ================= VIEW 2: PLANETS =================
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _planetSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search planets...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _planetSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _planetSearchController.clear();
                              notifier.applyPlanetFilters(name: '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (val) => notifier.applyPlanetFilters(name: val),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: state.isDestroyedFilter == null,
                      onSelected: (_) => notifier.applyPlanetFilters(isDestroyed: () => null),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Intact'),
                      selected: state.isDestroyedFilter == false,
                      onSelected: (_) => notifier.applyPlanetFilters(isDestroyed: () => false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Destroyed'),
                      selected: state.isDestroyedFilter == true,
                      onSelected: (_) => notifier.applyPlanetFilters(isDestroyed: () => true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : state.planets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.public_off, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No planets found.'),
                                TextButton(
                                  onPressed: () {
                                    _planetSearchController.clear();
                                    notifier.resetPlanetFilters();
                                  },
                                  child: const Text('Reset Planet Filters'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _planetsScrollController,
                            itemCount: state.planets.length + (state.isLoadingMorePlanets ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.planets.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  ),
                                );
                              }
                              final planet = state.planets[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CachedNetworkImage(
                                      imageUrl: planet.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Icon(Icons.public, size: 24),
                                      errorWidget: (_, __, ___) => const Icon(Icons.public_off),
                                    ),
                                  ),
                                  title: Text(planet.name),
                                  subtitle: Text(
                                    planet.isDestroyed ? 'Status: Destroyed' : 'Status: Intact',
                                    style: TextStyle(
                                      color: planet.isDestroyed ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}