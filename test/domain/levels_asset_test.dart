import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/countdown_feature.dart';
import 'package:vamoose/domain/countdowns.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/pace/pace_model.dart';
import 'package:vamoose/domain/pace/player.dart';

import '../../tool/generate_levels.dart' as tool;
import '../support/countdowns.dart';
import '../support/locks.dart';
import '../support/test_services.dart';

void main() {
  final catalog = loadLevelCatalog();
  final levels = [
    for (var number = 1; number <= catalog.count; number++)
      catalog.byNumber(number),
  ];
  int turnersIn(int number) =>
      levels[number - 1].board.blocks.where((block) => block.turns).length;
  int countdownsIn(int number) => levels[number - 1].board.blocks
      .where((block) => block.hasCountdown)
      .length;
  int frozenIn(int number) =>
      levels[number - 1].board.blocks.where((block) => block.isFrozen).length;
  int twinPairsIn(int number) => levels[number - 1].board.twins.length;

  /// Every 10 levels from [first] to the end use the mechanic at least once.
  void expectToTheEnd(int first, int Function(int number) uses) {
    for (var from = first; from <= catalog.count; from += 10) {
      expect(
        [for (var n = from; n < min(from + 10, catalog.count + 1); n++) uses(n)]
            .any((count) => count > 0),
        isTrue,
        reason: 'levels $from–${from + 9}',
      );
    }
  }

  test('ships one level per slot', () {
    expect(catalog.count, Chapters.levelCount);
  });

  test(
    'every level fits its chapter board and can be cleared in any order',
    () {
      for (final level in levels) {
        final board = level.board;
        final cells = [for (final block in board.blocks) ...block.cells];
        final reason = 'level ${level.number}';

        expect(board.size, Chapters.of(level.number).boardSize, reason: reason);
        expect(
          cells.toSet(),
          hasLength(cells.length),
          reason: '$reason overlaps',
        );
        expect(board.isSolvable, isTrue, reason: '$reason can get stuck');
      }
    },
  );

  test('boards start at 6x6 and grow to 8x8', () {
    expect(levels.first.board.size, 6);
    expect(levels.last.board.size, 8);
  });

  test('the first key and lock arrive at level 11 and always play fair', () {
    for (final level in levels) {
      final pairs = locksOf(level.board).length;
      if (level.number < 11) {
        expect(pairs, 0, reason: 'level ${level.number}');
      }
      expect(pairs, lessThanOrEqualTo(3), reason: 'level ${level.number}');
      expectFairLocks(level.board, reason: 'level ${level.number}');
    }
    expect(locksOf(levels[10].board), hasLength(1));
    expect(levels.any((level) => locksOf(level.board).length == 3), isTrue);
  });

  test('turning blocks arrive at level 51 and stay to the end', () {
    for (var number = 1; number < 51; number++) {
      expect(turnersIn(number), 0, reason: 'level $number');
    }
    expect(turnersIn(51), 1);
    expect(locksOf(levels[50].board), isEmpty);
    for (final level in levels) {
      for (final block in level.board.blocks.where((block) => block.turns)) {
        expect(block.length, 1, reason: 'level ${level.number}');
      }
      expect(turnersIn(level.number), lessThanOrEqualTo(3));
    }
    expectToTheEnd(51, turnersIn);
  });

  test('frozen blocks arrive at level 91, thick ice at 201', () {
    for (var number = 1; number < 91; number++) {
      expect(frozenIn(number), 0, reason: 'level $number');
    }
    expect(frozenIn(91), 1);
    expect(levels[90].board.blocks.where((b) => b.isFrozen).single.ice, 1);
    expectToTheEnd(91, frozenIn);
    for (final level in levels) {
      final board = level.board;
      final reason = 'level ${level.number}';
      for (final block in board.blocks.where((block) => block.isFrozen)) {
        expect(block.ice, inInclusiveRange(1, 2), reason: reason);
        if (level.number < 201) {
          expect(block.ice, 1, reason: reason);
        }
        expect(block.turns || block.hasCountdown, isFalse, reason: reason);
        expect(board.twinOf(block), isNull, reason: reason);
        expect(
          locksOf(
            board,
          ).where((lock) => lock.blockId == block.id || lock.keyId == block.id),
          isEmpty,
          reason: reason,
        );
        expect(
          board.neighboursOf(block).length,
          greaterThanOrEqualTo(block.ice),
          reason: reason,
        );
      }
      expect(frozenIn(level.number), lessThanOrEqualTo(3), reason: reason);
    }
    expect(
      levels.any((level) => level.board.blocks.any((block) => block.ice == 2)),
      isTrue,
    );
  });

  test('twin blocks arrive at level 131, one color per pair', () {
    for (var number = 1; number < 131; number++) {
      expect(twinPairsIn(number), 0, reason: 'level $number');
    }
    expect(twinPairsIn(131), 1);
    expectToTheEnd(131, twinPairsIn);
    for (final level in levels) {
      final board = level.board;
      final reason = 'level ${level.number}';
      expect(board.twins.length, lessThanOrEqualTo(3), reason: reason);
      final twins = [
        for (final pair in board.twins) ...[pair.first, pair.second],
      ];
      expect(twins.toSet(), hasLength(twins.length), reason: reason);
      for (final pair in board.twins) {
        final first = board.blockById(pair.first);
        final second = board.blockById(pair.second);
        for (final twin in [first, second]) {
          expect(twin.turns || twin.isFrozen, isFalse, reason: reason);
          expect(twin.hasCountdown, isFalse, reason: reason);
        }
        expect(board.waitsOn(first).contains(second.id), isFalse);
        expect(board.waitsOn(second).contains(first.id), isFalse);
      }
    }
    expect(levels.any((level) => twinPairsIn(level.number) == 3), isTrue);
  });

  test('a level can have all five mechanics at once', () {
    final all = levels.where((level) {
      final board = level.board;
      return locksOf(board).isNotEmpty &&
          board.hasTurningBlocks &&
          board.hasIce &&
          board.hasTwins &&
          board.hasCountdowns;
    });

    expect(all.first.number, greaterThanOrEqualTo(171));
    expect(all.length, greaterThan(10));
  });

  test('countdown blocks arrive at level 171 and stay to the end', () {
    for (var number = 1; number < 171; number++) {
      expect(countdownsIn(number), 0, reason: 'level $number');
    }
    expect(countdownsIn(171), 1);
    expectToTheEnd(171, countdownsIn);
    expect(
      levels.where((level) => level.board.hasCountdowns).length,
      greaterThan(80),
    );
    expect(levels.any((level) => countdownsIn(level.number) == 3), isTrue);
  });

  test('countdown blocks are plain blocks with a way to plan', () {
    for (final level in levels) {
      final board = level.board;
      final reason = 'level ${level.number}';
      expect(countdownsIn(level.number), lessThanOrEqualTo(3), reason: reason);
      for (final block in board.blocks.where((block) => block.hasCountdown)) {
        final waits = board.waitsOn(block);
        expect(block.turns, isFalse, reason: reason);
        expect(
          locksOf(
            board,
          ).where((lock) => lock.blockId == block.id || lock.keyId == block.id),
          isEmpty,
          reason: reason,
        );
        expect(
          block.count,
          inInclusiveRange(CountdownFeature.fewest, CountdownFeature.most),
          reason: reason,
        );
        expect(block.count, greaterThan(waits.length), reason: reason);
        expect(
          waits.length,
          greaterThanOrEqualTo(CountdownFeature.fewestWaits),
          reason: reason,
        );
        expect(
          waits.where((id) => board.blockById(id).turns),
          isEmpty,
          reason: '$reason: a countdown block waits on a turning block',
        );
      }
    }
  });

  test('every countdown block can be saved, most urgent first', () {
    for (final level in levels.where((level) => level.board.hasCountdowns)) {
      final reason = 'level ${level.number}';
      expect(Countdowns.canSaveAll(level.board), isTrue, reason: reason);
      expect(mostUrgentFirstSaves(level.board), isTrue, reason: reason);
    }
  });

  test('with two or more countdown blocks, the order mostly matters', () {
    var several = 0;
    var ordered = 0;
    for (final level in levels) {
      final board = level.board;
      final counting = board.blocks.where((block) => block.hasCountdown);
      if (counting.length < 2) {
        continue;
      }
      several++;
      // Saving one first, with all it waits on, loses another.
      final loses = counting.any(
        (first) => counting.any((then) {
          final firstWaits = board.waitsOn(first);
          final thenWaits = board.waitsOn(then);
          return first.id != then.id &&
              !firstWaits.contains(then.id) &&
              !thenWaits.contains(first.id) &&
              {...firstWaits, first.id, ...thenWaits, then.id}.length >
                  then.count!;
        }),
      );
      if (loses) {
        ordered++;
      }
    }
    expect(several, greaterThan(20));
    expect(ordered / several, greaterThan(0.65));
  });

  test('locks and turning blocks also share levels', () {
    final both = levels.where(
      (level) =>
          level.board.restraints.isNotEmpty && level.board.hasTurningBlocks,
    );

    expect(both.first.number, inInclusiveRange(52, 56));
    expect(both.length, greaterThan(100));
  });

  test('the clock starts at 12 s and grows tier by tier', () {
    final seconds = [for (final level in levels) level.timeLimit.inSeconds];

    expect(seconds.take(10), everyElement(12));
    for (var index = 1; index < seconds.length; index++) {
      expect(seconds[index], greaterThanOrEqualTo(seconds[index - 1]));
    }
    var tier = 0;
    for (var index = 1; index < seconds.length; index++) {
      if (seconds[index] != seconds[index - 1]) {
        expect(index - tier, inInclusiveRange(10, 20), reason: 'level $index');
        tier = index;
      }
    }
    expect(seconds.length - tier, inInclusiveRange(10, 20), reason: 'last');
    expect(seconds.last, lessThan(60));
  });

  group('no level is easier than in build 9', () {
    final build9 = LevelCodec.decode(
      File('test/fixtures/levels_build9.json').readAsStringSync(),
    );

    test('nor has fewer blocks, or fewer mechanics than it had locks', () {
      for (final level in levels) {
        final before = build9[level.number - 1].board;
        final reason = 'level ${level.number}';

        expect(
          level.board.blockCount,
          greaterThanOrEqualTo(before.blockCount),
          reason: reason,
        );
        expect(
          locksOf(level.board).length +
              turnersIn(level.number) +
              frozenIn(level.number) +
              twinPairsIn(level.number) +
              countdownsIn(level.number),
          greaterThanOrEqualTo(locksOf(before).length),
          reason: reason,
        );
      }
    });

    test('nor quicker to clear, unless build 9 was unfair at 10 s', () {
      // The crowd, seeds and fairness rules of tool/generate_levels.dart.
      const model = PaceModel();
      final crowd = Crowd.sample(tool.crowdSize, Random(2026));
      final experts =
          ([for (var index = 0; index < crowd.length; index++) index]
                ..sort((a, b) => crowd[a].think.compareTo(crowd[b].think)))
              .take((crowd.length * tool.expertShare).round())
              .toList();
      double untimed(Board board, int number) => model
          .trial(
            board,
            crowd,
            experience: number - 1,
            limit: PaceModel.giveUpAfter,
            tries: 1,
            seed: number,
          )
          .finishWithin(0.5);
      bool fairAtTenSeconds(Board board, int number) {
        final trial = model.trial(
          board,
          crowd,
          experience: number - 1,
          limit: tool.firstTierSeconds.toDouble(),
          seed: number,
        );
        return trial.passRate >= tool.firstTryFloor(1) &&
            trial.passWithin(3) >= tool.threeTriesFloor &&
            trial.outOfTimeRateAmong(experts) <= tool.expertTimeOuts;
      }

      for (final level in levels) {
        final number = level.number;
        final before = build9[number - 1].board;
        final reason = 'level $number';
        if (number <= tool.tierLength(1)) {
          expect(fairAtTenSeconds(level.board, number), isTrue, reason: reason);
          // Build 9 had no clock; a board unfair at 10 s is no yardstick.
          if (!fairAtTenSeconds(before, number)) {
            continue;
          }
        }
        expect(
          untimed(level.board, number),
          greaterThanOrEqualTo(untimed(before, number)),
          reason: reason,
        );
      }
    });
  });

  test('every level can be cleared in time within three tries', () {
    const model = PaceModel();
    final crowd = Crowd.sample(80, Random(5));
    for (final level in levels) {
      final trial = model.trial(
        level.board,
        crowd,
        experience: level.number - 1,
        limit: level.timeLimit.inMilliseconds / 1000,
        seed: level.number,
      );
      expect(
        trial.passWithin(3),
        greaterThanOrEqualTo(0.85),
        reason: 'level ${level.number}',
      );
    }
  });

  test('the first level is a short, fair start', () {
    final first = levels.first;

    expect(first.board.blockCount, inInclusiveRange(6, 8));
    expect(first.board.movableBlocks, isNotEmpty);
    expect(first.timeLimit, const Duration(seconds: 12));
  });
}
