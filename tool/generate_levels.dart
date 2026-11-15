import 'dart:io';
import 'dart:math';

import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/chapter.dart';
import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';

const _recipes = [
  _Recipe(blocksFrom: 3, blocksTo: 14, twistFrom: 0, twistTo: 0.2),
  _Recipe(blocksFrom: 15, blocksTo: 19, twistFrom: 0.1, twistTo: 0.3),
  _Recipe(blocksFrom: 18, blocksTo: 22, twistFrom: 0.3, twistTo: 0.5),
  _Recipe(blocksFrom: 20, blocksTo: 24, twistFrom: 0.4, twistTo: 0.6),
  _Recipe(blocksFrom: 20, blocksTo: 28, twistFrom: 0.3, twistTo: 0.5),
  _Recipe(blocksFrom: 24, blocksTo: 30, twistFrom: 0.4, twistTo: 0.6),
  _Recipe(blocksFrom: 26, blocksTo: 32, twistFrom: 0.5, twistTo: 0.7),
  _Recipe(blocksFrom: 28, blocksTo: 34, twistFrom: 0.6, twistTo: 0.8),
  _Recipe(blocksFrom: 30, blocksTo: 38, twistFrom: 0.5, twistTo: 0.7),
  _Recipe(blocksFrom: 34, blocksTo: 42, twistFrom: 0.6, twistTo: 0.8),
  _Recipe(blocksFrom: 38, blocksTo: 46, twistFrom: 0.7, twistTo: 0.9),
  _Recipe(blocksFrom: 42, blocksTo: 50, twistFrom: 0.8, twistTo: 1),
];

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
  File('assets/levels/levels.json')
      .writeAsStringSync(LevelCodec.encode(boards));
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
    return LevelSpec(
      size: chapter.boardSize,
      blockCount: (blocksFrom + (blocksTo - blocksFrom) * progress).round(),
      twist: twistFrom + (twistTo - twistFrom) * progress,
    );
  }
}
