import 'dart:async';

import 'package:dragonball_app/core/platform/experience_policy.dart';
import 'package:dragonball_app/core/platform/power_save_source.dart';
import 'package:dragonball_app/features/dragonball/presentation/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LEARN (testing native-backed behaviour WITHOUT a phone): the app depends on
// the PowerSaveSource contract, so a test hands it a fake that you control
// from the test body. "What does the app do when the user turns battery saver
// on?" becomes: controller.add(true), then look at the policy.

class FakePowerSaveSource implements PowerSaveSource {
  FakePowerSaveSource({this.initial = false});

  final bool initial;
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> current() async => initial;

  @override
  Stream<bool> changes() => controller.stream;
}

ProviderContainer makeContainer(FakePowerSaveSource source) {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final container = ProviderContainer(
    overrides: [powerSaveSourceProvider.overrideWithValue(source)],
  );

  addTearDown(container.dispose);
  addTearDown(source.controller.close);

  // Keep the providers alive for the whole test.
  container.listen(experiencePolicyProvider, (_, __) {});

  return container;
}

void main() {
  group('ExperiencePolicy.from', () {
    test('battery saver on and adaptation allowed -> everything dialled down', () {
      final policy = ExperiencePolicy.from(batterySaver: true, adaptEnabled: true);

      expect(policy.powerSaver, isTrue);
      expect(policy.reduceMotion, isTrue);
      expect(policy.preloadImages, isFalse);
      expect(policy.autoRevalidate, isFalse);
      expect(policy.imageDecodeScale, lessThan(1.0));
      expect(
        policy.imageCacheBytes,
        lessThan(ExperiencePolicy.defaultImageCacheBytes),
      );
    });

    test('battery saver on but the user opted out -> normal', () {
      final policy = ExperiencePolicy.from(batterySaver: true, adaptEnabled: false);

      expect(policy, const ExperiencePolicy());
    });

    test('battery saver off -> normal', () {
      final policy = ExperiencePolicy.from(batterySaver: false, adaptEnabled: true);

      expect(policy.powerSaver, isFalse);
      expect(policy.reduceMotion, isFalse);
      expect(policy.preloadImages, isTrue);
      expect(policy.autoRevalidate, isTrue);
      expect(policy.imageDecodeScale, 1.0);
    });

    test('equal policies are == (so Riverpod does not notify for nothing)', () {
      expect(const ExperiencePolicy(), const ExperiencePolicy());
      expect(const ExperiencePolicy.saver(), const ExperiencePolicy.saver());
      expect(const ExperiencePolicy(), isNot(const ExperiencePolicy.saver()));
      expect(
        const ExperiencePolicy().hashCode,
        const ExperiencePolicy().hashCode,
      );
    });
  });

  group('policy provider', () {
    test('starts normal and follows the native source', () async {
      final source = FakePowerSaveSource();
      final container = makeContainer(source);

      await pumpEventQueue();
      expect(container.read(experiencePolicyProvider).powerSaver, isFalse);

      source.controller.add(true);
      await pumpEventQueue();
      expect(container.read(experiencePolicyProvider).powerSaver, isTrue);

      source.controller.add(false);
      await pumpEventQueue();
      expect(container.read(experiencePolicyProvider).powerSaver, isFalse);
    });

    test('a source that starts with battery saver on is respected', () async {
      final container = makeContainer(FakePowerSaveSource(initial: true));

      await pumpEventQueue();

      expect(container.read(experiencePolicyProvider).reduceMotion, isTrue);
    });

    test('turning the setting off overrides battery saver', () async {
      final source = FakePowerSaveSource(initial: true);
      final container = makeContainer(source);

      await pumpEventQueue();
      expect(container.read(experiencePolicyProvider).powerSaver, isTrue);

      container.read(appSettingsProvider.notifier).setAdaptToPowerSaver(false);
      await pumpEventQueue();

      expect(container.read(experiencePolicyProvider), const ExperiencePolicy());
    });

    test('the unsupported source reports battery saver as off', () async {
      const source = UnsupportedPowerSaveSource();

      expect(await source.current(), isFalse);
      expect(await source.changes().isEmpty, isTrue);
    });
  });

  group('settings', () {
    test('adaptToPowerSaver defaults to on and copyWith changes only it', () {
      const settings = AppSettings();

      expect(settings.adaptToPowerSaver, isTrue);

      final changed = settings.copyWith(adaptToPowerSaver: false);

      expect(changed.adaptToPowerSaver, isFalse);
      expect(changed.trueBlack, settings.trueBlack);
    });
  });
}