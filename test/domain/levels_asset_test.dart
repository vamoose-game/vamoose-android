import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/chapters.dart';

import '../support/locks.dart';
import '../support/test_services.dart';

void main() {
  final catalog = loadLevelCatalog();

  test('ships one level per slot', () {
    expect(catalog.count, Chapters.levelCount);
  });

  test('every level fits its chapter board and can be solved', () {
    for (var number = 1; number <= catalog.count; number++) {
      final level = catalog.byNumber(number);
      final board = level.board;
      final cells = [for (final block in board.blocks) ...block.cells];

      expect(level.number, number);
      expect(
        board.size,
        Chapters.of(number).boardSize,
        reason: 'level $number',
      );
      expect(
        cells.toSet(),
        hasLength(cells.length),
        reason: 'level $number overlaps',
      );
      expect(
        cells.every(
          (cell) => cell.row < board.size && cell.column < board.size,
        ),
        isTrue,
        reason: 'level $number is out of bounds',
      );
      expect(board.isSolvable, isTrue, reason: 'level $number is stuck');
    }
  });

  test('boards start at 6x6 and grow to 8x8', () {
    expect(catalog.byNumber(1).board.size, 6);
    expect(catalog.byNumber(catalog.count).board.size, 8);
  });

  test('locks arrive at level 12 and always play fair', () {
    for (var number = 1; number <= catalog.count; number++) {
      final board = catalog.byNumber(number).board;
      final pairs = locksOf(board).length;

      if (number < 12) {
        expect(pairs, 0, reason: 'level $number');
      }
      expect(pairs, lessThanOrEqualTo(2), reason: 'level $number');
      expectFairLocks(board, reason: 'level $number');
    }
    expect(locksOf(catalog.byNumber(12).board), hasLength(1));
    expect(locksOf(catalog.byNumber(76).board), hasLength(2));
  });

  test('first level starts gentle', () {
    final board = catalog.byNumber(1).board;

    expect(board.blockCount, lessThanOrEqualTo(4));
    expect(board.movableBlocks, isNotEmpty);
  });
}
