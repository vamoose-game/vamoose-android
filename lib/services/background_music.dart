import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/settings_controller.dart';
import 'music_player.dart';

class BackgroundMusic with WidgetsBindingObserver {
  BackgroundMusic(this._player, this._settings);

  final MusicPlayer _player;
  final SettingsController _settings;
  bool _foreground = true;
  bool _playing = false;

  bool get isPlaying => _playing;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_sync);
    _sync();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_sync);
    _foreground = false;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final shouldPlay = _settings.music && _foreground;
    if (shouldPlay == _playing) {
      return;
    }
    _playing = shouldPlay;
    unawaited(shouldPlay ? _player.play() : _player.pause());
  }
}
