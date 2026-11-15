import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../data/level_catalog.dart';
import '../data/shared_preferences_store.dart';
import '../domain/daily_puzzle.dart';
import '../services/ads/ad_service.dart';
import '../services/ads/ad_units.dart';
import '../services/ads/admob_ad_service.dart';
import '../services/ads/interstitial_policy.dart';
import '../services/audio_player_sound_effects.dart';
import '../services/game_feedback.dart';
import '../services/haptics.dart';
import '../services/purchases/play_billing_gateway.dart';
import '../services/purchases/play_purchase_service.dart';
import '../services/purchases/purchase_service.dart';
import '../state/ad_free_controller.dart';
import '../state/daily_controller.dart';
import '../state/hint_wallet.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';

class AppServices {
  const AppServices({
    required this.levels,
    required this.settings,
    required this.progress,
    required this.hints,
    required this.daily,
    required this.dailyPuzzle,
    required this.feedback,
    required this.adFree,
    required this.ads,
    required this.purchases,
    required this.interstitials,
  });

  final LevelCatalog levels;
  final SettingsController settings;
  final ProgressController progress;
  final HintWallet hints;
  final DailyController daily;
  final DailyPuzzle dailyPuzzle;
  final GameFeedback feedback;
  final AdFreeController adFree;
  final AdService ads;
  final PurchaseService purchases;
  final InterstitialPolicy interstitials;

  static Future<AppServices> create() async {
    const clock = SystemClock();
    final store = SharedPreferencesStore(await SharedPreferences.getInstance());
    final levels = await LevelCatalog.load(rootBundle);
    final settings = SettingsController(store);
    final hints = HintWallet(store, clock);
    await hints.claimDailyHint();
    final adFree = AdFreeController(store);
    return AppServices(
      levels: levels,
      settings: settings,
      progress: ProgressController(store, levelCount: levels.count),
      hints: hints,
      daily: DailyController(store, clock),
      dailyPuzzle: const DailyPuzzle(),
      feedback: GameFeedback(
        sounds: await AudioPlayerSoundEffects.create(),
        haptics: const SystemHaptics(),
        settings: settings,
      ),
      adFree: adFree,
      ads: AdMobAdService(AdUnits.fromBuild, adFree),
      purchases: PlayPurchaseService(PlayBillingGateway(), adFree),
      interstitials: InterstitialPolicy(clock),
    );
  }
}
