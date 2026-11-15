import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vamoose/services/purchases/billing_gateway.dart';

PurchaseDetails purchaseOf(
  String productId,
  PurchaseStatus status, {
  bool acknowledged = true,
}) => PurchaseDetails(
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server',
    source: 'google_play',
  ),
  transactionDate: '0',
  status: status,
)..pendingCompletePurchase = !acknowledged;

class FakeBillingGateway implements BillingGateway {
  final StreamController<List<PurchaseDetails>> updates =
      StreamController.broadcast();
  final List<PurchaseDetails> completed = [];
  bool available = true;
  bool launchesCheckout = true;
  List<PurchaseDetails> owned = [];
  int checkouts = 0;
  ProductDetails? product = ProductDetails(
    id: 'remove_ads',
    title: 'Remove ads',
    description: 'No banners or interstitials',
    price: r'$2.99',
    rawPrice: 2.99,
    currencyCode: 'USD',
  );

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetails?> findProduct(String id) async =>
      product?.id == id ? product : null;

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    checkouts++;
    return launchesCheckout;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase);

  @override
  Future<List<PurchaseDetails>> pastPurchases() async => owned;
}
