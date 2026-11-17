import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';

class HintWallet extends ChangeNotifier {
  HintWallet(this._store);

  static const int startingHints = 3;
  static const String _countKey = 'hints.count';

  final KeyValueStore _store;

  int get count => _store.readInt(_countKey) ?? startingHints;

  Future<void> add(int amount) async {
    await _store.writeInt(_countKey, count + amount);
    notifyListeners();
  }

  Future<bool> spend() async {
    if (count == 0) {
      return false;
    }
    await _store.writeInt(_countKey, count - 1);
    notifyListeners();
    return true;
  }
}
