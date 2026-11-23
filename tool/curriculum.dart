import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/level_spec.dart';

/// The mechanics a level uses, and how many of each.
typedef Mix = ({
  int locks,
  int turners,
  int frozen,
  int thickIce,
  int twins,
  int countdowns,
  int spare,
  bool rest,
});

/// What each level asks of the player: the board, how many blocks, how
/// tangled they are and which mechanics show up.
///
/// - Every level has a block more than in build 9 (as many on a breather
///   and on the levels that bring in a mechanic), is at least as tangled,
///   and its mechanics together (lock pairs, turning blocks, frozen blocks,
///   twin pairs and countdown blocks) are at least build 9's locks.
/// - Levels 1–10: plain blocks, already a few chains to untangle.
/// - A new mechanic every 40 levels: locks at 11, turning blocks at 51,
///   frozen blocks at 91, twin blocks at 131 and countdown blocks at 171.
///   The level that brings one in has a block fewer and keeps the others
///   simple; from then on it joins the mix and stays to the end.
/// - From level 12 on, levels cycle through five mixes, each using some of
///   the mechanics met so far, and every fifth level is a breather with a
///   block and a lock pair fewer, as build 9's had a pair fewer. From 171
///   on, every tenth level has all five mechanics at once.
/// - More of each mechanic joins as the boards grow, frozen blocks get
///   thick ice (two layers) from 201, and countdowns spare fewer moves.
abstract final class Curriculum {
  static const int firstLock = 11;
  static const int firstTurn = 51;
  static const int firstIce = 91;
  static const int firstTwin = 131;
  static const int firstCountdown = 171;
  static const int restEvery = 5;
  static const int restBlocks = 1;

  /// Levels that bring in a mechanic.
  static const Set<int> firsts = {
    firstLock,
    firstTurn,
    firstIce,
    firstTwin,
    firstCountdown,
  };

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
      frozen: mix.frozen,
      thickIce: mix.thickIce,
      twins: mix.twins,
      countdowns: mix.countdowns,
      spare: mix.spare,
    );
  }

  static Mix mixFor(int level) {
    final breather = level % restEvery == 0;
    final rest = breather || firsts.contains(level);
    Mix mix({
      int locks = 0,
      int turners = 0,
      int frozen = 0,
      int twins = 0,
      int countdowns = 0,
    }) => (
      locks: locks,
      turners: level < firstTurn ? 0 : turners,
      frozen: level < firstIce ? 0 : frozen,
      thickIce: level < firstIce ? 0 : _thickIce(level, frozen),
      twins: level < firstTwin ? 0 : twins,
      countdowns: level < firstCountdown ? 0 : countdowns,
      spare: _spare(level),
      rest: rest,
    );

    if (level < firstLock) {
      return mix();
    }
    final locks = _maxLocks(level);
    // A level that brings in a mechanic: that one, and a lock pair.
    switch (level) {
      case firstLock:
        return mix(locks: 1);
      case firstTurn:
        return mix(turners: 1);
      case firstIce:
        return mix(locks: 1, frozen: 1);
      case firstTwin:
        return mix(locks: 1, twins: 1);
      case firstCountdown:
        return mix(locks: 1, countdowns: 1);
    }
    if (level < firstTurn) {
      return mix(locks: breather ? 0 : locks);
    }
    final turners = _maxTurners(level);
    final frozen = _maxFrozen(level);
    final twins = _maxTwins(level);
    final countdowns = _maxCountdowns(level);
    final everything = level >= firstCountdown && level % 10 == 3;
    return switch (level % restEvery) {
      1 => mix(locks: locks, turners: turners, frozen: frozen),
      2 => mix(
        turners: turners,
        frozen: level < firstTwin ? frozen : 0,
        twins: twins,
        countdowns: countdowns,
      ),
      3 => mix(
        locks: locks,
        turners: 1,
        frozen: frozen,
        twins: twins,
        countdowns: everything ? countdowns : 0,
      ),
      4 => mix(locks: locks, frozen: frozen, countdowns: countdowns),
      _ => mix(locks: locks - 1, turners: 1, twins: 1),
    };
  }

  static int _maxLocks(int level) => switch (level) {
    < 31 => 1,
    < 121 => 2,
    _ => 3,
  };

  static int _maxTurners(int level) => switch (level) {
    < 61 => 1,
    < 151 => 2,
    _ => 3,
  };

  static int _maxFrozen(int level) => switch (level) {
    < 111 => 1,
    < 181 => 2,
    _ => 3,
  };

  static int _thickIce(int level, int frozen) => switch (level) {
    < 201 => 0,
    < 281 => frozen > 0 ? 1 : 0,
    _ => frozen > 1 ? 2 : frozen,
  };

  static int _maxTwins(int level) => switch (level) {
    < 151 => 1,
    < 241 => 2,
    _ => 3,
  };

  static int _maxCountdowns(int level) => switch (level) {
    < 211 => 1,
    < 281 => 2,
    _ => 3,
  };

  static int _spare(int level) => switch (level) {
    < 201 => 2,
    < 281 => 1,
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
