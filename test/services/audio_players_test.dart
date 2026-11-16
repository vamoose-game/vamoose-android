import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/audio_player_music.dart';
import 'package:vamoose/services/audio_player_sound_effects.dart';
import 'package:vamoose/services/sound_effects.dart';

import '../support/fake_audio_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioPlatform platform;

  setUp(() => platform = FakeAudioPlatform.install());

  test('fast taps play every sound without polling the position', () async {
    final sounds = AudioPlayerSoundEffects.create();
    await pumpEventQueue();

    for (var streak = 0; streak < 12; streak++) {
      sounds.play(Sound.leave, variant: streak);
      sounds.play(Sound.bump);
    }
    await pumpEventQueue();

    expect(platform.count('resume'), 24);
    expect(platform.count('getCurrentPosition'), 0);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });

  test('music plays without polling the position every frame', () async {
    await AudioPlayerMusic().play();

    expect(platform.count('resume'), 1);
    expect(platform.count('getCurrentPosition'), 0);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });
}
