import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';
import 'package:vamoose/domain/lock_feature.dart';
import 'package:vamoose/domain/restraint.dart';
import 'package:vamoose/domain/tap_outcome.dart';

import '../support/boards.dart';
import '../support/locks.dart';
import '../support/turns.dart';

void main() {
  Block turner(int id, int row, int column, Direction facing) => Block(
    id: id,
    row: row,
    column: column,
    length: 1,
    direction: facing,
    turns: true,
  );

  test('directions turn clockwise and wrap around', () {
    expect(Direction.up.clockwise, Direction.right);
    expect(Direction.right.clockwise, Direction.down);
    expect(Direction.down.clockwise, Direction.left);
    expect(Direction.left.clockwise, Direction.up);
    expect(Direction.left.turned(6), Direction.right);
  });

  test('only 1×1 blocks can turn', () {
    expect(
      () => Block(
        id: 0,
        row: 0,
        column: 0,
        length: 2,
        direction: Direction.up,
        turns: true,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('turning blocks turn each time another block leaves', () {
    final board = Board(
      size: 3,
      blocks: [
        turner(0, 1, 1, Direction.up),
        block(1, 0, 0, 1, Direction.up),
        block(2, 2, 0, 1, Direction.down),
      ],
    );

    final after = board.without(1);

    expect(after.blockById(0).direction, Direction.right);
    expect(after.blockById(2).direction, Direction.down);
    expect(after.without(2).blockById(0).direction, Direction.down);
  });

  test('a turning block goes the way it faces now', () {
    final board = Board(
      size: 3,
      blocks: [
        turner(0, 1, 1, Direction.left),
        block(1, 1, 0, 1, Direction.up),
        block(2, 0, 2, 1, Direction.up),
      ],
    );

    expect(board.tap(0), isA<BlockBumps>());
    final turned = board.without(2);
    expect(turned.blockById(0).direction, Direction.up);
    expect(turned.tap(0), isA<BlockLeaves>());
  });

  test('a board that can turn into a dead end is not solvable', () {
    final board = Board(
      size: 3,
      blocks: [
        turner(0, 1, 1, Direction.left),
        block(1, 0, 1, 1, Direction.down),
        block(2, 1, 2, 1, Direction.left),
        block(3, 2, 2, 1, Direction.down),
      ],
    );

    final afterFree = board.without(3);
    expect(afterFree.movableBlocks, isEmpty);
    expect(hasReachableDeadEnd(board), isTrue);
    expect(board.isSolvable, isFalse);
  });

  test('the any-order check never calls a board with a dead end safe', () {
    final random = Random(7);
    var safe = 0;
    for (var trial = 0; trial < 400; trial++) {
      final size = 3 + random.nextInt(3);
      final cells = [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++) (row, column),
      ]..shuffle(random);
      final count = 3 + random.nextInt(min(8, cells.length - 3));
      final blocks = [
        for (var id = 0; id < count; id++)
          Block(
            id: id,
            row: cells[id].$1,
            column: cells[id].$2,
            length: 1,
            direction: Direction.values[random.nextInt(4)],
            turns: random.nextDouble() < 0.4,
          ),
      ];
      final board = Board(
        size: size,
        blocks: blocks,
        restraints: [
          if (count > 4 && !blocks[0].turns && !blocks[1].turns)
            const Lock(blockId: 0, keyId: 1),
        ],
      );

      if (hasReachableDeadEnd(board)) {
        expect(board.isSolvable, isFalse, reason: 'trial $trial');
      } else if (board.isSolvable) {
        safe++;
      }
    }
    expect(safe, greaterThan(40));
  });

  test('the level maker adds the turning blocks a spec asks for', () {
    const generator = LevelGenerator();
    for (var seed = 0; seed < 30; seed++) {
      final spec = LevelSpec(
        size: 6 + seed % 3,
        blockCount: 18 + seed % 10,
        twist: 0.5,
        turners: 1 + seed % 3,
        locks: seed % 3,
      );
      final board = generator.generate(spec, Random(seed));
      final turning = board.blocks.where((block) => block.turns).toList();

      expect(turning, hasLength(spec.turners), reason: 'seed $seed');
      expect(turning.every((block) => block.length == 1), isTrue);
      expect(board.isSolvable, isTrue, reason: 'seed $seed');
      for (final restraint in board.restraints) {
        expect(board.blockById(restraint.blockId).turns, isFalse);
        expect(board.blockById(restraint.holderId).turns, isFalse);
      }
    }
  });

  test('lock fairness replays only moves a player could make', () {
    // Turning block 11 faces block 12 when its turn in the round comes.
    final board = LevelCodec.decodeBoard({
      'size': 6,
      'blocks': [
        [0, 0, 3, 'u'],
        [0, 1, 3, 'r'],
        [0, 4, 3, 'u'],
        [1, 2, 2, 'd'],
        [1, 3, 2, 'u'],
        [2, 1, 3, 'u'],
        [3, 0, 2, 'd'],
        [3, 2, 3, 'r'],
        [3, 5, 1, 'r'],
        [4, 2, 3, 'r'],
        [4, 5, 2, 'd'],
        [5, 0, 1, 'r'],
        [5, 1, 2, 'l'],
        [5, 3, 1, 'r'],
        [5, 4, 1, 'l'],
      ],
      'locks': [
        [6, 7],
      ],
      'turns': [11, 13],
    });

    const lock = Lock(blockId: 6, keyId: 7);
    expect(board.isSolvable, isTrue);
    expect(LockFeature.holdsBack(board, lock), isFalse);
    expect(holdsBack(board, lock), isFalse);
  });

  test('locks the level maker adds hold a block back in real play', () {
    const generator = LevelGenerator();
    for (var seed = 0; seed < 60; seed++) {
      final board = generator.generate(
        LevelSpec(
          size: 6 + seed % 2,
          blockCount: 16 + seed % 8,
          twist: 0.6,
          turners: 2 + seed % 2,
          locks: 1 + seed % 3,
        ),
        Random(seed),
      );

      expectFairLocks(board, reason: 'seed $seed');
    }
  });

  test('the codec keeps turning blocks and the time limit', () {
    final board = const LevelGenerator().generate(
      const LevelSpec(
        size: 7,
        blockCount: 22,
        twist: 0.5,
        turners: 2,
        locks: 1,
      ),
      Random(4),
    );
    final level = Level(
      number: 1,
      board: board,
      timeLimit: const Duration(seconds: 17),
    );

    final decoded = LevelCodec.decode(LevelCodec.encode([level])).single;

    expect(decoded.timeLimit, const Duration(seconds: 17));
    expect(decoded.board.blocks.where((block) => block.turns), hasLength(2));
    expect(LevelCodec.encode([decoded]), LevelCodec.encode([level]));
  });
}
