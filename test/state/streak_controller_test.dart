import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/coin_wallet.dart';
import 'package:vamoose/state/streak_controller.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late FixedClock clock;
  late CoinWallet coins;
  late StreakController streak;

  setUp(() {
    store = MemoryStore();
    clock = FixedClock(DateTime(2026, 11, 1, 9));
    coins = CoinWallet(store);
    streak = StreakController(store, clock, coins);
  });

  Future<void> nextDay([int days = 1]) async {
    clock.current = DateTime(
      clock.current.year,
      clock.current.month,
      clock.current.day + days,
      9,
    );
    await streak.refresh();
  }

  test('day one is ready on the first visit', () {
    expect(streak.canCollect, isTrue);
    expect(streak.day, 1);
    expect(streak.reward, 10);
    expect(streak.count, 0);
  });

  test('collecting pays once a day and climbs the road', () async {
    expect(await streak.collect(), 10);
    expect(await streak.collect(), 0);
    expect(streak.canCollect, isFalse);
    expect(coins.balance, 110);

    await nextDay();
    expect(streak.day, 2);
    expect(await streak.collect(), 15);
    expect(streak.count, 2);
  });

  test('day seven opens the chest, adds a freeze and starts over', () async {
    for (var day = 1; day <= 7; day++) {
      await streak.collect();
      if (day < 7) {
        await nextDay();
      }
    }

    expect(coins.balance, 100 + 10 + 15 + 20 + 25 + 30 + 40 + 150);
    expect(streak.freezes, 1);
    expect(streak.count, 7);
    expect(streak.marks, isEmpty);

    await nextDay();
    expect(streak.day, 1);
    expect(streak.count, 7);
  });

  test('a missed day uses a freeze and shows as saved', () async {
    await streak.buyFreeze();
    await streak.collect();

    await nextDay(2);

    expect(streak.freezes, 0);
    expect(streak.marks, [StreakMark.collected, StreakMark.saved]);
    expect(streak.count, 2);
    expect(streak.day, 3);
    expect(streak.canCollect, isTrue);
  });

  test('a missed day without a freeze starts over', () async {
    await streak.collect();
    await nextDay();
    await streak.collect();

    await nextDay(3);

    expect(streak.count, 0);
    expect(streak.marks, isEmpty);
    expect(streak.day, 1);
  });

  test('freezes cost 60 coins and stop at two', () async {
    expect(await streak.buyFreeze(), isTrue);
    expect(coins.balance, 40);
    expect(await streak.buyFreeze(), isFalse);

    await coins.earn(200);
    expect(await streak.buyFreeze(), isTrue);
    expect(await streak.buyFreeze(), isFalse);
    expect(streak.freezes, 2);
    expect(coins.balance, 180);
  });

  test('reset starts the road again', () async {
    await streak.collect();
    await streak.buyFreeze();

    await streak.reset();

    expect(streak.count, 0);
    expect(streak.freezes, 0);
    expect(streak.canCollect, isTrue);
  });
}
