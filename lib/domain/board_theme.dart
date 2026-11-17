import 'economy.dart';

enum BoardTheme {
  classic(0),
  wood(Economy.woodThemePrice),
  night(Economy.nightThemePrice);

  const BoardTheme(this.price);

  final int price;
}
