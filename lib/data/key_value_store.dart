abstract interface class KeyValueStore {
  int? readInt(String key);

  bool? readBool(String key);

  String? readString(String key);

  List<String>? readStringList(String key);

  Future<void> writeInt(String key, int value);

  Future<void> writeBool(String key, bool value);

  Future<void> writeString(String key, String value);

  Future<void> writeStringList(String key, List<String> value);

  Future<void> remove(String key);
}
