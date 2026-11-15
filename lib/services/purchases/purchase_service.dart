enum PurchaseOutcome { purchased, pending, canceled, failed, unavailable }

abstract interface class PurchaseService {
  String? get removeAdsPrice;

  Future<void> initialize();

  Future<PurchaseOutcome> buyRemoveAds();

  Future<bool> restorePurchases();
}
