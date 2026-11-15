import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'billing_gateway.dart';

class PlayBillingGateway implements BillingGateway {
  PlayBillingGateway() : _store = InAppPurchase.instance;

  final InAppPurchase _store;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<ProductDetails?> findProduct(String id) async {
    final response = await _store.queryProductDetails({id});
    return response.productDetails
        .where((product) => product.id == id)
        .firstOrNull;
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails product) => _store
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);

  @override
  Future<List<PurchaseDetails>> pastPurchases() async {
    final response = await _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    return response.error == null ? response.pastPurchases : const [];
  }
}
