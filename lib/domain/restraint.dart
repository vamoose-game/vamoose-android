import 'block.dart';
import 'board.dart';

/// Something that keeps a block in place while another block is on the
/// board. Restraints only ever let go as blocks leave.
sealed class Restraint {
  const Restraint({required this.blockId});

  final int blockId;

  /// The block that holds [blockId] in place while it is on the board.
  int get holderId;

  Block? holderIn(Board board) =>
      board.contains(holderId) ? board.blockById(holderId) : null;
}

/// A padlocked block: it moves only after the block with its key has left.
final class Lock extends Restraint {
  const Lock({required super.blockId, required this.keyId});

  final int keyId;

  @override
  int get holderId => keyId;
}
