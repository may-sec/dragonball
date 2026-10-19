import 'dart:math' as math;

// LEARN (parsing messy data, and what "total" means): a parser is TOTAL when
// every possible input maps to a defined outcome. The API sends ki in many
// shapes:
//   "60.000.000"        dots are THOUSANDS separators (Spanish style)
//   "19.84 Septillion"  dot is a DECIMAL because a scale word follows
//   "90 Septillion" / "40 septillion"   different casing
//   "42.000 "           trailing space
//   "1.5"               a lone dot that does NOT group three digits: decimal
//   "0"
//   "Unknown", ""       not a number at all  -> null (NOT zero!)
//   "Infinite"          -> double.infinity
//
// "Unknown" and "zero" are different facts. parseKi returns null for the
// first, so callers can show "?" and no power tier instead of "Civilian".
// Pure functions (no widgets, no state) are the easiest code to unit test:
// see test/ki_parser_edge_cases_test.dart.

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
  'undecillion': 36,
  'duodecillion': 39,
};

const Set<String> _infiniteWords = {
  'infinite',
  'infinity',
  'unlimited',
  '∞',
};

/// Bars are drawn on a log scale from 10^0 up to 10^30.
const double kMaxKiExponent = 30;

// Digits grouped by thousands: 1.000 / 42.000 / 60.000.000 / 1,234,567
final RegExp _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');
final RegExp _plainInteger = RegExp(r'^\d+$');
final RegExp _singleDecimal = RegExp(r'^\d+[.,]\d+$');

/// Returns null when the text is not a ki value we understand.
double? parseKi(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;

  if (_infiniteWords.contains(text)) return double.infinity;

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

  // No scale word: decide between "thousands separators" and "decimal point".
  if (_plainInteger.hasMatch(numberPart)) {
    return double.tryParse(numberPart);
  }
  if (_grouped.hasMatch(numberPart)) {
    return double.tryParse(numberPart.replaceAll(RegExp(r'[.,]'), ''));
  }
  if (_singleDecimal.hasMatch(numberPart)) {
    return double.tryParse(numberPart.replaceAll(',', '.'));
  }

  // "12.34.5", "1..2": ambiguous, so we refuse to guess.
  return null;
}

/// The bigger of current ki and max ki, used for sorting and tiers.
/// Unknown values count as 0 here (fine for sorting). To tell "unknown" from
/// "zero", use [hasKnownKi] / [tierForKi].
double powerOf(String ki, String maxKi) =>
    math.max(parseKi(ki) ?? 0, parseKi(maxKi) ?? 0);

/// true when at least one of the two values could be read.
bool hasKnownKi(String ki, String maxKi) =>
    parseKi(ki) != null || parseKi(maxKi) != null;

/// Maps a ki value to 0..1 on a LOGARITHMIC scale.
/// Why: 60 million vs 90 septillion differ by 10^17. On a linear bar the
/// small one would be invisible. On a log bar both are readable.
double kiScale(double? value) {
  if (value == null || value.isNaN || value <= 1) return 0;
  if (value.isInfinite) return 1;
  final exponent = math.log(value) / math.ln10;
  return (exponent / kMaxKiExponent).clamp(0.0, 1.0).toDouble();
}

const List<String> _suffixes = [
  'K', 'M', 'B', 'T', 'Qa', 'Qi', 'Sx', 'Sp', 'Oc', 'No', 'Dc', 'Ud', 'Dd',
];

String _trimZeros(String s) =>
    s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;

/// 60000000 -> "60M", 9e25 -> "90Sp", 999999 -> "1M" (not "1000K").
/// Beyond the suffix table it falls back to scientific notation, so it can
/// never print something misleading like "1000Dd".
String formatKi(double? value) {
  if (value == null || value.isNaN) return '?';
  if (value.isInfinite) return '∞';

  if (value < 1000) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : _trimZeros(value.toStringAsFixed(2));
  }

  // The tiny epsilon protects against log10(1e24) = 23.999999999.
  final exponent = (math.log(value) / math.ln10 + 1e-9).floor();
  var group = math.max(exponent ~/ 3, 1);

  while (true) {
    if (group > _suffixes.length) return value.toStringAsExponential(2);

    final scaled = value / math.pow(10, group * 3);

    final digits = scaled >= 100
        ? scaled.toStringAsFixed(0)
        : scaled >= 10
            ? scaled.toStringAsFixed(1)
            : scaled.toStringAsFixed(2);

    // Rounding can carry over: 999.999K rounds to "1000", which must be
    // written as 1M in the NEXT group.
    if (double.parse(digits) >= 1000) {
      group++;
      continue;
    }

    return '${_trimZeros(digits)}${_suffixes[group - 1]}';
  }
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

/// Like tierFor(powerOf(...)) but null when BOTH values are unreadable, so the
/// UI can hide the tier instead of calling an unknown character a Civilian.
KiTier? tierForKi(String ki, String maxKi) =>
    hasKnownKi(ki, maxKi) ? tierFor(powerOf(ki, maxKi)) : null;