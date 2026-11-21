import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/daily_puzzle.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/pace/pace_model.dart';
import 'package:vamoose/domain/pace/player.dart';

void main() {
  final daily = DailyPuzzle();

  test('builds a 6x6 board with 16 blocks and no locks', () {
    final board = daily.puzzleFor(DateTime(2026, 11, 15)).board;

    expect(board.size, 6);
    expect(board.blockCount, 16);
    expect(board.restraints, isEmpty);
    expect(board.hasTurningBlocks, isFalse);
    expect(board.isSolvable, isTrue);
  });

  test('same day gives the same puzzle and time', () {
    final morning = daily.puzzleFor(DateTime(2026, 11, 15, 8));
    final evening = DailyPuzzle().puzzleFor(DateTime(2026, 11, 15, 22));

    expect(
      LevelCodec.encodeBoard(morning.board),
      LevelCodec.encodeBoard(evening.board),
    );
    expect(morning.timeLimit, evening.timeLimit);
  });

  test('next day gives a new puzzle', () {
    final today = daily.puzzleFor(DateTime(2026, 11, 15)).board;
    final tomorrow = daily.puzzleFor(DateTime(2026, 11, 16)).board;

    expect(
      LevelCodec.encodeBoard(today),
      isNot(LevelCodec.encodeBoard(tomorrow)),
    );
  });

  test('every day is timed for its own board, briskly', () {
    for (var offset = 0; offset < 30; offset++) {
      final puzzle = daily.puzzleFor(DateTime(2026, 1, 1 + offset));

      expect(puzzle.board.isSolvable, isTrue);
      expect(
        puzzle.timeLimit.inSeconds,
        inInclusiveRange(10, 30),
        reason: 'day $offset',
      );
    }
  });

  test('a new player clears each day within three tries', () {
    // Another crowd than the one the clock was set with.
    final crowd = Crowd.sample(400, Random(11));
    for (var offset = 0; offset < 10; offset++) {
      final puzzle = DailyPuzzle().puzzleFor(DateTime(2026, 12, 1 + offset));
      final trial = const PaceModel().trial(
        puzzle.board,
        crowd,
        experience: 0,
        limit: puzzle.timeLimit.inSeconds.toDouble(),
        seed: offset + 1,
      );

      expect(
        trial.passWithin(3),
        greaterThanOrEqualTo(0.88),
        reason: '$offset',
      );
      expect(trial.passRate, greaterThanOrEqualTo(0.56), reason: '$offset');
    }
  });
}
