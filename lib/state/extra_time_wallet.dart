import '../domain/economy.dart';
import 'coin_wallet.dart';
import 'stock.dart';

/// Extra-time boosters: each adds [Economy.extraTimeFor] the level's clock
/// before its first move.
class ExtraTimeWallet extends Stock {
  ExtraTimeWallet(super.store, this._coins)
    : super(key: 'boosters.extraTime', starting: Economy.startingExtraTime);

  final CoinWallet _coins;

  bool get canBuy => _coins.canAfford(Economy.extraTimePrice);

  Future<bool> buy() async {
    if (!await _coins.spend(Economy.extraTimePrice)) {
      return false;
    }
    await add(1);
    return true;
  }
}
