import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/ads/interstitial_policy.dart';
import 'package:vamoose/state/ad_free_controller.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late FixedClock clock;
  late AdFreeController adFree;
  late InterstitialPolicy policy;

  setUp(() {
    clock = FixedClock(DateTime(2026, 11, 15, 12));
    adFree = AdFreeController(MemoryStore());
    policy = InterstitialPolicy(clock, adFree);
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

  test('never shows after Remove ads', () async {
    await adFree.grant();

    expect(
      clearLevels([10, 11, 12, 13, 14, 15], const Duration(minutes: 5)),
      everyElement(isFalse),
    );
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
