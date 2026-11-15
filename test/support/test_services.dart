import 'dart:io';

import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/data/level_catalog.dart';
import 'package:vamoose/domain/daily_puzzle.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:flutter/widgets.dart';
import 'package:vamoose/services/ads/ad_service.dart';
import 'package:vamoose/services/ads/interstitial_policy.dart';
import 'package:vamoose/services/game_feedback.dart';
import 'package:vamoose/services/haptics.dart';
import 'package:vamoose/services/purchases/purchase_service.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/state/ad_free_controller.dart';
import 'package:vamoose/state/daily_controller.dart';
import 'package:vamoose/state/hint_wallet.dart';
import 'package:vamoose/state/progress_controller.dart';
import 'package:vamoose/state/settings_controller.dart';

import 'fixed_clock.dart';
import 'memory_store.dart';

class RecordingSounds implements SoundEffects {
  final List<Sound> played = [];

  @override
  void play(Sound sound) => played.add(sound);
}

class SilentHaptics implements Haptics {
  @override
  void light() {}

  @override
  void medium() {}

  @override
  void heavy() {}
}

class FakeAdService implements AdService {
  @override
  bool isReady = true;

  RewardOutcome nextReward = RewardOutcome.earned;
  int interstitialsShown = 0;
  int privacyOptionsShown = 0;

  @override
  Future<void> initialize() async {}

  @override
  Widget banner() => const SizedBox(key: ValueKey('ad-banner'), height: 50);

  @override
  Future<RewardOutcome> showRewarded() async => nextReward;

  @override
  Future<void> showInterstitial() async => interstitialsShown++;

  @override
  Future<void> showPrivacyOptions() async => privacyOptionsShown++;
}

class FakePurchaseService implements PurchaseService {
  FakePurchaseService(this.adFree);

  final AdFreeController adFree;
  PurchaseOutcome nextOutcome = PurchaseOutcome.purchased;
  bool ownsRemoveAds = false;

  @override
  String? removeAdsPrice = '\$2.99';

  @override
  Future<void> initialize() async {}

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    if (nextOutcome == PurchaseOutcome.purchased) {
      await adFree.grant();
    }
    return nextOutcome;
  }

  @override
  Future<bool> restorePurchases() async {
    if (ownsRemoveAds) {
      await adFree.grant();
    }
    return adFree.adsRemoved;
  }
}

LevelCatalog loadLevelCatalog() => LevelCatalog(
  LevelCodec.decode(File(LevelCatalog.assetPath).readAsStringSync()),
);

AppServices buildTestServices({
  MemoryStore? store,
  FixedClock? clock,
  RecordingSounds? sounds,
  AdService? ads,
}) {
  final memory = store ?? MemoryStore();
  final time = clock ?? FixedClock(DateTime(2026, 11, 15, 17, 47, 20));
  final levels = loadLevelCatalog();
  final settings = SettingsController(memory);
  final adFree = AdFreeController(memory);
  return AppServices(
    levels: levels,
    settings: settings,
    progress: ProgressController(memory, levelCount: levels.count),
    hints: HintWallet(memory, time),
    daily: DailyController(memory, time),
    dailyPuzzle: const DailyPuzzle(),
    feedback: GameFeedback(
      sounds: sounds ?? RecordingSounds(),
      haptics: SilentHaptics(),
      settings: settings,
    ),
    adFree: adFree,
    ads: ads ?? FakeAdService(),
    purchases: FakePurchaseService(adFree),
    interstitials: InterstitialPolicy(time, adFree),
  );
}
