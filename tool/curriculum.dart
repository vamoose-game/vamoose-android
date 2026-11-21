import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/level_spec.dart';

/// What each level asks of the player: the board, how many blocks, how
/// tangled they are and which mechanics show up.
///
/// - Every level has a block more than in build 9 (as many on a breather
///   and on level 21, which brings in turning blocks), is at least as
///   tangled, and its locks and turning blocks together are at least build
///   9's locks.
/// - Levels 1–10: plain blocks, already a few chains to untangle.
/// - Level 11: the first key and lock.
/// - Level 21: the first turning block; from 22 on, locks and turning blocks
///   also share levels.
/// - From 31 on, levels cycle through five mixes: both mechanics, turning
///   focus, both again, lock focus and a breather.
/// - Breathers (every 5th level) have a block and a lock pair fewer, as
///   build 9's had a pair fewer. The levels that bring in a mechanic have a
///   block fewer.
/// - More lock pairs and turning blocks join as the boards grow.
abstract final class Curriculum {
  static const int firstLock = 11;
  static const int firstTurn = 21;
  static const int restEvery = 5;
  static const int restBlocks = 1;

  /// Blocks on the board by level, between these keyframes.
  static const List<(int, double)> _blocks = [
    (1, 7),
    (10, 11),
    (11, 13),
    (20, 16),
    (30, 20),
    (60, 22),
    (90, 26),
    (120, 28),
    (121, 28),
    (180, 33),
    (240, 36),
    (241, 34),
    (260, 37),
    (280, 40),
    (300, 41),
    (360, 46),
  ];

  /// How often a block is placed to wait on another (see LevelGenerator).
  static const List<(int, double)> _twist = [
    (1, 0.35),
    (10, 0.5),
    (30, 0.6),
    (120, 0.85),
    (121, 0.7),
    (240, 0.9),
    (241, 0.75),
    (300, 0.9),
    (330, 1),
  ];

  static LevelSpec specFor(int level) {
    final mix = mixFor(level);
    return LevelSpec(
      size: Chapters.of(level).boardSize,
      blockCount: _at(_blocks, level).round() - (mix.rest ? restBlocks : 0),
      twist: _at(_twist, level),
      locks: mix.locks,
      keyDepth: _keyDepth(level),
      turners: mix.turners,
    );
  }

  static ({int locks, int turners, bool rest}) mixFor(int level) {
    final breather = level % restEvery == 0;
    final rest = breather || level == firstLock || level == firstTurn;
    if (level < firstLock) {
      return (locks: 0, turners: 0, rest: rest);
    }
    if (level < firstTurn) {
      return (locks: breather ? 0 : 1, turners: 0, rest: rest);
    }
    if (level <= 30) {
      return (
        locks: breather || level == firstTurn ? 0 : 1,
        turners: 1,
        rest: rest,
      );
    }
    final locks = _maxLocks(level);
    final turners = _maxTurners(level);
    return switch (level % restEvery) {
      1 => (locks: locks, turners: turners, rest: false),
      2 => (locks: 0, turners: turners, rest: false),
      3 => (locks: locks, turners: 1, rest: false),
      4 => (locks: locks, turners: 0, rest: false),
      _ => (locks: locks - 1, turners: 1, rest: true),
    };
  }

  static int _maxLocks(int level) => switch (level) {
    < 61 => 1,
    < 121 => 2,
    _ => 3,
  };

  static int _maxTurners(int level) => switch (level) {
    < 46 => 1,
    < 91 => 2,
    _ => 3,
  };

  static int _keyDepth(int level) => switch (level) {
    < 61 => 1,
    < 181 => 2,
    _ => 3,
  };

  static double _at(List<(int, double)> keys, int level) {
    if (level <= keys.first.$1) {
      return keys.first.$2;
    }
    for (var index = 1; index < keys.length; index++) {
      final (to, high) = keys[index];
      if (level <= to) {
        final (from, low) = keys[index - 1];
        return low + (high - low) * (level - from) / (to - from);
      }
    }
    return keys.last.$2;
  }
}
