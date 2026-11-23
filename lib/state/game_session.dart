import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/block.dart';
import '../domain/board.dart';
import '../domain/countdowns.dart';
import '../domain/level.dart';
import '../domain/star_rating.dart';
import '../domain/tap_outcome.dart';

enum Failure { outOfStars, outOfTime }

/// One go at a puzzle: the board as it stands, misses, stars and the clock.
///
/// A miss is a bump or a countdown block that runs out; each costs a star.
/// The clock counts down from the puzzle's time limit once [start] is
/// called, and only while nothing [hold]s it (a dialog, the app in the
/// background). Losing the last star or running out of time ends the go.
///
/// The clock is a [Stopwatch] from [stopwatch]; tests pass one that runs
/// on fake time.
class GameSession extends ChangeNotifier {
  GameSession(Puzzle puzzle, {Stopwatch Function() stopwatch = Stopwatch.new})
    : _initial = puzzle.board,
      _board = puzzle.board,
      timeLimit = puzzle.timeLimit,
      _watch = stopwatch(),
      _secondsLeft = ValueNotifier(_wholeSeconds(puzzle.timeLimit));

  final Board _initial;
  final Duration timeLimit;
  final Stopwatch _watch;
  final ValueNotifier<int> _secondsLeft;
  Board _board;
  int _bumps = 0;
  int _runOuts = 0;
  int _streak = 0;
  int? _hintedBlockId;
  Duration _bonus = Duration.zero;
  bool _started = false;
  bool _moved = false;
  int _holds = 0;
  Failure? _failure;
  Timer? _tick;

  Board get board => _board;

  int get bumps => _bumps;

  /// Countdown blocks that ran out on the board.
  int get runOuts => _runOuts;

  int get streak => _streak;

  int get stars => StarRating.forMisses(_bumps + _runOuts);

  int get totalBlocks => _initial.blockCount;

  int get blocksLeft => _board.blockCount;

  bool get isCleared => _board.isCleared;

  Failure? get failure => _failure;

  bool get isOver => isCleared || _failure != null;

  bool get hasMoved => _moved;

  bool get isRunning => _watch.isRunning;

  Duration get elapsed => _watch.elapsed;

  Duration get bonus => _bonus;

  Duration get remaining {
    final left = timeLimit + _bonus - _watch.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Whole seconds left, rounded up; changes once a second while running.
  ValueListenable<int> get secondsLeft => _secondsLeft;

  int? get hintedBlockId => _hintedBlockId;

  bool get hasActiveHint => _hintedBlockId != null;

  /// Extra time goes on before the first move, once per go.
  bool get canAddTime => !_moved && _bonus == Duration.zero && !isOver;

  /// Starts the clock, for example once the blocks have landed.
  void start() {
    _started = true;
    _sync();
  }

  void hold() {
    _holds++;
    _sync();
  }

  void release() {
    if (_holds > 0) {
      _holds--;
      _sync();
    }
  }

  TapOutcome? tap(int blockId) {
    if (isOver || !_board.contains(blockId)) {
      return null;
    }
    _moved = true;
    final outcome = _board.tap(blockId);
    switch (outcome) {
      case BlockLeaves(:final runOuts):
        _board = _board.without(blockId);
        _runOuts += runOuts.length;
        _streak = runOuts.isEmpty ? _streak + 1 : 0;
        _dropStaleHint();
      case BlockBumps():
        _bumps++;
        _streak = 0;
    }
    if (stars == 0) {
      _failure = Failure.outOfStars;
    }
    _sync();
    notifyListeners();
    return outcome;
  }

  bool addTime(Duration extra) {
    if (!canAddTime) {
      return false;
    }
    _bonus = extra;
    _showSeconds();
    _schedule();
    notifyListeners();
    return true;
  }

  /// Lights up a block that can go now: the first in the way of the most
  /// urgent countdown block, or else a plain one if there is one, since a
  /// turning block may face away again after the next move.
  Block? revealHint() {
    final free = _board.movableBlocks.toList();
    final block =
        Countdowns.nextMove(_board) ??
        free.where((block) => !block.turns).firstOrNull ??
        free.firstOrNull;
    _hintedBlockId = block?.id;
    notifyListeners();
    return block;
  }

  void restart() {
    _board = _initial;
    _bumps = 0;
    _runOuts = 0;
    _streak = 0;
    _hintedBlockId = null;
    _bonus = Duration.zero;
    _started = false;
    _moved = false;
    _failure = null;
    _tick?.cancel();
    _watch
      ..stop()
      ..reset();
    _showSeconds();
    notifyListeners();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _watch.stop();
    _secondsLeft.dispose();
    super.dispose();
  }

  void _dropStaleHint() {
    final hinted = _hintedBlockId;
    if (hinted != null &&
        (!_board.contains(hinted) ||
            !_board.canLeave(_board.blockById(hinted)))) {
      _hintedBlockId = null;
    }
  }

  void _sync() {
    final run = _started && _holds == 0 && !isOver;
    if (run && !_watch.isRunning) {
      _watch.start();
      _schedule();
    } else if (!run && _watch.isRunning) {
      _watch.stop();
      _tick?.cancel();
      _showSeconds();
    }
  }

  void _schedule() {
    _tick?.cancel();
    if (!_watch.isRunning) {
      return;
    }
    final left = remaining.inMicroseconds;
    if (left <= 0) {
      _timeOut();
      return;
    }
    final partial = left % Duration.microsecondsPerSecond;
    _tick = Timer(
      Duration(
        microseconds: partial == 0 ? Duration.microsecondsPerSecond : partial,
      ),
      () {
        _showSeconds();
        _schedule();
      },
    );
  }

  void _timeOut() {
    _failure = Failure.outOfTime;
    _watch.stop();
    _secondsLeft.value = 0;
    notifyListeners();
  }

  void _showSeconds() => _secondsLeft.value = _wholeSeconds(remaining);

  static int _wholeSeconds(Duration duration) =>
      (duration.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
      Duration.microsecondsPerSecond;
}
