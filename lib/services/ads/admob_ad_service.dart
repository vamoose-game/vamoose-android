import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../state/ad_free_controller.dart';
import 'ad_service.dart';
import 'ad_units.dart';
import 'admob_banner.dart';

class AdMobAdService implements AdService {
  AdMobAdService(this._units, this._adFree);

  final AdUnits _units;
  final AdFreeController _adFree;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (_ready) {
      return;
    }
    await _gatherConsent();
    if (!await ConsentInformation.instance.canRequestAds()) {
      return;
    }
    await MobileAds.instance.initialize();
    _ready = true;
    _loadRewarded();
    _loadInterstitial();
  }

  @override
  Widget banner() => AdMobBanner(unitId: _units.banner);

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (_adFree.adsRemoved) {
      return;
    }
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    void close(InterstitialAd ad) {
      unawaited(ad.dispose());
      closed.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: close,
      onAdFailedToShowFullScreenContent: (ad, _) => close(ad),
    );
    await ad.show();
    return closed.future;
  }

  @override
  Future<RewardOutcome> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return RewardOutcome.unavailable;
    }
    _rewarded = null;
    var earned = false;
    final closed = Completer<RewardOutcome>();
    void close(RewardedAd ad) {
      unawaited(ad.dispose());
      closed.complete(earned ? RewardOutcome.earned : RewardOutcome.skipped);
      _loadRewarded();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: close,
      onAdFailedToShowFullScreenContent: (ad, _) => close(ad),
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return closed.future;
  }

  @override
  Future<void> showPrivacyOptions() {
    final dismissed = Completer<void>();
    unawaited(ConsentForm.showPrivacyOptionsForm((_) => dismissed.complete()));
    return dismissed.future;
  }

  Future<void> _gatherConsent() {
    final gathered = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => unawaited(
        ConsentForm.loadAndShowConsentFormIfRequired(
          (_) => gathered.complete(),
        ),
      ),
      (_) => gathered.complete(),
    );
    return gathered.future;
  }

  void _loadInterstitial() {
    if (!_ready || _adFree.adsRemoved) {
      return;
    }
    unawaited(
      InterstitialAd.load(
        adUnitId: _units.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitial = ad,
          onAdFailedToLoad: (_) => _interstitial = null,
        ),
      ),
    );
  }

  void _loadRewarded() {
    if (!_ready) {
      return;
    }
    unawaited(
      RewardedAd.load(
        adUnitId: _units.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => _rewarded = ad,
          onAdFailedToLoad: (_) => _rewarded = null,
        ),
      ),
    );
  }
}
