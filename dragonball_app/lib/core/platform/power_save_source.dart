import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// LEARN (platform channels, Module 9.5): Dart cannot ask Android "is battery
// saver on?". Flutter's answer is a MESSAGE channel with a NAME that both sides
// agree on:
//
//   * MethodChannel  : Dart asks one question, native answers once
//                      (request / response).   -> "isPowerSaveMode"
//   * EventChannel   : native pushes a stream of events to Dart
//                      (a broadcast receiver turned into a Dart Stream).
//
// Messages are encoded with StandardMessageCodec (bool, int, String, List,
// Map...). The channel NAMES are plain strings, so a typo on one side fails
// silently at runtime: that fragility is exactly what Pigeon (Module 9.7)
// removes by generating both sides from one Dart interface.
//
// DEPENDENCY INVERSION (Module 6.1): the rest of the app depends on the small
// PowerSaveSource contract, never on MethodChannel. Tests and non-Android
// platforms plug in another implementation.
// =============================================================================

abstract interface class PowerSaveSource {
  /// Is the OS battery saver on right now? false when unknown.
  Future<bool> current();

  /// Emits every time battery saver is switched on or off.
  Stream<bool> changes();
}

/// Web, iOS, desktop: there is nothing to read, so "off".
class UnsupportedPowerSaveSource implements PowerSaveSource {
  const UnsupportedPowerSaveSource();

  @override
  Future<bool> current() async => false;

  @override
  Stream<bool> changes() => const Stream<bool>.empty();
}

class MethodChannelPowerSaveSource implements PowerSaveSource {
  const MethodChannelPowerSaveSource();

  // MUST match PowerSaveBridge.kt (METHOD_CHANNEL / EVENT_CHANNEL).
  static const MethodChannel _method = MethodChannel('dev.dragonball/power');
  static const EventChannel _events = EventChannel('dev.dragonball/power_events');

  @override
  Future<bool> current() async {
    try {
      return await _method.invokeMethod<bool>('isPowerSaveMode') ?? false;
    } on MissingPluginException {
      // The native side was not added (yet): behave as "off", do not crash.
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<bool> changes() async* {
    try {
      await for (final value in _events.receiveBroadcastStream()) {
        if (value is bool) yield value;
      }
    } on MissingPluginException {
      // Same: no native handler registered.
    } on PlatformException {
      // The native side reported an error; stop listening quietly.
    }
  }
}

/// Android gets the real channel; every other platform gets "unsupported".
/// (defaultTargetPlatform + kIsWeb come from foundation, so this file needs no
/// dart:io and still compiles for web.)
PowerSaveSource createPowerSaveSource() {
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  return isAndroid
      ? const MethodChannelPowerSaveSource()
      : const UnsupportedPowerSaveSource();
}

final powerSaveSourceProvider = Provider<PowerSaveSource>(
  (ref) => createPowerSaveSource(),
);

/// true while OS battery saver is on. Starts with the current value, then
/// follows changes.
final powerSaveProvider = StreamProvider<bool>((ref) async* {
  final source = ref.watch(powerSaveSourceProvider);

  yield await source.current();
  yield* source.changes();
});

/// false on web / iOS / desktop, where there is no battery-saver signal at all.
/// Lets the UI say "not available" instead of a misleading "off".
final powerSaveSupportedProvider = Provider<bool>(
  (ref) => ref.watch(powerSaveSourceProvider) is! UnsupportedPowerSaveSource,
);