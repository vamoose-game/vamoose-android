import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';

class AdFreeController extends ChangeNotifier {
  AdFreeController(this._store);

  static const String _key = 'purchases.removeAds';

  final KeyValueStore _store;

  bool get adsRemoved => _store.readBool(_key) ?? false;

  Future<void> grant() async {
    if (adsRemoved) {
      return;
    }
    await _store.writeBool(_key, true);
    notifyListeners();
  }
}
