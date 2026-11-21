import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/tap_outcome.dart';
import 'package:vamoose/state/game_session.dart';

import '../support/boards.dart';

void main() {
  const tenSeconds = Duration(seconds: 10);

  // Inside fakeAsync the zone's clock runs on fake time.
  GameSession sessionFor(Puzzle puzzle) =>
      GameSession(puzzle, stopwatch: clock.stopwatch);

  Puzzle puzzle({Duration timeLimit = tenSeconds}) => (
    board: Board(
      size: 3,
      blocks: [
        block(0, 1, 0, 1, Direction.right),
        block(1, 0, 2, 3, Direction.down),
      ],
    ),
    timeLimit: timeLimit,
  );

  test('a leaving block is removed', () {
    final session = sessionFor(puzzle());

    final outcome = session.tap(1);

    expect(outcome, isA<BlockLeaves>());
    expect(session.blocksLeft, 1);
    expect(session.totalBlocks, 2);
    expect(session.bumps, 0);
  });

  test('each bump costs a star', () {
    final session = sessionFor(puzzle());

    expect(session.stars, 3);
    expect(session.tap(0), isA<BlockBumps>());
    expect(session.stars, 2);
    expect(session.blocksLeft, 2);
  });

  test('the third bump runs out of stars and ends the go', () {
    final session = sessionFor(puzzle());

    session
      ..tap(0)
      ..tap(0)
      ..tap(0);

    expect(session.failure, Failure.outOfStars);
    expect(session.isOver, isTrue);
    expect(session.tap(1), isNull);
    expect(session.blocksLeft, 2);
  });

  test('the clock counts down once started and times out at zero', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle());
      final seen = <int>[];
      session.secondsLeft.addListener(
        () => seen.add(session.secondsLeft.value),
      );

      async.elapse(const Duration(seconds: 2));
      expect(session.secondsLeft.value, 10);
      expect(session.isRunning, isFalse);

      session.start();
      async.elapse(const Duration(milliseconds: 9500));
      expect(session.secondsLeft.value, 1);
      expect(session.failure, isNull);

      async.elapse(const Duration(milliseconds: 600));
      expect(session.failure, Failure.outOfTime);
      expect(session.secondsLeft.value, 0);
      expect(seen, [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
      expect(session.tap(1), isNull);
    });
  });

  test('a hold stops the clock until every hold is released', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())..start();
      async.elapse(const Duration(seconds: 3));

      session
        ..hold()
        ..hold();
      async.elapse(const Duration(minutes: 5));
      expect(session.secondsLeft.value, 7);

      session.release();
      async.elapse(const Duration(seconds: 1));
      expect(session.secondsLeft.value, 7);

      session.release();
      async.elapse(const Duration(seconds: 2));
      expect(session.secondsLeft.value, 5);
      expect(session.failure, isNull);
    });
  });

  test('a hold partway through a second picks up where it stopped', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())..start();
      async.elapse(const Duration(milliseconds: 3400));

      session.hold();
      async.elapse(const Duration(seconds: 5));
      expect(session.secondsLeft.value, 7);

      session.release();
      async.elapse(const Duration(milliseconds: 550));
      expect(session.secondsLeft.value, 7);

      async.elapse(const Duration(milliseconds: 100));
      expect(session.secondsLeft.value, 6);

      async.elapse(const Duration(milliseconds: 5900));
      expect(session.secondsLeft.value, 1);
      expect(session.failure, isNull);

      async.elapse(const Duration(milliseconds: 100));
      expect(session.failure, Failure.outOfTime);
      expect(session.secondsLeft.value, 0);
    });
  });

  test('clearing the board stops the clock', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())..start();
      async.elapse(const Duration(seconds: 4));

      session
        ..tap(1)
        ..tap(0);
      async.elapse(const Duration(seconds: 30));

      expect(session.isCleared, isTrue);
      expect(session.isRunning, isFalse);
      expect(session.failure, isNull);
      expect(session.elapsed, const Duration(seconds: 4));
    });
  });

  test('extra time goes on before the first move, once', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())..start();

      expect(session.addTime(const Duration(seconds: 5)), isTrue);
      expect(session.secondsLeft.value, 15);
      expect(session.canAddTime, isFalse);
      expect(session.addTime(const Duration(seconds: 5)), isFalse);

      async.elapse(const Duration(seconds: 12));
      expect(session.failure, isNull);
      expect(session.secondsLeft.value, 3);

      final moved = sessionFor(puzzle())..tap(1);
      expect(moved.canAddTime, isFalse);
      expect(moved.addTime(const Duration(seconds: 5)), isFalse);
    });
  });

  test('extra time partway through a second keeps the ticks in step', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())..start();
      async.elapse(const Duration(milliseconds: 2300));

      expect(session.addTime(const Duration(seconds: 5)), isTrue);
      expect(session.secondsLeft.value, 13);

      async.elapse(const Duration(milliseconds: 650));
      expect(session.secondsLeft.value, 13);

      async.elapse(const Duration(milliseconds: 100));
      expect(session.secondsLeft.value, 12);

      async.elapse(const Duration(milliseconds: 11900));
      expect(session.secondsLeft.value, 1);
      expect(session.failure, isNull);

      async.elapse(const Duration(milliseconds: 100));
      expect(session.failure, Failure.outOfTime);
    });
  });

  test('restart brings back the board, the stars and a full clock', () {
    fakeAsync((async) {
      final session = sessionFor(puzzle())
        ..start()
        ..tap(0)
        ..tap(1)
        ..revealHint();
      async.elapse(const Duration(seconds: 6));

      session.restart();

      expect(session.blocksLeft, 2);
      expect(session.stars, 3);
      expect(session.hasActiveHint, isFalse);
      expect(session.secondsLeft.value, 10);
      expect(session.isRunning, isFalse);
      expect(session.canAddTime, isTrue);
    });
  });

  test('hint points at a plain block that can leave', () {
    final session = sessionFor((
      board: Board(
        size: 3,
        blocks: [
          const Block(
            id: 0,
            row: 0,
            column: 0,
            length: 1,
            direction: Direction.up,
            turns: true,
          ),
          block(1, 1, 2, 1, Direction.right),
        ],
      ),
      timeLimit: tenSeconds,
    ));

    final hinted = session.revealHint();

    expect(hinted?.id, 1);
    session.tap(1);
    expect(session.hasActiveHint, isFalse);
  });

  test('a turning block loses its hint once it turns into a wall', () {
    Block turner(int id, int row, int column, Direction facing) => Block(
      id: id,
      row: row,
      column: column,
      length: 1,
      direction: facing,
      turns: true,
    );
    final session = sessionFor((
      board: Board(
        size: 3,
        blocks: [
          turner(0, 0, 0, Direction.up),
          turner(1, 2, 2, Direction.down),
          block(2, 0, 1, 1, Direction.left),
        ],
      ),
      timeLimit: tenSeconds,
    ));
    expect(session.revealHint()?.id, 0);

    session.tap(1);

    expect(session.board.blockById(0).direction, Direction.right);
    expect(session.hasActiveHint, isFalse);
  });

  test('streak counts blocks that leave in a row and resets on a bump', () {
    final session = sessionFor((
      board: Board(
        size: 3,
        blocks: [
          block(0, 0, 0, 1, Direction.up),
          block(1, 1, 0, 1, Direction.right),
          block(2, 1, 2, 1, Direction.right),
        ],
      ),
      timeLimit: tenSeconds,
    ));

    session.tap(0);
    expect(session.streak, 1);

    session.tap(1);
    expect(session.streak, 0);

    session
      ..tap(2)
      ..tap(1);
    expect(session.streak, 2);

    session.restart();
    expect(session.streak, 0);
  });
}
