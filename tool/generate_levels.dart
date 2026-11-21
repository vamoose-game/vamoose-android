import 'dart:io';
import 'dart:math';

import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/chapter.dart';
import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';

const _recipes = [
  _Recipe(blocksFrom: 6, blocksTo: 19, twistFrom: 0.1, twistTo: 0.3),
  _Recipe(blocksFrom: 16, blocksTo: 21, twistFrom: 0.2, twistTo: 0.4),
  _Recipe(blocksFrom: 19, blocksTo: 23, twistFrom: 0.4, twistTo: 0.6),
  _Recipe(blocksFrom: 21, blocksTo: 25, twistFrom: 0.5, twistTo: 0.7),
  _Recipe(blocksFrom: 22, blocksTo: 27, twistFrom: 0.4, twistTo: 0.6),
  _Recipe(blocksFrom: 24, blocksTo: 29, twistFrom: 0.5, twistTo: 0.7),
  _Recipe(blocksFrom: 26, blocksTo: 31, twistFrom: 0.6, twistTo: 0.8),
  _Recipe(blocksFrom: 28, blocksTo: 33, twistFrom: 0.7, twistTo: 0.9),
  _Recipe(blocksFrom: 30, blocksTo: 36, twistFrom: 0.6, twistTo: 0.8),
  _Recipe(blocksFrom: 32, blocksTo: 38, twistFrom: 0.7, twistTo: 0.9),
  _Recipe(blocksFrom: 34, blocksTo: 40, twistFrom: 0.8, twistTo: 1),
  _Recipe(blocksFrom: 36, blocksTo: 42, twistFrom: 0.9, twistTo: 1),
];

const _lockLevels = [12, 76, 181];
const _restEvery = 5;

int _locksFor(int level) {
  final pairs = _lockLevels.where((first) => level >= first).length;
  return pairs > 0 && level % _restEvery == 0 ? pairs - 1 : pairs;
}

int _keyDepthFor(int level) => level < 61
    ? 1
    : level < 181
    ? 2
    : 3;

void main() {
  const generator = LevelGenerator();
  final boards = <Board>[
    for (final chapter in Chapters.all)
      for (var step = 0; step < Chapter.levelCount; step++)
        generator.generate(
          _recipes[chapter.index].specFor(chapter, step),
          Random(chapter.firstLevel + step),
        ),
  ];
  File('assets/levels/levels.json').writeAsStringSync(
    LevelCodec.encode([
      for (final (index, board) in boards.indexed)
        Level(
          number: index + 1,
          board: board,
          timeLimit: LevelCodec.defaultTimeLimit,
        ),
    ]),
  );
  stdout.writeln('Generated ${boards.length} levels');
}

class _Recipe {
  const _Recipe({
    required this.blocksFrom,
    required this.blocksTo,
    required this.twistFrom,
    required this.twistTo,
  });

  final int blocksFrom;
  final int blocksTo;
  final double twistFrom;
  final double twistTo;

  LevelSpec specFor(Chapter chapter, int step) {
    final progress = step / (Chapter.levelCount - 1);
    final level = chapter.firstLevel + step;
    return LevelSpec(
      size: chapter.boardSize,
      blockCount: (blocksFrom + (blocksTo - blocksFrom) * progress).round(),
      twist: twistFrom + (twistTo - twistFrom) * progress,
      locks: _locksFor(level),
      keyDepth: _keyDepthFor(level),
    );
  }
}
