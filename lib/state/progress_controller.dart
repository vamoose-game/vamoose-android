import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/key_value_store.dart';
import '../domain/chapter.dart';
import '../domain/star_rating.dart';

class ProgressController extends ChangeNotifier {
  ProgressController(this._store, {required this.levelCount})
    : _stars = _decode(_store.readString(_starsKey), levelCount);

  static const String _starsKey = 'progress.stars';

  final KeyValueStore _store;
  final int levelCount;
  final List<int> _stars;

  int starsFor(int level) => _stars[level - 1];

  bool isCleared(int level) => starsFor(level) > 0;

  int get clearedCount => _stars.where((stars) => stars > 0).length;

  int get totalStars => _stars.fold(0, (sum, stars) => sum + stars);

  int get maxStars => levelCount * StarRating.max;

  int get currentLevel {
    final firstOpen = _stars.indexWhere((stars) => stars == 0);
    return firstOpen == -1 ? levelCount : firstOpen + 1;
  }

  bool isUnlocked(int level) => level <= currentLevel;

  bool isChapterUnlocked(Chapter chapter) => isUnlocked(chapter.firstLevel);

  int starsIn(Chapter chapter) => [
    for (var level = chapter.firstLevel; level <= chapter.lastLevel; level++)
      starsFor(level),
  ].fold(0, (sum, stars) => sum + stars);

  int clearedIn(Chapter chapter) => [
    for (var level = chapter.firstLevel; level <= chapter.lastLevel; level++)
      if (isCleared(level)) level,
  ].length;

  Future<void> record(int level, int stars) async {
    _stars[level - 1] = max(_stars[level - 1], stars);
    await _store.writeString(_starsKey, _stars.join());
    notifyListeners();
  }

  Future<void> reset() async {
    _stars.fillRange(0, levelCount, 0);
    await _store.remove(_starsKey);
    notifyListeners();
  }

  static List<int> _decode(String? encoded, int levelCount) => [
    for (var index = 0; index < levelCount; index++)
      encoded != null && index < encoded.length
          ? int.tryParse(encoded[index]) ?? 0
          : 0,
  ];
}
