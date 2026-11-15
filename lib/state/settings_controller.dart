import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._store);

  static const String _easyModeKey = 'settings.easyMode';
  static const String _biggerTextKey = 'settings.biggerText';
  static const String _soundKey = 'settings.sound';
  static const String _vibrationKey = 'settings.vibration';
  static const String _tutorialSeenKey = 'settings.tutorialSeen';

  final KeyValueStore _store;

  bool get easyMode => _store.readBool(_easyModeKey) ?? false;

  bool get biggerText => _store.readBool(_biggerTextKey) ?? false;

  bool get sound => _store.readBool(_soundKey) ?? true;

  bool get vibration => _store.readBool(_vibrationKey) ?? true;

  bool get tutorialSeen => _store.readBool(_tutorialSeenKey) ?? false;

  double get textScale => biggerText ? 1.2 : 1;

  Future<void> setEasyMode(bool value) => _write(_easyModeKey, value);

  Future<void> setBiggerText(bool value) => _write(_biggerTextKey, value);

  Future<void> setSound(bool value) => _write(_soundKey, value);

  Future<void> setVibration(bool value) => _write(_vibrationKey, value);

  Future<void> markTutorialSeen() => _write(_tutorialSeenKey, true);

  Future<void> _write(String key, bool value) async {
    await _store.writeBool(key, value);
    notifyListeners();
  }
}
