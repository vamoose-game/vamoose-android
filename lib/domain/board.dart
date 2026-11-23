import 'block.dart';
import 'cell.dart';
import 'direction.dart';
import 'restraint.dart';
import 'tap_outcome.dart';

/// The blocks still on a square board and the restraints between them.
///
/// A board never changes: every move returns a new one. Cells live in a flat
/// grid of block ids, so lookups and path walks allocate nothing.
final class Board {
  factory Board({
    required int size,
    required Iterable<Block> blocks,
    List<Restraint> restraints = const [],
  }) {
    final byId = {for (final block in blocks) block.id: block};
    final grid = List<int>.filled(size * size, _empty);
    for (final block in byId.values) {
      for (final cell in block.cells) {
        if (!cell.isInside(size)) {
          throw ArgumentError.value(
            block.id,
            'blocks',
            'Block is off the board',
          );
        }
        grid[cell.row * size + cell.column] = block.id;
      }
    }
    return Board._(size, byId, grid, restraints);
  }

  Board._(this.size, this._blocks, this._grid, this.restraints);

  static const int _empty = -1;

  final int size;
  final List<Restraint> restraints;
  final Map<int, Block> _blocks;
  final List<int> _grid;

  Iterable<Block> get blocks => _blocks.values;

  int get blockCount => _blocks.length;

  bool get isCleared => _blocks.isEmpty;

  bool get hasTurningBlocks => _blocks.values.any((block) => block.turns);

  bool get hasCountdowns => _blocks.values.any((block) => block.hasCountdown);

  bool contains(int id) => _blocks.containsKey(id);

  Block blockById(int id) => _blocks[id]!;

  Block? blockAt(Cell cell) => cell.isInside(size)
      ? _blocks[_grid[cell.row * size + cell.column]]
      : null;

  Block? blockerOf(Block block) {
    final id = _firstHit(block, block.direction);
    return id == null ? null : _blocks[id];
  }

  Restraint? holdOn(Block block) {
    for (final restraint in restraints) {
      if (restraint.blockId == block.id && contains(restraint.holderId)) {
        return restraint;
      }
    }
    return null;
  }

  bool canLeave(Block block) =>
      holdOn(block) == null && _firstHit(block, block.direction) == null;

  Iterable<Block> get movableBlocks => blocks.where(canLeave);

  TapOutcome tap(int id) {
    final block = blockById(id);
    final hold = holdOn(block);
    if (hold != null) {
      return BlockBumps(block, blocker: hold.holderIn(this)!, restraint: hold);
    }
    final blocker = blockerOf(block);
    if (blocker == null) {
      return BlockLeaves(
        block,
        travel: block.travelWithin(size),
        runOuts: [
          for (final other in blocks)
            if (other.id != id && other.count == 1) other,
        ],
      );
    }
    return BlockBumps(block, blocker: blocker);
  }

  /// The ids of the blocks [block] waits on directly: every block in its
  /// way, nearest first, then the block with the key to its lock. A turning
  /// block looks the way it faces now.
  Iterable<int> holdersOf(Block block) sync* {
    final seen = <int>{};
    final front = block.front;
    var row = front.row + block.direction.rowStep;
    var column = front.column + block.direction.columnStep;
    while (row >= 0 && row < size && column >= 0 && column < size) {
      final id = _grid[row * size + column];
      if (id != _empty && id != block.id && seen.add(id)) {
        yield id;
      }
      row += block.direction.rowStep;
      column += block.direction.columnStep;
    }
    if (holdOn(block) case final hold? when seen.add(hold.holderId)) {
      yield hold.holderId;
    }
  }

  /// The ids of every block that has to leave before [block] can: the ones
  /// it waits on, the ones they wait on, and so on.
  Set<int> waitsOn(Block block) {
    final waiting = <int>{};
    final todo = [block];
    while (todo.isNotEmpty) {
      for (final id in holdersOf(todo.removeLast())) {
        if (id != block.id && waiting.add(id)) {
          todo.add(_blocks[id]!);
        }
      }
    }
    return waiting;
  }

