import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dragonball_notifier.dart';

class PlanetDetailView extends ConsumerWidget {
  const PlanetDetailView({
    super.key,
    required this.planetId,
  });

  final int planetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planetAsync = ref.watch(planetDetailProvider(planetId));

    return Scaffold(
      appBar: AppBar(title: const Text('Planet dossier')),
      body: planetAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_off, size: 48),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(planetDetailProvider(planetId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (planet) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: CachedNetworkImage(
                imageUrl: planet.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.public,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              planet.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(
                  planet.isDestroyed ? Icons.broken_image : Icons.public,
                  size: 18,
                ),
                label: Text(
                  planet.isDestroyed ? 'Destroyed' : 'Intact',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              planet.description.isEmpty
                  ? 'No description is available for this planet.'
                  : planet.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (planet.characters.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Associated characters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...planet.characters.map(
                (character) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(character.name),
                    subtitle: Text(character.race),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}