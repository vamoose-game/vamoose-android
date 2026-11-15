import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/chapters.dart';

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

  test('first level starts gentle', () {
    final board = catalog.byNumber(1).board;

    expect(board.blockCount, lessThanOrEqualTo(4));
    expect(board.movableBlocks, isNotEmpty);
  });
}
