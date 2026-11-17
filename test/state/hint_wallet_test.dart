import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/hint_wallet.dart';

import '../support/memory_store.dart';

void main() {
  late HintWallet wallet;

  setUp(() => wallet = HintWallet(MemoryStore()));

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
}
