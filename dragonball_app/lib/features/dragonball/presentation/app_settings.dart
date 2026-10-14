
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

@immutable
class AppSettings {
  const AppSettings({
    this.isLoaded = false,
    this.themeMode = ThemeMode.system,
    this.accentColor = 'orange',
    this.animationsEnabled = true,
    this.charactersGridView = true,
    this.planetsGridView = true,
    this.favoritesGridView = true,
    this.compactCards = false,
    this.catalogSortOrder = 'default',
    this.favoritesSortOrder = 'recent',
    this.defaultTab = 0,
    this.textScale = 1.0,
    this.reducedMotion = false,
    this.highContrast = false,
  });

  final bool isLoaded;
  final ThemeMode themeMode;
  final String accentColor;
  final bool animationsEnabled;

  final bool charactersGridView;
  final bool planetsGridView;
  final bool favoritesGridView;
  final bool compactCards;
  final String catalogSortOrder;
  final String favoritesSortOrder;
  final int defaultTab;

  final double textScale;
  final bool reducedMotion;
  final bool highContrast;

  Color get seedColor => switch (accentColor) {
        'blue' => const Color(0xFF2879D0),
        'green' => const Color(0xFF278653),
        'purple' => const Color(0xFF8755C5),
        _ => const Color(0xFFED6C24),
      };

  bool get disableAnimations => !animationsEnabled || reducedMotion;

