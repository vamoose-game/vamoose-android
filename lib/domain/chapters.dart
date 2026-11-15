import 'chapter.dart';

abstract final class Chapters {
  static const List<Chapter> all = [
    Chapter(index: 0, name: 'Warm-up', boardSize: 5),
    Chapter(index: 1, name: 'Easy', boardSize: 6),
    Chapter(index: 2, name: 'Steady', boardSize: 6),
    Chapter(index: 3, name: 'Flow', boardSize: 6),
    Chapter(index: 4, name: 'Calm', boardSize: 7),
    Chapter(index: 5, name: 'Focus', boardSize: 7),
    Chapter(index: 6, name: 'Clever', boardSize: 7),
    Chapter(index: 7, name: 'Tricky', boardSize: 7),
    Chapter(index: 8, name: 'Deep', boardSize: 8),
    Chapter(index: 9, name: 'Expert', boardSize: 8),
    Chapter(index: 10, name: 'Master', boardSize: 8),
    Chapter(index: 11, name: 'Zen', boardSize: 8),
  ];

  static int get levelCount => all.length * Chapter.levelCount;

  static Chapter of(int level) =>
      all.firstWhere((chapter) => chapter.contains(level));
}
