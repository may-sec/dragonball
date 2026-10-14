import 'package:flutter/foundation.dart';

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;

  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }

  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  throw const FormatException('Expected a JSON object.');
}

@immutable
final class Transformation {
  const Transformation({
    required this.id,
    required this.name,
    required this.ki,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String ki;
  final String imageUrl;

  factory Transformation.fromJson(Map<String, dynamic> json) {
    return Transformation(
      id: _readInt(json['id']),
      name: _readString(
        json['name'],
        fallback: 'Unknown Form',
      ),
      ki: _readString(json['ki'], fallback: '0'),
      imageUrl: _readString(json['image']),
    );
  }
}

@immutable
final class Character {
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

  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String imageUrl;
  final String affiliation;

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'Unknown'),
      ki: _readString(json['ki'], fallback: '0'),
      maxKi: _readString(json['maxKi'], fallback: '0'),
      race: _readString(json['race'], fallback: 'Unknown Race'),
      gender: _readString(json['gender'], fallback: 'Unknown'),
      description: _readString(json['description']),
      imageUrl: _readString(json['image']),
      affiliation: _readString(json['affiliation'], fallback: 'None'),
    );
  }
}

@immutable
final class Planet {
  const Planet({
    required this.id,
    required this.name,
    required this.isDestroyed,
    required this.description,
    required this.imageUrl,
    this.characters = const [],
  });

  final int id;
  final String name;
  final bool isDestroyed;
  final String description;
  final String imageUrl;
  final List<Character> characters;

  factory Planet.fromJson(Map<String, dynamic> json) {
    final rawCharacters = json['characters'];

    final characters = rawCharacters is List
        ? rawCharacters
            .map((entry) => Character.fromJson(_asMap(entry)))
            .toList()
        : <Character>[];

    return Planet(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'Unknown Planet'),
      isDestroyed: _readBool(json['isDestroyed']),
      description: _readString(json['description']),
      imageUrl: _readString(json['image']),
      characters: List.unmodifiable(characters),
    );
  }
}

@immutable
final class CharacterProfile {
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

  factory CharacterProfile.fromJson(Map<String, dynamic> json) {
    final rawTransformations = json['transformations'];

    final transformations = rawTransformations is List
        ? rawTransformations
            .map((entry) => Transformation.fromJson(_asMap(entry)))
            .toList()
        : <Transformation>[];

    final rawPlanet = json['originPlanet'];

    return CharacterProfile(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'Unknown'),
      ki: _readString(json['ki'], fallback: '0'),
      maxKi: _readString(json['maxKi'], fallback: '0'),
      race: _readString(json['race'], fallback: 'Unknown Race'),
      gender: _readString(json['gender'], fallback: 'Unknown'),
      description: _readString(json['description']),
      imageUrl: _readString(json['image']),
      affiliation: _readString(json['affiliation'], fallback: 'None'),
      originPlanet: rawPlanet is Map
          ? Planet.fromJson(_asMap(rawPlanet))
          : null,
      transformations: List.unmodifiable(transformations),
    );
  }
}

