import 'block.dart';
import 'board.dart';

sealed class Restraint {
  const Restraint({required this.blockId});

  final int blockId;

  Block? holderIn(Board board);
}

final class Lock extends Restraint {
  const Lock({required super.blockId, required this.keyId});

  final int keyId;

  @override
  Block? holderIn(Board board) =>
      board.contains(keyId) ? board.blockById(keyId) : null;
}
