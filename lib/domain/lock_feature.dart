import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'level_feature.dart';
import 'level_spec.dart';
import 'restraint.dart';

class LockFeature implements LevelFeature {
  const LockFeature();

  @override
  Board? addTo(Board board, LevelSpec spec, Random random) {
    Board? current = board;
    for (var pair = 0; pair < spec.locks && current != null; pair++) {
      current = _addPair(current, spec, random);
    }
    return current;
  }

  Board? _addPair(Board board, LevelSpec spec, Random random) {
    final paired = {
      for (final restraint in board.restraints)
        if (restraint case Lock(:final blockId, :final keyId)) ...[
          blockId,
          keyId,
        ],
    };
    final depths = _depthsOf(board);
    final candidates = [
      for (final locked in board.blocks)
        for (final key in board.blocks)
          if (locked.id != key.id &&
              !paired.contains(locked.id) &&
              !paired.contains(key.id))
            (locked: locked, key: key),
    ]..shuffle(random);
    for (var rank = 0; rank < 4; rank++) {
      for (final candidate in candidates) {
        if (_rank(board, candidate.locked, candidate.key, depths, spec) !=
            rank) {
          continue;
        }
        final trial = board.restrainedBy([
          Lock(blockId: candidate.locked.id, keyId: candidate.key.id),
        ]);
        if (_fits(trial, candidate.locked, candidate.key)) {
          return trial;
        }
      }
    }
    return null;
  }

  int _rank(
    Board board,
    Block locked,
    Block key,
    Map<int, int> depths,
    LevelSpec spec,
  ) =>
      (board.canLeave(locked) ? 0 : 2) +
      ((depths[key.id] ?? 0) >= spec.keyDepth ? 0 : 1);

  bool _fits(Board board, Block locked, Block key) =>
      board.blockerOf(key) != null &&
      _holdsBack(board, locked, key) &&
      board.isSolvable;

  bool _holdsBack(Board board, Block locked, Block key) {
    var current = board;
    while (true) {
      final free = current.movableBlocks
          .where((block) => block.id != key.id)
          .toList();
      if (free.isEmpty) {
        return current.blockerOf(locked) == null;
      }
      for (final block in free) {
        current = current.without(block.id);
      }
    }
  }

  Map<int, int> _depthsOf(Board board) {
    final depths = <int, int>{};
    var current = board;
    for (var depth = 0; !current.isCleared; depth++) {
      final free = current.movableBlocks.toList();
      if (free.isEmpty) {
        break;
      }
      for (final block in free) {
        depths[block.id] = depth;
        current = current.without(block.id);
      }
    }
    return depths;
  }
}
