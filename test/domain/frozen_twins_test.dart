import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/countdowns.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/ice_feature.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';
import 'package:vamoose/domain/restraint.dart';
import 'package:vamoose/domain/tap_outcome.dart';

import '../support/boards.dart';
import '../support/countdowns.dart';
import '../support/locks.dart';
import '../support/turns.dart';

void main() {
  Block frozen(int id, int row, int column, Direction facing, {int ice = 1}) =>
      Block(
        id: id,
        row: row,
        column: column,
        length: 1,
        direction: facing,
        ice: ice,
      );

  group('frozen blocks', () {
    // Block 0 is frozen with a clear way left; 1 and 2 sit next to it.
    Board iced({int ice = 1}) => Board(
      size: 3,
      blocks: [
        frozen(0, 1, 0, Direction.left, ice: ice),
        block(1, 1, 1, 1, Direction.up),
        block(2, 2, 0, 1, Direction.down),
        block(3, 2, 2, 1, Direction.down),
      ],
    );

    test('cannot move, even with a clear way: tapping one is a bump', () {
      final board = iced();

      expect(board.canLeave(board.blockById(0)), isFalse);
      final outcome = board.tap(0) as BlockBumps;
      expect(outcome.frozen, isTrue);
      expect(outcome.blocker, isNull);
      expect(board.tap(0), isA<BlockBumps>());
    });

    test('thaw when a block next to them leaves', () {
      final board = iced();

      final afterFar = board.without(3);
      expect(afterFar.blockById(0).ice, 1, reason: '3 is not next to it');
      final thawed = afterFar.without(1);
      expect(thawed.blockById(0).isFrozen, isFalse);
      expect(thawed.tap(0), isA<BlockLeaves>());
    });

    test('thick ice cracks once per neighbour that leaves', () {
      final board = iced(ice: 2);

      final cracked = board.without(1);
      expect(cracked.blockById(0).ice, 1);
      expect(cracked.blockById(0).cracks, 1);
      expect(cracked.canLeave(cracked.blockById(0)), isFalse);
      final thawed = cracked.without(2).blockById(0);
      expect(thawed.ice, 0);
      expect(thawed.cracks, 0, reason: 'no ice left to show cracks in');
    });

    test('the thickest ice cracks twice before it shatters', () {
      // Block 0 is frozen under three layers, with a block on three sides.
      final board = Board(
        size: 3,
        blocks: [
          frozen(0, 1, 0, Direction.left, ice: 3),
          block(1, 1, 1, 1, Direction.up),
          block(2, 2, 0, 1, Direction.down),
          block(3, 0, 0, 1, Direction.up),
        ],
      );

      final once = board.without(1);
      expect(once.blockById(0).ice, 2);
      expect(once.blockById(0).cracks, 1);
      final twice = once.without(3);
      expect(twice.blockById(0).ice, 1);
      expect(twice.blockById(0).cracks, 2);
      expect(twice.canLeave(twice.blockById(0)), isFalse);
      final free = twice.without(2);
      expect(free.blockById(0).isFrozen, isFalse);
      expect(free.blockById(0).cracks, 0);
      expect(free.tap(0), isA<BlockLeaves>());
    });

    test('cracks last through turns and countdowns, and reset with ice', () {
      final thick = frozen(0, 0, 0, Direction.up, ice: 3);

      expect(thick.cracked(0), same(thick));
      expect(thick.cracked(2).ice, 1);
      expect(thick.cracked(2).cracks, 2);
      expect(thick.cracked(3).cracks, 0);
      final cracked = thick.cracked(1);
      expect(cracked.copyWith(direction: Direction.down).cracks, 1);
      expect(cracked.withCount(4).cracks, 1);
      expect(cracked.withCount(4).countedDown().cracks, 1);
      expect(cracked.withIce(2).cracks, 0);
      expect(thick.withIce(0).cracked(1).cracks, 0);
    });
  });

  group('twin blocks', () {
    // Twins 0 and 1; block 2 is in the way of twin 1.
    Board twins() => Board(
      size: 4,
      blocks: [
        block(0, 0, 0, 1, Direction.up),
        block(1, 3, 0, 1, Direction.right),
        block(2, 3, 2, 1, Direction.up),
        block(3, 1, 3, 1, Direction.right),
        Block(
          id: 4,
          row: 2,
          column: 3,
          length: 1,
          direction: Direction.down,
          turns: true,
        ),
        Block(
          id: 5,
          row: 0,
          column: 2,
          length: 1,
          direction: Direction.up,
          count: 2,
        ),
      ],
      twins: const [(first: 0, second: 1)],
    );

    test('bump together while either way is blocked', () {
      final board = twins();

      final fromFree = board.tap(0) as BlockBumps;
      expect(fromFree.twin?.id, 1);
      expect(fromFree.twinStuck, isTrue);
      expect(fromFree.blocker?.id, 2);
      expect(fromFree.stuck.id, 1);
      expect((board.tap(1) as BlockBumps).twinStuck, isFalse);
      expect(board.canLeave(board.blockById(0)), isFalse);
    });

    test('leave together, counting as two blocks leaving', () {
      final board = twins().without(2);
      expect(board.blockById(5).count, 1);
      expect(board.blockById(4).direction, Direction.left);

      final outcome = board.tap(1) as BlockLeaves;
      expect(outcome.twin?.id, 0);
      expect(outcome.runOuts.map((block) => block.id), [5]);

      final after = board.without(1);
      expect(after.contains(0), isFalse);
      expect(after.contains(1), isFalse);
      expect(after.blockById(4).direction, Direction.right);
      expect(after.hasTwins, isFalse);
    });

    test('ice next to both twins cracks twice when they leave', () {
      final board = Board(
        size: 3,
        blocks: [
          block(0, 0, 1, 1, Direction.up),
          frozen(1, 1, 1, Direction.down, ice: 2),
          block(2, 1, 2, 1, Direction.right),
        ],
        twins: const [(first: 0, second: 2)],
      );

      expect(board.without(0).blockById(1).ice, 0);
    });
  });

  test('the codec keeps ice and twins', () {
    final board = Board(
      size: 3,
      blocks: [
        frozen(0, 1, 0, Direction.left, ice: 2),
        block(1, 0, 1, 1, Direction.up),
        block(2, 2, 2, 1, Direction.down),
      ],
      twins: const [(first: 1, second: 2)],
    );
    final level = Level(
      number: 1,
      board: board,
      timeLimit: const Duration(seconds: 20),
    );

    final decoded = LevelCodec.decode(LevelCodec.encode([level])).single;

    expect(LevelCodec.encodeBoard(board)['ice'], [
      [0, 2],
    ]);
    expect(LevelCodec.encodeBoard(board)['twins'], [
      [1, 2],
    ]);
    expect(decoded.board.blockById(0).ice, 2);
    expect(decoded.board.twinOf(decoded.board.blockById(1))?.id, 2);
    expect(LevelCodec.encode([decoded]), LevelCodec.encode([level]));
    expect(
      LevelCodec.encodeBoard(board.without(1)).containsKey('twins'),
      isFalse,
    );
  });

  group('the any-order check', () {
    Board randomBoard(Random random, {required bool turning}) {
      final size = 3 + random.nextInt(3);
      final cells = [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++) (row, column),
      ]..shuffle(random);
      final count = 4 + random.nextInt(min(7, cells.length - 4));
      final blocks = [
        for (var id = 0; id < count; id++)
          Block(
            id: id,
            row: cells[id].$1,
            column: cells[id].$2,
            length: 1,
            direction: Direction.values[random.nextInt(4)],
            turns: turning && id >= count - 2 && random.nextBool(),
            ice: id < 2 ? random.nextInt(3) : 0,
          ),
      ];
      return Board(
        size: size,
        blocks: blocks,
        restraints: [
          if (random.nextBool() && !blocks[3].turns && blocks[3].ice == 0)
            const Lock(blockId: 3, keyId: 2),
        ],
        twins: [
          if (random.nextBool() &&
              !blocks[2].turns &&
              !blocks[count - 3].turns &&
              blocks[count - 3].ice == 0 &&
              count - 3 > 3)
            (first: 2, second: count - 3),
        ],
      );
    }

    test('is exact for boards without turning blocks', () {
      final random = Random(21);
      var stuck = 0;
      for (var trial = 0; trial < 500; trial++) {
        final board = randomBoard(random, turning: false);
        final deadEnd = hasReachableDeadEnd(board);
        expect(board.isSolvable, !deadEnd, reason: 'trial $trial');
        if (deadEnd) {
          stuck++;
        }
      }
      expect(stuck, greaterThan(40));
    });

    test('never calls a board with a dead end safe, turning blocks too', () {
      final random = Random(22);
      var safe = 0;
      for (var trial = 0; trial < 500; trial++) {
        final board = randomBoard(random, turning: true);
        if (hasReachableDeadEnd(board)) {
          expect(board.isSolvable, isFalse, reason: 'trial $trial');
        } else if (board.isSolvable) {
          safe++;
        }
      }
      expect(safe, greaterThan(60));
    });
  });

  group('the level maker', () {
    test('freezes and twins plain blocks, and the board still clears', () {
      const generator = LevelGenerator();
      for (var seed = 0; seed < 40; seed++) {
        final spec = LevelSpec(
          size: 6 + seed % 3,
          blockCount: 20 + seed % 12,
          twist: 0.7,
          locks: seed % 3,
          turners: seed % 4,
          ice: [
            for (var index = 0; index < 1 + seed % 3; index++)
              index == 0 ? 1 + seed % 3 : 1,
          ],
          twins: 1 + seed % 3,
          countdowns: seed % 3,
          spare: 1,
        );
        final board = generator.generate(spec, Random(seed));
        final reason = 'seed $seed';
        final ice = [
          for (final block in board.blocks)
            if (block.isFrozen) block,
        ];

        expect(
          [for (final block in ice) block.ice]..sort(),
          [...spec.ice]..sort(),
          reason: reason,
        );
        expect(board.twins, hasLength(spec.twins), reason: reason);
        final roles = <int>{};
        for (final lock in locksOf(board)) {
          roles.addAll([lock.blockId, lock.keyId]);
        }
        for (final block in ice) {
          expect(block.turns || block.hasCountdown, isFalse, reason: reason);
          expect(roles.contains(block.id), isFalse, reason: reason);
          expect(board.twinOf(block), isNull, reason: reason);
          expect(
            board.neighboursOf(block).length,
            greaterThanOrEqualTo(block.ice),
            reason: reason,
          );
        }
        for (final pair in board.twins) {
          final first = board.blockById(pair.first);
          final second = board.blockById(pair.second);
          for (final twin in [first, second]) {
            expect(twin.turns || twin.isFrozen, isFalse, reason: reason);
            expect(twin.hasCountdown, isFalse, reason: reason);
            expect(roles.contains(twin.id), isFalse, reason: reason);
          }
          expect(board.waitsOn(first).contains(second.id), isFalse);
          expect(board.waitsOn(second).contains(first.id), isFalse);
        }
        for (final block in board.blocks.where((b) => b.hasCountdown)) {
          for (final id in board.waitsOn(block)) {
            final waited = board.blockById(id);
            expect(waited.isFrozen || waited.turns, isFalse, reason: reason);
            expect(board.twinOf(waited), isNull, reason: reason);
          }
        }
        expect(IceFeature.fair(board), isTrue, reason: reason);
        expectFairLocks(board, reason: reason);
        expect(Countdowns.canSaveAll(board), isTrue, reason: reason);
        expect(mostUrgentFirstSaves(board), isTrue, reason: reason);
        expect(solutionOrder(board), hasLength(lessThan(spec.blockCount + 6)));
      }
    });
  });
}
