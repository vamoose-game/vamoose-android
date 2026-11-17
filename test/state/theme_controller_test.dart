import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board_theme.dart';
import 'package:vamoose/state/coin_wallet.dart';
import 'package:vamoose/state/theme_controller.dart';

import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late CoinWallet coins;
  late ThemeController themes;

  setUp(() {
    store = MemoryStore();
    coins = CoinWallet(store);
    themes = ThemeController(store, coins);
  });

  test('starts on Classic, the only theme owned', () {
    expect(themes.active, BoardTheme.classic);
    expect(themes.owns(BoardTheme.classic), isTrue);
    expect(themes.owns(BoardTheme.wood), isFalse);
    expect(themes.owns(BoardTheme.night), isFalse);
  });

  test('Wood costs 2,000 and Night 3,000', () {
    expect(BoardTheme.classic.price, 0);
    expect(BoardTheme.wood.price, 2000);
    expect(BoardTheme.night.price, 3000);
  });

  test('cannot buy a theme without enough coins', () async {
    expect(themes.canBuy(BoardTheme.wood), isFalse);
    expect(await themes.buy(BoardTheme.wood), isFalse);

    expect(themes.owns(BoardTheme.wood), isFalse);
    expect(coins.balance, 100);
  });

  test('buying pays the price and puts the theme in use', () async {
    await coins.earn(2000);

    expect(themes.canBuy(BoardTheme.wood), isTrue);
    expect(await themes.buy(BoardTheme.wood), isTrue);

    expect(themes.owns(BoardTheme.wood), isTrue);
    expect(themes.active, BoardTheme.wood);
    expect(coins.balance, 100);
    expect(await themes.buy(BoardTheme.wood), isFalse);
    expect(coins.balance, 100);
  });

  test('only owned themes can be used', () async {
    await themes.use(BoardTheme.night);
    expect(themes.active, BoardTheme.classic);

    await coins.earn(3000);
    await themes.buy(BoardTheme.night);
    await themes.use(BoardTheme.classic);
    expect(themes.active, BoardTheme.classic);

    await themes.use(BoardTheme.night);
    expect(themes.active, BoardTheme.night);
  });

  test('remembers owned and active themes', () async {
    await coins.earn(3000);
    await themes.buy(BoardTheme.night);

    final reopened = ThemeController(store, CoinWallet(store));

    expect(reopened.owns(BoardTheme.night), isTrue);
    expect(reopened.active, BoardTheme.night);
  });

  test('reset goes back to Classic only', () async {
    await coins.earn(2000);
    await themes.buy(BoardTheme.wood);

    await themes.reset();

    expect(themes.active, BoardTheme.classic);
    expect(themes.owns(BoardTheme.wood), isFalse);
  });
}
