import 'dart:math';

import '../core/calendar_day.dart';
import 'level.dart';
import 'level_generator.dart';
import 'level_spec.dart';
import 'pace/pace_model.dart';
import 'pace/player.dart';

/// One new board a day, the same for everyone, timed for its own layout.
class DailyPuzzle {
  DailyPuzzle({
    this._generator = const LevelGenerator(),
    this._pace = const PaceModel(),
  });

  static const LevelSpec spec = LevelSpec(size: 6, blockCount: 16, twist: 0.4);

  /// The timer lets at least [targetPass] of players with [experience]
  /// levels behind them clear today's board on the first try, and
  /// [threeTries] of them within three tries. Anyone can play it from day
  /// one, so it is timed for a new player.
  static const double targetPass = 0.6;
  static const double threeTries = 0.9;
  static const int experience = 0;

  /// The clock is set on a sample of simulated players, so it aims this much
  /// above [targetPass] to hold for everyone and not just the sample.
  static const double sampleMargin = 0.03;
  static const int _crowdSize = 160;
  static const int _fewestSeconds = 10;

  static final List<Player> _crowd = Crowd.sample(_crowdSize, Random(7));

  final LevelGenerator _generator;
  final PaceModel _pace;
  (String, Puzzle)? _today;

  Puzzle puzzleFor(DateTime day) {
    final key = day.dayKey;
    if (_today case (final cached, final puzzle) when cached == key) {
      return puzzle;
    }
    final puzzle = _make(day.year * 10000 + day.month * 100 + day.day);
    _today = (key, puzzle);
    return puzzle;
  }

  Puzzle _make(int seed) {
    final board = _generator.generate(spec, Random(seed));
    final seconds = _pace.fairLimit(
      board,
      _crowd,
      experience: experience,
      share: targetPass + sampleMargin,
      withinThreeTries: threeTries,
      from: _fewestSeconds,
      seed: seed,
    );
    return (board: board, timeLimit: Duration(seconds: seconds));
  }
}
