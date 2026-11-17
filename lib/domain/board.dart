import 'block.dart';
import 'cell.dart';
import 'restraint.dart';
import 'tap_outcome.dart';

class Board {
  Board({
    required this.size,
    required Iterable<Block> blocks,
    this.restraints = const [],
  }) : _blocks = {for (final block in blocks) block.id: block},
       _occupancy = {
         for (final block in blocks)
           for (final cell in block.cells) cell: block.id,
       };

  final int size;
  final List<Restraint> restraints;
  final Map<int, Block> _blocks;
  final Map<Cell, int> _occupancy;

  Iterable<Block> get blocks => _blocks.values;

  int get blockCount => _blocks.length;

  bool get isCleared => _blocks.isEmpty;

  bool contains(int id) => _blocks.containsKey(id);

  Block blockById(int id) => _blocks[id]!;

  Block? blockAt(Cell cell) {
    final id = _occupancy[cell];
    return id == null ? null : _blocks[id];
  }

  Block? blockerOf(Block block) {
    for (final cell in block.pathWithin(size)) {
      final hit = blockAt(cell);
      if (hit != null) {
        return hit;
      }
    }
    return null;
  }

  Restraint? holdOn(Block block) {
    for (final restraint in restraints) {
      if (restraint.blockId == block.id && restraint.holderIn(this) != null) {
        return restraint;
      }
    }
    return null;
  }

  bool canLeave(Block block) =>
      holdOn(block) == null && blockerOf(block) == null;

  Iterable<Block> get movableBlocks => blocks.where(canLeave);

  TapOutcome tap(int id) {
    final block = blockById(id);
    final hold = holdOn(block);
    if (hold != null) {
      return BlockBumps(block, blocker: hold.holderIn(this)!, restraint: hold);
    }
    final blocker = blockerOf(block);
    if (blocker == null) {
      return BlockLeaves(block, travel: block.pathWithin(size).length);
    }
    return BlockBumps(block, blocker: blocker);
  }

  Board without(int id) => Board(
    size: size,
    blocks: blocks.where((block) => block.id != id),
    restraints: restraints,
  );

  Board restrainedBy(Iterable<Restraint> added) =>
      Board(size: size, blocks: blocks, restraints: [...restraints, ...added]);

  bool get isSolvable {
    var board = this;
    while (!board.isCleared) {
      final next = board.movableBlocks.firstOrNull;
      if (next == null) {
        return false;
      }
      board = board.without(next.id);
    }
    return true;
  }
}
