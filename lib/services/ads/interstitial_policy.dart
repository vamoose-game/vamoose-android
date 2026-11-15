import '../../core/clock.dart';
import '../../state/ad_free_controller.dart';

class InterstitialPolicy {
  InterstitialPolicy(this._clock, this._adFree);

  static const int clearsBetweenAds = 3;
  static const int firstEligibleLevel = 10;
  static const Duration minimumGap = Duration(minutes: 2);

  final Clock _clock;
  final AdFreeController _adFree;
  int _clearsSinceAd = 0;
  DateTime? _lastShownAt;

  bool shouldShowAfterClearing(int level) {
    _clearsSinceAd++;
    final now = _clock.now();
    final lastShownAt = _lastShownAt;
    final eligible =
        !_adFree.adsRemoved &&
        level >= firstEligibleLevel &&
        _clearsSinceAd >= clearsBetweenAds &&
        (lastShownAt == null || now.difference(lastShownAt) >= minimumGap);
    if (eligible) {
      _clearsSinceAd = 0;
      _lastShownAt = now;
    }
    return eligible;
  }
}
