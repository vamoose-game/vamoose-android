import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/calendar_day.dart';
import '../core/clock.dart';
import '../data/key_value_store.dart';

class DailyController extends ChangeNotifier {
  DailyController(this._store, this._clock)
    : _completed = {...?_store.readStringList(_completedKey)};

  static const String _completedKey = 'daily.completed';
  static const String _bestKey = 'daily.best';

  final KeyValueStore _store;
  final Clock _clock;
  final Set<String> _completed;

  DateTime get today => _clock.now().startOfDay;

  bool isCompleted(DateTime day) => _completed.contains(day.dayKey);

  bool get isTodayCompleted => isCompleted(today);

  int get currentStreak {
    var day = isTodayCompleted ? today : today.addDays(-1);
    var streak = 0;
    while (isCompleted(day)) {
      streak++;
      day = day.addDays(-1);
    }
    return streak;
  }

  int get bestStreak => max(_store.readInt(_bestKey) ?? 0, currentStreak);

  List<DateTime> get currentWeek => [
    for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
      today.startOfWeek.addDays(offset),
  ];

  Duration get timeUntilNextPuzzle => today.addDays(1).difference(_clock.now());

  Future<bool> completeToday() async {
    if (isTodayCompleted) {
      return false;
    }
    _completed.add(today.dayKey);
    await _store.writeStringList(_completedKey, _completed.toList()..sort());
    await _store.writeInt(_bestKey, bestStreak);
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    _completed.clear();
    await _store.remove(_completedKey);
    await _store.remove(_bestKey);
    notifyListeners();
  }
}
