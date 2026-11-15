import 'package:vamoose/data/key_value_store.dart';

class MemoryStore implements KeyValueStore {
  final Map<String, Object> values = {};

  @override
  int? readInt(String key) => values[key] as int?;

  @override
  bool? readBool(String key) => values[key] as bool?;

  @override
  String? readString(String key) => values[key] as String?;

  @override
  List<String>? readStringList(String key) => values[key] as List<String>?;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;

  @override
  Future<void> writeBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> writeString(String key, String value) async =>
      values[key] = value;

  @override
  Future<void> writeStringList(String key, List<String> value) async =>
      values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}
