// lib/features/dragonball/models/dragonball_models.dart
// (Keep your existing Transformation, Planet, Character, CharacterProfile classes)

import 'package:meta/meta.dart';

@immutable
// 'final class' (Dart 3 feature):
// Locks this class from being extended, implemented, or subclassed outside this file.
// Generic type parameter `<T>` allows this model to wrap any entity type
// (e.g., Page<Character> or Page<Planet>).
final class Page<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  const Page({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  factory Page.empty() => const Page(
        items: [],
        currentPage: 1,
        totalPages: 1,
        hasNext: false,
      );
}