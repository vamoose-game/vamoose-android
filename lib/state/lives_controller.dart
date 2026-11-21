import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../data/key_value_store.dart';
import '../domain/economy.dart';
import 'coin_wallet.dart';

/// Lives shared by the whole game. A failed level costs one, and one comes
/// back every [Economy.lifeRefill] until there are [Economy.maxLives].
///
/// The time the next life arrives is saved as a timestamp, so lives refill
/// while the app is closed. Reads work it out from the clock; anything that
/// shows a countdown calls [refresh] as it ticks.
class LivesController extends ChangeNotifier {
  LivesController(this._store, this._clock);

  static const String _countKey = 'lives.count';
  static const String _nextKey = 'lives.nextAt';
  static const int max = Economy.maxLives;
  static const Duration refill = Economy.lifeRefill;

  final KeyValueStore _store;
  final Clock _clock;
  int? _shown;

  int get count => _current().count;

  bool get isFull => count >= max;

  bool get isEmpty => count == 0;

  /// Time until the next life comes back, or null when lives are full.
  Duration? get untilNext {
    final next = _current().nextAt;
    return next?.difference(_clock.now());
  }

  /// How far the returning life has filled up, from 0 to 1.
  double get refillProgress {
    final left = untilNext;
    if (left == null) {
      return 1;
    }
    return (1 - left.inMilliseconds / refill.inMilliseconds).clamp(0, 1);
  }

  /// Saves lives that came back since the last look, and a wait cut short
  /// after the phone's clock moved back, and tells listeners.
  Future<void> refresh() async {
    final current = _current();
    if (current.count != (_store.readInt(_countKey) ?? max) ||
        current.nextAt?.millisecondsSinceEpoch != _store.readInt(_nextKey)) {
      await _save(current.count, current.nextAt);
    } else if (_shown != current.count) {
      _shown = current.count;
      notifyListeners();
    }
  }

  Future<bool> spend() async {
    final current = _current();
    if (current.count == 0) {
      return false;
    }
    await _save(current.count - 1, current.nextAt ?? _clock.now().add(refill));
    return true;
  }

  Future<void> add(int amount) async {
    final current = _current();
    final count = min(max, current.count + amount);
    await _save(
      count,
      count >= max ? null : current.nextAt ?? _clock.now().add(refill),
    );
  }

  Future<bool> refillAll(CoinWallet coins) async {
    if (isFull || !await coins.spend(Economy.refillLivesPrice)) {
      return false;
    }
    await _save(max, null);
    return true;
  }

  Future<void> reset() async {
    _shown = max;
    await Future.wait([_store.remove(_countKey), _store.remove(_nextKey)]);
    notifyListeners();
  }

  ({int count, DateTime? nextAt}) _current() {
    final stored = _store.readInt(_countKey) ?? max;
    if (stored >= max) {
      return (count: max, nextAt: null);
    }
    final now = _clock.now();
    final saved = _store.readInt(_nextKey);
    var next = saved == null
        ? now.add(refill)
        : DateTime.fromMillisecondsSinceEpoch(saved);
    if (next.difference(now) > refill) {
      next = now.add(refill);
    }
    if (now.isBefore(next)) {
      return (count: stored, nextAt: next);
    }
    final back =
        1 + now.difference(next).inMicroseconds ~/ refill.inMicroseconds;
    final count = min(max, stored + back);
    return (
      count: count,
      nextAt: count >= max ? null : next.add(refill * back),
    );
  }

  /// Writes both values before waiting on either, so a [refresh] that runs
  /// in between never sees the new count with the old time.
  Future<void> _save(int count, DateTime? nextAt) async {
    _shown = count;
    await Future.wait([
      _store.writeInt(_countKey, count),
      if (nextAt == null)
        _store.remove(_nextKey)
      else
        _store.writeInt(_nextKey, nextAt.millisecondsSinceEpoch),
    ]);
    notifyListeners();
  }
}
