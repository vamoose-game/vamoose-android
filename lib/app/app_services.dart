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
import '../services/audio_player_music.dart';
import '../services/audio_player_sound_effects.dart';
import '../services/background_music.dart';
import '../services/game_feedback.dart';
import '../services/haptics.dart';
import '../services/link_opener.dart';
import '../services/purchases/play_billing_gateway.dart';
import '../services/purchases/play_purchase_service.dart';
import '../services/purchases/purchase_service.dart';
import '../state/ad_free_controller.dart';
import '../state/coin_wallet.dart';
import '../state/daily_controller.dart';
import '../state/extra_time_wallet.dart';
import '../state/hint_wallet.dart';
import '../state/lives_controller.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';
import '../state/streak_controller.dart';
import '../state/theme_controller.dart';

class AppServices {
  const AppServices({
    required this.levels,
    required this.settings,
    required this.progress,
    required this.hints,
    required this.extraTime,
    required this.lives,
    required this.coins,
    required this.streak,
    required this.daily,
    required this.dailyPuzzle,
    required this.feedback,
    required this.adFree,
    required this.ads,
    required this.purchases,
    required this.interstitials,
    required this.links,
    required this.music,
    required this.themes,
    this.stopwatch = Stopwatch.new,
  });

  final LevelCatalog levels;
  final SettingsController settings;
  final ProgressController progress;
  final HintWallet hints;
  final ExtraTimeWallet extraTime;
  final LivesController lives;
  final CoinWallet coins;
  final StreakController streak;
  final DailyController daily;
  final DailyPuzzle dailyPuzzle;
  final GameFeedback feedback;
  final AdFreeController adFree;
  final AdService ads;
  final PurchaseService purchases;
  final InterstitialPolicy interstitials;
  final LinkOpener links;
  final BackgroundMusic music;
  final ThemeController themes;

  /// Makes the stopwatch behind each level's countdown.
  final Stopwatch Function() stopwatch;

  static Future<AppServices> create() async {
    const clock = SystemClock();
    final store = SharedPreferencesStore(await SharedPreferences.getInstance());
    final levels = await LevelCatalog.load(rootBundle);
    final settings = SettingsController(store);
    final coins = CoinWallet(store);
    final streak = StreakController(store, clock, coins);
    await streak.refresh();
    final adFree = AdFreeController(store);
    final daily = DailyController(store, clock);
    final dailyPuzzle = DailyPuzzle();
    // Times today's puzzle now, behind the splash screen, so the daily
    // screen finds it ready instead of working it out as it builds.
    dailyPuzzle.puzzleFor(daily.today);
    return AppServices(
      levels: levels,
      settings: settings,
      progress: ProgressController(store, levelCount: levels.count),
      hints: HintWallet(store),
      extraTime: ExtraTimeWallet(store, coins),
      lives: LivesController(store, clock),
      coins: coins,
      streak: streak,
      daily: daily,
      dailyPuzzle: dailyPuzzle,
      feedback: GameFeedback(
        sounds: AudioPlayerSoundEffects.create(),
        haptics: const SystemHaptics(),
        settings: settings,
      ),
      adFree: adFree,
      ads: AdMobAdService(AdUnits.fromBuild, adFree),
      purchases: PlayPurchaseService(PlayBillingGateway(), adFree),
      interstitials: InterstitialPolicy(clock, adFree),
      links: const ExternalLinkOpener(),
      music: BackgroundMusic(AudioPlayerMusic(), settings),
      themes: ThemeController(store, coins),
    );
  }
}
