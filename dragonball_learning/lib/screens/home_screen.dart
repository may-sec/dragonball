import 'package:dragonball_learning/widgets/character_card.dart';
import 'package:flutter/material.dart';

import '../models/character.dart';
import '../services/dragon_ball_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DragonBallApi _api = DragonBallApi();
  late Future<List<Character>> _charactersFuture;

  final TextEditingController _searchController = TextEditingController();

  

  void _retryFetchCharacters() {
    setState(() {
      _charactersFuture = _api.fetchCharacters();
    });
  }

  @override
  void initState() {
    super.initState();

    _charactersFuture = _api.fetchCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dragon Ball Universe'),
        centerTitle: true,
      ),

      body: FutureBuilder<List<Character>>(
        future: _charactersFuture,

        builder: (context, snapshot) {

          // 1. Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Unable to load characters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _retryFetchCharacters,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No characters found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // 4. Success state
          final characters = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),

            itemCount: characters.length,

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),

            itemBuilder: (context, index) {
              final character = characters[index];

              return CharacterCard(character: character);
            },
          );
        },
      ),
    );
  }
}