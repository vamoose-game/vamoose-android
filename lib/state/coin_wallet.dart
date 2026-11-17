import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';
import '../domain/economy.dart';

class CoinWallet extends ChangeNotifier {
  CoinWallet(this._store);

  static const String _balanceKey = 'coins.balance';
  static const String _doubledKey = 'coins.doubled';

  final KeyValueStore _store;

  int get balance => _store.readInt(_balanceKey) ?? Economy.startingCoins;

  bool canAfford(int price) => balance >= price;

  Future<void> earn(int amount) async {
    if (amount <= 0) {
      return;
    }
    await _store.writeInt(_balanceKey, balance + amount);
    notifyListeners();
  }

  Future<bool> spend(int price) async {
    if (!canAfford(price)) {
      return false;
    }
    await _store.writeInt(_balanceKey, balance - price);
    notifyListeners();
    return true;
  }

  bool hasDoubled(String reward) =>
      (_store.readStringList(_doubledKey) ?? const []).contains(reward);

  Future<void> markDoubled(String reward) async {
    await _store.writeStringList(_doubledKey, [
      ...?_store.readStringList(_doubledKey),
      reward,
    ]);
    notifyListeners();
  }

  Future<void> reset() async {
    await _store.remove(_balanceKey);
    await _store.remove(_doubledKey);
    notifyListeners();
  }
}
