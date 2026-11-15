import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/game_feedback.dart';
import 'package:vamoose/services/haptics.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/state/settings_controller.dart';

import '../support/memory_store.dart';
import '../support/test_services.dart';

class _CountingHaptics implements Haptics {
  int pulses = 0;

  @override
  void light() => pulses++;

  @override
  void medium() => pulses++;

  @override
  void heavy() => pulses++;
}

void main() {
  late SettingsController settings;
  late RecordingSounds sounds;
  late _CountingHaptics haptics;
  late GameFeedback feedback;

  setUp(() {
    settings = SettingsController(MemoryStore());
    sounds = RecordingSounds();
    haptics = _CountingHaptics();
    feedback = GameFeedback(
      sounds: sounds,
      haptics: haptics,
      settings: settings,
    );
  });

  test('plays sounds and vibrates by default', () {
    feedback
      ..blockLeft()
      ..blockBumped()
      ..boardCleared();

    expect(sounds.played, [Sound.slide, Sound.bump, Sound.clear]);
    expect(haptics.pulses, 3);
  });

  test('stays quiet when sound is off', () async {
    await settings.setSound(false);

    feedback
      ..blockLeft()
      ..hintShown();

    expect(sounds.played, isEmpty);
    expect(haptics.pulses, 1);
  });

  test('does not vibrate when vibration is off', () async {
    await settings.setVibration(false);

    feedback.blockBumped();

    expect(sounds.played, [Sound.bump]);
    expect(haptics.pulses, 0);
  });
}
