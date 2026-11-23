import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/countdowns.dart';
import 'package:vamoose/domain/direction.dart';

Block block(int id, int row, int column, int length, Direction direction) =>
    Block(
      id: id,
      row: row,
      column: column,
      length: length,
      direction: direction,
    );

/// An order that clears [board] and saves every countdown block it can.
List<int> solutionOrder(Board board) {
  final order = <int>[];
  var current = board;
  while (!current.isCleared) {
    final next = Countdowns.nextMove(current) ?? current.movableBlocks.first;
    order.add(next.id);
    current = current.without(next.id);
  }
  return order;
}
