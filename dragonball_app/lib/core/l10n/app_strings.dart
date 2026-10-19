import 'package:flutter/widgets.dart';

import '../utils/ki_parser.dart';

// LEARN (localization, simple version): every visible word of the screens
// comes from here as a getter. A screen never types 'Explore' directly; it
// asks AppStrings. Adding a language later = add one enum value + one more
// argument to _t. (The official way is flutter_localizations + ARB files;
// once this idea clicks, that tool is easy to learn.)
//
// Known limit of this design: every language is an ARGUMENT of _t, so all
// languages are compiled in. A downloadable language pack needs key-based
// lookup tables instead (see the language-pack step later).

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

  // ---------------------------------------------------------------------------
  // Tabs / titles
  // ---------------------------------------------------------------------------
  String get tabCharacters => _t('Characters', 'Personajes');
  String get tabExplore => _t('Explore', 'Explorar');
  String get tabPlanets => _t('Planets', 'Planetas');
  String get tabFavorites => _t('Favorites', 'Favoritos');

  String get charactersTitle => _t('Warrior database', 'Base de guerreros');
  String get charactersSubtitle =>
      _t('Explore fighters and villains', 'Explora luchadores y villanos');
  String get exploreTitle => _t('Explore the universe', 'Explora el universo');
  String get exploreSubtitle =>
      _t('Browse by race or affiliation', 'Navega por raza o afiliación');
  String get planetsTitle => _t('Cosmic atlas', 'Atlas cósmico');
  String get planetsSubtitle =>
      _t('Explore worlds across the universe', 'Explora mundos del universo');
  String get favoritesTitle => _t('Favorite warriors', 'Guerreros favoritos');
  String get favoritesSubtitle =>
      _t('Your saved characters', 'Tus personajes guardados');

  String get characterDossier => _t('Character dossier', 'Ficha del personaje');
  String get planetDossier => _t('Planet dossier', 'Ficha del planeta');
  String get favoritesCrumb => _t('Favorites', 'Favoritos');

  String get settingsTooltip => _t('Settings', 'Ajustes');
  String get favoritesCountTooltip =>
      _t('Saved favorite characters', 'Personajes favoritos guardados');

  // ---------------------------------------------------------------------------
  // Explore modes
  // ---------------------------------------------------------------------------
  String get modeAll => _t('All', 'Todos');
  String get modeRace => _t('Race', 'Raza');
  String get modeAffiliation => _t('Affiliation', 'Afiliación');
  String get allRaces => _t('All races', 'Todas las razas');
  String get allAffiliations => _t('All affiliations', 'Todas las afiliaciones');

  // ---------------------------------------------------------------------------
  // Search / sort / view / filters
  // ---------------------------------------------------------------------------
  String get searchHint => _t('Search by name…', 'Buscar por nombre…');
  String get searchPlanetsHint => _t('Search planets…', 'Buscar planetas…');
  String get sortTooltip => _t('Sort', 'Ordenar');
  String get sortNameAsc => _t('Name A–Z', 'Nombre A–Z');
  String get sortNameDesc => _t('Name Z–A', 'Nombre Z–A');
  String get sortKiDesc => _t('Highest power', 'Mayor poder');
  String get gridTooltip => _t('Grid view', 'Vista de cuadrícula');
  String get listTooltip => _t('List view', 'Vista de lista');
  String get clearSearch => _t('Clear search', 'Borrar búsqueda');
  String get filterTooltip => _t('Filter characters', 'Filtrar personajes');
  String get clearFiltersTooltip => _t('Clear filters', 'Quitar filtros');

  String get filterTitle => _t('Filter characters', 'Filtrar personajes');
  String get filterReset => _t('Reset all', 'Restablecer todo');
  String get filterRace => _t('Race', 'Raza');
  String get filterGender => _t('Gender', 'Género');
  String get filterAffiliation => _t('Affiliation', 'Afiliación');
  String get filterApply => _t('Apply and close', 'Aplicar y cerrar');
  String get filterAll => _t('All', 'Todos');

  String warriorCount(int n) => lang == AppLanguage.es
      ? (n == 1 ? '1 guerrero' : '$n guerreros')
      : (n == 1 ? '1 warrior' : '$n warriors');

  // ---------------------------------------------------------------------------
  // Empty / error
  // ---------------------------------------------------------------------------
  String get noResultsTitle =>
      _t('No warriors found', 'No se encontraron guerreros');
  String get noResultsBody =>
      _t('Try another search or group.', 'Prueba otra búsqueda o grupo.');
  String get resetFilters => _t('Reset filters', 'Restablecer filtros');
  String get loadFailed =>
      _t('Could not load the warriors.', 'No se pudieron cargar los guerreros.');
  String get planetsLoadFailed =>
      _t('Could not load the planets.', 'No se pudieron cargar los planetas.');
  String get retry => _t('Try again', 'Reintentar');
  String get imageLoadFailed => _t(
        'Could not load an image. Check your connection.',
        'No se pudo cargar una imagen. Revisa tu conexión.',
      );

  String charactersError(String message) =>
      _t('Characters: $message', 'Personajes: $message');
  String planetsError(String message) =>
      _t('Planets: $message', 'Planetas: $message');

  // ---------------------------------------------------------------------------
  // Catalog status banner
  // ---------------------------------------------------------------------------
  String get catalogOffline => _t(
        'You are offline. Showing saved data.',
        'Sin conexión. Mostrando datos guardados.',
      );
  String get catalogServerProblem => _t(
        'The server had a problem. Showing saved data.',
        'El servidor no respondió bien. Mostrando datos guardados.',
      );
  String get catalogSlow => _t(
        'Slow connection. Checking for updates…',
        'La conexión es lenta. Buscando actualizaciones…',
      );
  String get catalogPartial => _t(
        'Some data is missing. Try again.',
        'Faltan algunos datos. Inténtalo de nuevo.',
      );

  // ---------------------------------------------------------------------------
  // Favorites tab
  // ---------------------------------------------------------------------------
  String get savedCharacters => _t('Saved characters', 'Personajes guardados');
  String get noFavoritesTitle => _t('No favorites yet', 'Aún no hay favoritos');
  String get noFavoritesBody => _t(
        'Tap the heart on a character card to save a warrior.',
        'Toca el corazón de un personaje para guardarlo.',
      );
  String get browseCharacters =>
      _t('Browse characters', 'Ver personajes');
  String get favoritesUnavailable => _t(
        'Your favorites are not loaded yet.',
        'Tus favoritos aún no se han cargado.',
      );
  String favoritesNotLoaded(int missing) => lang == AppLanguage.es
      ? (missing == 1
          ? '1 favorito aún no está disponible.'
          : '$missing favoritos aún no están disponibles.')
      : (missing == 1
          ? '1 favorite is not available yet.'
          : '$missing favorites are not available yet.');

  // ---------------------------------------------------------------------------
  // Character detail
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Planets
  // ---------------------------------------------------------------------------
  String get residents => _t('Residents', 'Habitantes');
  String get destroyed => _t('Destroyed', 'Destruido');
  String get intact => _t('Intact', 'Intacto');
  String get allWorlds => _t('All worlds', 'Todos los mundos');
  String get noPlanetsTitle =>
      _t('No planets found', 'No se encontraron planetas');
  String get noPlanetDescription => _t(
        'No description is available for this planet.',
        'No hay descripción para este planeta.',
      );

  // ---------------------------------------------------------------------------
  // Power tiers
  // ---------------------------------------------------------------------------
  String tierName(KiTier tier) => switch (tier) {
        KiTier.civilian => _t('Civilian', 'Civil'),
        KiTier.warrior => _t('Warrior', 'Guerrero'),
        KiTier.elite => _t('Elite', 'Élite'),
        KiTier.legendary => _t('Legendary', 'Legendario'),
        KiTier.mythic => _t('Mythic', 'Mítico'),
        KiTier.divine => _t('Divine', 'Divino'),
      };

  // ---------------------------------------------------------------------------
  // Settings: language section
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Settings: screen, sections
  // ---------------------------------------------------------------------------
  String get settingsTitle => _t('Settings', 'Ajustes');
  String get sectionAppearance => _t('Appearance', 'Apariencia');
  String get sectionBrowsing => _t('Browsing & display', 'Navegación y vista');
  String get sectionFavorites => _t('Favorites', 'Favoritos');
  String get sectionStorage => _t('Storage & data', 'Almacenamiento y datos');
  String get sectionNetwork => _t('Network & diagnostics', 'Red y diagnóstico');
  String get sectionAccessibility => _t('Accessibility', 'Accesibilidad');
  String get sectionAbout => _t('About', 'Acerca de');
  String get sectionPower => _t('Battery & performance', 'Batería y rendimiento');

  // Appearance
  String get themeTitle => _t('Theme', 'Tema');
  String get themeSystem => _t('System', 'Sistema');
  String get themeLight => _t('Light', 'Claro');
  String get themeDark => _t('Dark', 'Oscuro');
  String get trueBlack => _t('True black (AMOLED)', 'Negro puro (AMOLED)');
  String get trueBlackHint => _t(
        'Pure black in dark mode. Can save battery on OLED screens.',
        'Negro puro en modo oscuro. Puede ahorrar batería en pantallas OLED.',
      );
  String get accentColor => _t('Accent color', 'Color de acento');
  String get accentHint =>
      _t('Customize the app highlight color', 'Personaliza el color de resalte');
  String get accentOrange => _t('Orange', 'Naranja');
  String get accentBlue => _t('Blue', 'Azul');
  String get accentGreen => _t('Green', 'Verde');
  String get accentPurple => _t('Purple', 'Morado');
  String get animations => _t('Animations', 'Animaciones');
  String get animationsHint =>
      _t('Enable interface animations', 'Activar animaciones de la interfaz');

  // Browsing & display
  String get charactersGrid =>
      _t('Characters grid', 'Cuadrícula de personajes');
  String get planetsGrid => _t('Planets grid', 'Cuadrícula de planetas');
  String get favoritesGrid => _t('Favorites grid', 'Cuadrícula de favoritos');
  String get gridHint =>
      _t('Off displays a list instead', 'Si está apagado, se muestra una lista');
  String get compactCards => _t('Compact cards', 'Tarjetas compactas');
  String get compactCardsHint =>
      _t('Use denser interface spacing', 'Usar espaciado más denso');
  String get catalogSorting => _t('Catalog sorting', 'Orden del catálogo');
  String get catalogSortingHint => _t(
        'Sort the characters and planets lists',
        'Ordena las listas de personajes y planetas',
      );
  String get sortDefault => _t('Default', 'Predeterminado');
  String get sortAZ => _t('A–Z', 'A–Z');
  String get sortZA => _t('Z–A', 'Z–A');
  String get defaultTab => _t('Default starting tab', 'Pestaña inicial');

  // Favorites
  String get favoritesSort => _t('Sort favorites', 'Ordenar favoritos');
  String get sortRecent => _t('Recently added', 'Añadidos recientemente');
  String get sortIdAsc => _t('ID ascending', 'ID ascendente');
  String get sortIdDesc => _t('ID descending', 'ID descendente');
  String get exportFavorites => _t('Export favorites', 'Exportar favoritos');
  String get exportHint =>
      _t('Share a JSON backup', 'Compartir una copia JSON');
  String get importFavorites => _t('Import favorites', 'Importar favoritos');
  String get importHint =>
      _t('Restore from a JSON backup', 'Restaurar desde una copia JSON');
  String get removeAllFavorites =>
      _t('Remove all favorites', 'Quitar todos los favoritos');

  // Storage
  String get memoryImageCache =>
      _t('In-memory image cache', 'Caché de imágenes en memoria');
  String imagesCount(int n, String size) =>
      _t('$n images · $size', '$n imágenes · $size');
  String get clearImageCache =>
      _t('Clear image cache', 'Borrar caché de imágenes');
  String get clearImageCacheHint => _t(
        'Remove cached and decoded images',
        'Eliminar imágenes en caché y decodificadas',
      );
  String get apiCache => _t('API data cache', 'Caché de datos de la API');
  String apiCacheEntries(int n, String size) =>
      _t('$n entries · $size', '$n entradas · $size');
  String get apiCacheCalculating =>
      _t('Calculating cache size...', 'Calculando tamaño...');
  String get apiCacheUnavailable =>
      _t('Cache statistics unavailable', 'Estadísticas no disponibles');
  String get refreshCacheStats =>
      _t('Refresh cache statistics', 'Actualizar estadísticas');
  String get clearApiCache =>
      _t('Clear API cache', 'Borrar caché de la API');
  String get clearApiCacheHint => _t(
        'Remove saved API responses only',
        'Eliminar solo las respuestas guardadas de la API',
      );
  String get storageNote => _t(
        'Image cache, API cache, favorites, and settings are managed independently.',
        'La caché de imágenes, la caché de la API, los favoritos y los ajustes se gestionan por separado.',
      );

  // Dialogs and messages
  String get cancel => _t('Cancel', 'Cancelar');
  String get close => _t('Close', 'Cerrar');
  String get continueLabel => _t('Continue', 'Continuar');

  String get clearImagesTitle =>
      _t('Clear image cache?', '¿Borrar la caché de imágenes?');
  String get clearImagesBody => _t(
        'Cached images will be downloaded again when needed. Favorites, settings, and API cache will remain.',
        'Las imágenes se volverán a descargar cuando hagan falta. Los favoritos, los ajustes y la caché de la API se conservan.',
      );
  String get clearImagesAction => _t('Clear images', 'Borrar imágenes');
  String get imagesCleared =>
      _t('Image cache cleared.', 'Caché de imágenes borrada.');
  String get imagesClearFailed => _t(
        'Unable to completely clear the image cache.',
        'No se pudo borrar por completo la caché de imágenes.',
      );

  String get clearApiTitle =>
      _t('Clear API cache?', '¿Borrar la caché de la API?');
  String get clearApiBody => _t(
        'Saved characters, planets and details will be removed from this device. Favorites and images will remain. The app downloads them again when you are online.',
        'Los personajes, planetas y fichas guardados se eliminarán de este dispositivo. Los favoritos y las imágenes se conservan. La app los descargará de nuevo cuando tengas conexión.',
      );
  String get clearApiAction => _t('Clear API cache', 'Borrar caché de la API');
  String get apiCleared => _t('API cache cleared.', 'Caché de la API borrada.');
  String get apiClearFailed =>
      _t('Unable to clear the API cache.', 'No se pudo borrar la caché de la API.');

  String get removeFavoritesTitle =>
      _t('Remove all favorites?', '¿Quitar todos los favoritos?');
  String get removeFavoritesBody => _t(
        'This permanently removes your saved favorite character IDs from this device. This does not clear cached images.',
        'Esto elimina de forma permanente los IDs de tus personajes favoritos en este dispositivo. No borra las imágenes en caché.',
      );
  String get removeFavoritesAction => _t('Remove all', 'Quitar todos');
  String get favoritesRemoved =>
      _t('All favorites removed.', 'Todos los favoritos se quitaron.');

  String get exportText => _t(
        'Dragon Ball Universe favorites backup',
        'Copia de favoritos de Dragon Ball Universe',
      );
  String exportFailed(String error) =>
      _t('Could not export favorites: $error', 'No se pudieron exportar los favoritos: $error');
  String get importInvalid => _t(
        'This is not a supported favorites backup.',
        'Esta no es una copia de favoritos compatible.',
      );
  String get importInvalidId => _t(
        'The backup contains an invalid character ID.',
        'La copia contiene un ID de personaje no válido.',
      );
  String get importConfirmTitle =>
      _t('Import favorites?', '¿Importar favoritos?');
  String importConfirmBody(int count) => _t(
        'This will replace your current favorites with $count character IDs from the selected backup.',
        'Esto reemplazará tus favoritos actuales por $count IDs de personajes de la copia seleccionada.',
      );
  String get importAction => _t('Import', 'Importar');
  String get importDone => _t(
        'Favorites imported successfully.',
        'Favoritos importados correctamente.',
      );
  String get importBadJson => _t(
        'The selected file contains invalid JSON.',
        'El archivo seleccionado contiene JSON no válido.',
      );
  String importFailed(String error) =>
      _t('Could not import favorites: $error', 'No se pudieron importar los favoritos: $error');

  String get resetTitle => _t('Reset settings?', '¿Restablecer los ajustes?');
  String get resetBody => _t(
        'Theme, layout, sorting, and accessibility preferences will return to their defaults. Favorites and cached data will not be deleted.',
        'El tema, la disposición, el orden y la accesibilidad volverán a sus valores predeterminados. Los favoritos y los datos en caché no se borran.',
      );
  String get resetAction => _t('Reset settings', 'Restablecer ajustes');
  String get resetDone =>
      _t('Settings restored to defaults.', 'Ajustes restablecidos.');
  String get resetSettings => _t('Reset settings', 'Restablecer ajustes');
  String get resetSettingsHint => _t(
        'Restore defaults without deleting favorites',
        'Restaurar valores sin borrar favoritos',
      );

  // Battery & performance
  String get adaptPowerSaver =>
      _t('Adapt to battery saver', 'Adaptarse al ahorro de batería');
  String get adaptPowerSaverHint => _t(
        'While Android battery saver is on: no animations, no image preloading and no automatic update checks.',
        'Con el ahorro de batería de Android activado: sin animaciones, sin precarga de imágenes y sin comprobaciones automáticas.',
      );
  String get batterySaverOn =>
      _t('Battery saver is on', 'El ahorro de batería está activado');
  String get batterySaverOff =>
      _t('Battery saver is off', 'El ahorro de batería está desactivado');
  String get batterySaverUnknown => _t(
        'Battery saver status is not available here',
        'El estado del ahorro de batería no está disponible aquí',
      );

  // Network & diagnostics
  String get apiStatus => _t('Latest API status', 'Estado de la API');
  String get apiStatusOk => _t(
        'No recent API error is recorded.',
        'No hay errores recientes de la API.',
      );
  String lastChecked(String when) =>
      _t('Last checked: $when', 'Última comprobación: $when');
  String get neverChecked => _t(
        'Not checked on this device yet.',
        'Aún no se ha comprobado en este dispositivo.',
      );
  String get checkForUpdates =>
      _t('Check for updates', 'Buscar actualizaciones');
  String get checkForUpdatesHint =>
      _t('Refresh characters and planets', 'Actualizar personajes y planetas');
  String get refreshRequested =>
      _t('Checking for updates…', 'Buscando actualizaciones…');
  String get dismissDiagnostic =>
      _t('Dismiss diagnostic message', 'Descartar mensaje de diagnóstico');
  String get justNow => _t('just now', 'ahora mismo');
  String minutesAgo(int n) => _t('$n min ago', 'hace $n min');
  String hoursAgo(int n) => _t('$n h ago', 'hace $n h');
  String daysAgo(int n) => _t('$n d ago', 'hace $n d');

  // Accessibility
  String get textSize => _t('Text size', 'Tamaño del texto');
  String get textSizeHint =>
      _t('Adjust app text size', 'Ajusta el tamaño del texto de la app');
  String get textSmall => _t('Small', 'Pequeño');
  String get textDefault => _t('Default', 'Predeterminado');
  String get textLarge => _t('Large', 'Grande');
  String get textLargest => _t('Largest', 'Muy grande');
  String get reducedMotion => _t('Reduced motion', 'Movimiento reducido');
  String get reducedMotionHint => _t(
        'Reduce motion where supported',
        'Reduce el movimiento donde sea posible',
      );
  String get highContrast => _t('Higher contrast', 'Mayor contraste');
  String get highContrastHint => _t(
        'Strengthen theme color contrast',
        'Refuerza el contraste de los colores',
      );

  // About
  String get appName => 'Dragon Ball Universe';
  String get versionLoading =>
      _t('Loading app version...', 'Cargando versión...');
  String versionLabel(String version, String build) =>
      _t('Version $version (Build $build)', 'Versión $version (compilación $build)');
  String get privacyPolicy => _t('Privacy Policy', 'Política de privacidad');
  String get privacyHint =>
      _t('How the app handles data', 'Cómo la app trata los datos');
  String get privacyBody => _t(
        'Dragon Ball Universe does not require an account.\n\n'
            'Local Storage\n'
            'Favorites, preferences, and cached data may be stored on your device.\n\n'
            'Third-Party Services\n'
            'Character and planet data are retrieved from dragonball-api.com. '
            'Requests may be subject to that service’s privacy practices.\n\n'
            'Data Sharing\n'
            'The app does not sell personal information.\n\n'
            'Data Deletion\n'
            'You can remove favorites and clear supported caches through Settings. '
            'Uninstalling the app may remove locally stored data.\n\n'
            'This policy may be updated as the app changes.',
        'Dragon Ball Universe no requiere una cuenta.\n\n'
            'Almacenamiento local\n'
            'Los favoritos, las preferencias y los datos en caché pueden guardarse en tu dispositivo.\n\n'
            'Servicios de terceros\n'
            'Los datos de personajes y planetas se obtienen de dragonball-api.com. '
            'Las solicitudes pueden estar sujetas a las prácticas de privacidad de ese servicio.\n\n'
            'Compartir datos\n'
            'La app no vende información personal.\n\n'
            'Eliminación de datos\n'
            'Puedes quitar favoritos y borrar las cachés compatibles desde Ajustes. '
            'Desinstalar la app puede eliminar los datos guardados localmente.\n\n'
            'Esta política puede actualizarse a medida que cambie la app.',
      );
}