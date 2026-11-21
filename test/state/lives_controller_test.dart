import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/economy.dart';
import 'package:vamoose/state/coin_wallet.dart';
import 'package:vamoose/state/lives_controller.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late FixedClock clock;
  late LivesController lives;

  setUp(() {
    store = MemoryStore();
    clock = FixedClock(DateTime(2026, 11, 20, 9));
    lives = LivesController(store, clock);
  });

  test('starts full', () {
    expect(lives.count, Economy.maxLives);
    expect(lives.isFull, isTrue);
    expect(lives.untilNext, isNull);
  });

  test('a lost life starts the refill clock', () async {
    expect(await lives.spend(), isTrue);

    expect(lives.count, 4);
    expect(lives.untilNext, Economy.lifeRefill);
  });

  test('lives come back one every 20 minutes, even while closed', () async {
    await lives.spend();
    await lives.spend();
    await lives.spend();

    clock.current = clock.current.add(const Duration(minutes: 19));
    expect(lives.count, 2);
    expect(lives.untilNext, const Duration(minutes: 1));

    clock.current = clock.current.add(const Duration(minutes: 22));
    expect(lives.count, 4);
    expect(lives.untilNext, const Duration(minutes: 19));

    final reopened = LivesController(store, clock);
    clock.current = clock.current.add(const Duration(hours: 3));
    expect(reopened.count, Economy.maxLives);
    expect(reopened.untilNext, isNull);
  });

  test('spending keeps the clock of the life already on its way', () async {
    await lives.spend();
    clock.current = clock.current.add(const Duration(minutes: 5));

    await lives.spend();

    expect(lives.count, 3);
    expect(lives.untilNext, const Duration(minutes: 15));
  });

  test('no life can be spent at zero', () async {
    for (var index = 0; index < Economy.maxLives; index++) {
      await lives.spend();
    }

    expect(lives.isEmpty, isTrue);
    expect(await lives.spend(), isFalse);
  });

  test('a clock moved back cannot stretch the wait', () async {
    await lives.spend();
    clock.current = clock.current.subtract(const Duration(days: 2));

    expect(lives.untilNext, Economy.lifeRefill);
    await lives.refresh();

    clock.current = clock.current.add(const Duration(minutes: 5));
    expect(lives.untilNext, const Duration(minutes: 15));

    clock.current = clock.current.add(const Duration(minutes: 15));
    await lives.refresh();
    expect(lives.count, Economy.maxLives);
  });

  test('refreshes that overlap count a returning life once', () async {
    await lives.spend();
    await lives.spend();
    clock.current = clock.current.add(Economy.lifeRefill);

    await Future.wait([lives.refresh(), lives.refresh()]);

    expect(lives.count, Economy.maxLives - 1);
    expect(LivesController(store, clock).count, Economy.maxLives - 1);
  });

  test('a video adds one, coins refill all', () async {
    final coins = CoinWallet(store);
    for (var index = 0; index < 3; index++) {
      await lives.spend();
    }

    await lives.add(1);
    expect(lives.count, 3);

    expect(await lives.refillAll(coins), isFalse);
    await coins.earn(100);
    expect(await lives.refillAll(coins), isTrue);
    expect(lives.isFull, isTrue);
    expect(coins.balance, 200 - Economy.refillLivesPrice);
    expect(await lives.refillAll(coins), isFalse);
  });

  test('refresh saves lives that came back and tells listeners', () async {
    var told = 0;
    lives.addListener(() => told++);
    await lives.spend();
    told = 0;

    clock.current = clock.current.add(Economy.lifeRefill);
    await lives.refresh();

    expect(told, 1);
    expect(LivesController(store, clock).count, Economy.maxLives);
  });
}
