import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/platform/experience_policy.dart';
import '../data/json_response_cache.dart';
import 'app_settings.dart';
import 'dragonball_notifier.dart';
import 'language_section.dart';

// =============================================================================
// SettingsScreen (migrated to the design system)
//
// LEARN (what changed and why):
//  * Every label comes from AppStrings, so the language setting finally
//    translates the screen that contains it.
//  * Icons come from AppIcons, spacing from AppSpace.
//  * The theme picker is a SegmentedButton<ThemeMode>: one control instead of
//    three RadioListTiles. (RadioListTile's groupValue/onChanged pair is being
//    replaced by RadioGroup in newer Flutter versions, so this also avoids a
//    deprecation.)
//  * flutter_cache_manager has no web support, so "clear image cache" skips it
//    on web and only clears Flutter's own in-memory ImageCache there.
//  * "Latest API status" now also says WHEN the server last confirmed the data
//    (catalog.lastValidatedAt), which is what makes offline mode understandable.
//  * Messages after an await read the strings through ref.read, and every
//    setState / snackbar is guarded by `mounted`.
// =============================================================================
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const double _maxWidth = 720;

  late Future<JsonResponseCacheStats> _cacheStats;
  late Future<PackageInfo> _packageInfo;

  bool _working = false;

  AppStrings get _s => ref.read(stringsProvider);

  @override
  void initState() {
    super.initState();
    _reloadCacheStats();
    _packageInfo = PackageInfo.fromPlatform();
  }

  void _reloadCacheStats() {
    _cacheStats = JsonResponseCache.instance.stats();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _timeAgo(AppStrings s, DateTime at) {
    final diff = DateTime.now().difference(at);

    if (diff.isNegative || diff.inMinutes < 1) return s.justNow;
    if (diff.inMinutes < 60) return s.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return s.hoursAgo(diff.inHours);

    return s.daysAgo(diff.inDays);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final s = _s;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPrivacyPolicy() {
    final s = _s;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.privacyPolicy),
        content: SingleChildScrollView(child: Text(s.privacyBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  Future<void> _clearImageCache() async {
    final s = _s;

    final confirmed = await _confirm(
      title: s.clearImagesTitle,
      message: s.clearImagesBody,
      action: s.clearImagesAction,
    );

    if (!confirmed || !mounted) return;

    setState(() => _working = true);

    try {
      // The disk image cache does not exist on web.
      if (!kIsWeb) await DefaultCacheManager().emptyCache();

      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();

      _message(s.imagesCleared);
    } catch (_) {
      _message(s.imagesClearFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearApiCache() async {
    final s = _s;

    final confirmed = await _confirm(
      title: s.clearApiTitle,
      message: s.clearApiBody,
      action: s.clearApiAction,
    );

    if (!confirmed || !mounted) return;

    setState(() => _working = true);

    try {
      await JsonResponseCache.instance.clear();

      if (!mounted) return;

      setState(_reloadCacheStats);
      _message(s.apiCleared);
    } catch (_) {
      _message(s.apiClearFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearFavorites() async {
    final s = _s;

    final confirmed = await _confirm(
      title: s.removeFavoritesTitle,
      message: s.removeFavoritesBody,
      action: s.removeFavoritesAction,
    );

    if (!confirmed || !mounted) return;

    ref.read(dragonBallFavoritesProvider.notifier).replaceAll(<int>{});

    _message(s.favoritesRemoved);
  }

  Future<void> _exportFavorites() async {
    final s = _s;

    try {
      final ids = ref.read(dragonBallFavoritesProvider).toList();

      final contents = jsonEncode({
        'schemaVersion': 1,
        'app': 'dragonball_app',
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'favoriteCharacterIds': ids,
      });

      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(contents)),
        mimeType: 'application/json',
        name: 'dragonball-favorites.json',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: s.exportText,
          fileNameOverrides: ['dragonball-favorites.json'],
        ),
      );
    } catch (error) {
      _message(s.exportFailed('$error'));
    }
  }

  Future<void> _importFavorites() async {
    final s = _s;

    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // Your installed API returns a List<PlatformFile>.
      if (files.isEmpty || !mounted) return;

      final selectedFile = files.first;
      final fileBytes = await selectedFile.readAsBytes();

      final dynamic decoded = jsonDecode(utf8.decode(fileBytes));

      if (decoded is! Map ||
          decoded['schemaVersion'] != 1 ||
          decoded['favoriteCharacterIds'] is! List) {
        _message(s.importInvalid);
        return;
      }

      final rawIds = decoded['favoriteCharacterIds'] as List;
      final ids = <int>{};

      for (final rawId in rawIds) {
        final int? id = rawId is int
            ? rawId
            : rawId is String
                ? int.tryParse(rawId)
                : null;

        if (id == null || id <= 0) {
          _message(s.importInvalidId);
          return;
        }

        ids.add(id);
      }

      if (!mounted) return;

      final confirmed = await _confirm(
        title: s.importConfirmTitle,
        message: s.importConfirmBody(ids.length),
        action: s.importAction,
      );

      if (!confirmed || !mounted) return;

      ref.read(dragonBallFavoritesProvider.notifier).replaceAll(ids);

      _message(s.importDone);
    } on FormatException {
      _message(s.importBadJson);
    } catch (error) {
      _message(s.importFailed('$error'));
    }
  }

  Future<void> _resetSettings() async {
    final s = _s;

    final confirmed = await _confirm(
      title: s.resetTitle,
      message: s.resetBody,
      action: s.resetAction,
    );

    if (!confirmed || !mounted) return;

    await ref.read(appSettingsProvider.notifier).resetPreferences();

    _message(s.resetDone);
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.x6, bottom: AppSpace.x2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final catalog = ref.watch(dragonBallControllerProvider).asData?.value;
    final networkNotice = ref.watch(networkNoticeProvider);
    final imageCache = PaintingBinding.instance.imageCache;
    final scheme = Theme.of(context).colorScheme;
    final powerSaveSupported = ref.watch(powerSaveSupportedProvider);
    final batterySaver = ref.watch(powerSaveProvider).asData?.value ?? false;

    final apiErrors = [
      if (catalog?.characterError != null)
        s.charactersError(catalog!.characterError!),
      if (catalog?.planetError != null) s.planetsError(catalog!.planetError!),
    ];

    final lastValidated = catalog?.lastValidatedAt;

    final statusLines = [
      if (apiErrors.isNotEmpty)
        ...apiErrors
      else
        networkNotice ?? s.apiStatusOk,
      lastValidated != null
          ? s.lastChecked(_timeAgo(s, lastValidated))
          : s.neverChecked,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x4,
              0,
              AppSpace.x4,
              AppSpace.x8,
            ),
            children: [
              // ---------------------------------------------------- APPEARANCE
              _sectionTitle(context, s.sectionAppearance),
              _group([
                ListTile(
                  title: Text(s.themeTitle),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.x2),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(AppIcons.themeSystem),
                            label: Text(s.themeSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(AppIcons.themeLight),
                            label: Text(s.themeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(AppIcons.themeDark),
                            label: Text(s.themeDark),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) =>
                            notifier.setThemeMode(selection.first),
                      ),
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.themeDark),
                  title: Text(s.trueBlack),
                  subtitle: Text(s.trueBlackHint),
                  value: settings.trueBlack,
                  onChanged: notifier.setTrueBlack,
                ),
                ListTile(
                  leading: Icon(AppIcons.palette, color: scheme.primary),
                  title: Text(s.accentColor),
                  subtitle: Text(s.accentHint),
                  trailing: DropdownButton<String>(
                    value: settings.accentColor,
                    items: [
                      DropdownMenuItem(
                        value: 'orange',
                        child: Text(s.accentOrange),
                      ),
                      DropdownMenuItem(
                        value: 'blue',
                        child: Text(s.accentBlue),
                      ),
                      DropdownMenuItem(
                        value: 'green',
                        child: Text(s.accentGreen),
                      ),
                      DropdownMenuItem(
                        value: 'purple',
                        child: Text(s.accentPurple),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) notifier.setAccentColor(value);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.animation),
                  title: Text(s.animations),
                  subtitle: Text(s.animationsHint),
                  value: settings.animationsEnabled,
                  onChanged: notifier.setAnimationsEnabled,
                ),
              ]),

              // ------------------------------------------------------ LANGUAGE
              const LanguageSettingsSection(),

              // ---------------------------------------- BROWSING & DISPLAY
              _sectionTitle(context, s.sectionBrowsing),
              _group([
                SwitchListTile(
                  secondary: const Icon(AppIcons.grid),
                  title: Text(s.charactersGrid),
                  subtitle: Text(s.gridHint),
                  value: settings.charactersGridView,
                  onChanged: notifier.setCharactersGridView,
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.planet),
                  title: Text(s.planetsGrid),
                  subtitle: Text(s.gridHint),
                  value: settings.planetsGridView,
                  onChanged: notifier.setPlanetsGridView,
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.favorites),
                  title: Text(s.favoritesGrid),
                  subtitle: Text(s.gridHint),
                  value: settings.favoritesGridView,
                  onChanged: notifier.setFavoritesGridView,
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.density),
                  title: Text(s.compactCards),
                  subtitle: Text(s.compactCardsHint),
                  value: settings.compactCards,
                  onChanged: notifier.setCompactCards,
                ),
                ListTile(
                  leading: const Icon(AppIcons.sort),
                  title: Text(s.catalogSorting),
                  subtitle: Text(s.catalogSortingHint),
                  trailing: DropdownButton<String>(
                    value: settings.catalogSortOrder,
                    items: [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text(s.sortDefault),
                      ),
                      DropdownMenuItem(
                        value: 'name_asc',
                        child: Text(s.sortAZ),
                      ),
                      DropdownMenuItem(
                        value: 'name_desc',
                        child: Text(s.sortZA),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) notifier.setCatalogSortOrder(value);
                    },
                  ),
                ),
                ListTile(
                  title: Text(s.defaultTab),
                  trailing: DropdownButton<int>(
                    value: settings.defaultTab,
                    items: [
                      DropdownMenuItem(value: 0, child: Text(s.tabCharacters)),
                      DropdownMenuItem(value: 1, child: Text(s.tabExplore)),
                      DropdownMenuItem(value: 2, child: Text(s.tabPlanets)),
                      DropdownMenuItem(value: 3, child: Text(s.tabFavorites)),
                    ],
                    onChanged: (value) {
                      if (value != null) notifier.setDefaultTab(value);
                    },
                  ),
                ),
              ]),

              // ------------------------------------------------- FAVORITES
              _sectionTitle(context, s.sectionFavorites),
              _group([
                ListTile(
                  leading: const Icon(AppIcons.sort),
                  title: Text(s.favoritesSort),
                  trailing: DropdownButton<String>(
                    value: settings.favoritesSortOrder,
                    items: [
                      DropdownMenuItem(
                        value: 'recent',
                        child: Text(s.sortRecent),
                      ),
                      DropdownMenuItem(
                        value: 'id_asc',
                        child: Text(s.sortIdAsc),
                      ),
                      DropdownMenuItem(
                        value: 'id_desc',
                        child: Text(s.sortIdDesc),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) notifier.setFavoritesSortOrder(value);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(AppIcons.share),
                  title: Text(s.exportFavorites),
                  subtitle: Text(s.exportHint),
                  onTap: _exportFavorites,
                ),
                ListTile(
                  leading: const Icon(AppIcons.importFile),
                  title: Text(s.importFavorites),
                  subtitle: Text(s.importHint),
                  onTap: _importFavorites,
                ),
                ListTile(
                  leading: Icon(AppIcons.delete, color: scheme.error),
                  title: Text(
                    s.removeAllFavorites,
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: _clearFavorites,
                ),
              ]),

              // --------------------------------------------------- STORAGE
              _sectionTitle(context, s.sectionStorage),
              _group([
                ListTile(
                  leading: const Icon(AppIcons.memory),
                  title: Text(s.memoryImageCache),
                  subtitle: Text(
                    s.imagesCount(
                      imageCache.currentSize,
                      _formatBytes(imageCache.currentSizeBytes),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(AppIcons.imageBroken),
                  title: Text(s.clearImageCache),
                  subtitle: Text(s.clearImageCacheHint),
                  trailing: const Icon(AppIcons.caretRight),
                  onTap: _working ? null : _clearImageCache,
                ),
                FutureBuilder<JsonResponseCacheStats>(
                  future: _cacheStats,
                  builder: (context, snapshot) {
                    final stats = snapshot.data;

                    return ListTile(
                      leading: const Icon(AppIcons.storage),
                      title: Text(s.apiCache),
                      subtitle: Text(
                        snapshot.hasError
                            ? s.apiCacheUnavailable
                            : stats == null
                                ? s.apiCacheCalculating
                                : s.apiCacheEntries(
                                    stats.fileCount,
                                    _formatBytes(stats.totalBytes),
                                  ),
                      ),
                      trailing: IconButton(
                        tooltip: s.refreshCacheStats,
                        onPressed: () => setState(_reloadCacheStats),
                        icon: const Icon(AppIcons.retry),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.delete),
                  title: Text(s.clearApiCache),
                  subtitle: Text(s.clearApiCacheHint),
                  onTap: _working ? null : _clearApiCache,
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.x2),
                child: Text(
                  s.storageNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // --------------------------------------------------- NETWORK
              _sectionTitle(context, s.sectionNetwork),
              _group([
                ListTile(
                  leading: Icon(
                    apiErrors.isNotEmpty
                        ? AppIcons.cloudOff
                        : AppIcons.cloudOk,
                    color: apiErrors.isNotEmpty ? scheme.error : scheme.primary,
                  ),
                  title: Text(s.apiStatus),
                  subtitle: Text(statusLines.join('\n')),
                ),
                ListTile(
                  leading: const Icon(AppIcons.retry),
                  title: Text(s.checkForUpdates),
                  subtitle: Text(s.checkForUpdatesHint),
                  onTap: _working
                      ? null
                      : () {
                          ref
                              .read(dragonBallControllerProvider.notifier)
                              .refresh();
                          _message(s.refreshRequested);
                        },
                ),
                if (networkNotice != null)
                  ListTile(
                    leading: const Icon(AppIcons.info),
                    title: Text(s.dismissDiagnostic),
                    onTap: () =>
                        ref.read(networkNoticeProvider.notifier).clear(),
                  ),
              ]),

              _sectionTitle(context, s.sectionPower),
              _group([
                SwitchListTile(
                  secondary: const Icon(AppIcons.battery),
                  title: Text(s.adaptPowerSaver),
                  subtitle: Text(s.adaptPowerSaverHint),
                  value: settings.adaptToPowerSaver,
                  onChanged: notifier.setAdaptToPowerSaver,
                ),
                ListTile(
                  leading: Icon(
                    powerSaveSupported && batterySaver
                        ? AppIcons.batterySaver
                        : AppIcons.battery,
                    color: powerSaveSupported && batterySaver
                        ? scheme.primary
                        : null,
                  ),
                  title: Text(
                    !powerSaveSupported
                        ? s.batterySaverUnknown
                        : batterySaver
                            ? s.batterySaverOn
                            : s.batterySaverOff,
                  ),
                ),
              ]),

              // ---------------------------------------------- ACCESSIBILITY
              _sectionTitle(context, s.sectionAccessibility),
              _group([
                ListTile(
                  leading: const Icon(AppIcons.textSize),
                  title: Text(s.textSize),
                  subtitle: Text(s.textSizeHint),
                  trailing: DropdownButton<double>(
                    value: settings.textScale,
                    items: [
                      DropdownMenuItem(value: 0.9, child: Text(s.textSmall)),
                      DropdownMenuItem(value: 1.0, child: Text(s.textDefault)),
                      DropdownMenuItem(value: 1.15, child: Text(s.textLarge)),
                      DropdownMenuItem(value: 1.3, child: Text(s.textLargest)),
                    ],
                    onChanged: (value) {
                      if (value != null) notifier.setTextScale(value);
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.animation),
                  title: Text(s.reducedMotion),
                  subtitle: Text(s.reducedMotionHint),
                  value: settings.reducedMotion,
                  onChanged: notifier.setReducedMotion,
                ),
                SwitchListTile(
                  secondary: const Icon(AppIcons.contrast),
                  title: Text(s.highContrast),
                  subtitle: Text(s.highContrastHint),
                  value: settings.highContrast,
                  onChanged: notifier.setHighContrast,
                ),
              ]),

              // -------------------------------------------------------- ABOUT
              _sectionTitle(context, s.sectionAbout),
              _group([
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;

                    return ListTile(
                      leading: const Icon(AppIcons.info),
                      title: Text(s.appName),
                      subtitle: Text(
                        info == null
                            ? s.versionLoading
                            : s.versionLabel(info.version, info.buildNumber),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.privacy),
                  title: Text(s.privacyPolicy),
                  subtitle: Text(s.privacyHint),
                  onTap: _showPrivacyPolicy,
                ),
                ListTile(
                  leading: const Icon(AppIcons.reset),
                  title: Text(s.resetSettings),
                  subtitle: Text(s.resetSettingsHint),
                  onTap: _resetSettings,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}