  /// The board after block [id] leaves: every turning block left on the
  /// board turns a quarter clockwise and every countdown counts down.
  Board without(int id) {
    final gone = _blocks[id];
    if (gone == null) {
      return this;
    }
    final grid = List<int>.of(_grid);
    for (final cell in gone.cells) {
      grid[cell.row * size + cell.column] = _empty;
    }
    return Board._(
      size,
      {
        for (final block in _blocks.values)
          if (block.id != id) block.id: block.turned().countedDown(),
      },
      grid,
      restraints,
    );
  }

  Board restrainedBy(Iterable<Restraint> added) =>
      Board._(size, _blocks, _grid, [...restraints, ...added]);

  /// The same board with a countdown of [counts] moves on each block in it.
  Board counting(Map<int, int> counts) => Board._(
    size,
    {
      for (final block in _blocks.values)
        block.id: switch (counts[block.id]) {
          final count? => block.withCount(count),
          null => block,
        },
    },
    _grid,
    restraints,
  );

  /// The same board with the blocks in [facing] made turning blocks that
  /// start facing the given directions.
  Board turning(Map<int, Direction> facing) => Board._(
    size,
    {
      for (final block in _blocks.values)
        block.id: switch (facing[block.id]) {
          final direction? => block.copyWith(direction: direction, turns: true),
          null => block,
        },
    },
    _grid,
    restraints,
  );

  /// Whether the board clears whatever order the player picks: from every
  /// position a player can reach, some block can still leave. Countdowns
  /// only ever cost stars, never moves, so they play no part here.
  ///
  /// Plain blocks and locks only ever free up as blocks leave, so with no
  /// turning blocks one greedy pass decides it. Turning blocks change
  /// direction on every move, so a reachable position could leave every
  /// block stuck. Such a dead end keeps some set T of turning blocks, and
  /// its plain blocks must be exactly the ones that can never leave while T
  /// stays: the stuck core of T. Checking that some turning block can leave
  /// from the core of every subset of turning blocks covers every dead end.
  bool get isSolvable {
    final turners = [
      for (final block in blocks)
        if (block.turns) block,
    ];
    for (var kept = 0; kept < 1 << turners.length; kept++) {
      final present = {
        for (final block in blocks)
          if (!block.turns) block.id,
        for (var index = 0; index < turners.length; index++)
          if (kept & (1 << index) != 0) turners[index].id,
      };
      _peelPlainBlocks(present);
      if (present.isEmpty) {
        continue;
      }
      final moves = blockCount - present.length;
      final escapes = turners.any(
        (turner) =>
            present.contains(turner.id) &&
            _canLeaveAmong(turner, turner.direction.turned(moves), present),
      );
      if (!escapes) {
        return false;
      }
    }
    return true;
  }

  /// Removes every plain block that can leave from [present], over and over,
  /// treating the turning blocks in it as fixed obstacles.
  void _peelPlainBlocks(Set<int> present) {
    var peeled = true;
    while (peeled) {
      peeled = false;
      for (final id in present.toList(growable: false)) {
        final block = _blocks[id]!;
        if (!block.turns && _canLeaveAmong(block, block.direction, present)) {
          present.remove(id);
          peeled = true;
        }
      }
    }
  }

  bool _canLeaveAmong(Block block, Direction facing, Set<int> present) {
    for (final restraint in restraints) {
      if (restraint.blockId == block.id &&
          present.contains(restraint.holderId)) {
        return false;
      }
    }
    return _firstHit(block, facing, present) == null;
  }

  /// The id of the first block in front of [block] facing [facing], counting
  /// only the blocks in [among] when given; null when the path is clear.
  int? _firstHit(Block block, Direction facing, [Set<int>? among]) {
    final front = block.front;
    var row = front.row + facing.rowStep;
    var column = front.column + facing.columnStep;
    while (row >= 0 && row < size && column >= 0 && column < size) {
      final id = _grid[row * size + column];
      if (id != _empty && id != block.id && (among?.contains(id) ?? true)) {
        return id;
      }
      row += facing.rowStep;
      column += facing.columnStep;
    }
    return null;
  }
}
