import 'package:flutter/widgets.dart';

import '../utils/ki_parser.dart';

// LEARN (localization, simple version): every visible word of the NEW screens
// comes from here as a getter. A screen never types 'Explore' directly; it
// asks AppStrings. Adding a language later = add one enum value + one more
// argument to _t. (The official way is flutter_localizations + ARB files;
// once this idea clicks, that tool is easy to learn.)

/// Language of buttons, labels and menus.
enum AppLanguage {
  en('English', 'en'),
  es('Español', 'es');

  const AppLanguage(this.label, this.code);
  final String label;
  final String code;

  Locale get locale => Locale(code);
}

/// Language of text that comes from the API (character descriptions).
/// Only Spanish exists today; English is listed but disabled so the settings
/// section is ready the day a translator is added.
enum ContentLanguage {
  es('Español', available: true),
  en('English', available: false);

  const ContentLanguage(this.label, {required this.available});
  final String label;
  final bool available;
}

@immutable
class AppStrings {
  const AppStrings(this.lang);

  final AppLanguage lang;

  String _t(String en, String es) => lang == AppLanguage.es ? es : en;

  // Tabs / titles
  String get tabExplore => _t('Explore', 'Explorar');
  String get exploreTitle => _t('Explore the universe', 'Explora el universo');
  String get exploreSubtitle =>
      _t('Browse by race or affiliation', 'Navega por raza o afiliación');
  String get characterDossier => _t('Character dossier', 'Ficha del personaje');
  String get planetDossier => _t('Planet dossier', 'Ficha del planeta');
  String get favoritesCrumb => _t('Favorites', 'Favoritos');

  // Explore modes
  String get modeAll => _t('All', 'Todos');
  String get modeRace => _t('Race', 'Raza');
  String get modeAffiliation => _t('Affiliation', 'Afiliación');
  String get allRaces => _t('All races', 'Todas las razas');
  String get allAffiliations => _t('All affiliations', 'Todas las afiliaciones');

  // Search / sort / view
  String get searchHint => _t('Search by name…', 'Buscar por nombre…');
  String get sortTooltip => _t('Sort', 'Ordenar');
  String get sortNameAsc => _t('Name A–Z', 'Nombre A–Z');
  String get sortNameDesc => _t('Name Z–A', 'Nombre Z–A');
  String get sortKiDesc => _t('Highest power', 'Mayor poder');
  String get gridTooltip => _t('Grid view', 'Vista de cuadrícula');
  String get listTooltip => _t('List view', 'Vista de lista');
  String get clearSearch => _t('Clear search', 'Borrar búsqueda');

  String warriorCount(int n) => lang == AppLanguage.es
      ? (n == 1 ? '1 guerrero' : '$n guerreros')
      : (n == 1 ? '1 warrior' : '$n warriors');

  // Empty / error
  String get noResultsTitle => _t('No warriors found', 'No se encontraron guerreros');
  String get noResultsBody =>
      _t('Try another search or group.', 'Prueba otra búsqueda o grupo.');
  String get resetFilters => _t('Reset filters', 'Restablecer filtros');
  String get loadFailed =>
      _t('Could not load the warriors.', 'No se pudieron cargar los guerreros.');
  String get retry => _t('Try again', 'Reintentar');

  // Character detail
  String get power => _t('Power', 'Poder');
  String get kiNow => _t('Current ki', 'Ki actual');
  String get kiMax => _t('Maximum ki', 'Ki máximo');
  String get logScaleNote => _t(
        'Bars use a logarithmic scale so huge values stay comparable.',
        'Las barras usan escala logarítmica para comparar valores enormes.',
      );
  String get about => _t('About', 'Acerca de');
  String descriptionLanguageNote(String languageLabel) =>
      _t('Original text: $languageLabel', 'Texto original: $languageLabel');
  String get noDescription =>
      _t('No description is available.', 'No hay descripción disponible.');
  String get showMore => _t('Show more', 'Ver más');
  String get showLess => _t('Show less', 'Ver menos');
  String get originPlanet => _t('Origin planet', 'Planeta de origen');
  String get transformations => _t('Transformations', 'Transformaciones');
  String get addFavorite => _t('Add favorite', 'Añadir a favoritos');
  String get removeFavorite => _t('Remove favorite', 'Quitar de favoritos');

  // Planet detail
  String get residents => _t('Residents', 'Habitantes');
  String get destroyed => _t('Destroyed', 'Destruido');
  String get intact => _t('Intact', 'Intacto');
  String get noPlanetDescription =>
      _t('No description is available for this planet.',
          'No hay descripción para este planeta.');

  // Power tiers
  String tierName(KiTier tier) => switch (tier) {
        KiTier.civilian => _t('Civilian', 'Civil'),
        KiTier.warrior => _t('Warrior', 'Guerrero'),
        KiTier.elite => _t('Elite', 'Élite'),
        KiTier.legendary => _t('Legendary', 'Legendario'),
        KiTier.mythic => _t('Mythic', 'Mítico'),
        KiTier.divine => _t('Divine', 'Divino'),
      };

  // Settings: language section
  String get languageSection => _t('Language', 'Idioma');
  String get appLanguage => _t('App language', 'Idioma de la app');
  String get appLanguageHint =>
      _t('Buttons, labels and menus', 'Botones, etiquetas y menús');
  String get contentLanguage => _t('Content language', 'Idioma del contenido');
  String get contentLanguageHint => _t(
        'Descriptions that come from the API',
        'Descripciones que vienen de la API',
      );
  String get comingSoon => _t('Coming soon', 'Próximamente');
}