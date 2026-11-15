import 'package:flutter/widgets.dart';

enum RewardOutcome { earned, skipped, unavailable }

abstract interface class AdService {
  bool get isReady;

  Future<void> initialize();

  Widget banner();

  Future<RewardOutcome> showRewarded();

  Future<void> showInterstitial();

  Future<void> showPrivacyOptions();
}
