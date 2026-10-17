import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

// LEARN (Riverpod):
//  * languageProvider  -> state that can change (a Notifier)
//  * stringsProvider   -> DERIVED state: rebuilt automatically whenever the
//    language changes. Widgets just `ref.watch(stringsProvider)`.
//  * `.select(...)` -> watch only ONE field, so unrelated changes do not
//    rebuild the derived provider.

@immutable
class LanguageSettings {
  const LanguageSettings({
    this.app = AppLanguage.en,
    this.content = ContentLanguage.es,
  });

  final AppLanguage app;
  final ContentLanguage content;

  LanguageSettings copyWith({AppLanguage? app, ContentLanguage? content}) =>
      LanguageSettings(app: app ?? this.app, content: content ?? this.content);
}

final languageProvider =
    NotifierProvider<LanguageController, LanguageSettings>(
  LanguageController.new,
);

final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings(ref.watch(languageProvider.select((s) => s.app))),
);

class LanguageController extends Notifier<LanguageSettings> {
  static const _appKey = 'lang_app';
  static const _contentKey = 'lang_content';

  bool _changedByUser = false;

  @override
  LanguageSettings build() {
    _restore(); // async; the UI starts with defaults, then updates.
    return const LanguageSettings();
  }

  T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Same guard as AppSettings: do not overwrite a choice the user made
      // while storage was still loading.
      if (_changedByUser) return;

      state = LanguageSettings(
        app: _byName(AppLanguage.values, prefs.getString(_appKey), AppLanguage.en),
        content: _byName(
          ContentLanguage.values,
          prefs.getString(_contentKey),
          ContentLanguage.es,
        ),
      );
    } catch (_) {
      // Keep defaults if storage fails.
    }
  }

  Future<void> setApp(AppLanguage value) async {
    _changedByUser = true;
    state = state.copyWith(app: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appKey, value.name);
    } catch (_) {}
  }

  Future<void> setContent(ContentLanguage value) async {
    if (!value.available) return; // disabled options cannot be selected
    _changedByUser = true;
    state = state.copyWith(content: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_contentKey, value.name);
    } catch (_) {}
  }
}