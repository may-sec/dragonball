import 'dart:convert';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../data/json_response_cache.dart';
import 'app_settings.dart';
import 'dragonball_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<JsonResponseCacheStats> _cacheStats;
  late Future<PackageInfo> _packageInfo;

  bool _working = false;

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

  Future<bool> _confirm({
    required String title,
    required String message,
    String action = 'Continue',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _clearImageCache() async {
    final confirmed = await _confirm(
      title: 'Clear image cache?',
      message:
          'Cached images will be downloaded again when needed. '
          'Favorites, settings, and JSON API cache will remain.',
      action: 'Clear images',
    );

    if (!confirmed || !mounted) return;

    setState(() => _working = true);

    try {
      await DefaultCacheManager().emptyCache();

      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();

      if (mounted) {
        _message('Image cache cleared.');
      }
    } catch (_) {
      _message('Unable to completely clear the image cache.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearApiCache() async {
    final confirmed = await _confirm(
      title: 'Clear API cache?',
      message:
          'Cached character, planet, and detail responses will '
          'be removed. Your favorites and image files will remain.',
      action: 'Clear API cache',
    );

    if (!confirmed || !mounted) return;

    setState(() => _working = true);

    try {
      await JsonResponseCache.instance.clear();

      if (!mounted) return;

      setState(_reloadCacheStats);
      _message('JSON API cache cleared.');
    } catch (_) {
      _message('Unable to clear the API cache.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _clearFavorites() async {
    final confirmed = await _confirm(
      title: 'Remove all favorites?',
      message:
          'This permanently removes your saved favorite character '
          'IDs from this device. This does not clear cached images.',
      action: 'Remove all',
    );

    if (!confirmed || !mounted) return;

    ref
        .read(dragonBallFavoritesProvider.notifier)
        .replaceAll(<int>{});

    _message('All favorites removed.');
  }

  Future<void> _exportFavorites() async {
    try {
      final ids = ref
          .read(dragonBallFavoritesProvider)
          .toList();

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
          text: 'Dragon Ball Universe favorites backup',
          fileNameOverrides: ['dragonball-favorites.json'],
        ),
      );
    } catch (error) {
      _message('Could not export favorites: $error');
    }
  }

Future<void> _importFavorites() async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Your installed API returns a List<PlatformFile>.
    if (files.isEmpty || !mounted) return;

    final selectedFile = files.first;
    final fileBytes = await selectedFile.readAsBytes();

    final dynamic decoded = jsonDecode(
      utf8.decode(fileBytes),
    );

    if (decoded is! Map ||
        decoded['schemaVersion'] != 1 ||
        decoded['favoriteCharacterIds'] is! List) {
      _message('This is not a supported favorites backup.');
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
        _message('The backup contains an invalid character ID.');
        return;
      }

      ids.add(id);
    }

    final confirmed = await _confirm(
      title: 'Import favorites?',
      message:
          'This will replace your current favorites with '
          '${ids.length} character IDs from the selected backup.',
      action: 'Import',
    );

    if (!confirmed || !mounted) return;

    ref
        .read(dragonBallFavoritesProvider.notifier)
        .replaceAll(ids);

    _message('Favorites imported successfully.');
  } on FormatException {
    _message('The selected file contains invalid JSON.');
  } catch (error) {
    _message('Could not import favorites: $error');
  }
}

  Future<void> _resetSettings() async {
    final confirmed = await _confirm(
      title: 'Reset settings?',
      message:
          'Theme, layout, sorting, and accessibility preferences '
          'will return to their defaults. Favorites and cached '
          'data will not be deleted.',
      action: 'Reset settings',
    );

    if (!confirmed || !mounted) return;

    await ref.read(appSettingsProvider.notifier).resetPreferences();

    if (mounted) {
      _message('Settings restored to defaults.');
    }
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
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
    final settings = ref.watch(appSettingsProvider);
    final catalogAsync = ref.watch(dragonBallControllerProvider);
    final networkNotice = ref.watch(networkNoticeProvider);
    final imageCache = PaintingBinding.instance.imageCache;
    final scheme = Theme.of(context).colorScheme;

    final catalog = catalogAsync.asData?.value;

    final apiErrors = [
      if (catalog?.characterError != null)
        'Characters: ${catalog!.characterError}',
      if (catalog?.planetError != null)
        'Planets: ${catalog!.planetError}',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // APPEARANCE
          _sectionTitle(context, 'Appearance'),
          _group([
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              secondary: const Icon(Icons.brightness_auto),
              title: const Text('System default'),
              subtitle: const Text('Follow device appearance'),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              secondary: const Icon(Icons.light_mode_outlined),
              title: const Text('Light'),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark'),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(value);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.palette_outlined, color: scheme.primary),
              title: const Text('Accent color'),
              subtitle: const Text('Customize the app highlight color'),
              trailing: DropdownButton<String>(
                value: settings.accentColor,
                items: const [
                  DropdownMenuItem(
                    value: 'orange',
                    child: Text('Orange'),
                  ),
                  DropdownMenuItem(
                    value: 'blue',
                    child: Text('Blue'),
                  ),
                  DropdownMenuItem(
                    value: 'green',
                    child: Text('Green'),
                  ),
                  DropdownMenuItem(
                    value: 'purple',
                    child: Text('Purple'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setAccentColor(value);
                  }
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.animation),
              title: const Text('Animations'),
              subtitle: const Text('Enable interface animations'),
              value: settings.animationsEnabled,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setAnimationsEnabled,
            ),
          ]),

          // BROWSING & DISPLAY
          _sectionTitle(context, 'Browsing & display'),
          _group([
            SwitchListTile(
              title: const Text('Characters grid'),
              subtitle: const Text('Off displays a list instead'),
              value: settings.charactersGridView,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setCharactersGridView,
            ),
            SwitchListTile(
              title: const Text('Planets grid'),
              subtitle: const Text('Off displays a list instead'),
              value: settings.planetsGridView,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setPlanetsGridView,
            ),
            SwitchListTile(
              title: const Text('Favorites grid'),
              subtitle: const Text('Off displays a list instead'),
              value: settings.favoritesGridView,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setFavoritesGridView,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.density_small),
              title: const Text('Compact cards'),
              subtitle: const Text('Use denser interface spacing'),
              value: settings.compactCards,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setCompactCards,
            ),
            ListTile(
              title: const Text('Catalog sorting'),
              subtitle: const Text('Sort currently loaded results'),
              trailing: DropdownButton<String>(
                value: settings.catalogSortOrder,
                items: const [
                  DropdownMenuItem(
                    value: 'default',
                    child: Text('Default'),
                  ),
                  DropdownMenuItem(
                    value: 'name_asc',
                    child: Text('A–Z'),
                  ),
                  DropdownMenuItem(
                    value: 'name_desc',
                    child: Text('Z–A'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setCatalogSortOrder(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Default starting tab'),
              trailing: DropdownButton<int>(
                value: settings.defaultTab,
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Characters'),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Planets'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('Favorites'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setDefaultTab(value);
                  }
                },
              ),
            ),
          ]),

          // FAVORITES
          _sectionTitle(context, 'Favorites'),
          _group([
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort favorites'),
              trailing: DropdownButton<String>(
                value: settings.favoritesSortOrder,
                items: const [
                  DropdownMenuItem(
                    value: 'recent',
                    child: Text('Recently added'),
                  ),
                  DropdownMenuItem(
                    value: 'id_asc',
                    child: Text('ID ascending'),
                  ),
                  DropdownMenuItem(
                    value: 'id_desc',
                    child: Text('ID descending'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setFavoritesSortOrder(value);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Export favorites'),
              subtitle: const Text('Share a JSON backup'),
              onTap: _exportFavorites,
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text('Import favorites'),
              subtitle: const Text('Restore from a JSON backup'),
              onTap: _importFavorites,
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                'Remove all favorites',
                style: TextStyle(color: scheme.error),
              ),
              onTap: _clearFavorites,
            ),
          ]),

          // STORAGE
          _sectionTitle(context, 'Storage & data'),
          _group([
            ListTile(
              leading: const Icon(Icons.memory),
              title: const Text('In-memory image cache'),
              subtitle: Text(
                '${imageCache.currentSize} images · '
                '${_formatBytes(imageCache.currentSizeBytes)}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image_not_supported_outlined),
              title: const Text('Clear image cache'),
              subtitle: const Text('Remove cached and decoded images'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _working ? null : _clearImageCache,
            ),
            FutureBuilder<JsonResponseCacheStats>(
              future: _cacheStats,
              builder: (context, snapshot) {
                final stats = snapshot.data;

                return ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('JSON API cache'),
                  subtitle: Text(
                    snapshot.hasError
                        ? 'Cache statistics unavailable'
                        : stats == null
                            ? 'Calculating cache size...'
                            : '${stats.fileCount} files · '
                                '${_formatBytes(stats.totalBytes)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Refresh cache statistics',
                    onPressed: () {
                      setState(_reloadCacheStats);
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear JSON API cache'),
              subtitle: const Text('Remove cached API responses only'),
              onTap: _working ? null : _clearApiCache,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Image cache, JSON API cache, favorites, and settings '
              'are managed independently.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // NETWORK
          _sectionTitle(context, 'Network & diagnostics'),
          _group([
            ListTile(
              leading: Icon(
                apiErrors.isNotEmpty
                    ? Icons.cloud_off
                    : Icons.cloud_done_outlined,
                color: apiErrors.isNotEmpty ? scheme.error : scheme.primary,
              ),
              title: const Text('Latest API status'),
              subtitle: Text(
                apiErrors.isNotEmpty
                    ? apiErrors.join('\n')
                    : networkNotice ??
                        'No recent API error is recorded.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Retry API requests'),
              subtitle: const Text('Refresh characters and planets'),
              onTap: _working
                  ? null
                  : () {
                      ref
                          .read(dragonBallControllerProvider.notifier)
                          .refresh();
                      _message('API refresh requested.');
                    },
            ),
            if (networkNotice != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Dismiss diagnostic message'),
                onTap: () {
                  ref.read(networkNoticeProvider.notifier).clear();
                },
              ),
          ]),

          // ACCESSIBILITY
          _sectionTitle(context, 'Accessibility'),
          _group([
            ListTile(
              title: const Text('Text size'),
              subtitle: const Text('Adjust app text size'),
              trailing: DropdownButton<double>(
                value: settings.textScale,
                items: const [
                  DropdownMenuItem(value: 0.9, child: Text('Small')),
                  DropdownMenuItem(value: 1.0, child: Text('Default')),
                  DropdownMenuItem(value: 1.15, child: Text('Large')),
                  DropdownMenuItem(value: 1.3, child: Text('Largest')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setTextScale(value);
                  }
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.motion_photos_off_outlined),
              title: const Text('Reduced motion'),
              subtitle: const Text('Reduce motion where supported'),
              value: settings.reducedMotion,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setReducedMotion,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.contrast),
              title: const Text('Higher contrast'),
              subtitle: const Text('Strengthen theme color contrast'),
              value: settings.highContrast,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setHighContrast,
            ),
          ]),

          // ABOUT
          _sectionTitle(context, 'About'),
          _group([
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;

                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Dragon Ball Universe'),
                  subtitle: Text(
                    info == null
                        ? 'Loading app version...'
                        : 'Version ${info.version} '
                            '(Build ${info.buildNumber})',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Open-source licenses'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Dragon Ball Universe',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Acknowledgements'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Dragon Ball Universe',
                  applicationVersion: 'Dragon Ball Explorer',
                  applicationLegalese:
                      'Character and planet data are provided by '
                      'the Dragon Ball API. This app is an independent '
                      'explorer and is not an official Dragon Ball product.',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset settings'),
              subtitle: const Text(
                'Restore defaults without deleting favorites',
              ),
              onTap: _resetSettings,
            ),
          ]),
        ],
      ),
    );
  }
}
