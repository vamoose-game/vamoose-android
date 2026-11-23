import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'sound_effects.dart';

class AudioPlayerSoundEffects implements SoundEffects {
  AudioPlayerSoundEffects._(this._channels);

  static const Map<Sound, int> _voices = {
    Sound.tap: 3,
    Sound.leave: 3,
    Sound.bump: 2,
    Sound.hint: 1,
    Sound.clear: 1,
    Sound.star: 1,
    Sound.tick: 2,
    Sound.fail: 1,
    Sound.boost: 1,
    Sound.crack: 2,
    Sound.shatter: 2,
  };

  final Map<(Sound, int), _Channel> _channels;

  static AudioPlayerSoundEffects create() {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    final channels = {
      for (final sound in Sound.values)
        for (var variant = 0; variant < sound.variants; variant++)
          (sound, variant): _Channel(_asset(sound, variant), _voices[sound]!),
    };
    for (final channel in channels.values) {
      unawaited(channel.load(context));
    }
    return AudioPlayerSoundEffects._(channels);
  }

  static String _asset(Sound sound, int variant) => sound.variants == 1
      ? 'sounds/${sound.name}.wav'
      : 'sounds/${sound.name}_$variant.wav';

  @override
  void play(Sound sound, {int variant = 0}) {
    _channels[(sound, variant.clamp(0, sound.variants - 1))]?.play();
  }
}

class _Channel {
  _Channel(this._asset, int voices)
    : _players = [
        for (var index = 0; index < voices; index++)
          AudioPlayer()..positionUpdater = null,
      ];

  final String _asset;
  final List<AudioPlayer> _players;
  int _next = 0;

  Future<void> load(AudioContext context) async {
    for (final player in _players) {
      try {
        await player.setAudioContext(context);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(_asset));
      } on Object {
        continue;
      }
    }
  }

  void play() {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    unawaited(_restart(player));
  }

  Future<void> _restart(AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } on Object {
      return;
    }
  }
}
