import '../state/settings_controller.dart';
import 'haptics.dart';
import 'sound_effects.dart';

class GameFeedback {
  const GameFeedback({
    required this._sounds,
    required this._haptics,
    required this._settings,
  });

  final SoundEffects _sounds;
  final Haptics _haptics;
  final SettingsController _settings;

  void keyPressed() => _play(Sound.tap);

  void blockLeft({required int streak}) {
    _play(Sound.leave, variant: streak - 1);
    _vibrate(_haptics.light);
  }

  void blockBumped() {
    _play(Sound.bump);
    _vibrate(_haptics.medium);
  }

  void hintShown() => _play(Sound.hint);

  void boardCleared() {
    _play(Sound.clear);
    _vibrate(_haptics.heavy);
  }

  void starEarned(int index) => _play(Sound.star, variant: index);

  void _play(Sound sound, {int variant = 0}) {
    if (_settings.sound) {
      _sounds.play(sound, variant: variant.clamp(0, sound.variants - 1));
    }
  }

  void _vibrate(void Function() pulse) {
    if (_settings.vibration) {
      pulse();
    }
  }
}
