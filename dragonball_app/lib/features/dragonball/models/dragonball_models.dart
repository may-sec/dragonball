// lib/features/dragonball/models/dragonball_models.dart
import 'package:meta/meta.dart';

@immutable
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
  final List<CharacterSummary> characters;

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
      characters: rawCharacters
          .map((c) => CharacterSummary.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
final class CharacterSummary {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String imageUrl;
  final String affiliation;

  const CharacterSummary({
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

  factory CharacterSummary.fromJson(Map<String, dynamic> json) {
    return CharacterSummary(
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
final class CharacterDetail {
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

  const CharacterDetail({
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

  factory CharacterDetail.fromJson(Map<String, dynamic> json) {
    final rawTransformations = json['transformations'] as List<dynamic>? ?? [];
    final rawPlanet = json['originPlanet'] as Map<String, dynamic>?;

    return CharacterDetail(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      ki: json['ki'] as String? ?? '0',
      maxKi: json['maxKi'] as String? ?? '0',
      race: json['race'] as String? ?? 'Unknown Race',
      gender: json['gender'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      affiliation: json['affiliation'] as String? ?? 'None',
      originPlanet: rawPlanet != null ? Planet.fromJson(rawPlanet) : null,
      transformations: rawTransformations
          .map((t) => Transformation.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}