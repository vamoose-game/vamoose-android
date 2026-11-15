abstract interface class PurchaseService {
  String get removeAdsPrice;

  Future<bool> buyRemoveAds();

  Future<bool> restorePurchases();
}

class PlaceholderPurchaseService implements PurchaseService {
  const PlaceholderPurchaseService();

  @override
  String get removeAdsPrice => '[YOUR PRICE]';

  @override
  Future<bool> buyRemoveAds() async => false;

  @override
  Future<bool> restorePurchases() async => false;
}
