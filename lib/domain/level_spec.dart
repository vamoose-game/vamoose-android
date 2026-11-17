class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.blockCount,
    this.twist = 0,
    this.locks = 0,
    this.keyDepth = 1,
  });

  final int size;
  final int blockCount;
  final double twist;
  final int locks;
  final int keyDepth;
}
