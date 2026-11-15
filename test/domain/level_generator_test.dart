import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';

void main() {
  const generator = LevelGenerator();

  void expectWellFormed(Board board) {
    final cells = [for (final block in board.blocks) ...block.cells];
    expect(cells.toSet(), hasLength(cells.length), reason: 'blocks overlap');
    for (final cell in cells) {
      expect(cell.row, inInclusiveRange(0, board.size - 1));
      expect(cell.column, inInclusiveRange(0, board.size - 1));
    }
    for (final block in board.blocks) {
      expect(block.length, inInclusiveRange(1, 3));
    }
  }

  test('builds solvable boards with the requested block count', () {
    for (final size in [4, 5, 6, 7, 8]) {
      for (var seed = 0; seed < 25; seed++) {
        final count = 3 + seed % (size * size - 3);
        final board = generator.generate(
          LevelSpec(size: size, blockCount: count, twist: seed / 25),
          Random(seed),
        );

        expect(board.size, size);
        expect(board.blockCount, count);
        expectWellFormed(board);
        expect(board.isSolvable, isTrue, reason: 'size $size seed $seed');
      }
    }
  });

  test('same seed builds the same board', () {
    const spec = LevelSpec(size: 6, blockCount: 18, twist: 0.4);

    final first = generator.generate(spec, Random(41));
    final second = generator.generate(spec, Random(41));

    expect(LevelCodec.encode([first]), LevelCodec.encode([second]));
  });

  test('rejects impossible block counts', () {
    expect(
      () => generator.generate(
        const LevelSpec(size: 3, blockCount: 10),
        Random(1),
      ),
      throwsArgumentError,
    );
    expect(
      () => generator.generate(
        const LevelSpec(size: 3, blockCount: 0),
        Random(1),
      ),
      throwsArgumentError,
    );
  });

  test('codec round trips a board', () {
    final board = generator.generate(
      const LevelSpec(size: 5, blockCount: 12),
      Random(3),
    );

    final decoded = LevelCodec.decode(LevelCodec.encode([board])).single;

    expect(decoded.number, 1);
    expect(LevelCodec.encode([decoded.board]), LevelCodec.encode([board]));
  });
}
