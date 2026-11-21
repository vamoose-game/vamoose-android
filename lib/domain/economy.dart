import 'dart:math';

abstract final class Economy {
  static const int startingCoins = 100;
  static const int clearReward = 10;
  static const int starReward = 5;
  static const int dailyPuzzleReward = 50;
  static const int hintPrice = 50;
  static const List<int> loginRewards = [10, 15, 20, 25, 30, 40, 150];
  static const int freezePrice = 60;
  static const int maxFreezes = 2;
  static const int woodThemePrice = 2000;
  static const int nightThemePrice = 3000;

  /// Lives are shared by the whole game; a failed level costs one.
  static const int maxLives = 5;
  static const Duration lifeRefill = Duration(minutes: 20);
  static const int refillLivesPrice = 120;

  /// The extra-time booster: used before the first move, once per try. It
  /// adds a fifth of the level's clock, 2–5 s, so it rescues a try on a
  /// short clock instead of making the clear a sure thing.
  static const double extraTimeShare = 0.2;
  static const int fewestExtraSeconds = 2;
  static const int mostExtraSeconds = 5;
  static const int extraTimePrice = 30;
  static const int startingExtraTime = 1;

  static Duration extraTimeFor(Duration limit) => Duration(
    seconds: max(
      fewestExtraSeconds,
      min(mostExtraSeconds, (limit.inSeconds * extraTimeShare).round()),
    ),
  );

  static int levelReward({required int bestBefore, required int stars}) =>
      (bestBefore == 0 ? clearReward : 0) +
      starReward * max(0, stars - bestBefore);
}
