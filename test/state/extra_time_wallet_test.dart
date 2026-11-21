import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/economy.dart';
import 'package:vamoose/state/coin_wallet.dart';
import 'package:vamoose/state/extra_time_wallet.dart';

import '../support/memory_store.dart';

void main() {
  late CoinWallet coins;
  late ExtraTimeWallet wallet;

  setUp(() {
    final store = MemoryStore();
    coins = CoinWallet(store);
    wallet = ExtraTimeWallet(store, coins);
  });

  test('starts with one booster', () {
    expect(wallet.count, Economy.startingExtraTime);
  });

  test('a booster adds a fifth of the clock, 2 to 5 seconds', () {
    Duration extra(int seconds) =>
        Economy.extraTimeFor(Duration(seconds: seconds));

    expect(extra(10), const Duration(seconds: 2));
    expect(extra(15), const Duration(seconds: 3));
    expect(extra(18), const Duration(seconds: 4));
    expect(extra(23), const Duration(seconds: 5));
    expect(extra(38), const Duration(seconds: 5));
    expect(extra(5), const Duration(seconds: 2));
  });

  test('buying one costs coins', () async {
    expect(await wallet.buy(), isTrue);

    expect(wallet.count, Economy.startingExtraTime + 1);
    expect(coins.balance, Economy.startingCoins - Economy.extraTimePrice);
  });

  test('cannot buy without the coins', () async {
    await coins.spend(Economy.startingCoins);

    expect(wallet.canBuy, isFalse);
    expect(await wallet.buy(), isFalse);
    expect(wallet.count, Economy.startingExtraTime);
  });

  test('reset goes back to the starting stock', () async {
    await wallet.spend();
    await wallet.reset();

    expect(wallet.count, Economy.startingExtraTime);
  });
}
