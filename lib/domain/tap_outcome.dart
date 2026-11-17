import 'block.dart';
import 'restraint.dart';

sealed class TapOutcome {
  const TapOutcome(this.block);

  final Block block;
}

final class BlockLeaves extends TapOutcome {
  const BlockLeaves(super.block, {required this.travel});

  final int travel;
}

final class BlockBumps extends TapOutcome {
  const BlockBumps(super.block, {required this.blocker, this.restraint});

  final Block blocker;
  final Restraint? restraint;
}
