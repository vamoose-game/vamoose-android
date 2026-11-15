abstract interface class AdService {
  bool get showsBanners;

  bool get offersRewardedAds;

  Future<bool> showRewarded();

  Future<void> showInterstitial();

  Future<void> showPrivacyOptions();
}

class PlaceholderAdService implements AdService {
  const PlaceholderAdService();

  @override
  bool get showsBanners => true;

  @override
  bool get offersRewardedAds => true;

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<void> showPrivacyOptions() async {}
}