  AppSettings copyWith({
    bool? isLoaded,
    ThemeMode? themeMode,
    String? accentColor,
    bool? animationsEnabled,
    bool? charactersGridView,
    bool? planetsGridView,
    bool? favoritesGridView,
    bool? compactCards,
    String? catalogSortOrder,
    String? favoritesSortOrder,
    int? defaultTab,
    double? textScale,
    bool? reducedMotion,
    bool? highContrast,
  }) {
    return AppSettings(
      isLoaded: isLoaded ?? this.isLoaded,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      charactersGridView:
          charactersGridView ?? this.charactersGridView,
      planetsGridView: planetsGridView ?? this.planetsGridView,
      favoritesGridView:
          favoritesGridView ?? this.favoritesGridView,
      compactCards: compactCards ?? this.compactCards,
      catalogSortOrder: catalogSortOrder ?? this.catalogSortOrder,
      favoritesSortOrder:
          favoritesSortOrder ?? this.favoritesSortOrder,
      defaultTab: defaultTab ?? this.defaultTab,
      textScale: textScale ?? this.textScale,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}

class AppSettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'app_theme_mode';
  static const _accentKey = 'app_accent_color';
  static const _animationsKey = 'app_animations_enabled';

  static const _charactersGridKey = 'characters_grid_view';
  static const _planetsGridKey = 'planets_grid_view';
  static const _favoritesGridKey = 'favorites_grid_view';

  static const _compactCardsKey = 'app_compact_cards';
  static const _catalogSortKey = 'app_catalog_sort';
  static const _favoritesSortKey = 'app_favorites_sort';
  static const _defaultTabKey = 'app_default_tab';
  static const _textScaleKey = 'app_text_scale';
  static const _reducedMotionKey = 'app_reduced_motion';
  static const _highContrastKey = 'app_high_contrast';

  bool _restoreStarted = false;
  bool _userChangedSettings = false;

  @override
  AppSettings build() {
    if (!_restoreStarted) {
      _restoreStarted = true;
      _restore();
    }

    return const AppSettings();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final restored = AppSettings(
        isLoaded: true,
        themeMode: switch (prefs.getString(_themeKey)) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        accentColor: _validAccent(prefs.getString(_accentKey)),
        animationsEnabled:
            prefs.getBool(_animationsKey) ?? true,
        charactersGridView:
            prefs.getBool(_charactersGridKey) ?? true,
        planetsGridView:
            prefs.getBool(_planetsGridKey) ?? true,
        favoritesGridView:
            prefs.getBool(_favoritesGridKey) ?? true,
        compactCards: prefs.getBool(_compactCardsKey) ?? false,
        catalogSortOrder: _validCatalogSort(
          prefs.getString(_catalogSortKey),
        ),
        favoritesSortOrder: _validFavoritesSort(
          prefs.getString(_favoritesSortKey),
        ),
        defaultTab: _validTab(prefs.getInt(_defaultTabKey)),
        textScale: _validTextScale(prefs.getDouble(_textScaleKey)),
        reducedMotion:
            prefs.getBool(_reducedMotionKey) ?? false,
        highContrast: prefs.getBool(_highContrastKey) ?? false,
      );

      // Don't overwrite choices made while storage was loading.
      if (!_userChangedSettings) {
        state = restored;
      } else {
        state = state.copyWith(isLoaded: true);
      }
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  String _validAccent(String? value) =>
      const {'orange', 'blue', 'green', 'purple'}.contains(value)
          ? value!
          : 'orange';

  String _validCatalogSort(String? value) =>
      const {'default', 'name_asc', 'name_desc'}.contains(value)
          ? value!
          : 'default';

  String _validFavoritesSort(String? value) =>
      const {'recent', 'id_asc', 'id_desc'}.contains(value)
          ? value!
          : 'recent';

  int _validTab(int? value) =>
      value != null && value >= 0 && value <= 2 ? value : 0;

  double _validTextScale(double? value) =>
      value != null &&
              const [0.9, 1.0, 1.15, 1.3].contains(value)
          ? value
          : 1.0;

  Future<void> _save(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (_) {
      // Keep the in-memory setting even if persistence fails.
    }
  }

  void setThemeMode(ThemeMode value) {
    _change(state.copyWith(themeMode: value));
    _save(
      _themeKey,
      switch (value) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  void setAccentColor(String value) {
    if (!const {'orange', 'blue', 'green', 'purple'}.contains(value)) {
      return;
    }
    _change(state.copyWith(accentColor: value));
    _save(_accentKey, value);
  }

  void setAnimationsEnabled(bool value) {
    _change(state.copyWith(animationsEnabled: value));
    _save(_animationsKey, value);
  }

  void setCharactersGridView(bool value) {
    _change(state.copyWith(charactersGridView: value));
    _save(_charactersGridKey, value);
  }

  void setPlanetsGridView(bool value) {
    _change(state.copyWith(planetsGridView: value));
    _save(_planetsGridKey, value);
  }

  void setFavoritesGridView(bool value) {
    _change(state.copyWith(favoritesGridView: value));
    _save(_favoritesGridKey, value);
  }

  void setCompactCards(bool value) {
    _change(state.copyWith(compactCards: value));
    _save(_compactCardsKey, value);
  }

  void setCatalogSortOrder(String value) {
    if (_validCatalogSort(value) != value) return;
    _change(state.copyWith(catalogSortOrder: value));
    _save(_catalogSortKey, value);
  }

  void setFavoritesSortOrder(String value) {
    if (_validFavoritesSort(value) != value) return;
    _change(state.copyWith(favoritesSortOrder: value));
    _save(_favoritesSortKey, value);
  }

  void setDefaultTab(int value) {
    if (value < 0 || value > 2) return;
    _change(state.copyWith(defaultTab: value));
    _save(_defaultTabKey, value);
  }

  void setTextScale(double value) {
    if (!_validTextScale(value).isFinite ||
        _validTextScale(value) != value) {
      return;
    }
    _change(state.copyWith(textScale: value));
    _save(_textScaleKey, value);
  }

  void setReducedMotion(bool value) {
    _change(state.copyWith(reducedMotion: value));
    _save(_reducedMotionKey, value);
  }

  void setHighContrast(bool value) {
    _change(state.copyWith(highContrast: value));
    _save(_highContrastKey, value);
  }

  void _change(AppSettings value) {
    _userChangedSettings = true;
    state = value;
  }

  Future<void> resetPreferences() async {
    _userChangedSettings = true;
    state = const AppSettings(isLoaded: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        _themeKey,
        _accentKey,
        _animationsKey,
        _charactersGridKey,
        _planetsGridKey,
        _favoritesGridKey,
        _compactCardsKey,
        _catalogSortKey,
        _favoritesSortKey,
        _defaultTabKey,
        _textScaleKey,
        _reducedMotionKey,
        _highContrastKey,
      ]) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
