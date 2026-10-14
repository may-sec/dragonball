import 'package:flutter/foundation.dart';

@immutable
final class Page<T> {
  const Page({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  const Page.empty()
      : items = const [],
        currentPage = 1,
        totalPages = 1,
        hasNext = false;

  final List<T> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
}