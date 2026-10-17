// LEARN (regular expressions + lookup tables): small pure helpers that clean
// API text before it reaches the UI. Keeping them out of widgets means they
// can be tested and reused.

/// Removes Wikipedia-style footnote markers: "líder[9]." -> "líder."
String stripFootnotes(String text) => text
    .replaceAll(RegExp(r'\[\d+\]'), '')
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
    .trim();

const Map<String, String> _knownForms = {
  'ssj': 'Super Saiyan',
  'ssj2': 'Super Saiyan 2',
  'ssj3': 'Super Saiyan 3',
  'ssj4': 'Super Saiyan 4',
  'ssjb': 'Super Saiyan Blue',
  'ssjg': 'Super Saiyan God',
  'ultrainstinc': 'Ultra Instinct', // typo exists in the API itself
  'ultrainstinct': 'Ultra Instinct',
};

/// "Goku SSJB" + "Goku" -> "Super Saiyan Blue".
/// Steps: drop the repeated character name, then map abbreviations.
String prettyTransformationName(String raw, String characterName) {
  var name = raw.trim();
  final prefix = characterName.trim();

  if (prefix.isNotEmpty && name.toLowerCase().startsWith(prefix.toLowerCase())) {
    name = name.substring(prefix.length).trim();
  }
  if (name.isEmpty) return raw.trim();

  final key = name.toLowerCase().replaceAll(' ', '');
  return _knownForms[key] ?? name;
}