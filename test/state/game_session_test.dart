import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/tap_outcome.dart';
import 'package:vamoose/state/game_session.dart';

import '../support/boards.dart';

void main() {
  Board board() => Board(
    size: 3,
    blocks: [
      block(0, 1, 0, 1, Direction.right),
      block(1, 0, 2, 3, Direction.down),
    ],
  );

  test('a leaving block is removed', () {
    final session = GameSession(board());

    final outcome = session.tap(1);

    expect(outcome, isA<BlockLeaves>());
    expect(session.blocksLeft, 1);
    expect(session.totalBlocks, 2);
    expect(session.bumps, 0);
  });

  test('a bump counts and lowers the stars', () {
    final session = GameSession(board());

    final outcome = session.tap(0);

    expect(outcome, isA<BlockBumps>());
    expect(session.blocksLeft, 2);
    expect(session.bumps, 1);
    expect(session.stars, 2);
  });

  test('clearing the board stops the clock', () {
    final stopwatch = Stopwatch();
    final session = GameSession(board(), stopwatch: stopwatch);

    session
      ..tap(1)
      ..tap(0);

    expect(session.isCleared, isTrue);
    expect(stopwatch.isRunning, isFalse);
  });

  test('hint points at a block that can leave', () {
    final session = GameSession(board());

    final hinted = session.revealHint();

    expect(hinted?.id, 1);
    expect(session.hintedBlockId, 1);
    session.tap(1);
    expect(session.hasActiveHint, isFalse);
  });

  test('restart brings back the starting board', () {
    final session = GameSession(board())
      ..tap(0)
      ..tap(1)
      ..revealHint();

    session.restart();

    expect(session.blocksLeft, 2);
    expect(session.bumps, 0);
    expect(session.hasActiveHint, isFalse);
  });

  test('pause and resume control the clock', () {
    final stopwatch = Stopwatch();
    final session = GameSession(board(), stopwatch: stopwatch);

    session.pause();
    expect(stopwatch.isRunning, isFalse);

    session.resume();
    expect(stopwatch.isRunning, isTrue);
  });

  test('streak counts blocks that leave in a row and resets on a bump', () {
    final session = GameSession(
      Board(
        size: 3,
        blocks: [
          block(0, 0, 0, 1, Direction.up),
          block(1, 1, 0, 1, Direction.right),
          block(2, 1, 2, 1, Direction.right),
        ],
      ),
    );

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
