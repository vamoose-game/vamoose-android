import 'block.dart';
import 'board.dart';

/// The order of moves that saves countdown blocks.
///
/// A countdown block must leave while its number shows 1 or more: with
/// count n it has to go as one of the next n moves. It can only go once
/// every block it waits on has gone ([Board.waitsOn]), so saving it costs
/// those moves first. Removing a block only ever frees space, so while no
/// countdown block waits on a turning block, any other move just wastes
/// one: the best order is a schedule of the countdown blocks and what they
/// wait on, one move each, each block after the ones it waits on.
///
/// Lawler's rule finds it: fill the last move first, each time with a block
/// that nothing left to place waits on, and of those the one that can go
/// latest. No order gets the latest countdown block out earlier, so every
/// countdown block can be saved exactly when this order saves them all.
abstract final class Countdowns {
  /// Whether some order of moves gets every countdown block on [board] out
  /// in time.
  static bool canSaveAll(Board board) => plan(board).lost.isEmpty;

  /// The block to move now to save the most countdown blocks: the first in
  /// the way of the most urgent one, or that block itself. Null when there
  /// is no countdown block left to save.
  static Block? nextMove(Board board) {
    final order = plan(board).order;
    return order.isEmpty ? null : board.blockById(order.first);
  }

  /// The moves that save the most countdown blocks on [board], in order,
  /// and the countdown blocks that no order saves. When some must be lost,
  /// the one that would be latest is given up, from then on planned as a
  /// block without a countdown, and the rest planned again.
  static CountdownPlan plan(Board board) {
    final deadlines = {
      for (final block in board.blocks) block.id: ?block.count,
    };
    final lost = <int>[];
    while (deadlines.isNotEmpty) {
      final order = _schedule(board, deadlines);
      if (order == null) {
        return CountdownPlan(
          order: const [],
          lost: [...lost, ...deadlines.keys],
        );
      }
      int? latest;
      var lateness = 0;
      for (var move = 0; move < order.length; move++) {
        final late = move + 1 - (deadlines[order[move]] ?? move + 1);
        if (late > lateness) {
          latest = order[move];
          lateness = late;
        }
      }
      if (latest == null) {
        return CountdownPlan(order: order, lost: lost);
      }
      lost.add(latest);
      deadlines.remove(latest);
    }
    return CountdownPlan(order: const [], lost: lost);
  }

  /// The order of the blocks with [deadlines] and every block they wait on
  /// that keeps the latest of them as early as possible (Lawler's rule), or
  /// null when the blocks wait on each other in a loop.
  static List<int>? _schedule(Board board, Map<int, int> deadlines) {
    final holders = <int, List<int>>{};
    final todo = [...deadlines.keys];
    while (todo.isNotEmpty) {
      final id = todo.removeLast();
      if (!holders.containsKey(id)) {
        final held = board.holdersOf(board.blockById(id)).toList();
        holders[id] = held;
        todo.addAll(held);
      }
    }
    final waiters = {for (final id in holders.keys) id: 0};
    for (final held in holders.values) {
      for (final id in held) {
        waiters[id] = waiters[id]! + 1;
      }
    }
    final order = List<int>.filled(holders.length, 0);
    final left = holders.keys.toSet();
    for (var move = holders.length - 1; move >= 0; move--) {
      int? last;
      for (final id in left) {
        if (waiters[id] == 0 &&
            (last == null || _goesLater(deadlines, id, last))) {
          last = id;
        }
      }
      if (last == null) {
        return null;
      }
      left.remove(last);
      order[move] = last;
      for (final id in holders[last]!) {
        waiters[id] = waiters[id]! - 1;
      }
    }
    return order;
  }

  /// Whether block [a] can wait longer than block [b]: no deadline beats
  /// any deadline, a later one beats an earlier one, then the bigger id.
  static bool _goesLater(Map<int, int> deadlines, int a, int b) {
    final deadlineA = deadlines[a];
    final deadlineB = deadlines[b];
    if (deadlineA != deadlineB) {
      return deadlineA == null || (deadlineB != null && deadlineA > deadlineB);
    }
    return a > b;
  }
}

/// Moves that save countdown blocks: [order] is the countdown blocks to save
/// and every block they wait on, in the order to move them; [lost] is the
/// countdown blocks that no order saves.
final class CountdownPlan {
  const CountdownPlan({required this.order, required this.lost});

  final List<int> order;
  final List<int> lost;
}
