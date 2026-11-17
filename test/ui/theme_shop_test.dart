import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/board_theme.dart';
import 'package:vamoose/ui/screens/home_screen.dart';
import 'package:vamoose/ui/screens/settings_screen.dart';
import 'package:vamoose/ui/screens/theme_shop_screen.dart';
import 'package:vamoose/ui/theme/board_colors.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  BoardColors appColors(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Navigator)))
          .extension<BoardColors>()!;

  testWidgets('home opens the theme shop on the theme in use', (tester) async {
    await tester.launch(services, home: const HomeScreen());

    await tester.tapAndWait(find.bySemanticsLabel('Themes'));

    expect(find.byType(ThemeShopScreen), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('Classic is your theme'), findsOneWidget);
    expect(find.text('2,000'), findsOneWidget);
    expect(find.text('3,000'), findsOneWidget);
    await tester.close();
  });

  testWidgets('a theme you cannot afford shows the coins still needed', (
    tester,
  ) async {
    await tester.launch(services, home: const ThemeShopScreen());

    await tester.tapAndWait(find.text('Wood'));

    expect(find.text('1,900 more coins needed'), findsOneWidget);
    expect(services.themes.owns(BoardTheme.wood), isFalse);
    await tester.close();
  });

  testWidgets('buying Night pays for it and puts it on the board', (
    tester,
  ) async {
    await services.coins.earn(3000);
    await tester.launch(services, home: const ThemeShopScreen());

    await tester.tapAndWait(find.text('Night'));
    await tester.tapAndWait(find.text('Buy Night for'));

    expect(services.coins.balance, 100);
    expect(services.themes.active, BoardTheme.night);
    expect(find.text('Night is your theme'), findsOneWidget);
    expect(appColors(tester).name, 'Night');
    await tester.close();
  });

  testWidgets('an owned theme can be put back in use', (tester) async {
    await services.coins.earn(2000);
    await services.themes.buy(BoardTheme.wood);
    await tester.launch(services, home: const ThemeShopScreen());

    expect(find.text('Owned'), findsOneWidget);
    await tester.tapAndWait(find.text('Classic'));
    await tester.tapAndWait(find.text('Use Classic'));

    expect(services.themes.active, BoardTheme.classic);
    expect(find.text('Classic is your theme'), findsOneWidget);
    await tester.close();
  });

  testWidgets('settings shows the theme in use and opens the shop', (
    tester,
  ) async {
    await tester.launch(services, home: const SettingsScreen());

    expect(find.text('LOOK'), findsOneWidget);
    await tester.tapAndWait(find.text('Theme'));

    expect(find.byType(ThemeShopScreen), findsOneWidget);
    await tester.close();
  });
}
