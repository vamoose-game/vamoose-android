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
              !locked.turns &&
              !key.turns &&
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
      holdsBack(board, Lock(blockId: locked.id, keyId: key.id)) &&
      board.isSolvable;

  /// Whether [lock] holds its block back in play: with every block but the
  /// key played, one legal move after another, the locked block's path is
  /// clear once nothing else can go, so only the lock stops it.
  static bool holdsBack(Board board, Lock lock) {
    var current = board;
    while (true) {
      final free = [
        for (final block in current.movableBlocks)
          if (block.id != lock.keyId) block.id,
      ];
      if (free.isEmpty) {
        return current.blockerOf(current.blockById(lock.blockId)) == null;
      }
      current = _playAll(current, free, (_) {});
    }
  }

  /// How many rounds of moves each block waits before it can go.
  Map<int, int> _depthsOf(Board board) {
    final depths = <int, int>{};
    var current = board;
    for (var depth = 0; !current.isCleared; depth++) {
      final free = [for (final block in current.movableBlocks) block.id];
      if (free.isEmpty) {
        break;
      }
      current = _playAll(current, free, (id) => depths[id] = depth);
    }
    return depths;
  }

  /// Moves the blocks in [ids] off one by one, skipping any that a turning
  /// block has turned into a wall by its turn, or that left with its twin,
  /// so every move is one a player could make. The first always goes, so
  /// each round makes progress.
  static Board _playAll(
    Board board,
    List<int> ids,
    void Function(int id) moved,
  ) {
    var current = board;
    for (final id in ids) {
      if (current.contains(id) && current.canLeave(current.blockById(id))) {
        moved(id);
        current = current.without(id);
      }
    }
    return current;
  }
}
