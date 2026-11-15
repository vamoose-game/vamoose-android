class AdUnits {
  const AdUnits({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  static const AdUnits fromBuild = AdUnits(
    banner: String.fromEnvironment(
      'ADMOB_BANNER_ID',
      defaultValue: 'ca-app-pub-3940256099942544/9214589741',
    ),
    interstitial: String.fromEnvironment(
      'ADMOB_INTERSTITIAL_ID',
      defaultValue: 'ca-app-pub-3940256099942544/1033173712',
    ),
    rewarded: String.fromEnvironment(
      'ADMOB_REWARDED_ID',
      defaultValue: 'ca-app-pub-3940256099942544/5224354917',
    ),
  );

  final String banner;
  final String interstitial;
  final String rewarded;
}
