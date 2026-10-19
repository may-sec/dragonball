import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dragonball/presentation/app_settings.dart';
import 'power_save_source.dart';

// Re-exported so a screen that needs the policy imports ONE file.
export 'power_save_source.dart'
    show powerSaveProvider, powerSaveSupportedProvider;

// =============================================================================
// LEARN (constraint-aware UI): many different signals say "be careful":
// battery saver, reduced motion, data saver, offline, slow network... If every
// widget checked each signal itself, the rules would be scattered and
// contradictory. Instead:
//
//     signals  ->  ONE derived "policy"  ->  consumers just obey it
//
//   powerSaveProvider (native) ----+
//                                  +--> experiencePolicyProvider --> main.dart
//   settings.adaptToPowerSaver ----+                             --> splash
//        (the USER keeps control)                                --> catalog
//                                                                --> detail view
//
// The policy is a plain immutable value with a PURE factory (ExperiencePolicy
// .from), so every rule is a one-line unit test, and a screen test can override
// the provider to see how the UI behaves under battery saver without a phone.
// =============================================================================
@immutable
class ExperiencePolicy {
  const ExperiencePolicy({
    this.powerSaver = false,
    this.reduceMotion = false,
    this.preloadImages = true,
    this.autoRevalidate = true,
    this.imageCacheBytes = defaultImageCacheBytes,
    this.imageDecodeScale = 1.0,
  });

  /// Everything dialled down.
  const ExperiencePolicy.saver()
      : powerSaver = true,
        reduceMotion = true,
        preloadImages = false,
        autoRevalidate = false,
        imageCacheBytes = saverImageCacheBytes,
        imageDecodeScale = saverImageDecodeScale;

  /// Flutter's own default size for decoded images in RAM (100 MB).
  static const int defaultImageCacheBytes = 100 << 20;

  /// Under battery saver a smaller decoded-image cache means less memory
  /// pressure and fewer re-decodes of huge bitmaps.
  static const int saverImageCacheBytes = 32 << 20;

  /// Under battery saver images are decoded at 75% of the pixels the screen
  /// could show: noticeably less memory and decode work, slightly softer.
  static const double saverImageDecodeScale = 0.75;

  /// The adaptation is active: OS battery saver is on AND the user allows it.
  final bool powerSaver;

  /// No decorative motion (merged with the user's own reduced-motion setting).
  final bool reduceMotion;

  /// Warm the image cache ahead of time (splash, detail screen).
  final bool preloadImages;

  /// Start a background "is the server data newer?" check by itself.
  /// A manual refresh always works.
  final bool autoRevalidate;

  /// maximumSizeBytes for Flutter's in-memory ImageCache.
  final int imageCacheBytes;

  /// Multiplier for the decode size of every image (1.0 = full quality).
  final double imageDecodeScale;

  factory ExperiencePolicy.from({
    required bool batterySaver,
    required bool adaptEnabled,
  }) {
    return batterySaver && adaptEnabled
        ? const ExperiencePolicy.saver()
        : const ExperiencePolicy();
  }

  // == and hashCode make Riverpod notify listeners ONLY when something really
  // changed (a new-but-equal policy is ignored). Models without == are the
  // reason the catalog rebuilds more than it needs to.
  @override
  bool operator ==(Object other) =>
      other is ExperiencePolicy &&
      other.powerSaver == powerSaver &&
      other.reduceMotion == reduceMotion &&
      other.preloadImages == preloadImages &&
      other.autoRevalidate == autoRevalidate &&
      other.imageCacheBytes == imageCacheBytes &&
      other.imageDecodeScale == imageDecodeScale;

  @override
  int get hashCode => Object.hash(
        powerSaver,
        reduceMotion,
        preloadImages,
        autoRevalidate,
        imageCacheBytes,
        imageDecodeScale,
      );
}

final experiencePolicyProvider = Provider<ExperiencePolicy>((ref) {
  // While the first native answer is loading this is false: start "normal".
  final batterySaver = ref.watch(powerSaveProvider).asData?.value ?? false;

  final adaptEnabled = ref.watch(
    appSettingsProvider.select((settings) => settings.adaptToPowerSaver),
  );

  return ExperiencePolicy.from(
    batterySaver: batterySaver,
    adaptEnabled: adaptEnabled,
  );
});