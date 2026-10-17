import 'package:flutter/material.dart';

import '../utils/ki_parser.dart';
import 'app_icons.dart';

// LEARN (data -> visuals): the API only gives us strings like "Saiyan" or
// "Army of Frieza". This file turns those strings into an icon + color pair,
// so a chip / card / gradient always looks the same for the same category.

@immutable
class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Works for both races and affiliations (names are matched in lower case).
/// Unknown values fall back to a neutral style, so new API data never crashes.
CategoryStyle styleForCategory(String name) {
  switch (name.trim().toLowerCase()) {
    case 'saiyan':
      return const CategoryStyle(AppIcons.flame, Color(0xFFFF8A2B));
    case 'namekian':
    case 'namekian warrior':
      return const CategoryStyle(AppIcons.leaf, Color(0xFF3FA66A));
    case 'human':
      return const CategoryStyle(AppIcons.user, Color(0xFF4C9BE8));
    case 'frieza race':
    case 'army of frieza':
      return const CategoryStyle(AppIcons.skull, Color(0xFF9B6BE0));
    case 'android':
      return const CategoryStyle(AppIcons.robot, Color(0xFF8A94A6));
    case 'majin':
      return const CategoryStyle(AppIcons.ghost, Color(0xFFEF6FA8));
    case 'god':
    case 'angel':
      return const CategoryStyle(AppIcons.sparkle, Color(0xFFE8B931));
    case 'jiren race':
      return const CategoryStyle(AppIcons.ki, Color(0xFFD9534F));
    case 'evil':
    case 'villain':
      return const CategoryStyle(AppIcons.skull, Color(0xFFC0392B));
    case 'z fighter':
      return const CategoryStyle(AppIcons.shield, Color(0xFFFF8A2B));
    case 'red ribbon army':
      return const CategoryStyle(AppIcons.flag, Color(0xFFE5484D));
    case 'freelancer':
      return const CategoryStyle(AppIcons.star, Color(0xFF2BB0A6));
    case 'pride troopers':
      return const CategoryStyle(AppIcons.medal, Color(0xFFD9534F));
    default:
      return const CategoryStyle(AppIcons.question, Color(0xFF7C8798));
  }
}

IconData genderIcon(String gender) {
  switch (gender.trim().toLowerCase()) {
    case 'male':
      return AppIcons.male;
    case 'female':
      return AppIcons.female;
    default:
      return AppIcons.neuter;
  }
}

Color tierColor(KiTier tier) {
  switch (tier) {
    case KiTier.civilian:
      return const Color(0xFF8A94A6);
    case KiTier.warrior:
      return const Color(0xFF4C9BE8);
    case KiTier.elite:
      return const Color(0xFF3FA66A);
    case KiTier.legendary:
      return const Color(0xFFFF8A2B);
    case KiTier.mythic:
      return const Color(0xFF9B6BE0);
    case KiTier.divine:
      return const Color(0xFFE8B931);
  }
}

/// Signature color for a transformation, based on its cleaned name.
Color formAccentColor(String prettyName, Color fallback) {
  final n = prettyName.toLowerCase();
  if (n.contains('ultra')) return const Color(0xFFC9D1D9);
  if (n.contains('blue')) return const Color(0xFF3B82F6);
  if (n.contains('god')) return const Color(0xFFEF4444);
  if (n.contains('super saiyan')) return const Color(0xFFFFC94D);
  return fallback;
}