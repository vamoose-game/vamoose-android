import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/ui/screens/daily_screen.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/home_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  testWidgets('collect pays today and waits for tomorrow', (tester) async {
    await tester.launch(services, home: const DailyScreen());

    expect(find.text('Daily streak'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    await tester.tapAndWait(find.text('Collect'));

    expect(services.coins.balance, 110);
    expect(services.streak.count, 1);
    expect(find.text('See you tomorrow'), findsOneWidget);
    expect(find.text('Collect'), findsNothing);
    await tester.close();
  });

  testWidgets('a streak freeze can be bought until both slots are full', (
    tester,
  ) async {
    await services.coins.earn(100);
    await tester.launch(services, home: const DailyScreen());

    for (var bought = 0; bought < 2; bought++) {
      await tester.tapAndWait(find.text('60'));
    }

    expect(services.streak.freezes, 2);
    expect(services.coins.balance, 80);
    expect(find.text('Full'), findsOneWidget);
    await tester.close();
  });

  testWidgets("today's puzzle opens the daily game", (tester) async {
    await tester.launch(services, home: const DailyScreen());

    await tester.tapAndWait(find.text("Today's puzzle"));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Daily puzzle'), findsOneWidget);
    await tester.close();
  });

  testWidgets('home shows the coins waiting today', (tester) async {
    await tester.launch(services, home: const HomeScreen());

    expect(find.text('Daily streak'), findsOneWidget);
    expect(find.text('+10 waiting'), findsOneWidget);
    await tester.close();
  });
}
