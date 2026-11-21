import 'dart:math' as math;

/// A level starts with [max] stars and every bump costs one. Losing the
/// last star fails the level.
abstract final class StarRating {
  static const int max = 3;

  static int forBumps(int bumps) => math.max(0, max - bumps);
}
