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
      ..blockLeft(streak: 1)
      ..blockBumped()
      ..boardCleared();

    expect(sounds.played, [
      (Sound.leave, 0),
      (Sound.bump, 0),
      (Sound.clear, 0),
    ]);
    expect(haptics.pulses, 3);
  });

  test('each block in a streak plays the next note up', () {
    for (var streak = 1; streak <= 4; streak++) {
      feedback.blockLeft(streak: streak);
    }

    expect(sounds.played.map((played) => played.$2), [0, 1, 2, 3]);
  });

  test('long streaks stay on the top note', () {
    feedback.blockLeft(streak: 30);

    expect(sounds.played.single, (Sound.leave, Sound.leave.variants - 1));
  });

  test('stars ring higher one after another', () {
    feedback
      ..starEarned(0)
      ..starEarned(1)
      ..starEarned(2);

    expect(sounds.played, [(Sound.star, 0), (Sound.star, 1), (Sound.star, 2)]);
  });

  test('stays quiet when sound is off', () async {
    await settings.setSound(false);

    feedback
      ..blockLeft(streak: 1)
      ..hintShown()
      ..keyPressed();

    expect(sounds.played, isEmpty);
    expect(haptics.pulses, 1);
  });

  test('does not vibrate when vibration is off', () async {
    await settings.setVibration(false);

    feedback.blockBumped();

    expect(sounds.played, [(Sound.bump, 0)]);
    expect(haptics.pulses, 0);
  });
}
