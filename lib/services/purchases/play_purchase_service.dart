import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../state/ad_free_controller.dart';
import 'billing_gateway.dart';
import 'purchase_service.dart';

class PlayPurchaseService implements PurchaseService {
  PlayPurchaseService(this._gateway, this._adFree);

  static const String removeAdsId = 'remove_ads';

  final BillingGateway _gateway;
  final AdFreeController _adFree;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAds;
  Completer<PurchaseOutcome>? _checkout;

  @override
  String? get removeAdsPrice => _removeAds?.price;

  @override
  Future<void> initialize() async {
    _subscription ??= _gateway.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) => _finishCheckout(PurchaseOutcome.failed),
    );
    if (!await _gateway.isAvailable()) {
      return;
    }
    _removeAds = await _gateway.findProduct(removeAdsId);
    await restorePurchases();
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    final product = _removeAds;
    if (_adFree.adsRemoved) {
      return PurchaseOutcome.purchased;
    }
    if (product == null) {
      return PurchaseOutcome.unavailable;
    }
    final checkout = _checkout = Completer<PurchaseOutcome>();
    if (!await _gateway.buyNonConsumable(product)) {
      _finishCheckout(PurchaseOutcome.failed);
    }
    return checkout.future;
  }

  @override
  Future<bool> restorePurchases() async {
    for (final purchase in (await _gateway.pastPurchases()).where(
      _isRemoveAds,
    )) {
      await _settle(purchase);
    }
    return _adFree.adsRemoved;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases.where(_isRemoveAds)) {
      await _settle(purchase);
      _finishCheckout(_outcomeOf(purchase.status));
    }
  }

  Future<void> _settle(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await _adFree.grant();
    }
    if (purchase.pendingCompletePurchase) {
      await _gateway.completePurchase(purchase);
    }
  }

  PurchaseOutcome _outcomeOf(PurchaseStatus status) => switch (status) {
    PurchaseStatus.purchased ||
    PurchaseStatus.restored => PurchaseOutcome.purchased,
    PurchaseStatus.pending => PurchaseOutcome.pending,
    PurchaseStatus.canceled => PurchaseOutcome.canceled,
    PurchaseStatus.error => PurchaseOutcome.failed,
  };

  bool _isRemoveAds(PurchaseDetails purchase) =>
      purchase.productID == removeAdsId;

  void _finishCheckout(PurchaseOutcome outcome) {
    final checkout = _checkout;
    if (checkout != null && !checkout.isCompleted) {
      checkout.complete(outcome);
    }
    _checkout = null;
  }
}
