import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';
import '../domain/board_theme.dart';
import 'coin_wallet.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._store, this._coins);

  static const String _ownedKey = 'themes.owned';
  static const String _activeKey = 'themes.active';

  final KeyValueStore _store;
  final CoinWallet _coins;

  BoardTheme get active {
    final stored = BoardTheme.values.asNameMap()[_store.readString(_activeKey)];
    return stored != null && owns(stored) ? stored : BoardTheme.classic;
  }

  bool owns(BoardTheme theme) =>
      theme.price == 0 ||
      (_store.readStringList(_ownedKey) ?? const []).contains(theme.name);

  bool canBuy(BoardTheme theme) =>
      !owns(theme) && _coins.canAfford(theme.price);

  Future<bool> buy(BoardTheme theme) async {
    if (owns(theme) || !await _coins.spend(theme.price)) {
      return false;
    }
    await _store.writeStringList(_ownedKey, [
      ...?_store.readStringList(_ownedKey),
      theme.name,
    ]);
    await use(theme);
    return true;
  }

  Future<void> use(BoardTheme theme) async {
    if (!owns(theme)) {
      return;
    }
    await _store.writeString(_activeKey, theme.name);
    notifyListeners();
  }

  Future<void> reset() async {
    await _store.remove(_ownedKey);
    await _store.remove(_activeKey);
    notifyListeners();
  }
}
