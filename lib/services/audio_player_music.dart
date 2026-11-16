import 'package:audioplayers/audioplayers.dart';

import 'music_player.dart';

class AudioPlayerMusic implements MusicPlayer {
  AudioPlayerMusic({this.volume = 0.45});

  static const String asset = 'music/calm.ogg';
  static const int _fadeSteps = 20;
  static const Duration _fadeStep = Duration(milliseconds: 75);

  final double volume;
  final AudioPlayer _player = AudioPlayer(playerId: 'music');
  Future<void>? _loading;
  int _session = 0;

  Future<void> _load() async {
    await _player.setAudioContext(AudioContextConfig().build());
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource(asset));
  }

  @override
  Future<void> play() async {
    final session = ++_session;
    try {
      await (_loading ??= _load());
      await _player.setVolume(0);
      await _player.resume();
      for (var step = 1; step <= _fadeSteps && session == _session; step++) {
        await Future<void>.delayed(_fadeStep);
        if (session == _session) {
          await _player.setVolume(volume * step / _fadeSteps);
        }
      }
    } on Object {
      return;
    }
  }

  @override
  Future<void> pause() async {
    _session++;
    try {
      await _player.pause();
    } on Object {
      return;
    }
  }
}
