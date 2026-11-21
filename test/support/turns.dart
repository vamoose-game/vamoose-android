import 'package:vamoose/domain/board.dart';

/// Exhaustively plays every order of moves and reports whether any position
/// the player can reach leaves no block able to go. Only for small boards.
bool hasReachableDeadEnd(Board board) {
  final seen = <String>{};
  bool explore(Board current) {
    if (current.isCleared) {
      return false;
    }
    final key = (current.blocks.map((block) => block.id).toList()..sort()).join(
      ',',
    );
    if (!seen.add(key)) {
      return false;
    }
    final free = current.movableBlocks.toList();
    if (free.isEmpty) {
      return true;
    }
    return free.any((block) => explore(current.without(block.id)));
  }

  return explore(board);
}
