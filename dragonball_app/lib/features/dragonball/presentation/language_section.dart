import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';

// LEARN (extracting a section): the settings screen is already ~600 lines.
// New sections live in their own widget file and are dropped in with ONE line:
//     const LanguageSettingsSection(),
//
// Two independent choices:
//   * App language     -> changes labels/menus immediately (stringsProvider)
//   * Content language -> language of API descriptions. Only Spanish exists,
//                         so English is shown disabled with "Coming soon".
class LanguageSettingsSection extends ConsumerWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final settings = ref.watch(languageProvider);
    final controller = ref.read(languageProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            s.languageSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(AppIcons.translate),
                title: Text(s.appLanguage),
                subtitle: Text(s.appLanguageHint),
              ),
              for (final language in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  value: language,
                  groupValue: settings.app,
                  title: Text(language.label),
                  onChanged: (value) {
                    if (value != null) controller.setApp(value);
                  },
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(AppIcons.translate),
                title: Text(s.contentLanguage),
                subtitle: Text(s.contentLanguageHint),
              ),
              for (final language in ContentLanguage.values)
                RadioListTile<ContentLanguage>(
                  value: language,
                  groupValue: settings.content,
                  title: Text(language.label),
                  subtitle: language.available ? null : Text(s.comingSoon),
                  secondary:
                      language.available ? null : const Icon(AppIcons.lock),
                  // null onChanged = disabled tile.
                  onChanged: language.available
                      ? (value) {
                          if (value != null) controller.setContent(value);
                        }
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}