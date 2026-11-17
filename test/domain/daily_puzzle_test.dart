import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/daily_puzzle.dart';
import 'package:vamoose/domain/level_codec.dart';

void main() {
  const daily = DailyPuzzle();

  test('builds a relaxed 6x6 board with 16 blocks and no locks', () {
    final board = daily.boardFor(DateTime(2026, 11, 15));

    expect(board.size, 6);
    expect(board.blockCount, 16);
    expect(board.restraints, isEmpty);
    expect(board.isSolvable, isTrue);
  });

  test('same day gives the same puzzle', () {
    final morning = daily.boardFor(DateTime(2026, 11, 15, 8));
    final evening = daily.boardFor(DateTime(2026, 11, 15, 22));

    expect(LevelCodec.encode([morning]), LevelCodec.encode([evening]));
  });

  test('next day gives a new puzzle', () {
    final today = daily.boardFor(DateTime(2026, 11, 15));
    final tomorrow = daily.boardFor(DateTime(2026, 11, 16));

    expect(LevelCodec.encode([today]), isNot(LevelCodec.encode([tomorrow])));
  });

  test('a year of daily puzzles is solvable', () {
    for (var offset = 0; offset < 365; offset++) {
      expect(daily.boardFor(DateTime(2026, 1, 1 + offset)).isSolvable, isTrue);
    }
  });
}
