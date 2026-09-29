// lib/features/dragonball/models/dragonball_models.dart
import 'package:meta/meta.dart';

@immutable
// 'final class' locks this class from being extended or implemented outside this library.
final class Transformation {
  final int id;
  final String name;
  final String ki;
  final String imageUrl;

  const Transformation({
    required this.id,
    required this.name,
    required this.ki,
    required this.imageUrl,
  });

  // Factory constructor for parsing a raw JSON Map into a typed Transformation instance.
  // Applies defensive null-coalescing fallbacks to eliminate runtime null-pointer crashes.
  factory Transformation.fromJson(Map<String, dynamic> json) {
    return Transformation(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Form',
      ki: json['ki'] as String? ?? '0',
      imageUrl: json['image'] as String? ?? '',
    );
  }
}

@immutable
final class Planet {
  final int id;
  final String name;
  final bool isDestroyed;
  final String description;
  final String imageUrl;
  final List<Character> characters;

  const Planet({
    required this.id,
    required this.name,
    required this.isDestroyed,
    required this.description,
    required this.imageUrl,
    this.characters = const [],
  });

  factory Planet.fromJson(Map<String, dynamic> json) {
    final rawCharacters = json['characters'] as List<dynamic>? ?? [];
    return Planet(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Planet',
      isDestroyed: json['isDestroyed'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      // Iterates through every element in the dynamic array, casts to Map,
      // and transforms each child item into a Character model.
      characters: rawCharacters
          .map((c) => Character.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
final class Character {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String imageUrl;
  final String affiliation;

  const Character({
    required this.id,
    required this.name,
    required this.ki,
    required this.maxKi,
    required this.race,
    required this.gender,
    required this.description,
    required this.imageUrl,
    required this.affiliation,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      ki: json['ki'] as String? ?? '0',
      maxKi: json['maxKi'] as String? ?? '0',
      race: json['race'] as String? ?? 'Unknown Race',
      gender: json['gender'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      affiliation: json['affiliation'] as String? ?? 'None',
    );
  }
}

@immutable
final class CharacterProfile {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String imageUrl;
  final String affiliation;
  final Planet? originPlanet;
  final List<Transformation> transformations;

  const CharacterProfile({
    required this.id,
    required this.name,
    required this.ki,
    required this.maxKi,
    required this.race,
    required this.gender,
    required this.description,
    required this.imageUrl,
    required this.affiliation,
    this.originPlanet,
    this.transformations = const [],
  });

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    // Safely reads raw dynamic list from JSON key 'transformations', defaulting to empty list.
    final rawTransformations = json['transformations'] as List<dynamic>? ?? [];

    // Safely extracts nested JSON map for 'originPlanet' (null if key does not exist or is null).
    final rawPlanet = json['originPlanet'] as Map<String, dynamic>?;

    return CharacterProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      ki: json['ki'] as String? ?? '0',
      maxKi: json['maxKi'] as String? ?? '0',
      race: json['race'] as String? ?? 'Unknown Race',
      gender: json['gender'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      affiliation: json['affiliation'] as String? ?? 'None',
      // Conditionally instantiates a nested Planet entity only if rawPlanet map is non-null.
      originPlanet: rawPlanet != null ? Planet.fromJson(rawPlanet) : null,
      // Deserializes each raw transformation entry into a typed Transformation instance.
      transformations: rawTransformations
          .map((t) => Transformation.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}