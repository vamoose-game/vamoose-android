import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/board_theme.dart';
import 'package:vamoose/domain/economy.dart';
import 'package:vamoose/ui/screens/home_screen.dart';
import 'package:vamoose/ui/screens/settings_screen.dart';
import 'package:vamoose/ui/screens/store_screen.dart';
import 'package:vamoose/ui/theme/board_colors.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  BoardColors appColors(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Navigator)))
          .extension<BoardColors>()!;

  const themes = StoreScreen(tab: StoreTab.themes);

  group('items', () {
    testWidgets('home opens the store on its items', (tester) async {
      await tester.launch(services, home: const HomeScreen());

      await tester.tapAndWait(find.bySemanticsLabel('Store'));

      expect(find.byType(StoreScreen), findsOneWidget);
      expect(find.text('Full lives'), findsOneWidget);
      expect(find.text('Extra time'), findsOneWidget);
      expect(find.text('Streak freeze'), findsOneWidget);
      await tester.close();
    });

    testWidgets('extra time is bought with coins', (tester) async {
      await tester.launch(services, home: const StoreScreen());

      await tester.tapAndWait(find.text('${Economy.extraTimePrice}'));

      expect(services.extraTime.count, Economy.startingExtraTime + 1);
      expect(
        services.coins.balance,
        Economy.startingCoins - Economy.extraTimePrice,
      );
      expect(find.text('+2–5 s · ×2'), findsOneWidget);
      await tester.close();
    });

    testWidgets('lives refill for coins, or one per video', (tester) async {
      await services.coins.earn(200);
      await services.lives.spend();
      await services.lives.spend();
      await tester.launch(services, home: const StoreScreen());
      expect(find.text('3/5'), findsOneWidget);

      await tester.tapAndWait(find.text('Watch'));
      expect(services.lives.count, 4);

      await tester.tapAndWait(find.text('${Economy.refillLivesPrice}'));
      expect(services.lives.isFull, isTrue);
      expect(services.coins.balance, 300 - Economy.refillLivesPrice);
      expect(find.text('Full'), findsNWidgets(2));
      await tester.close();
    });

    testWidgets('too few coins says so', (tester) async {
      await services.coins.spend(Economy.startingCoins);
      await tester.launch(services, home: const StoreScreen());

      await tester.tapAndWait(find.text('${Economy.freezePrice}'));

      expect(find.text('Not enough coins'), findsOneWidget);
      expect(services.streak.freezes, 0);
      await tester.close();
    });
  });

  group('themes', () {
    testWidgets('show the theme in use first', (tester) async {
      await tester.launch(services, home: themes);

      expect(find.text('In use'), findsOneWidget);
      expect(find.text('Your theme'), findsOneWidget);
      expect(find.text('2,000'), findsOneWidget);
      expect(find.text('3,000'), findsOneWidget);
      await tester.close();
    });

    testWidgets('a theme you cannot afford shows the coins still needed', (
      tester,
    ) async {
      await tester.launch(services, home: themes);

      await tester.tapAndWait(find.text('Wood'));

      expect(find.text('1,900 more coins'), findsOneWidget);
      expect(services.themes.owns(BoardTheme.wood), isFalse);
      await tester.close();
    });

    testWidgets('buying Night pays for it and puts it on the board', (
      tester,
    ) async {
      await services.coins.earn(3000);
      await tester.launch(services, home: themes);

      await tester.tapAndWait(find.text('Night'));
      await tester.tapAndWait(find.text('Buy Night for'));

      expect(services.coins.balance, 100);
      expect(services.themes.active, BoardTheme.night);
      expect(find.text('Your theme'), findsOneWidget);
      expect(appColors(tester).name, 'Night');
      await tester.close();
    });

    testWidgets('an owned theme can be put back in use', (tester) async {
      await services.coins.earn(2000);
      await services.themes.buy(BoardTheme.wood);
      await tester.launch(services, home: themes);

      expect(find.text('Owned'), findsOneWidget);
      await tester.tapAndWait(find.text('Classic'));
      await tester.tapAndWait(find.text('Use Classic'));

      expect(services.themes.active, BoardTheme.classic);
      expect(find.text('Your theme'), findsOneWidget);
      await tester.close();
    });

    testWidgets('settings shows the theme in use and opens the store', (
      tester,
    ) async {
      await tester.launch(services, home: const SettingsScreen());

      expect(find.text('LOOK'), findsOneWidget);
      await tester.tapAndWait(find.text('Theme'));

      expect(find.byType(StoreScreen), findsOneWidget);
      expect(find.text('Your theme'), findsOneWidget);
      await tester.close();
    });
  });
}
