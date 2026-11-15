import 'package:flutter/foundation.dart';

import '../core/calendar_day.dart';
import '../core/clock.dart';
import '../data/key_value_store.dart';

class HintWallet extends ChangeNotifier {
  HintWallet(this._store, this._clock);

  static const int startingHints = 3;
  static const String _countKey = 'hints.count';
  static const String _lastDailyKey = 'hints.lastDaily';

  final KeyValueStore _store;
  final Clock _clock;

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

  Future<bool> claimDailyHint() async {
    final today = _clock.now().dayKey;
    final lastClaim = _store.readString(_lastDailyKey);
    if (lastClaim == today) {
      return false;
    }
    await _store.writeString(_lastDailyKey, today);
    if (lastClaim == null) {
      return false;
    }
    await add(1);
    return true;
  }
}
