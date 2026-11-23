import 'package:dragonball_learning/models/character.dart';
import 'package:dragonball_learning/screens/character_details_screen.dart';
import 'package:flutter/material.dart';

class CharacterCard extends StatelessWidget {
  final Character character;

  const CharacterCard({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context){
                return CharacterDetailsScreen(character:character);
              }));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
        
          children: [
            Expanded(
              child: Image.network(
                character.image,
                fit: BoxFit.cover,
                width: double.infinity,
        
                // Image loading failure
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image, size: 48));
                },
              ),
            ),
        
            Padding(
              padding: const EdgeInsets.all(8),
        
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
        
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        
                  const SizedBox(height: 4),
        
                  Text(
                    character.race,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
