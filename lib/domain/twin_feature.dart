import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'cell.dart';
import 'ice_feature.dart';
import 'level_feature.dart';
import 'level_spec.dart';

/// Chains [LevelSpec.twins] pairs of blocks together.
///
/// Twins are plain blocks (no lock, key, turn, ice or countdown). Neither
/// waits on the other, even through other blocks, and their ways never
/// cross, so they can always leave side by side. A pair is best when its
/// twins free up at different times, so one sits ready while the other is
/// still blocked, and when they are apart, so both ways need a look. Every
/// pair keeps the board clearable in any order and every lock fair.
class TwinFeature implements LevelFeature {
  const TwinFeature();

  @override
  Board? addTo(Board board, LevelSpec spec, Random random) {
    Board? current = board;
    for (var added = 0; added < spec.twins && current != null; added++) {
      current = _pairOne(current, random);
    }
    return current;
  }

  Board? _pairOne(Board board, Random random) {
    final singles = [
      for (final block in board.blocks)
        if (_canPair(board, block)) block,
    ];
    final rounds = _roundsOf(board);
    final waits = {for (final block in singles) block.id: board.waitsOn(block)};
    final paths = {
      for (final block in singles) block.id: _pathAndCells(board, block),
    };
    final pairs = [
      for (var a = 0; a < singles.length; a++)
        for (var b = a + 1; b < singles.length; b++)
          if (_apart(singles[a], singles[b], waits, paths))
            (
              first: singles[a],
              second: singles[b],
              interest: _interest(singles[a], singles[b], rounds),
            ),
    ]..shuffle(random);
    pairs.sort((x, y) => y.interest - x.interest);
    for (final pair in pairs.take(60)) {
      final trial = board.twinnedBy([
        (first: pair.first.id, second: pair.second.id),
      ]);
      if (IceFeature.fair(trial)) {
        return trial;
      }
    }
    return null;
  }

  static bool _canPair(Board board, Block block) =>
      !block.turns &&
      !block.isFrozen &&
      !block.hasCountdown &&
      board.twinOf(block) == null &&
      !board.restraints.any(
        (restraint) =>
            restraint.blockId == block.id || restraint.holderId == block.id,
      );

  /// Whether neither waits on the other and their ways, and the cells they
  /// leave from, never meet.
  static bool _apart(
    Block a,
    Block b,
    Map<int, Set<int>> waits,
    Map<int, Set<Cell>> paths,
  ) =>
      !waits[a.id]!.contains(b.id) &&
      !waits[b.id]!.contains(a.id) &&
      paths[a.id]!.intersection(paths[b.id]!).isEmpty;

  static Set<Cell> _pathAndCells(Board board, Block block) => {
    ...block.cells,
    ...block.pathWithin(board.size),
  };

  static int _interest(Block a, Block b, Map<int, int> rounds) {
    final apart = (a.row - b.row).abs() + (a.column - b.column).abs() >= 3
        ? 1
        : 0;
    final first = rounds[a.id] ?? 0;
    final second = rounds[b.id] ?? 0;
    return (first != second ? 3 : 0) +
        (first > 0 && second > 0 ? 1 : 0) +
        apart;
  }

  /// How many rounds of moves each block waits before it can go, playing
  /// every block that can go in each round.
  static Map<int, int> _roundsOf(Board board) {
    final rounds = <int, int>{};
    var current = board;
    for (var round = 0; !current.isCleared; round++) {
      final free = [for (final block in current.movableBlocks) block.id];
      if (free.isEmpty) {
        break;
      }
      for (final id in free) {
        if (current.contains(id) && current.canLeave(current.blockById(id))) {
          rounds[id] = round;
          current = current.without(id);
        }
      }
    }
    return rounds;
  }
}
