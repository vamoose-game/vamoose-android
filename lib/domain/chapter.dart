class Chapter {
  const Chapter({
    required this.index,
    required this.name,
    required this.boardSize,
  });

  static const int levelCount = 30;

  final int index;
  final String name;
  final int boardSize;

  int get firstLevel => index * levelCount + 1;

  int get lastLevel => firstLevel + levelCount - 1;

  bool contains(int level) => level >= firstLevel && level <= lastLevel;
}
