import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'level_feature.dart';
import 'level_spec.dart';
import 'lock_feature.dart';
import 'restraint.dart';

/// Freezes [LevelSpec.frozen] blocks, [LevelSpec.thickIce] of them under
/// two layers of ice.
///
/// A frozen block is a plain block (no lock, key or turn) with at least as
/// many neighbours as layers of ice, so it can always thaw. Ice is put
/// where it matters: on a block that could go at once, so tapping it is a
/// trap, or one that others wait on, so it holds them up. Every pick keeps
/// the board clearable in any order and every lock fair.
class IceFeature implements LevelFeature {
  const IceFeature();

  @override
  Board? addTo(Board board, LevelSpec spec, Random random) {
    Board? current = board;
    for (var added = 0; added < spec.frozen && current != null; added++) {
      current = _freezeOne(current, added < spec.thickIce ? 2 : 1, random);
    }
    return current;
  }

  Board? _freezeOne(Board board, int layers, Random random) {
    final candidates = [
      for (final block in board.blocks)
        if (_canFreeze(board, block, layers))
          (block: block, interest: _interest(board, block)),
    ]..shuffle(random);
    candidates.sort((a, b) => b.interest - a.interest);
    for (final (:block, interest: _) in candidates) {
      final trial = board.freezing({block.id: layers});
      if (fair(trial)) {
        return trial;
      }
    }
    return null;
  }

  static bool _canFreeze(Board board, Block block, int layers) =>
      !block.turns &&
      !block.isFrozen &&
      !block.hasCountdown &&
      board.twinOf(block) == null &&
      !board.restraints.any(
        (restraint) =>
            restraint.blockId == block.id || restraint.holderId == block.id,
      ) &&
      board.neighboursOf(block).length >= layers;

  /// A free block makes a trap; blocks waiting on it are held up.
  static int _interest(Board board, Block block) {
    final waiting = board.blocks
        .where((other) => board.blockerOf(other)?.id == block.id)
        .length;
    return (board.canLeave(block) ? 3 : 0) + min(waiting, 2).toInt();
  }

  /// Whether [board] clears in any order and every lock on it still holds
  /// its block back in real play.
  static bool fair(Board board) =>
      board.isSolvable &&
      board.restraints.every(
        (restraint) => switch (restraint) {
          Lock() => LockFeature.holdsBack(board, restraint),
        },
      );
}
