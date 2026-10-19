import 'dart:math' as math;

// =============================================================================
// LEARN (why decode size matters): an image file is compressed (PNG / JPEG).
// To DRAW it, Flutter decodes it into an uncompressed bitmap that costs
//
//     width * height * 4 bytes (RGBA)
//
// A 1000 x 1500 character PNG is about 6 MB once decoded, even if it is shown
// in a 72 x 88 thumbnail that needs about 190 x 230 real pixels (~170 KB).
// A grid of 20 cards is the difference between ~120 MB and ~4 MB of image RAM.
//
// The fix is to tell the decoder the size we actually need:
//   * Android: CachedNetworkImage(memCacheWidth / memCacheHeight)
//   * web:     Image.network(cacheWidth / cacheHeight)
// Give ONE side only: Flutter then keeps the aspect ratio. Giving both would
// stretch the picture.
//
// Real pixels = logical size * devicePixelRatio. The result is rounded UP to a
// "bucket" so that many slightly different layouts (141px, 144px, 150px...)
// share one cache entry instead of each decoding the same file again.
//
// Pure function: no widgets, no providers. See
// test/image_sizing_test.dart.
// =============================================================================

typedef DecodeTarget = ({int? width, int? height});

/// Sizes are rounded up to a multiple of this many pixels.
const int kImageBucketPixels = 128;

/// Never decode wider than this, whatever the screen says.
const int kMaxDecodePixels = 2048;

/// "No hint": decode at the file's own size (the previous behaviour).
const DecodeTarget kDecodeOriginal = (width: null, height: null);

/// [maxWidth] / [maxHeight] are the layout limits for the image (they may be
/// infinite). [scale] < 1 lowers the quality on purpose (battery saver).
DecodeTarget decodeTargetFor({
  required double maxWidth,
  required double maxHeight,
  required double devicePixelRatio,
  double scale = 1.0,
  int bucket = kImageBucketPixels,
  int maxPixels = kMaxDecodePixels,
}) {
  final hasWidth = maxWidth.isFinite && maxWidth > 0;
  final hasHeight = maxHeight.isFinite && maxHeight > 0;

  // Unbounded or empty box: we cannot know the size, so do not guess.
  if (!hasWidth && !hasHeight) return kDecodeOriginal;

  // Which side limits the picture? We do not know the file's aspect ratio
  // here, so use the box shape: character art is mostly portrait, so in a
  // box that is not wider than tall the WIDTH is the limit; in a wider box the
  // HEIGHT is. When the guess is wrong the result is only a little larger than
  // needed, never blurry, and still far below the full-size decode.
  final useWidth = hasWidth && (!hasHeight || maxWidth <= maxHeight);
  final logical = useWidth ? maxWidth : maxHeight;

  final needed = logical * devicePixelRatio * scale;
  final bucketed = (needed / bucket).ceil() * bucket;
  final value = math.min(math.max(bucketed, bucket), maxPixels);

  return useWidth ? (width: value, height: null) : (width: null, height: value);
}