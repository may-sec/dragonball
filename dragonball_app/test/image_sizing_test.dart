import 'package:dragonball_app/core/utils/image_sizing.dart';
import 'package:flutter_test/flutter_test.dart';

// LEARN (numbers worth knowing): 72 x 88 logical px on a phone with devicePixelRatio
// 2.6 needs about 187 x 229 real pixels. Decoding the 1000 x 1500 original is
// ~6 MB; a 256 px wide decode of the same image is ~0.4 MB.

void main() {
  group('decodeTargetFor', () {
    test('a portrait box limits the WIDTH and rounds up to a bucket', () {
      final target = decodeTargetFor(
        maxWidth: 72,
        maxHeight: 88,
        devicePixelRatio: 2.6,
      );

      // 72 * 2.6 = 187.2 -> next multiple of 128 = 256
      expect(target.width, 256);
      expect(target.height, isNull);
    });

    test('a landscape box limits the HEIGHT', () {
      final target = decodeTargetFor(
        maxWidth: 300,
        maxHeight: 100,
        devicePixelRatio: 2.0,
      );

      // 100 * 2.0 = 200 -> 256
      expect(target.width, isNull);
      expect(target.height, 256);
    });

    test('a square box uses the width', () {
      final target = decodeTargetFor(
        maxWidth: 100,
        maxHeight: 100,
        devicePixelRatio: 1.0,
      );

      expect(target.width, 128);
      expect(target.height, isNull);
    });

    test('different slightly-sized boxes share one bucket (one cache entry)', () {
      final sizes = {
        for (final w in [141.0, 144.0, 150.0, 160.0])
          decodeTargetFor(maxWidth: w, maxHeight: 400, devicePixelRatio: 1.0).width,
      };

      expect(sizes, {256});
    });

    test('an unbounded or empty box decodes at the original size', () {
      expect(
        decodeTargetFor(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          devicePixelRatio: 3,
        ),
        kDecodeOriginal,
      );
      expect(
        decodeTargetFor(maxWidth: 0, maxHeight: 0, devicePixelRatio: 3),
        kDecodeOriginal,
      );
    });

    test('one unbounded side falls back to the other', () {
      final target = decodeTargetFor(
        maxWidth: double.infinity,
        maxHeight: 200,
        devicePixelRatio: 2.0,
      );

      expect(target.width, isNull);
      expect(target.height, 512); // 400 -> 512
    });

    test('huge boxes are capped', () {
      final target = decodeTargetFor(
        maxWidth: 5000,
        maxHeight: 9000,
        devicePixelRatio: 3.0,
      );

      expect(target.width, kMaxDecodePixels);
    });

    test('a tiny box still gets at least one bucket', () {
      final target = decodeTargetFor(
        maxWidth: 4,
        maxHeight: 4,
        devicePixelRatio: 1.0,
      );

      expect(target.width, kImageBucketPixels);
    });

    test('battery saver scale lowers the decode size', () {
      final normal = decodeTargetFor(
        maxWidth: 400,
        maxHeight: 600,
        devicePixelRatio: 2.0,
      );
      final saver = decodeTargetFor(
        maxWidth: 400,
        maxHeight: 600,
        devicePixelRatio: 2.0,
        scale: 0.75,
      );

      // 800 -> 896 ; 600 -> 640
      expect(normal.width, 896);
      expect(saver.width, 640);
      expect(saver.width!, lessThan(normal.width!));
    });

    test('never returns both sides (that would distort the image)', () {
      for (final w in [50.0, 120.0, 411.0]) {
        for (final h in [50.0, 300.0, 900.0]) {
          final target = decodeTargetFor(
            maxWidth: w,
            maxHeight: h,
            devicePixelRatio: 2.6,
          );

          expect((target.width == null) != (target.height == null), isTrue);
        }
      }
    });
  });
}