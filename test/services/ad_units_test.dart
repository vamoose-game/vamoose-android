import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/ads/ad_units.dart';

void main() {
  test('non-release builds use Google test ads', () {
    expect(AdUnits.fromBuild, same(AdUnits.test));
  });

  test('production units belong to the Vamoose AdMob account', () {
    for (final unit in [
      AdUnits.production.banner,
      AdUnits.production.interstitial,
      AdUnits.production.rewarded,
    ]) {
      expect(unit, startsWith('ca-app-pub-7531106875262722/'));
    }
  });
}
