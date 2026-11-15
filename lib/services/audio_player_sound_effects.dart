import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'sound_effects.dart';

class AudioPlayerSoundEffects implements SoundEffects {
  AudioPlayerSoundEffects();

  final Map<Sound, AudioPlayer> _players = {};

  static Future<AudioPlayerSoundEffects> create() async {
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    return AudioPlayerSoundEffects();
  }

  @override
  void play(Sound sound) {
    final player = _players.putIfAbsent(
      sound,
      () => AudioPlayer(playerId: 'sfx-${sound.name}'),
    );
    unawaited(
      player
          .play(
            AssetSource('sounds/${sound.name}.wav'),
            mode: PlayerMode.lowLatency,
          )
          .catchError((Object _) {}),
    );
  }
}
