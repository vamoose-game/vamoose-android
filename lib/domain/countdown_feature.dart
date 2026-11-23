import 'dart:math';

import 'block.dart';
import 'board.dart';
import 'level_feature.dart';
import 'level_spec.dart';

/// Puts a countdown on up to [LevelSpec.countdowns] blocks.
///
/// A countdown block is a plain block (no lock, key or turn) that waits on
/// at least [fewestWaits] blocks and on no turning block, so its way out
/// never depends on timing. Blocks that wait on [deepWaits] or more are
/// tried first, so there is a way to plan.
///
/// Taking the most urgent countdown block first, each one's number is the
/// moves it truly needs, every block it waits on and itself, plus spare
/// moves: [LevelSpec.spare] for the most urgent, at least one for the
/// rest, so one wasted move never costs more than one star. The numbers
/// grow in that order and "most urgent first" always saves them all. With
/// two or more, a pick where saving one first loses another is kept over
/// one where any order works.
class CountdownFeature implements LevelFeature {
  const CountdownFeature();

  /// Numbers shown on a countdown block at the start of a level.
  static const int fewest = 2;
  static const int most = 9;

  /// Blocks a countdown block waits on at the start: at least, and enough
  /// to be tried first.
  static const int fewestWaits = 2;
  static const int deepWaits = 3;

  static const int _picks = 40;

  @override
  Board? addTo(Board board, LevelSpec spec, Random random) {
    if (spec.countdowns <= 0) {
      return board;
    }
    final waits = {
      for (final block in board.blocks)
        if (_canCount(board, block)) block.id: board.waitsOn(block),
    };
    final all = waits.keys.toList()..shuffle(random);
    final deep = [
      for (final id in all)
        if (waits[id]!.length >= deepWaits) id,
    ];
    for (var wanted = spec.countdowns; wanted > 0; wanted--) {
      for (final pool in [deep, all]) {
        final counts = _pick(pool, wanted, waits, spec.spare, random);
        if (counts != null) {
          return board.counting(counts);
        }
      }
    }
    return null;
  }

  bool _canCount(Board board, Block block) {
    if (block.turns ||
        block.hasCountdown ||
        board.restraints.any(
          (restraint) =>
              restraint.blockId == block.id || restraint.holderId == block.id,
        )) {
      return false;
    }
    final waits = board.waitsOn(block);
    return waits.length >= fewestWaits &&
        !waits.any((id) => board.blockById(id).turns);
  }

  /// Numbers for [wanted] blocks from [pool], preferring a pick where the
  /// order matters; null when no pick fits.
  static Map<int, int>? _pick(
    List<int> pool,
    int wanted,
    Map<int, Set<int>> waits,
    int spare,
    Random random,
  ) {
    if (pool.length < wanted) {
      return null;
    }
    Map<int, int>? fallback;
    for (var pick = 0; pick < _picks; pick++) {
      final chosen = (pool..shuffle(random)).take(wanted).toList();
      final counts = _numbers(chosen, waits, spare);
      if (counts == null) {
        continue;
      }
      if (wanted == 1 || _orderMatters(counts, waits)) {
        return counts;
      }
      fallback ??= counts;
    }
    return fallback;
  }

  /// The number for each of [chosen]: the move it gets out on when each goes
  /// as soon as it can, in order of the moves it needs, plus its spare
  /// moves. Null when a number would be out of range.
  static Map<int, int>? _numbers(
    List<int> chosen,
    Map<int, Set<int>> waits,
    int spare,
  ) {
    final counts = <int, int>{};
    for (final (id, moves) in movesToSave(chosen, waits)) {
      final extra = counts.isEmpty ? spare : max(spare, 1);
      final count = moves + extra;
      if (count < fewest || count > most) {
        return null;
      }
      counts[id] = count;
    }
    return counts;
  }

  /// The move on which each of [ids] gets out when they are saved one at a
  /// time, fewest moves needed first: each takes the blocks it waits on that
  /// are still there, then itself. A block one of them waits on needs fewer
  /// moves than that one, so it always comes first.
  static List<(int, int)> movesToSave(
    Iterable<int> ids,
    Map<int, Set<int>> waits,
  ) {
    final order = ids.toList()
      ..sort((a, b) {
        final need = waits[a]!.length - waits[b]!.length;
        return need != 0 ? need : a - b;
      });
    final gone = <int>{};
    return [
      for (final id in order)
        (
          id,
          (gone
                ..addAll(waits[id]!)
                ..add(id))
              .length,
        ),
    ];
  }

  /// Whether saving one countdown block first, with all it waits on, loses
  /// another that neither waits on the other.
  static bool _orderMatters(Map<int, int> counts, Map<int, Set<int>> waits) {
    for (final first in counts.keys) {
      for (final then in counts.keys) {
        if (first != then &&
            !waits[first]!.contains(then) &&
            !waits[then]!.contains(first) &&
            {...waits[first]!, first, ...waits[then]!, then}.length >
                counts[then]!) {
          return true;
        }
      }
    }
    return false;
  }
}
