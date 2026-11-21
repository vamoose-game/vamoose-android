import 'cell.dart';
import 'direction.dart';

class Block {
  const Block({
    required this.id,
    required this.row,
    required this.column,
    required this.length,
    required this.direction,
    this.turns = false,
  }) : assert(!turns || length == 1, 'Only 1×1 blocks can turn');

  final int id;
  final int row;
  final int column;
  final int length;
  final Direction direction;

  /// A turning block is round and 1×1. It turns a quarter clockwise every
  /// time another block leaves the board.
  final bool turns;

  bool get isVertical => direction.isVertical;

  List<Cell> get cells => [
    for (var offset = 0; offset < length; offset++)
      isVertical
          ? (row: row + offset, column: column)
          : (row: row, column: column + offset),
  ];

  Cell get front => switch (direction) {
    Direction.up || Direction.left => (row: row, column: column),
    Direction.down => (row: row + length - 1, column: column),
    Direction.right => (row: row, column: column + length - 1),
  };

  /// Cells from the front of the block to the edge of a [size] board.
  int travelWithin(int size) => switch (direction) {
    Direction.up => front.row,
    Direction.down => size - 1 - front.row,
    Direction.left => front.column,
    Direction.right => size - 1 - front.column,
  };

  List<Cell> pathWithin(int size) {
    final path = <Cell>[];
    var cell = front.step(direction);
    while (cell.isInside(size)) {
      path.add(cell);
      cell = cell.step(direction);
    }
    return path;
  }

  /// This block a quarter turn on if it turns, else this block.
  Block turned() => turns ? copyWith(direction: direction.clockwise) : this;

  Block copyWith({Direction? direction, bool? turns}) => Block(
    id: id,
    row: row,
    column: column,
    length: length,
    direction: direction ?? this.direction,
    turns: turns ?? this.turns,
  );
}
