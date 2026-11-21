import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/pace/pace_model.dart';
import 'package:vamoose/domain/pace/player.dart';

import '../support/test_services.dart';

void main() {
  test('a share the crowd misses even untimed gets the longest limit', () {
    const pace = PaceModel();
    final board = loadLevelCatalog().byNumber(354).board;
    final crowd = Crowd.sample(160, Random(7));
    final untimed = pace.trial(
      board,
      crowd,
      experience: 0,
      limit: PaceModel.giveUpAfter,
      tries: 1,
      seed: 354,
    );
    expect(untimed.passRate, lessThan(1));

    final limit = pace.fairLimit(
      board,
      crowd,
      experience: 0,
      share: untimed.passRate + 0.01,
      seed: 354,
    );

    expect(limit, PaceModel.giveUpAfter.ceil());
  });

  test('a three-try share no clock can reach gets the longest limit', () {
    final board = loadLevelCatalog().byNumber(354).board;
    final crowd = Crowd.sample(160, Random(7));

    final limit = const PaceModel().fairLimit(
      board,
      crowd,
      experience: 0,
      share: 0.5,
      withinThreeTries: 1.01,
      seed: 354,
    );

    expect(limit, PaceModel.giveUpAfter.ceil());
  });
}
