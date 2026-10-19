import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';

// LEARN (extracting a section): the settings screen is already ~700 lines.
// New sections live in their own widget file and are dropped in with ONE line:
//     const LanguageSettingsSection(),
//
// Two independent choices:
//   * App language     -> changes labels/menus immediately (stringsProvider)
//   * Content language -> language of API descriptions. Only Spanish exists,
//                         so English is shown disabled with "Coming soon".
//
// LEARN (RadioGroup, Flutter 3.32+): a group of radio buttons used to be
// "N tiles that each know the selected value and each have an onChanged".
// Now ONE RadioGroup ancestor owns groupValue + onChanged, and each
// RadioListTile only says which value IT represents. Less repetition, and the
// group can handle things like keyboard navigation between the options.
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
          padding: const EdgeInsets.only(top: AppSpace.x6, bottom: AppSpace.x2),
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
              RadioGroup<AppLanguage>(
                groupValue: settings.app,
                onChanged: (value) {
                  if (value != null) controller.setApp(value);
                },
                child: Column(
                  children: [
                    for (final language in AppLanguage.values)
                      RadioListTile<AppLanguage>(
                        value: language,
                        title: Text(language.label),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(AppIcons.translate),
                title: Text(s.contentLanguage),
                subtitle: Text(s.contentLanguageHint),
              ),
              RadioGroup<ContentLanguage>(
                groupValue: settings.content,
                onChanged: (value) {
                  if (value != null) controller.setContent(value);
                },
                child: Column(
                  children: [
                    for (final language in ContentLanguage.values)
                      if (language.available)
                        RadioListTile<ContentLanguage>(
                          value: language,
                          title: Text(language.label),
                        )
                      else
                        // Not selectable yet: a disabled tile, not a radio.
                        ListTile(
                          enabled: false,
                          title: Text(language.label),
                          subtitle: Text(s.comingSoon),
                          trailing: const Icon(AppIcons.lock),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}