import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'direction.dart';
import 'level_feature.dart';
import 'level_spec.dart';

/// Turns some 1×1 blocks into turning blocks.
///
/// A good turning block stands in the way of other blocks and starts facing
/// a blocked path, so the player has to time it. Every pick keeps the board
/// clearable in any order ([Board.isSolvable]).
class TurnFeature implements LevelFeature {
  const TurnFeature();

  @override
  Board? addTo(Board board, LevelSpec spec, Random random) {
    Board? current = board;
    for (var added = 0; added < spec.turners && current != null; added++) {
      current = _addOne(current, random);
    }
    return current;
  }

  Board? _addOne(Board board, Random random) {
    final candidates = [
      for (final block in board.blocks)
        if (block.length == 1 && !block.turns && !_restrained(board, block))
          (block: block, interest: _interest(board, block)),
    ]..shuffle(random);
    candidates.sort((a, b) => b.interest - a.interest);
    for (final (:block, interest: _) in candidates) {
      final facings = [...Direction.values]..shuffle(random);
      facings.sort(
        (a, b) => _openness(board, block, a) - _openness(board, block, b),
      );
      for (final facing in facings) {
        final trial = board.turning({block.id: facing});
        if (trial.isSolvable) {
          return trial;
        }
      }
    }
    return null;
  }

  bool _restrained(Board board, Block block) => board.restraints.any(
    (restraint) =>
        restraint.blockId == block.id || restraint.holderId == block.id,
  );

  /// Blocks that wait on [block], plus how few ways out it has at the start.
  int _interest(Board board, Block block) {
    final waiting = board.blocks
        .where((other) => board.blockerOf(other)?.id == block.id)
        .length;
    final closed = Direction.values
        .where((facing) => _openness(board, block, facing) == 0)
        .length;
    return 3 * min(waiting, 2).toInt() + closed;
  }

  int _openness(Board board, Block block, Direction facing) =>
      board.blockerOf(block.copyWith(direction: facing)) == null ? 1 : 0;
}
