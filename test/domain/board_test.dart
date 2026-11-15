import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/tap_outcome.dart';

import '../support/boards.dart';

void main() {
  group('Board.tap', () {
    test('block with a clear path leaves with its travel distance', () {
      final board = Board(
        size: 5,
        blocks: [block(0, 2, 0, 2, Direction.right)],
      );

      final outcome = board.tap(0);

      expect(outcome, isA<BlockLeaves>());
      expect((outcome as BlockLeaves).travel, 3);
    });

    test('block bumps into the first block in its path', () {
      final board = Board(
        size: 5,
        blocks: [
          block(0, 2, 0, 1, Direction.right),
          block(1, 2, 3, 1, Direction.up),
          block(2, 0, 2, 3, Direction.down),
        ],
      );

      final outcome = board.tap(0);

      expect(outcome, isA<BlockBumps>());
      expect((outcome as BlockBumps).blocker.id, 2);
    });

    test('tapping does not change the board', () {
      final board = Board(size: 4, blocks: [block(0, 0, 0, 1, Direction.up)]);

      board.tap(0);

      expect(board.blockCount, 1);
    });
  });

  group('Board', () {
    test('without removes only the given block', () {
      final board = Board(
        size: 4,
        blocks: [
          block(0, 0, 0, 1, Direction.up),
          block(1, 3, 3, 1, Direction.down),
        ],
      );

      final next = board.without(0);

      expect(next.contains(0), isFalse);
      expect(next.contains(1), isTrue);
      expect(next.blockAt((row: 0, column: 0)), isNull);
    });

    test('movable blocks are the ones with a clear path', () {
      final board = Board(
        size: 3,
        blocks: [
          block(0, 1, 0, 1, Direction.right),
          block(1, 1, 2, 1, Direction.right),
        ],
      );

      expect(board.movableBlocks.map((block) => block.id), [1]);
    });

    test('is cleared when no blocks remain', () {
      expect(Board(size: 3, blocks: const []).isCleared, isTrue);
    });

    test('is solvable when blocks can leave in some order', () {
      final board = Board(
        size: 3,
        blocks: [
          block(0, 1, 0, 1, Direction.right),
          block(1, 0, 2, 3, Direction.down),
        ],
      );

      expect(board.isSolvable, isTrue);
    });

    test('is not solvable when two blocks face each other', () {
      final board = Board(
        size: 3,
        blocks: [
          block(0, 1, 0, 1, Direction.right),
          block(1, 1, 2, 1, Direction.left),
        ],
      );

      expect(board.isSolvable, isFalse);
    });
  });
}
