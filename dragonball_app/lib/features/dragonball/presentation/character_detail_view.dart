// lib/features/dragonball/presentation/character_detail_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dragonball_notifier.dart';

class CharacterDetailView extends ConsumerWidget {
  final int characterId;

  const CharacterDetailView({super.key, required this.characterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(characterDetailProvider(characterId));

    return Scaffold(
      appBar: AppBar(title: const Text('Character File')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (character) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  height: 240,
                  child: CachedNetworkImage(
                    imageUrl: character.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(character.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('Max Ki: ${character.maxKi}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              Text(character.description),
              const SizedBox(height: 20),

              // Origin Planet Tile
              if (character.originPlanet != null) ...[
                Text('Origin Planet', style: Theme.of(context).textTheme.titleMedium),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: CachedNetworkImage(
                        imageUrl: character.originPlanet!.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(character.originPlanet!.name),
                    subtitle: Text(
                      character.originPlanet!.isDestroyed ? 'Destroyed' : 'Active',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Transformations Gallery
              if (character.transformations.isNotEmpty) ...[
                Text('Transformations (${character.transformations.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: character.transformations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final trans = character.transformations[index];
                      return SizedBox(
                        width: 110,
                        child: Column(
                          children: [
                            Expanded(
                              child: CachedNetworkImage(
                                imageUrl: trans.imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trans.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              trans.ki,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}