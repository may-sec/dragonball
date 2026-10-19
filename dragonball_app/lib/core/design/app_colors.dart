import 'package:flutter/material.dart';

// LEARN (ThemeExtension, Module 2.5): ColorScheme only has the roles Material
// invented (primary, error, surface...). "Intact planet green" or "favorite
// heart red" are OUR meanings. A ThemeExtension carries them inside ThemeData,
// so every theme variant (light, dark, true black) can define its own value,
// and widgets read them with AppColors.of(context). Nothing hard-codes a color
// that only looks right in one theme.
//
// lerp() is what lets Flutter animate between two themes (for example when the
// user switches light <-> dark): it blends the colors during the transition.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.intact,
    required this.favorite,
    required this.viewerBackground,
  });

  /// Status color of an intact planet.
  final Color intact;

  /// The favorite heart.
  final Color favorite;

  /// Background behind the full-screen image viewer.
  final Color viewerBackground;

  static const AppColors light = AppColors(
    intact: Color(0xFF3FA66A),
    favorite: Color(0xFFE5484D),
    viewerBackground: Color(0xFF090B12),
  );

  static const AppColors dark = AppColors(
    intact: Color(0xFF5CCB8A),
    favorite: Color(0xFFFF6B70),
    viewerBackground: Color(0xFF090B12),
  );

  /// Same accents as dark, but the viewer is pure black too.
  static const AppColors trueBlack = AppColors(
    intact: Color(0xFF5CCB8A),
    favorite: Color(0xFFFF6B70),
    viewerBackground: Color(0xFF000000),
  );

  /// The extension of the current theme (light as a safe fallback, for
  /// example in a test that builds a bare MaterialApp).
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? intact,
    Color? favorite,
    Color? viewerBackground,
  }) {
    return AppColors(
      intact: intact ?? this.intact,
      favorite: favorite ?? this.favorite,
      viewerBackground: viewerBackground ?? this.viewerBackground,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    return AppColors(
      intact: Color.lerp(intact, other.intact, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      viewerBackground: Color.lerp(viewerBackground, other.viewerBackground, t)!,
    );
  }
}