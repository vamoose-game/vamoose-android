class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.blockCount,
    this.twist = 0,
    this.locks = 0,
    this.keyDepth = 1,
    this.turners = 0,
    this.countdowns = 0,
    this.spare = 0,
    this.ice = const [],
    this.twins = 0,
  });

  final int size;
  final int blockCount;
  final double twist;
  final int locks;
  final int keyDepth;

  /// How many 1×1 blocks turn a quarter every time another block leaves.
  final int turners;

  /// At most how many blocks carry a countdown.
  final int countdowns;

  /// Moves a countdown gives on top of the ones its block truly needs.
  final int spare;

  /// The layers of ice on each frozen block, thickest first.
  final List<int> ice;

  /// How many pairs of twins.
  final int twins;
}
