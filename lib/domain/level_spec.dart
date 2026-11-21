class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.blockCount,
    this.twist = 0,
    this.locks = 0,
    this.keyDepth = 1,
    this.turners = 0,
  });

  final int size;
  final int blockCount;
  final double twist;
  final int locks;
  final int keyDepth;

  /// How many 1×1 blocks turn a quarter every time another block leaves.
  final int turners;
}
