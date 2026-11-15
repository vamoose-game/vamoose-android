import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/ad_free_controller.dart';

import '../support/memory_store.dart';

void main() {
  test('shows ads until Remove ads is bought', () {
    expect(AdFreeController(MemoryStore()).adsRemoved, isFalse);
  });

  test('granting persists and notifies once', () async {
    final store = MemoryStore();
    final adFree = AdFreeController(store);
    var notified = 0;
    adFree.addListener(() => notified++);

    await adFree.grant();
    await adFree.grant();

    expect(AdFreeController(store).adsRemoved, isTrue);
    expect(notified, 1);
  });
}
