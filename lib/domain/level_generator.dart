import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'cell.dart';
import 'direction.dart';
import 'level_feature.dart';
import 'level_spec.dart';
import 'lock_feature.dart';

class LevelGenerator {
  const LevelGenerator({this.features = const [LockFeature()]});

  static const List<int> _lengthWeights = [0, 2, 5, 3];
  static const int _attempts = 200;

  final List<LevelFeature> features;

  Board generate(LevelSpec spec, Random random) {
    final cellCount = spec.size * spec.size;
    if (spec.blockCount < 1 || spec.blockCount > cellCount) {
      throw ArgumentError.value(spec.blockCount, 'blockCount');
    }
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final tiles = _tile(spec.size, random);
      _fitCount(tiles, spec.blockCount, random);
      final board = _addFeatures(_orient(spec, tiles, random), spec, random);
      if (board != null) {
        return board;
      }
    }
    throw StateError('No board fits the level spec');
  }

  Board? _addFeatures(Board base, LevelSpec spec, Random random) {
    Board? board = base;
    for (final feature in features) {
      if (board == null) {
        return null;
      }
      board = feature.addTo(board, spec, random);
    }
    return board;
  }

  List<_Tile> _tile(int size, Random random) {
    final taken = <Cell>{};
    final tiles = <_Tile>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (taken.contains((row: row, column: column))) {
          continue;
        }
        final tile = _placeTile(row, column, size, taken, random);
        taken.addAll(tile.cells);
        tiles.add(tile);
      }
    }
    return tiles;
  }

  _Tile _placeTile(
    int row,
    int column,
    int size,
    Set<Cell> taken,
    Random random,
  ) {
    final preferVertical = random.nextBool();
    for (var length = _pickLength(random); length > 1; length--) {
      for (final vertical in [preferVertical, !preferVertical]) {
        final tile = _Tile(row, column, length, vertical: vertical);
        if (tile.cells.every(
          (cell) => cell.isInside(size) && !taken.contains(cell),
        )) {
          return tile;
        }
      }
    }
    return _Tile(row, column, 1, vertical: preferVertical);
  }

  int _pickLength(Random random) {
    final total = _lengthWeights.reduce((a, b) => a + b);
    var roll = random.nextInt(total);
    for (var length = 0; length < _lengthWeights.length; length++) {
      roll -= _lengthWeights[length];
      if (roll < 0) {
        return length;
      }
    }
    return 1;
  }

  void _fitCount(List<_Tile> tiles, int target, Random random) {
    while (tiles.length > target) {
      tiles.removeAt(random.nextInt(tiles.length));
    }
    while (tiles.length < target) {
      final splittable = tiles.where((tile) => tile.length > 1).toList();
      final tile = splittable[random.nextInt(splittable.length)];
      final cut = 1 + random.nextInt(tile.length - 1);
      tiles
        ..remove(tile)
        ..addAll(tile.splitAt(cut));
    }
  }

  Board _orient(LevelSpec spec, List<_Tile> tiles, Random random) {
    tiles.sort((a, b) => a.row != b.row ? a.row - b.row : a.column - b.column);
    final owner = <Cell, int>{
      for (var index = 0; index < tiles.length; index++)
        for (final cell in tiles[index].cells) cell: index,
    };
    final remaining = {
      for (var index = 0; index < tiles.length; index++) index,
    };
    final blocks = <Block>[];
    while (remaining.isNotEmpty) {
      final candidates = <_Candidate>[];
      for (final index in remaining) {
        for (final direction in tiles[index].directions) {
          final block = tiles[index].toBlock(index, direction);
          final crossed = <int>{};
          var free = true;
          for (final cell in block.pathWithin(spec.size)) {
            final hit = owner[cell];
            if (hit == null) {
              continue;
            }
            if (remaining.contains(hit)) {
              free = false;
              break;
            }
            crossed.add(hit);
          }
          if (free) {
            candidates.add(_Candidate(block, crossed.length));
          }
        }
      }
      final chosen = _choose(candidates, spec.twist, random);
      blocks.add(chosen.block);
      remaining.remove(chosen.block.id);
    }
    blocks.sort((a, b) => a.id - b.id);
    return Board(size: spec.size, blocks: blocks);
  }

  _Candidate _choose(List<_Candidate> candidates, double twist, Random random) {
    final directions = candidates
        .map((candidate) => candidate.block.direction)
        .toSet()
        .toList();
    final direction = directions[random.nextInt(directions.length)];
    final pool = candidates
        .where((candidate) => candidate.block.direction == direction)
        .toList();
    if (random.nextDouble() >= twist) {
      return pool[random.nextInt(pool.length)];
    }
    final most = pool.map((candidate) => candidate.crossed).reduce(max);
    final best = pool.where((candidate) => candidate.crossed == most).toList();
    return best[random.nextInt(best.length)];
  }
}

class _Tile {
  const _Tile(this.row, this.column, this.length, {required this.vertical});

  final int row;
  final int column;
  final int length;
  final bool vertical;

  List<Cell> get cells => [
    for (var offset = 0; offset < length; offset++)
      vertical
          ? (row: row + offset, column: column)
          : (row: row, column: column + offset),
  ];

  List<Direction> get directions {
    if (length == 1) {
      return Direction.values;
    }
    return vertical
        ? const [Direction.up, Direction.down]
        : const [Direction.left, Direction.right];
  }

  List<_Tile> splitAt(int cut) => [
    _Tile(row, column, cut, vertical: vertical),
    vertical
        ? _Tile(row + cut, column, length - cut, vertical: vertical)
        : _Tile(row, column + cut, length - cut, vertical: vertical),
  ];

  Block toBlock(int id, Direction direction) => Block(
    id: id,
    row: row,
    column: column,
    length: length,
    direction: direction,
  );
}

class _Candidate {
  const _Candidate(this.block, this.crossed);

  final Block block;
  final int crossed;
}
