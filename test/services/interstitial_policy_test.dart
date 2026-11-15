import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/ads/interstitial_policy.dart';

import '../support/fixed_clock.dart';

void main() {
  late FixedClock clock;
  late InterstitialPolicy policy;

  setUp(() {
    clock = FixedClock(DateTime(2026, 11, 15, 12));
    policy = InterstitialPolicy(clock);
  });

  List<bool> clearLevels(Iterable<int> levels, Duration gap) => [
    for (final level in levels) _clearAfter(policy, clock, level, gap),
  ];

  test('never shows before level 10', () {
    expect(
      clearLevels([
        for (var level = 1; level < 10; level++) level,
      ], const Duration(minutes: 5)),
      everyElement(isFalse),
    );
  });

  test('shows on every third clear from level 10', () {
    expect(clearLevels([10, 11, 12, 13, 14, 15], const Duration(minutes: 1)), [
      false,
      false,
      true,
      false,
      false,
      true,
    ]);
  });

  test('waits two minutes between ads', () {
    expect(clearLevels([10, 11, 12, 13, 14, 15], const Duration(seconds: 20)), [
      false,
      false,
      true,
      false,
      false,
      false,
    ]);
  });
}

bool _clearAfter(
  InterstitialPolicy policy,
  FixedClock clock,
  int level,
  Duration gap,
) {
  clock.current = clock.current.add(gap);
  return policy.shouldShowAfterClearing(level);
}
