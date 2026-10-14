
import 'package:flutter/material.dart';

typedef CharacterFiltersApplyCallback = void Function({
  required String race,
  required String gender,
  required String affiliation,
  required bool resetSearch,
});

void showCharacterFilterSheet({
  required BuildContext context,
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

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter characters',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            draftRace = 'ALL';
                            draftGender = 'ALL';
                            draftAffiliation = 'ALL';
                            resetSearchOnApply = true;
                          });
                        },
                        child: const Text('Reset all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Race',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: races.map((race) {
                      return ChoiceChip(
                        label: Text(race),
                        selected: draftRace == race,
                        onSelected: (selected) {
                          setModalState(() {
                            draftRace = selected ? race : 'ALL';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(draftGender),
                          initialValue: genders.contains(draftGender)
                              ? draftGender
                              : 'ALL',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: genders.map((gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(draftAffiliation),
                          initialValue:
                              affiliations.contains(draftAffiliation)
                                  ? draftAffiliation
                                  : 'ALL',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Affiliation',
                            border: OutlineInputBorder(),
                          ),
                          items: affiliations.map((affiliation) {
                            return DropdownMenuItem<String>(
                              value: affiliation,
                              child: Text(
                                affiliation,
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
                  const SizedBox(height: 24),
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
                      child: const Text('Apply and close'),
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
