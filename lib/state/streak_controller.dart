import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/calendar_day.dart';
import '../core/clock.dart';
import '../data/key_value_store.dart';
import '../domain/economy.dart';
import 'coin_wallet.dart';

enum StreakMark { collected, saved }

class StreakController extends ChangeNotifier {
  StreakController(this._store, this._clock, this._coins);

  static const String _marksKey = 'streak.marks';
  static const String _countKey = 'streak.count';
  static const String _lastKey = 'streak.last';
  static const String _freezesKey = 'streak.freezes';

  final KeyValueStore _store;
  final Clock _clock;
  final CoinWallet _coins;

  DateTime get today => _clock.now().startOfDay;

  List<StreakMark> get marks => [
    for (final code in (_store.readString(_marksKey) ?? '').split(''))
      code == 's' ? StreakMark.saved : StreakMark.collected,
  ];

  int get count => _store.readInt(_countKey) ?? 0;

  int get freezes => _store.readInt(_freezesKey) ?? 0;

  int get day => marks.length + 1;

  int get reward => Economy.loginRewards[day - 1];

  bool get canCollect => _store.readString(_lastKey) != today.dayKey;

  bool get canBuyFreeze =>
      freezes < Economy.maxFreezes && _coins.canAfford(Economy.freezePrice);

  Future<void> refresh() async {
    final last = _store.readString(_lastKey);
    if (last == null) {
      return;
    }
    final missed = DateTime.parse(last).daysUntil(today) - 1;
    if (missed <= 0) {
      return;
    }
    var marks = this.marks;
    var count = this.count;
    var freezes = this.freezes;
    for (var gap = 0; gap < missed; gap++) {
      if (freezes == 0) {
        marks = [];
        count = 0;
        break;
      }
      freezes--;
      count++;
      marks = _advance(marks, StreakMark.saved);
    }
    await _save(marks, count, freezes, today.addDays(-1));
  }

  Future<int> collect() async {
    await refresh();
    if (!canCollect) {
      return 0;
    }
    final amount = reward;
    final freezes = day == Economy.loginRewards.length
        ? min(Economy.maxFreezes, this.freezes + 1)
        : this.freezes;
    await _save(
      _advance(marks, StreakMark.collected),
      count + 1,
      freezes,
      today,
    );
    await _coins.earn(amount);
    return amount;
  }

  Future<bool> buyFreeze() async {
    if (freezes >= Economy.maxFreezes ||
        !await _coins.spend(Economy.freezePrice)) {
      return false;
    }
    await _store.writeInt(_freezesKey, freezes + 1);
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    for (final key in [_marksKey, _countKey, _lastKey, _freezesKey]) {
      await _store.remove(key);
    }
    notifyListeners();
  }

  List<StreakMark> _advance(List<StreakMark> marks, StreakMark mark) {
    final next = [...marks, mark];
    return next.length == Economy.loginRewards.length ? [] : next;
  }

  Future<void> _save(
    List<StreakMark> marks,
    int count,
    int freezes,
    DateTime last,
  ) async {
    await _store.writeString(
      _marksKey,
      [for (final mark in marks) mark == StreakMark.saved ? 's' : 'c'].join(),
    );
    await _store.writeInt(_countKey, count);
    await _store.writeInt(_freezesKey, freezes);
    await _store.writeString(_lastKey, last.dayKey);
    notifyListeners();
  }
}
