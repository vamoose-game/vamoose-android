import 'dart:math';

import 'board.dart';
import 'level_generator.dart';
import 'level_spec.dart';

class DailyPuzzle {
  const DailyPuzzle({this._generator = const LevelGenerator()});

  static const LevelSpec spec = LevelSpec(size: 5, blockCount: 15, twist: 0.3);
  static const String difficulty = 'Relaxed';

  final LevelGenerator _generator;

  Board boardFor(DateTime day) => _generator.generate(
    spec,
    Random(day.year * 10000 + day.month * 100 + day.day),
  );
}
