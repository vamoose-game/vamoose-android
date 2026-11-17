import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const String _soundKey = 'settings.sound';
  static const String _musicKey = 'settings.music';
  static const String _vibrationKey = 'settings.vibration';
  static const String _tutorialSeenKey = 'settings.tutorialSeen';
  static const String _introSeenKey = 'settings.introSeen';

  final KeyValueStore _store;

  bool get sound => _store.readBool(_soundKey) ?? true;

  bool get music => _store.readBool(_musicKey) ?? true;

  bool get vibration => _store.readBool(_vibrationKey) ?? true;

  bool get tutorialSeen => _store.readBool(_tutorialSeenKey) ?? false;

  bool hasSeenIntro(String id) =>
      _store.readBool('$_introSeenKey.$id') ?? false;

  Future<void> setSound(bool value) => _write(_soundKey, value);

  Future<void> setMusic(bool value) => _write(_musicKey, value);

  Future<void> setVibration(bool value) => _write(_vibrationKey, value);

  Future<void> markTutorialSeen() => _write(_tutorialSeenKey, true);

  Future<void> markIntroSeen(String id) => _write('$_introSeenKey.$id', true);

  Future<void> _write(String key, bool value) async {
    await _store.writeBool(key, value);
    notifyListeners();
  }
}
