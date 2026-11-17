import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/restraint.dart';
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

  group('Locks', () {
    Board lockedBoard() => Board(
      size: 4,
      blocks: [
        block(0, 0, 0, 1, Direction.left),
        block(1, 2, 1, 1, Direction.left),
        block(2, 2, 0, 1, Direction.down),
      ],
      restraints: const [Lock(blockId: 0, keyId: 1)],
    );

    test('a locked block stays while its key is on the board', () {
      final board = lockedBoard();
      final locked = board.blockById(0);

      expect(board.blockerOf(locked), isNull);
      expect(board.holdOn(locked), isA<Lock>());
      expect(board.canLeave(locked), isFalse);
      expect(board.movableBlocks.map((block) => block.id), [2]);
    });

    test('tapping a locked block bumps into its key', () {
      final outcome = lockedBoard().tap(0);

      expect(outcome, isA<BlockBumps>());
      final bump = outcome as BlockBumps;
      expect(bump.blocker.id, 1);
      expect(bump.restraint, isA<Lock>());
    });

    test('a path bump has no restraint', () {
      final outcome = lockedBoard().tap(1);

      expect((outcome as BlockBumps).blocker.id, 2);
      expect(outcome.restraint, isNull);
    });

    test('the lock opens once the key has left', () {
      final board = lockedBoard().without(2).without(1);
      final locked = board.blockById(0);

      expect(board.holdOn(locked), isNull);
      expect(board.tap(0), isA<BlockLeaves>());
    });

    test('a key that only the locked block can free is unsolvable', () {
      final blocks = [
        block(0, 1, 0, 1, Direction.right),
        block(1, 1, 2, 1, Direction.up),
      ];

      expect(Board(size: 3, blocks: blocks).isSolvable, isTrue);
      expect(
        Board(
          size: 3,
          blocks: blocks,
          restraints: const [Lock(blockId: 1, keyId: 0)],
        ).isSolvable,
        isFalse,
      );
    });
  });
}
