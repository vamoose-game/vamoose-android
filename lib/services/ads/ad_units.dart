import 'package:flutter/foundation.dart';

class AdUnits {
  const AdUnits({
    required this.banner,
    required this.interstitial,
    required this.rewarded,
  });

  static const AdUnits production = AdUnits(
    banner: 'ca-app-pub-7531106875262722/7164402973',
    interstitial: 'ca-app-pub-7531106875262722/4685433506',
    rewarded: 'ca-app-pub-7531106875262722/8433106823',
  );

  static const AdUnits test = AdUnits(
    banner: 'ca-app-pub-3940256099942544/9214589741',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const AdUnits fromBuild = kReleaseMode ? production : test;

  final String banner;
  final String interstitial;
  final String rewarded;
}
