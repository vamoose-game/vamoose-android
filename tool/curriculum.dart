import 'dart:math';

import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/level_spec.dart';

/// What each level asks of the player: the board, how many blocks, how
/// tangled they are and which mechanics show up.
///
/// - Every level has a block more than in build 9 (as many on a breather
///   and on levels 21 and 26, which bring in turning and countdown blocks),
///   is at least as tangled, and its locks and turning blocks together are
///   at least build 9's locks.
/// - Levels 1–10: plain blocks, already a few chains to untangle.
/// - Level 11: the first key and lock.
/// - Level 21: the first turning block; from 22 on, locks and turning blocks
///   also share levels.
/// - Level 26: the first countdown block, with a lock and no turning block,
///   and again on level 29.
/// - From 31 on, levels cycle through five mixes: both mechanics, turning
///   blocks with countdowns, both again, locks with countdowns and a
///   breather. So two levels in five have countdown blocks, to the end.
/// - Breathers (every 5th level) have a block and a lock pair fewer, as
///   build 9's had a pair fewer. The levels that bring in a mechanic have a
///   block fewer.
/// - More lock pairs, turning blocks and countdown blocks join as the boards
///   grow, and countdowns spare fewer moves: two up to level 45, one up to
///   240, then none on the levels that pair them with locks.
abstract final class Curriculum {
  static const int firstLock = 11;
  static const int firstTurn = 21;
  static const int firstCountdown = 26;
  static const int restEvery = 5;
  static const int restBlocks = 1;

  /// Levels before 31 with countdown blocks.
  static const Set<int> _earlyCountdowns = {firstCountdown, 29};

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
      countdowns: mix.countdowns,
      spare: mix.spare,
    );
  }

  static ({int locks, int turners, int countdowns, int spare, bool rest})
  mixFor(int level) {
    final breather = level % restEvery == 0;
    final rest =
        breather ||
        level == firstLock ||
        level == firstTurn ||
        level == firstCountdown;
    if (level < firstLock) {
      return (locks: 0, turners: 0, countdowns: 0, spare: 0, rest: rest);
    }
    if (level < firstTurn) {
      return (
        locks: breather ? 0 : 1,
        turners: 0,
        countdowns: 0,
        spare: 0,
        rest: rest,
      );
    }
    if (level <= 30) {
      final counting = _earlyCountdowns.contains(level);
      return (
        locks: breather || level == firstTurn ? 0 : 1,
        turners: counting ? 0 : 1,
        countdowns: counting ? 1 : 0,
        spare: counting ? _spare(level) : 0,
        rest: rest,
      );
    }
    final locks = _maxLocks(level);
    final turners = _maxTurners(level);
    final countdowns = _maxCountdowns(level);
    return switch (level % restEvery) {
      1 => (
        locks: locks,
        turners: turners,
        countdowns: 0,
        spare: 0,
        rest: false,
      ),
      2 => (
        locks: 0,
        turners: turners,
        countdowns: max(1, countdowns - 1),
        spare: max(1, _spare(level)),
        rest: false,
      ),
      3 => (locks: locks, turners: 1, countdowns: 0, spare: 0, rest: false),
      4 => (
        locks: locks,
        turners: 0,
        countdowns: countdowns,
        spare: _spare(level),
        rest: false,
      ),
      _ => (locks: locks - 1, turners: 1, countdowns: 0, spare: 0, rest: true),
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

  static int _maxCountdowns(int level) => switch (level) {
    < 61 => 1,
    < 181 => 2,
    _ => 3,
  };

  static int _spare(int level) => switch (level) {
    < 46 => 2,
    < 241 => 1,
    _ => 0,
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
