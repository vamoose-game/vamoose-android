import 'package:in_app_purchase/in_app_purchase.dart';

abstract interface class BillingGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetails?> findProduct(String id);

  Future<bool> buyNonConsumable(ProductDetails product);

  Future<void> completePurchase(PurchaseDetails purchase);

  Future<List<PurchaseDetails>> pastPurchases();
}
