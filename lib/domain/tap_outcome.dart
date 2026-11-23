import 'block.dart';
import 'restraint.dart';

sealed class TapOutcome {
  const TapOutcome(this.block);

  final Block block;
}

/// The tapped block leaves, and its twin with it if it has one.
final class BlockLeaves extends TapOutcome {
  const BlockLeaves(
    super.block, {
    required this.travel,
    this.runOuts = const [],
    this.twin,
    this.twinTravel = 0,
    this.cracked = const [],
    this.thawed = const [],
  });

  final int travel;

  /// Countdown blocks that ran out as this block left: each costs a star.
  final List<Block> runOuts;

  /// The tapped block's twin, which leaves with it, and its cells to travel.
  final Block? twin;
  final int twinTravel;

  /// Frozen blocks next to the blocks that left: [cracked] still have ice
  /// left, [thawed] lost their last layer and can move.
  final List<Block> cracked;
  final List<Block> thawed;
}

/// The tapped block stays put, and so does its twin: a bump.
final class BlockBumps extends TapOutcome {
  const BlockBumps(
    super.block, {
    this.blocker,
    this.restraint,
    this.frozen = false,
    this.twin,
    this.twinStuck = false,
  });

  /// The block in the way, or the one with the key to the lock; null when
  /// ice holds it.
  final Block? blocker;
  final Restraint? restraint;

  /// Whether ice held it.
  final bool frozen;

  /// The tapped block's twin, which bumps with it.
  final Block? twin;

  /// Whether the twin, not the tapped block, was the one that could not go.
  final bool twinStuck;

  /// The block that could not go.
  Block get stuck => twinStuck ? twin! : block;
}
