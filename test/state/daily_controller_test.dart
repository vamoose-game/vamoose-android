import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/daily_controller.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late FixedClock clock;

  DailyController controller() => DailyController(store, clock);

  Future<void> solveOn(DateTime day) async {
    clock.current = day;
    await controller().completeToday();
  }

  setUp(() {
    store = MemoryStore();
    clock = FixedClock(DateTime(2026, 11, 15, 17, 47, 20));
  });

  test('starts with no streak', () {
    final daily = controller();

    expect(daily.currentStreak, 0);
    expect(daily.bestStreak, 0);
    expect(daily.isTodayCompleted, isFalse);
  });

  test('completing today counts once', () async {
    final daily = controller();

    expect(await daily.completeToday(), isTrue);
    expect(await daily.completeToday(), isFalse);
    expect(daily.isTodayCompleted, isTrue);
    expect(daily.currentStreak, 1);
  });

  test('streak runs through yesterday until today is solved', () async {
    for (final day in [11, 12, 13, 14]) {
      await solveOn(DateTime(2026, 11, day, 10));
    }
    clock.current = DateTime(2026, 11, 15, 10);

    final daily = controller();
    expect(daily.currentStreak, 4);

    await daily.completeToday();
    expect(daily.currentStreak, 5);
  });

  test('a missed day breaks the streak but keeps the best', () async {
    for (final day in [1, 2, 3]) {
      await solveOn(DateTime(2026, 11, day, 10));
    }
    await solveOn(DateTime(2026, 11, 10, 10));

    final daily = controller();
    expect(daily.currentStreak, 1);
    expect(daily.bestStreak, 3);
  });

  test('week runs Monday to Sunday', () {
    final week = controller().currentWeek;

    expect(week.first, DateTime(2026, 11, 9));
    expect(week.last, DateTime(2026, 11, 15));
  });

  test('counts down to the next midnight', () {
    expect(
      controller().timeUntilNextPuzzle,
      const Duration(hours: 6, minutes: 12, seconds: 40),
    );
  });

  test('reset forgets every day', () async {
    final daily = controller();
    await daily.completeToday();

    await daily.reset();

    expect(daily.isTodayCompleted, isFalse);
    expect(controller().bestStreak, 0);
  });
}
