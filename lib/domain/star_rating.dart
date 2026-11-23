import 'dart:math' as math;

/// A level starts with [max] stars. Every miss costs one: a bump, or a
/// countdown block that runs out. Losing the last star fails the level.
abstract final class StarRating {
  static const int max = 3;

  static int forMisses(int misses) => math.max(0, max - misses);
}
