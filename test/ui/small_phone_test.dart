import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/app/vamoose_app.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/level_result.dart';
import 'package:vamoose/ui/screens/daily_screen.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/home_screen.dart';
import 'package:vamoose/ui/screens/how_to_play_screen.dart';
import 'package:vamoose/ui/screens/level_complete_screen.dart';
import 'package:vamoose/ui/screens/levels_screen.dart';
import 'package:vamoose/ui/screens/store_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

/// Every screen fits a 360×640 phone, at the normal text size and at the
/// largest one the app allows, without overflowing.
void main() {
  for (final textScale in [1.0, VamooseApp.maxTextScale]) {
    group('360×640 at text ×$textScale', () {
      late AppServices services;

      setUp(() => services = buildTestServices());

      Future<void> open(WidgetTester tester, Widget home) async {
        await tester.launch(services, home: home);
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(VamooseApp(services: services, home: home));
        await tester.wait(const Duration(milliseconds: 1500));
      }

      testWidgets('game with extra time and a crowded board', (tester) async {
        await services.extraTime.add(8);
        await open(tester, const GameScreen(mode: CampaignMode(301)));

        expect(tester.takeException(), isNull);
        await tester.close();
      });

      testWidgets('home with a large balance', (tester) async {
        await services.coins.earn(12000);
        await open(tester, const HomeScreen());

        expect(tester.takeException(), isNull);
        await tester.close();
      });

      testWidgets('store items and themes', (tester) async {
        await services.lives.spend();
        await open(tester, const StoreScreen());
        await tester.tapAndWait(find.text('Themes'));

        expect(tester.takeException(), isNull);
        await tester.close();
      });

      testWidgets('fail sheet with no lives left', (tester) async {
        for (var life = 0; life < 4; life++) {
          await services.lives.spend();
        }
        await open(tester, const GameScreen(mode: CampaignMode(1)));
        await tester.wait(const Duration(seconds: 12));

        expect(find.text('+1 life'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.close();
      });

      testWidgets('out of lives card', (tester) async {
        for (var life = 0; life < 5; life++) {
          await services.lives.spend();
        }
        await open(tester, const HomeScreen());
        await tester.tapAndWait(find.text('Play'));

        expect(find.text('Out of lives'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.close();
      });

      testWidgets('results, levels, daily and how to play', (tester) async {
        for (final home in const [
          LevelCompleteScreen(
            result: LevelResult(
              mode: CampaignMode(301),
              bumps: 1,
              stars: 2,
              coins: 20,
              time: Duration(seconds: 33),
            ),
          ),
          LevelsScreen(),
          DailyScreen(),
          HowToPlayScreen(),
        ]) {
          await open(tester, home);
          expect(tester.takeException(), isNull, reason: '${home.runtimeType}');
          await tester.close();
        }
      });

      testWidgets('turning intro and pause', (tester) async {
        await open(tester, const GameScreen(mode: CampaignMode(21)));
        expect(find.text('Turning blocks'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tapAndWait(
          find.text('Got it'),
          const Duration(seconds: 1),
        );
        await tester.tapAndWait(find.byIcon(Icons.pause_rounded));
        expect(find.text('Paused'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.close();
      });
    });
  }
}
