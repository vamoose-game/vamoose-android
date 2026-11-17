import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/coin_wallet.dart';

import '../support/memory_store.dart';

void main() {
  late CoinWallet wallet;

  setUp(() => wallet = CoinWallet(MemoryStore()));

  test('starts with 100 coins', () {
    expect(wallet.balance, 100);
  });

  test('earns and spends', () async {
    await wallet.earn(25);
    expect(await wallet.spend(50), isTrue);
    expect(wallet.balance, 75);
  });

  test('refuses to spend more than it holds', () async {
    expect(await wallet.spend(101), isFalse);
    expect(wallet.balance, 100);
  });

  test('remembers doubled rewards', () async {
    await wallet.markDoubled('level.5');

    expect(wallet.hasDoubled('level.5'), isTrue);
    expect(wallet.hasDoubled('level.6'), isFalse);
  });

  test('reset goes back to the start', () async {
    await wallet.earn(500);
    await wallet.markDoubled('level.5');

    await wallet.reset();

    expect(wallet.balance, 100);
    expect(wallet.hasDoubled('level.5'), isFalse);
  });
}
