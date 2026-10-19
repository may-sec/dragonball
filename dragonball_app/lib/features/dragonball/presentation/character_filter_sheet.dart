import 'package:flutter/material.dart';

import '../../../core/design/app_tokens.dart';
import '../../../core/l10n/app_strings.dart';

/// Internal "no filter" value. Never shown to the user: the sheet displays
/// strings.filterAll instead (so it can be translated).
const String kFilterAll = 'ALL';

typedef CharacterFiltersApplyCallback = void Function({
  required String race,
  required String gender,
  required String affiliation,
  required bool resetSearch,
});

// LEARN (a sheet with its own draft state): the user can change several
// options and then press "Apply". The choices live in local variables
// (draftRace, ...) inside a StatefulBuilder and only reach the real filters
// when Apply is pressed. Closing the sheet without applying discards them.
//
// The option lists (races, genders, affiliations) are passed in by the caller,
// built from the REAL catalog data, so a new race in the API shows up by
// itself instead of waiting for someone to edit a hard-coded list.
void showCharacterFilterSheet({
  required BuildContext context,
  required AppStrings strings,
  required String selectedRace,
  required String selectedGender,
  required String selectedAffiliation,
  required List<String> races,
  required List<String> genders,
  required List<String> affiliations,
  required VoidCallback onResetSearch,
  required CharacterFiltersApplyCallback onApply,
}) {
  String draftRace = selectedRace;
  String draftGender = selectedGender;
  String draftAffiliation = selectedAffiliation;

  bool resetSearchOnApply = false;

  String label(String value) => value == kFilterAll ? strings.filterAll : value;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.x5,
                AppSpace.x2,
                AppSpace.x5,
                AppSpace.x8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.filterTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            draftRace = kFilterAll;
                            draftGender = kFilterAll;
                            draftAffiliation = kFilterAll;
                            resetSearchOnApply = true;
                          });
                        },
                        child: Text(strings.filterReset),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x4),
                  Text(strings.filterRace, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpace.x2),
                  Wrap(
                    spacing: AppSpace.x2,
                    runSpacing: AppSpace.x1,
                    children: races.map((race) {
                      return ChoiceChip(
                        label: Text(label(race)),
                        selected: draftRace == race,
                        onSelected: (selected) {
                          setModalState(() {
                            draftRace = selected ? race : kFilterAll;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpace.x5),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(draftGender),
                          initialValue: genders.contains(draftGender)
                              ? draftGender
                              : kFilterAll,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: strings.filterGender,
                          ),
                          items: genders.map((gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(label(gender)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setModalState(() {
                              draftGender = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpace.x3),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(draftAffiliation),
                          initialValue: affiliations.contains(draftAffiliation)
                              ? draftAffiliation
                              : kFilterAll,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: strings.filterAffiliation,
                          ),
                          items: affiliations.map((affiliation) {
                            return DropdownMenuItem<String>(
                              value: affiliation,
                              child: Text(
                                label(affiliation),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setModalState(() {
                              draftAffiliation = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.x6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (resetSearchOnApply) {
                          onResetSearch();
                        }

                        onApply(
                          race: draftRace,
                          gender: draftGender,
                          affiliation: draftAffiliation,
                          resetSearch: resetSearchOnApply,
                        );

                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(strings.filterApply),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}