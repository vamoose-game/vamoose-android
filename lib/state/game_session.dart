import 'package:flutter/foundation.dart';

import '../domain/block.dart';
import '../domain/board.dart';
import '../domain/star_rating.dart';
import '../domain/tap_outcome.dart';

class GameSession extends ChangeNotifier {
  GameSession(Board board, {Stopwatch? stopwatch})
    : _initial = board,
      _board = board,
      _stopwatch = stopwatch ?? Stopwatch() {
    _stopwatch.start();
  }

  final Board _initial;
  final Stopwatch _stopwatch;
  Board _board;
  int _bumps = 0;
  int? _hintedBlockId;

  Board get board => _board;

  int get bumps => _bumps;

  int get stars => StarRating.forBumps(_bumps);

  int get totalBlocks => _initial.blockCount;

  int get blocksLeft => _board.blockCount;

  bool get isCleared => _board.isCleared;

  Duration get elapsed => _stopwatch.elapsed;

  int? get hintedBlockId => _hintedBlockId;

  bool get hasActiveHint => _hintedBlockId != null;

  TapOutcome tap(int blockId) {
    final outcome = _board.tap(blockId);
    switch (outcome) {
      case BlockLeaves():
        _board = _board.without(blockId);
        if (_hintedBlockId == blockId) {
          _hintedBlockId = null;
        }
        if (_board.isCleared) {
          _stopwatch.stop();
        }
      case BlockBumps():
        _bumps++;
    }
    notifyListeners();
    return outcome;
  }

  Block? revealHint() {
    final block = _board.movableBlocks.firstOrNull;
    _hintedBlockId = block?.id;
    notifyListeners();
    return block;
  }

  void restart() {
    _board = _initial;
    _bumps = 0;
    _hintedBlockId = null;
    _stopwatch
      ..reset()
      ..start();
    notifyListeners();
  }

  void pause() => _stopwatch.stop();

  void resume() {
    if (!isCleared) {
      _stopwatch.start();
    }
  }
}
