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

  static int levelReward({required int bestBefore, required int stars}) =>
      (bestBefore == 0 ? clearReward : 0) +
      starReward * max(0, stars - bestBefore);
}
