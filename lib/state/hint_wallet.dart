import 'stock.dart';

class HintWallet extends Stock {
  HintWallet(super.store) : super(key: 'hints.count', starting: startingHints);

  static const int startingHints = 3;
}
