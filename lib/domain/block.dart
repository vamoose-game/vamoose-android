import 'cell.dart';
import 'direction.dart';

class Block {
  const Block({
    required this.id,
    required this.row,
    required this.column,
    required this.length,
    required this.direction,
  });

  final int id;
  final int row;
  final int column;
  final int length;
  final Direction direction;

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

  List<Cell> pathWithin(int size) {
    final path = <Cell>[];
    var cell = front.step(direction);
    while (cell.isInside(size)) {
      path.add(cell);
      cell = cell.step(direction);
    }
    return path;
  }
}
