// lib/features/dragonball/models/dragonball_models.dart
// (Keep your existing Transformation, Planet, CharacterSummary, CharacterDetail classes)

import 'package:meta/meta.dart';

@immutable
final class PaginatedList<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  const PaginatedList({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  factory PaginatedList.empty() => const PaginatedList(
        items: [],
        currentPage: 1,
        totalPages: 1,
        hasNext: false,
      );
}