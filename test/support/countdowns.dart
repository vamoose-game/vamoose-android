import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/tap_outcome.dart';

/// Tries every order of moves and says whether one gets every countdown
/// block out in time. Only for small boards.
bool canSaveAllByTrying(Board board) {
  final tried = <String>{};
  bool explore(Board current) {
    if (!current.hasCountdowns) {
      return true;
    }
    final key = (current.blocks.map((block) => block.id).toList()..sort()).join(
      ',',
    );
    if (!tried.add(key)) {
      return false;
    }
    for (final block in current.movableBlocks) {
      final outcome = current.tap(block.id) as BlockLeaves;
      if (outcome.runOuts.isEmpty && explore(current.without(block.id))) {
        return true;
      }
    }
    return false;
  }

  return explore(board);
}

/// Plays as a player who always works on the countdown block with the
/// fewest moves left: they move a block in its way that can go, or the
/// countdown block itself. Says whether no countdown block ran out.
bool mostUrgentFirstSaves(Board board) {
  var current = board;
  while (current.hasCountdowns) {
    final counting = current.blocks.where((block) => block.hasCountdown);
    final urgent = counting.reduce((a, b) => b.count! < a.count! ? b : a);
    final next = [
      ...current.waitsOn(urgent).map(current.blockById),
      urgent,
    ].firstWhere(current.canLeave);
    final outcome = current.tap(next.id) as BlockLeaves;
    if (outcome.runOuts.isNotEmpty) {
      return false;
    }
    current = current.without(next.id);
  }
  return true;
}
