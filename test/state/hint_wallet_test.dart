import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/hint_wallet.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late FixedClock clock;
  late HintWallet wallet;

  setUp(() {
    store = MemoryStore();
    clock = FixedClock(DateTime(2026, 11, 15, 9));
    wallet = HintWallet(store, clock);
  });

  test('starts with three hints', () {
    expect(wallet.count, 3);
  });

  test('spending takes one hint', () async {
    expect(await wallet.spend(), isTrue);
    expect(wallet.count, 2);
  });

  test('cannot spend with no hints left', () async {
    for (var index = 0; index < 3; index++) {
      await wallet.spend();
    }

    expect(await wallet.spend(), isFalse);
    expect(wallet.count, 0);
  });

  test('adding hints raises the count', () async {
    await wallet.add(2);

    expect(wallet.count, 5);
  });

  test('first launch gives no extra daily hint', () async {
    expect(await wallet.claimDailyHint(), isFalse);
    expect(wallet.count, 3);
  });

  test('gives one free hint on each new day', () async {
    await wallet.claimDailyHint();

    clock.current = DateTime(2026, 11, 15, 23);
    expect(await wallet.claimDailyHint(), isFalse);

    clock.current = DateTime(2026, 11, 16, 7);
    expect(await wallet.claimDailyHint(), isTrue);
    expect(wallet.count, 4);
  });
}
