import 'dart:math' as math;

// LEARN (parsing messy data): the API sends ki in many shapes:
//   "60.000.000"   dots are THOUSANDS separators (Spanish style)
//   "19.84 Septillion"   dot is a DECIMAL because a scale word follows
//   "90 Septillion" / "40 septillion"   different casing
//   "42.000 "      trailing space
//   "0"
// One pure function turns all of them into a double. Pure functions (no
// widgets, no state) are the easiest code to unit test: see
// test/dragonball_logic_test.dart.

const Map<String, int> _scaleWords = {
  'thousand': 3,
  'million': 6,
  'billion': 9,
  'trillion': 12,
  'quadrillion': 15,
  'quintillion': 18,
  'sextillion': 21,
  'septillion': 24,
  'octillion': 27,
  'nonillion': 30,
  'decillion': 33,
};

/// Bars are drawn on a log scale from 10^0 up to 10^30.
const double kMaxKiExponent = 30;

/// Returns null when the text is not a ki value we understand.
double? parseKi(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;

  // number part (digits, dots, commas) + optional scale word
  final match = RegExp(r'^([\d.,]+)\s*([a-z]+)?$').firstMatch(text);
  if (match == null) return null;

  final numberPart = match.group(1)!;
  final word = match.group(2);

  if (word != null) {
    final exponent = _scaleWords[word];
    if (exponent == null) return null;
    final base = double.tryParse(numberPart.replaceAll(',', ''));
    if (base == null) return null;
    return base * math.pow(10, exponent).toDouble();
  }

  // No scale word -> dots/commas are thousands separators.
  return double.tryParse(numberPart.replaceAll(RegExp(r'[.,]'), ''));
}

/// The bigger of current ki and max ki, used for sorting and tiers.
double powerOf(String ki, String maxKi) =>
    math.max(parseKi(ki) ?? 0, parseKi(maxKi) ?? 0);

/// Maps a ki value to 0..1 on a LOGARITHMIC scale.
/// Why: 60 million vs 90 septillion differ by 10^17. On a linear bar the
/// small one would be invisible. On a log bar both are readable.
double kiScale(double? value) {
  if (value == null || value <= 1) return 0;
  final exponent = math.log(value) / math.ln10;
  return (exponent / kMaxKiExponent).clamp(0.0, 1.0).toDouble();
}

const List<String> _suffixes = [
  'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No',
];

String _trimZeros(String s) =>
    s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// 60000000 -> "60M", 9e25 -> "90Sp". Compact text for small UI spaces.
String formatKi(double? value) {
  if (value == null) return '?';
  if (value < 1000) return value.toStringAsFixed(0);

  // The tiny epsilon protects against log10(1e24) = 23.999999999.
  final exponent = (math.log(value) / math.ln10 + 1e-9).floor();
  final group = math.min(math.max(exponent ~/ 3, 1), _suffixes.length);
  final scaled = value / math.pow(10, group * 3);

  final digits = scaled >= 100
      ? scaled.toStringAsFixed(0)
      : scaled >= 10
          ? scaled.toStringAsFixed(1)
          : scaled.toStringAsFixed(2);

  return '${_trimZeros(digits)}${_suffixes[group - 1]}';
}

/// Power tiers. Names are translated in AppStrings.tierName.
enum KiTier { civilian, warrior, elite, legendary, mythic, divine }

KiTier tierFor(double power) {
  if (power < 1e3) return KiTier.civilian;
  if (power < 1e6) return KiTier.warrior;
  if (power < 1e9) return KiTier.elite;
  if (power < 1e15) return KiTier.legendary;
  if (power < 1e21) return KiTier.mythic;
  return KiTier.divine;
}