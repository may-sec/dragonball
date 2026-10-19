import 'package:dragonball_app/core/utils/ki_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// LEARN (table-driven tests): instead of one test per input, keep a TABLE of
// (input, expected) pairs and loop over it. Adding a new API quirk later is
// one new line, and a failing row names the exact input that broke.

void expectRelative(double? actual, double expected) {
  expect(actual, isNotNull);
  final difference = (actual! - expected).abs();
  final scale = expected == 0 ? 1.0 : expected.abs();
  expect(difference / scale, lessThan(1e-12));
}

void main() {
  group('parseKi', () {
    final readable = <String, double>{
      '0': 0,
      '42': 42,
      '42.000 ': 42000,
      '1.000': 1000,
      '60.000.000': 60e6,
      '1,234,567': 1234567,
      '1.5': 1.5,
      '1,5': 1.5,
      '19.84 Septillion': 19.84e24,
      '90 Septillion': 90e24,
      '40 septillion': 40e24,
      '2 Decillion': 2e33,
      '3 undecillion': 3e36,
    };

    readable.forEach((input, expected) {
      test('reads "$input"', () => expectRelative(parseKi(input), expected));
    });

    for (final input in ['', '   ', 'Unknown', '12.34.5', '1..2', '3 gazillion']) {
      test('refuses "$input" (null, not zero)', () {
        expect(parseKi(input), isNull);
      });
    }

    test('infinite words become double.infinity', () {
      expect(parseKi('Infinite'), double.infinity);
      expect(parseKi(' unlimited '), double.infinity);
    });
  });

  group('formatKi', () {
    final table = <double, String>{
      0: '0',
      7: '7',
      999: '999',
      1000: '1K',
      1500: '1.5K',
      999999: '1M', // rounding carries into the next group
      60e6: '60M',
      9e25: '90Sp',
      1e33: '1Dc',
    };

    table.forEach((value, expected) {
      test('$value -> $expected', () => expect(formatKi(value), expected));
    });

    test('unknown and special values', () {
      expect(formatKi(null), '?');
      expect(formatKi(double.nan), '?');
      expect(formatKi(double.infinity), '∞');
    });

    test('beyond the suffix table it uses scientific notation', () {
      expect(formatKi(1e100), '1.00e+100');
    });

    test('a fraction below 1000 keeps up to two decimals', () {
      expect(formatKi(1.5), '1.5');
    });
  });

  group('kiScale', () {
    test('null, zero and one are an empty bar', () {
      expect(kiScale(null), 0);
      expect(kiScale(0), 0);
      expect(kiScale(1), 0);
    });

    test('infinite is a full bar and huge values are clamped', () {
      expect(kiScale(double.infinity), 1);
      expect(kiScale(1e40), 1);
    });

    test('10^15 is half of the 10^30 scale', () {
      expect(kiScale(1e15), closeTo(0.5, 1e-9));
    });
  });

  group('tiers', () {
    test('thresholds', () {
      expect(tierFor(999), KiTier.civilian);
      expect(tierFor(1e3), KiTier.warrior);
      expect(tierFor(1e6), KiTier.elite);
      expect(tierFor(1e9), KiTier.legendary);
      expect(tierFor(1e15), KiTier.mythic);
      expect(tierFor(1e21), KiTier.divine);
      expect(tierFor(double.infinity), KiTier.divine);
    });

    test('unknown ki has no tier, but a real zero is Civilian', () {
      expect(tierForKi('Unknown', ''), isNull);
      expect(tierForKi('0', '0'), KiTier.civilian);
      expect(tierForKi('Unknown', '60.000.000'), KiTier.elite);
    });
  });
}