import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';

/// A count of something the player holds, kept on the device.
class Stock extends ChangeNotifier {
  Stock(this._store, {required this.key, required this.starting});

  final KeyValueStore _store;
  final String key;
  final int starting;

  int get count => _store.readInt(key) ?? starting;

  Future<void> add(int amount) async {
    await _store.writeInt(key, count + amount);
    notifyListeners();
  }

  Future<bool> spend() async {
    if (count == 0) {
      return false;
    }
    await _store.writeInt(key, count - 1);
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    await _store.remove(key);
    notifyListeners();
  }
}
