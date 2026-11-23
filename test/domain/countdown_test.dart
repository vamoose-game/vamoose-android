import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/countdown_feature.dart';
import 'package:vamoose/domain/countdowns.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';
import 'package:vamoose/domain/lock_feature.dart';
import 'package:vamoose/domain/restraint.dart';
import 'package:vamoose/domain/tap_outcome.dart';
import 'package:vamoose/domain/turn_feature.dart';

import '../support/boards.dart';
import '../support/countdowns.dart';

void main() {
  Block counting(int id, int row, int column, int count, Direction facing) =>
      Block(
        id: id,
        row: row,
        column: column,
        length: 1,
        direction: facing,
        count: count,
      );

  /// Level 128 of the design: F (5) has to go before J (9).
  Board focusBoard() {
    const rows = [
      (0, 0, 1, Direction.up, null),
      (0, 1, 1, Direction.up, null),
      (0, 2, 3, Direction.left, null),
      (0, 5, 2, Direction.right, null),
      (1, 0, 3, Direction.left, null),
      (1, 4, 1, Direction.up, 5),
      (1, 6, 2, Direction.up, null),
      (2, 0, 1, Direction.up, null),
      (2, 1, 1, Direction.left, null),
      (2, 2, 3, Direction.left, 9),
      (3, 1, 1, Direction.down, null),
      (3, 2, 3, Direction.down, null),
      (3, 3, 2, Direction.left, null),
      (4, 0, 3, Direction.down, null),
      (4, 1, 3, Direction.down, null),
      (4, 3, 3, Direction.down, null),
      (4, 5, 2, Direction.right, null),
      (5, 5, 1, Direction.down, null),
      (5, 6, 1, Direction.up, null),
      (6, 2, 1, Direction.left, null),
    ];
    return Board(
      size: 7,
      blocks: [
        for (var id = 0; id < rows.length; id++)
          Block(
            id: id,
            row: rows[id].$1,
            column: rows[id].$2,
            length: rows[id].$3,
            direction: rows[id].$4,
            count: rows[id].$5,
          ),
      ],
    );
  }

  const a = 0, b = 1, c = 2, e = 4, f = 5, h = 7, i = 8, j = 9;

  group('countdown blocks', () {
    test('count down each time another block leaves, not on a bump', () {
      final board = Board(
        size: 3,
        blocks: [
          counting(0, 1, 0, 3, Direction.right),
          block(1, 1, 2, 1, Direction.up),
          block(2, 2, 0, 1, Direction.down),
        ],
      );

      expect(board.tap(0), isA<BlockBumps>());
      expect(board.without(2).blockById(0).count, 2);
      expect(board.without(2).without(1).blockById(0).count, 1);
    });

    test('run out at 0, cost a star there, then go on as plain blocks', () {
      final board = Board(
        size: 3,
        blocks: [
          counting(0, 1, 0, 1, Direction.right),
          block(1, 1, 2, 1, Direction.up),
          block(2, 2, 0, 1, Direction.down),
        ],
      );

      final outcome = board.tap(2) as BlockLeaves;
      expect(outcome.runOuts.map((block) => block.id), [0]);

      final after = board.without(2);
      expect(after.blockById(0).count, isNull);
      expect(after.hasCountdowns, isFalse);
      expect((after.tap(1) as BlockLeaves).runOuts, isEmpty);
    });

    test('leaving on the last move is in time', () {
      final board = Board(
        size: 3,
        blocks: [
          counting(0, 1, 0, 1, Direction.left),
          counting(1, 0, 0, 1, Direction.up),
        ],
      );

      final outcome = board.tap(0) as BlockLeaves;

      expect(outcome.runOuts.map((block) => block.id), [1]);
    });

    test('wait on the blocks in their way, theirs and the keys', () {
      final board = focusBoard();

      expect(board.waitsOn(board.blockById(f)), {a, b, c});
      expect(board.waitsOn(board.blockById(j)), {a, e, h, i});
      expect(board.holdersOf(board.blockById(c)).toList(), [b, a]);

      final locked = board.restrainedBy([const Lock(blockId: a, keyId: 3)]);
      expect(locked.waitsOn(locked.blockById(f)), containsAll([a, b, c, 3]));
    });
  });

  group('the countdown plan', () {
    test('saves the 5 before the 9, and taking the 9 first loses the 5', () {
      final board = focusBoard();

      expect(Countdowns.canSaveAll(board), isTrue);
      expect(Countdowns.plan(board).order, [a, b, c, f, e, h, i, j]);
      expect(Countdowns.nextMove(board)?.id, a);
      expect(mostUrgentFirstSaves(board), isTrue);

      var current = board;
      final lost = <int>[];
      for (final id in [a, e, h, i, j]) {
        lost.addAll((current.tap(id) as BlockLeaves).runOuts.map((x) => x.id));
        current = current.without(id);
      }
      expect(lost, [f]);
    });

    test('after wasted moves, gives up the 5 to save the 9', () {
      var board = focusBoard();
      for (final wasted in [3, 6, 17, 16]) {
        final outcome = board.tap(wasted);
        expect(outcome, isA<BlockLeaves>());
        expect((outcome as BlockLeaves).runOuts, isEmpty);
        board = board.without(wasted);
      }

      final plan = Countdowns.plan(board);

      expect(board.blockById(f).count, 1);
      expect(Countdowns.canSaveAll(board), isFalse);
      expect(plan.lost, [f]);
      expect(plan.order, [a, e, h, i, j]);
      expect(Countdowns.nextMove(board)?.id, a);
    });

    test('has nothing to say without countdown blocks', () {
      final board = Board(size: 3, blocks: [block(0, 0, 0, 1, Direction.up)]);

      expect(Countdowns.nextMove(board), isNull);
      expect(Countdowns.canSaveAll(board), isTrue);
    });

    test('agrees with trying every order on small boards', () {
      final random = Random(11);
      var saveable = 0;
      var lost = 0;
      for (var trial = 0; saveable + lost < 300; trial++) {
        final size = 4 + random.nextInt(2);
        final cells = [
          for (var row = 0; row < size; row++)
            for (var column = 0; column < size; column++) (row, column),
        ]..shuffle(random);
        final count = 5 + random.nextInt(5);
        final countdowns = 1 + random.nextInt(3);
        final blocks = [
          for (var id = 0; id < count; id++)
            Block(
              id: id,
              row: cells[id].$1,
              column: cells[id].$2,
              length: 1,
              direction: Direction.values[random.nextInt(4)],
              count: id < countdowns ? 1 + random.nextInt(5) : null,
            ),
        ];
        final board = Board(
          size: size,
          blocks: blocks,
          restraints: [
            if (random.nextBool() && blocks[count - 1].count == null)
              Lock(blockId: count - 1, keyId: count - 2),
          ],
        );
        if (!board.isSolvable) {
          continue;
        }

        final expected = canSaveAllByTrying(board);
        expect(Countdowns.canSaveAll(board), expected, reason: 'trial $trial');
        expected ? saveable++ : lost++;
        if (expected) {
          var current = board;
          for (final id in Countdowns.plan(board).order) {
            final outcome = current.tap(id);
            expect(outcome, isA<BlockLeaves>(), reason: 'trial $trial');
            expect((outcome as BlockLeaves).runOuts, isEmpty);
            current = current.without(id);
          }
          expect(current.hasCountdowns, isFalse, reason: 'trial $trial');
        }
      }
      expect(saveable, greaterThan(60));
      expect(lost, greaterThan(60));
    });
  });

  group('the level maker', () {
    test('numbers countdown blocks by the moves they need, plus spare', () {
      const generator = LevelGenerator();
      for (var seed = 0; seed < 40; seed++) {
        final spec = LevelSpec(
          size: 6 + seed % 3,
          blockCount: 20 + seed % 12,
          twist: 0.7,
          locks: seed % 3,
          turners: seed % 4,
          countdowns: 1 + seed % 3,
          spare: seed % 3,
        );
        final board = generator.generate(spec, Random(seed));
        final counting = [
          for (final block in board.blocks)
            if (block.hasCountdown) block,
        ];
        final reason = 'seed $seed';

        expect(counting.length, inInclusiveRange(1, spec.countdowns));
        for (final block in counting) {
          final waits = board.waitsOn(block);
          expect(block.turns, isFalse, reason: reason);
          expect(
            board.restraints.where(
              (restraint) =>
                  restraint.blockId == block.id ||
                  restraint.holderId == block.id,
            ),
            isEmpty,
            reason: reason,
          );
          expect(
            waits.length,
            greaterThanOrEqualTo(CountdownFeature.fewestWaits),
          );
          expect(waits.where((id) => board.blockById(id).turns), isEmpty);
          expect(block.count, greaterThanOrEqualTo(waits.length + 1));
          expect(
            block.count,
            inInclusiveRange(CountdownFeature.fewest, CountdownFeature.most),
          );
        }
        expect(Countdowns.canSaveAll(board), isTrue, reason: reason);
        expect(mostUrgentFirstSaves(board), isTrue, reason: reason);
        expect(board.isSolvable, isTrue, reason: reason);
      }
    });

    test('the most urgent block spares exactly what the spec asks', () {
      const generator = LevelGenerator();
      for (var seed = 0; seed < 20; seed++) {
        final board = generator.generate(
          LevelSpec(
            size: 7,
            blockCount: 26,
            twist: 0.8,
            countdowns: 1,
            spare: seed % 3,
          ),
          Random(seed),
        );
        final only = board.blocks.singleWhere((block) => block.hasCountdown);

        expect(only.count, board.waitsOn(only).length + 1 + seed % 3);
      }
    });

    test('leaves a spec without countdowns exactly as before', () {
      const before = LevelGenerator(features: [TurnFeature(), LockFeature()]);
      for (var seed = 0; seed < 10; seed++) {
        final spec = LevelSpec(
          size: 7,
          blockCount: 24,
          twist: 0.7,
          locks: seed % 3,
          turners: seed % 2,
        );
        final board = const LevelGenerator().generate(spec, Random(seed));

        expect(board.hasCountdowns, isFalse);
        expect(
          LevelCodec.encodeBoard(board),
          LevelCodec.encodeBoard(before.generate(spec, Random(seed))),
        );
      }
    });

    test('the codec keeps countdowns', () {
      final board = focusBoard();
      final level = Level(
        number: 1,
        board: board,
        timeLimit: const Duration(seconds: 25),
      );

      final decoded = LevelCodec.decode(LevelCodec.encode([level])).single;

      expect(LevelCodec.encodeBoard(board)['counts'], [
        [f, 5],
        [j, 9],
      ]);
      expect(decoded.board.blockById(f).count, 5);
      expect(decoded.board.blockById(j).count, 9);
      expect(decoded.board.blockById(a).count, isNull);
      expect(LevelCodec.encode([decoded]), LevelCodec.encode([level]));
      expect(
        LevelCodec.encodeBoard(board.without(a)).containsKey('counts'),
        isTrue,
      );
    });
  });
}
