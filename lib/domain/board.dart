import 'block.dart';
import 'cell.dart';
import 'direction.dart';
import 'restraint.dart';
import 'tap_outcome.dart';

/// Two blocks chained together: tapping either one sends both off at once,
/// so both their ways must be clear.
typedef TwinPair = ({int first, int second});

/// The blocks still on a square board, the restraints between them and the
/// twins among them.
///
/// A board never changes: every move returns a new one. Cells live in a flat
/// grid of block ids, so lookups and path walks allocate nothing.
final class Board {
  factory Board({
    required int size,
    required Iterable<Block> blocks,
    List<Restraint> restraints = const [],
    List<TwinPair> twins = const [],
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
    return Board._(size, byId, grid, restraints, twins);
  }

  Board._(this.size, this._blocks, this._grid, this.restraints, this.twins);

  static const int _empty = -1;

  final int size;
  final List<Restraint> restraints;

  /// Twin pairs, in the order their badges are colored. A pair leaves
  /// together, so both of its blocks are on the board or neither is.
  final List<TwinPair> twins;
  final Map<int, Block> _blocks;
  final List<int> _grid;

  Iterable<Block> get blocks => _blocks.values;

  int get blockCount => _blocks.length;

  bool get isCleared => _blocks.isEmpty;

  bool get hasTurningBlocks => _blocks.values.any((block) => block.turns);

  bool get hasCountdowns => _blocks.values.any((block) => block.hasCountdown);

  bool get hasIce => _blocks.values.any((block) => block.isFrozen);

  bool get hasTwins =>
      twins.any((pair) => contains(pair.first) && contains(pair.second));

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

  /// The twin chained to [block], while it is on the board.
  Block? twinOf(Block block) {
    for (final pair in twins) {
      final other = pair.first == block.id
          ? pair.second
          : pair.second == block.id
          ? pair.first
          : null;
      if (other != null) {
        return _blocks[other];
      }
    }
    return null;
  }

  /// Whether [block] can leave now: no ice on it, no lock holding it and
  /// nothing in its way, and the same for its twin, which leaves with it.
  bool canLeave(Block block) {
    if (!_canGoAlone(block)) {
      return false;
    }
    final twin = twinOf(block);
    return twin == null || _canGoAlone(twin);
  }

  bool _canGoAlone(Block block) =>
      !block.isFrozen &&
      holdOn(block) == null &&
      _firstHit(block, block.direction) == null;

  Iterable<Block> get movableBlocks => blocks.where(canLeave);

  TapOutcome tap(int id) {
    final block = blockById(id);
    final twin = twinOf(block);
    for (final mover in [block, ?twin]) {
      final bumps = _bumpOf(mover);
      if (bumps != null) {
        return BlockBumps(
          block,
          blocker: bumps.blocker,
          restraint: bumps.restraint,
          frozen: mover.isFrozen,
          twin: twin,
          twinStuck: mover != block,
        );
      }
    }
    final leaving = twin == null ? 1 : 2;
    final cracks = _cracksFrom([block, ?twin]);
    return BlockLeaves(
      block,
      travel: block.travelWithin(size),
      twin: twin,
      twinTravel: twin?.travelWithin(size) ?? 0,
      runOuts: [
        for (final other in blocks)
          if (other.id != id &&
              other.id != twin?.id &&
              (other.count ?? leaving + 1) <= leaving)
            other,
      ],
      cracked: [
        for (final MapEntry(key: id, value: cracks) in cracks.entries)
          if (_blocks[id]!.ice > cracks) _blocks[id]!,
      ],
      thawed: [
        for (final MapEntry(key: id, value: cracks) in cracks.entries)
          if (_blocks[id]!.isFrozen && _blocks[id]!.ice <= cracks) _blocks[id]!,
      ],
    );
  }

  /// How many layers of ice each block loses as [leaving] leave: one for
  /// each of them it touches.
  Map<int, int> _cracksFrom(List<Block> leaving) {
    final cracks = <int, int>{};
    for (final block in leaving) {
      for (final neighbour in neighboursOf(block)) {
        if (!leaving.any((other) => other.id == neighbour)) {
          cracks[neighbour] = (cracks[neighbour] ?? 0) + 1;
        }
      }
    }
    return cracks;
  }

  /// What keeps [block] in place, if anything: its ice, a lock or a block in
  /// its way.
  ({Block? blocker, Restraint? restraint})? _bumpOf(Block block) {
    if (block.isFrozen) {
      return (blocker: null, restraint: null);
    }
    final hold = holdOn(block);
    if (hold != null) {
      return (blocker: hold.holderIn(this), restraint: hold);
    }
    final blocker = blockerOf(block);
    return blocker == null ? null : (blocker: blocker, restraint: null);
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

  /// The ids of the blocks that touch [block] side to side.
  Set<int> neighboursOf(Block block) {
    final neighbours = <int>{};
    for (final cell in block.cells) {
      for (final direction in Direction.values) {
        final next = cell.step(direction);
        if (next.isInside(size)) {
          final id = _grid[next.row * size + next.column];
          if (id != _empty && id != block.id) {
            neighbours.add(id);
          }
        }
      }
    }
    return neighbours;
  }

  /// The board after block [id] leaves, with its twin if it has one. For
  /// each block that leaves, every turning block left turns a quarter
  /// clockwise, every countdown counts down, and the ice on each frozen
  /// block next to it cracks a layer.
  Board without(int id) {
    final gone = _blocks[id];
    if (gone == null) {
      return this;
    }
    final leaving = [gone, ?twinOf(gone)];
    final grid = List<int>.of(_grid);
    final cracks = _cracksFrom(leaving);
    for (final block in leaving) {
      for (final cell in block.cells) {
        grid[cell.row * size + cell.column] = _empty;
      }
    }
    Block after(Block block) {
      var next = block.cracked(cracks[block.id] ?? 0);
      for (var move = 0; move < leaving.length; move++) {
        next = next.turned().countedDown();
      }
      return next;
    }

    return Board._(
      size,
      {
        for (final block in _blocks.values)
          if (!leaving.contains(block)) block.id: after(block),
      },
      grid,
      restraints,
      twins,
    );
  }

  Board restrainedBy(Iterable<Restraint> added) =>
      Board._(size, _blocks, _grid, [...restraints, ...added], twins);

  /// The same board with the blocks of each pair in [added] made twins.
  Board twinnedBy(Iterable<TwinPair> added) =>
      Board._(size, _blocks, _grid, restraints, [...twins, ...added]);

  /// The same board with a countdown of [counts] moves on each block in it.
  Board counting(Map<int, int> counts) => _changed(
    (block) => switch (counts[block.id]) {
      final count? => block.withCount(count),
      null => block,
    },
  );

  /// The same board with [ice] layers of ice on each block in it.
  Board freezing(Map<int, int> ice) => _changed(
    (block) => switch (ice[block.id]) {
      final layers? => block.withIce(layers),
      null => block,
    },
  );

  /// The same board with the blocks in [facing] made turning blocks that
  /// start facing the given directions.
  Board turning(Map<int, Direction> facing) => _changed(
    (block) => switch (facing[block.id]) {
      final direction? => block.copyWith(direction: direction, turns: true),
      null => block,
    },
  );

  Board _changed(Block Function(Block block) change) => Board._(
    size,
    {for (final block in _blocks.values) block.id: change(block)},
    _grid,
    restraints,
    twins,
  );

  /// Whether the board clears whatever order the player picks: from every
  /// position a player can reach, some block can still leave. Countdowns
  /// only ever cost stars, never moves, so they play no part here.
  ///
  /// Plain blocks, locks, ice and twins only ever free up as blocks leave:
  /// a lock opens, ice cracks, a way clears. So with no turning blocks one
  /// greedy pass decides it. Turning blocks change direction on every move,
  /// so a reachable position could leave every block stuck. Such a dead end
  /// keeps some set T of turning blocks, and its other blocks must be
  /// exactly the ones that can never leave while T stays: the stuck core of
  /// T. Checking that some turning block can leave from the core of every
  /// subset of turning blocks covers every dead end.
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

  /// Removes every block but the turning ones that can leave from
  /// [present], twins two at a time, over and over, treating the turning
  /// blocks in it as fixed obstacles.
  void _peelPlainBlocks(Set<int> present) {
    var peeled = true;
    while (peeled) {
      peeled = false;
      for (final id in present.toList(growable: false)) {
        final block = _blocks[id]!;
        if (block.turns ||
            !present.contains(id) ||
            !_canLeaveAmong(block, block.direction, present)) {
          continue;
        }
        final twin = twinOf(block);
        if (twin != null &&
            (!present.contains(twin.id) ||
                twin.turns ||
                !_canLeaveAmong(twin, twin.direction, present))) {
          continue;
        }
        present.remove(id);
        if (twin != null) {
          present.remove(twin.id);
        }
        peeled = true;
      }
    }
  }

  /// Whether [block] facing [facing] could leave with only the blocks in
  /// [present] still on the board: its ice cracked away by the neighbours
  /// that have left, its lock open and its way clear.
  bool _canLeaveAmong(Block block, Direction facing, Set<int> present) {
    if (block.isFrozen &&
        neighboursOf(block).where((id) => !present.contains(id)).length <
            block.ice) {
      return false;
    }
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
