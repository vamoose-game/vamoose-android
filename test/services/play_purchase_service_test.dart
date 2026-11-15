import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vamoose/services/purchases/play_purchase_service.dart';
import 'package:vamoose/services/purchases/purchase_service.dart';
import 'package:vamoose/state/ad_free_controller.dart';

import '../support/fake_billing_gateway.dart';
import '../support/memory_store.dart';

void main() {
  late FakeBillingGateway gateway;
  late AdFreeController adFree;
  late PlayPurchaseService purchases;

  setUp(() {
    gateway = FakeBillingGateway();
    adFree = AdFreeController(MemoryStore());
    purchases = PlayPurchaseService(gateway, adFree);
  });

  Future<PurchaseOutcome> buyAndAnswer(PurchaseStatus status) async {
    final outcome = purchases.buyRemoveAds();
    await pumpEventQueue();
    gateway.updates.add([
      purchaseOf(PlayPurchaseService.removeAdsId, status, acknowledged: false),
    ]);
    return outcome;
  }

  test('loads the Play price on start', () async {
    await purchases.initialize();

    expect(purchases.removeAdsPrice, r'$2.99');
  });

  test('restores an owned purchase on start and acknowledges it', () async {
    gateway.owned = [
      purchaseOf(
        PlayPurchaseService.removeAdsId,
        PurchaseStatus.purchased,
        acknowledged: false,
      ),
    ];

    await purchases.initialize();

    expect(adFree.adsRemoved, isTrue);
    expect(gateway.completed, hasLength(1));
  });

  test('a completed purchase removes ads', () async {
    await purchases.initialize();

    final outcome = await buyAndAnswer(PurchaseStatus.purchased);

    expect(outcome, PurchaseOutcome.purchased);
    expect(adFree.adsRemoved, isTrue);
    expect(gateway.completed, hasLength(1));
  });

  test('a canceled purchase keeps ads', () async {
    await purchases.initialize();

    final outcome = await buyAndAnswer(PurchaseStatus.canceled);

    expect(outcome, PurchaseOutcome.canceled);
    expect(adFree.adsRemoved, isFalse);
  });

  test('a store error reports a failure', () async {
    await purchases.initialize();

    expect(await buyAndAnswer(PurchaseStatus.error), PurchaseOutcome.failed);
    expect(adFree.adsRemoved, isFalse);
  });

  test('a pending payment removes ads once it clears', () async {
    await purchases.initialize();

    expect(await buyAndAnswer(PurchaseStatus.pending), PurchaseOutcome.pending);
    expect(adFree.adsRemoved, isFalse);

    gateway.updates.add([
      purchaseOf(PlayPurchaseService.removeAdsId, PurchaseStatus.purchased),
    ]);
    await pumpEventQueue();

    expect(adFree.adsRemoved, isTrue);
  });

  test('checkout that does not open reports a failure', () async {
    gateway.launchesCheckout = false;
    await purchases.initialize();

    expect(await purchases.buyRemoveAds(), PurchaseOutcome.failed);
  });

  test('no store means the purchase is unavailable', () async {
    gateway.available = false;
    await purchases.initialize();

    expect(purchases.removeAdsPrice, isNull);
    expect(await purchases.buyRemoveAds(), PurchaseOutcome.unavailable);
    expect(gateway.checkouts, 0);
  });

  test('buying again after removing ads opens no checkout', () async {
    await adFree.grant();
    await purchases.initialize();

    expect(await purchases.buyRemoveAds(), PurchaseOutcome.purchased);
    expect(gateway.checkouts, 0);
  });

  test('restore finds nothing when nothing was bought', () async {
    await purchases.initialize();

    expect(await purchases.restorePurchases(), isFalse);
  });

  test('restore brings back a past purchase', () async {
    await purchases.initialize();
    gateway.owned = [
      purchaseOf(PlayPurchaseService.removeAdsId, PurchaseStatus.purchased),
    ];

    expect(await purchases.restorePurchases(), isTrue);
    expect(adFree.adsRemoved, isTrue);
    expect(gateway.completed, isEmpty);
  });

  test('other products are ignored', () async {
    await purchases.initialize();
    gateway.updates.add([
      purchaseOf('coins', PurchaseStatus.purchased, acknowledged: false),
    ]);
    await pumpEventQueue();

    expect(adFree.adsRemoved, isFalse);
    expect(gateway.completed, isEmpty);
  });
}
