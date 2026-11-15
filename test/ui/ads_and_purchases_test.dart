import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/services/ads/ad_service.dart';
import 'package:vamoose/services/purchases/purchase_service.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/level_result.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/level_complete_screen.dart';
import 'package:vamoose/ui/screens/levels_screen.dart';
import 'package:vamoose/ui/screens/settings_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

final Finder banner = find.byKey(const ValueKey('ad-banner'));
const String watchAd = 'Watch a short ad for +1 hint';

LevelCompleteScreen completed(int level) => LevelCompleteScreen(
  result: LevelResult(
    mode: CampaignMode(level),
    blocks: 10,
    bumps: 0,
    time: const Duration(seconds: 40),
    stars: 3,
  ),
);

void main() {
  late AppServices services;
  late FakeAdService ads;
  late FakePurchaseService purchases;

  setUp(() {
    ads = FakeAdService();
    services = buildTestServices(ads: ads);
    purchases = services.purchases as FakePurchaseService;
  });

  group('banners', () {
    testWidgets('game shows a banner until ads are removed', (tester) async {
      await tester.launch(
        services,
        home: const GameScreen(mode: CampaignMode(1)),
      );
      expect(banner, findsOneWidget);

      await services.adFree.grant();
      await tester.wait(frame);

      expect(banner, findsNothing);
      await tester.close();
    });

    testWidgets('levels shows no banner before consent allows ads', (
      tester,
    ) async {
      ads.isReady = false;
      await tester.launch(services, home: const LevelsScreen());

      expect(banner, findsNothing);
      await tester.close();
    });
  });

  group('rewarded video on board clear', () {
    testWidgets('a watched video adds a hint', (tester) async {
      await tester.launch(services, home: completed(5));

      await tester.tapAndWait(find.text(watchAd));

      expect(services.hints.count, 4);
      expect(find.text('+1 hint added'), findsOneWidget);
      await tester.close();
    });

    testWidgets('a skipped video adds nothing', (tester) async {
      ads.nextReward = RewardOutcome.skipped;
      await tester.launch(services, home: completed(5));

      await tester.tapAndWait(find.text(watchAd));

      expect(services.hints.count, 3);
      expect(find.byType(SnackBar), findsNothing);
      await tester.close();
    });

    testWidgets('no video says so', (tester) async {
      ads.nextReward = RewardOutcome.unavailable;
      await tester.launch(services, home: completed(5));

      await tester.tapAndWait(find.text(watchAd));

      expect(services.hints.count, 3);
      expect(find.text('No video right now. Try again soon.'), findsOneWidget);
      await tester.close();
    });

    testWidgets('is hidden until ads are ready', (tester) async {
      ads.isReady = false;
      await tester.launch(services, home: completed(5));

      expect(find.text(watchAd), findsNothing);
      await tester.close();
    });
  });

  group('rewarded video when out of hints', () {
    setUp(() async {
      for (var index = 0; index < 3; index++) {
        await services.hints.spend();
      }
    });

    testWidgets('a watched video shows a hint right away', (tester) async {
      await tester.launch(
        services,
        home: const GameScreen(mode: CampaignMode(5)),
      );

      await tester.tapAndWait(find.text('Hint'));
      await tester.tapAndWait(find.text('Watch video · +1 hint'));

      expect(find.text('Out of hints'), findsNothing);
      expect(services.hints.count, 0);
      await tester.close();
    });

    testWidgets('no video keeps the sheet open and explains', (tester) async {
      ads.nextReward = RewardOutcome.unavailable;
      await tester.launch(
        services,
        home: const GameScreen(mode: CampaignMode(5)),
      );

      await tester.tapAndWait(find.text('Hint'));
      await tester.tapAndWait(find.text('Watch video · +1 hint'));

      expect(find.text('Out of hints'), findsOneWidget);
      expect(find.text('No video right now. Try again soon.'), findsOneWidget);
      await tester.close();
    });
  });

  group('interstitial after Next level', () {
    testWidgets('shows on the third clear from level 10', (tester) async {
      services.interstitials
        ..shouldShowAfterClearing(10)
        ..shouldShowAfterClearing(11);
      await tester.launch(services, home: completed(12));

      await tester.tapAndWait(find.text('Next level'));

      expect(ads.interstitialsShown, 1);
      expect(find.text('Level 13'), findsOneWidget);
      await tester.close();
    });

    testWidgets('never shows early in the game', (tester) async {
      await tester.launch(services, home: completed(3));

      await tester.tapAndWait(find.text('Next level'));

      expect(ads.interstitialsShown, 0);
      await tester.close();
    });
  });

  group('settings', () {
    testWidgets('shows the Play price and removes ads after buying', (
      tester,
    ) async {
      await tester.launch(services, home: const SettingsScreen());
      expect(find.text(r'$2.99'), findsOneWidget);

      await tester.tapAndWait(find.text('Remove ads'));

      expect(services.adFree.adsRemoved, isTrue);
      expect(find.text('Ads removed'), findsOneWidget);
      expect(find.text('Ads removed. Thank you!'), findsOneWidget);
      await tester.close();
    });

    testWidgets('a canceled purchase changes nothing', (tester) async {
      purchases.nextOutcome = PurchaseOutcome.canceled;
      await tester.launch(services, home: const SettingsScreen());

      await tester.tapAndWait(find.text('Remove ads'));

      expect(services.adFree.adsRemoved, isFalse);
      expect(find.byType(SnackBar), findsNothing);
      await tester.close();
    });

    testWidgets('restore reports when nothing was bought', (tester) async {
      await tester.launch(services, home: const SettingsScreen());

      await tester.tapAndWait(find.text('Restore purchase'));

      expect(find.text('No purchase to restore.'), findsOneWidget);
      await tester.close();
    });

    testWidgets('restore brings back Remove ads', (tester) async {
      purchases.ownsRemoveAds = true;
      await tester.launch(services, home: const SettingsScreen());

      await tester.tapAndWait(find.text('Restore purchase'));

      expect(services.adFree.adsRemoved, isTrue);
      expect(find.text('Purchase restored. Ads removed.'), findsOneWidget);
      await tester.close();
    });

    testWidgets('ad privacy choices opens the consent form', (tester) async {
      await tester.launch(services, home: const SettingsScreen());

      await tester.tapAndWait(find.text('Ad privacy choices'));

      expect(ads.privacyOptionsShown, 1);
      await tester.close();
    });
  });
}
