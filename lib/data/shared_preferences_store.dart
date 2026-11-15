import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

class SharedPreferencesStore implements KeyValueStore {
  const SharedPreferencesStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  int? readInt(String key) => _preferences.getInt(key);

  @override
  bool? readBool(String key) => _preferences.getBool(key);

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  List<String>? readStringList(String key) => _preferences.getStringList(key);

  @override
  Future<void> writeInt(String key, int value) =>
      _preferences.setInt(key, value);

  @override
  Future<void> writeBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> writeString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> writeStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
