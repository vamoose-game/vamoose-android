class LevelSpec {
  const LevelSpec({
    required this.size,
    required this.blockCount,
    this.twist = 0,
  });

  final int size;
  final int blockCount;
  final double twist;
}
