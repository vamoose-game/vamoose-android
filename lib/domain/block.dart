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
    this.count,
    this.ice = 0,
    this.cracks = 0,
  }) : assert(!turns || length == 1, 'Only 1×1 blocks can turn'),
       assert(count == null || count > 0, 'A countdown shows 1 or more'),
       assert(ice >= 0, 'Ice has no fewer than 0 layers');

  final int id;
  final int row;
  final int column;
  final int length;
  final Direction direction;

  /// A turning block is round and 1×1. It turns a quarter clockwise every
  /// time another block leaves the board.
  final bool turns;

  /// The moves a countdown block has left: every other block that leaves
  /// counts it down by one, and it must leave while it shows 1 or more.
  /// Null for a block without a countdown.
  final int? count;

  /// Layers of ice on a frozen block, 0 when it is not frozen. A frozen
  /// block can't move; every block that leaves next to it cracks a layer.
  final int ice;

  /// Layers of ice that have cracked so far, while some are left.
  final int cracks;

  bool get isVertical => direction.isVertical;

  bool get hasCountdown => count != null;

  bool get isFrozen => ice > 0;

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

  /// This block one move further down its countdown, if it has one. At 0
  /// it has run out and goes on as a block without a countdown.
  Block countedDown() => switch (count) {
    null => this,
    final count => withCount(count > 1 ? count - 1 : null),
  };

  /// This block with [more] layers of ice cracked; with none left it is no
  /// longer frozen.
  Block cracked(int more) {
    if (more <= 0 || ice == 0) {
      return this;
    }
    final left = ice > more ? ice - more : 0;
    return _with(ice: left, cracks: left == 0 ? 0 : cracks + ice - left);
  }

  Block copyWith({Direction? direction, bool? turns}) =>
      _with(direction: direction, turns: turns);

  /// This block with [count] moves left, or no countdown when null.
  Block withCount(int? count) => Block(
    id: id,
    row: row,
    column: column,
    length: length,
    direction: direction,
    turns: turns,
    count: count,
    ice: ice,
    cracks: cracks,
  );

  /// This block under [ice] fresh layers of ice, or not frozen at 0.
  Block withIce(int ice) => _with(ice: ice, cracks: 0);

  Block _with({Direction? direction, bool? turns, int? ice, int? cracks}) =>
      Block(
        id: id,
        row: row,
        column: column,
        length: length,
        direction: direction ?? this.direction,
        turns: turns ?? this.turns,
        count: count,
        ice: ice ?? this.ice,
        cracks: cracks ?? this.cracks,
      );
}
