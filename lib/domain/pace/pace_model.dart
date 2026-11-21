import 'dart:math';
import 'dart:typed_data';

import '../board.dart';
import '../direction.dart';
import 'player.dart';

/// Seconds a newcomer spends on each step of play.
///
/// The figures follow visual search and touch research: about 200 ms to
/// fixate a block, a few tens of ms to trace each cell of its path, and
/// Fitts' law (a + b·log2(1 + distance / width)) for the finger.
final class PaceTiming {
  const PaceTiming({
    this.orient = 0.6,
    this.fixate = 0.25,
    this.perCell = 0.04,
    this.decide = 0.12,
    this.lockGlance = 0.1,
    this.turnRead = 0.12,
    this.react = 0.12,
    this.bumpRecover = 0.6,
    this.reachBase = 0.08,
    this.reachPerBit = 0.12,
  });

  /// First look at the board once the blocks have landed.
  final double orient;

  /// Looking at one block and its arrow.
  final double fixate;

  /// Tracing one empty cell of a path.
  final double perCell;

  /// Settling on a block before tapping it.
  final double decide;

  /// Seeing that a padlocked block still has its key on the board.
  final double lockGlance;

  /// Reading which way a turning block faces now.
  final double turnRead;

  /// Taking in the board after a block leaves.
  final double react;

  /// Watching a bump and the block in the way, then looking again.
  final double bumpRecover;

  /// Fitts' law intercept and slope for a tap, in seconds and seconds per bit.
  final double reachBase;
  final double reachPerBit;
}

/// The speed–accuracy trade-off under a running clock: once [from] of the
/// time is gone, people look faster and misread more.
final class TimePressure {
  const TimePressure({this.from = 0.65, this.think = 0.82, this.slip = 1.8});

  final double from;
  final double think;
  final double slip;
}

enum Ending { cleared, outOfStars, outOfTime }

/// How one simulated try at a board went.
typedef Attempt = ({double seconds, int bumps, Ending ending});

/// Simulates people playing a board, one try at a time.
///
/// Each move, the player looks at blocks one by one, most eye-catching
/// first: blocks near the edge pointing out, and blocks whose blocker just
/// left. Each look costs time and traces the arrow's path. A clear path is
/// tapped. A blocked one is remembered, unless the player misreads it and
/// taps anyway: a bump, which costs a star and makes them more careful.
/// Three bumps or the end of the clock end the try. Turning blocks are read
/// again after every move, since they turn.
final class PaceModel {
  const PaceModel({
    this.timing = const PaceTiming(),
    this.pressure = const TimePressure(),
    this.maxBumps = 3,
  });

  /// Longest untimed try simulated; a guard far above any time limit.
  static const double giveUpAfter = 900;

  final PaceTiming timing;
  final TimePressure pressure;
  final int maxBumps;

  Attempt play(Board board, Player player, Random random, {double? limit}) =>
      _Run(_Layout.of(board), this, player, random, limit).play();

  /// Tries of [crowd] at [board] against a [limit]-second clock, everyone
  /// with the practice of having played [experience] levels. A person
  /// retries, up to [tries] in all, until they clear it.
  Trial trial(
    Board board,
    List<Player> crowd, {
    required int experience,
    required double limit,
    int tries = 3,
    int seed = 1,
  }) {
    final layout = _Layout.of(board);
    final random = Random(seed);
    final first = <Attempt>[];
    final clearedBy = Uint8List(crowd.length);
    for (var index = 0; index < crowd.length; index++) {
      final practiced = crowd[index].practiced(experience);
      for (var attempt = 0; attempt < tries; attempt++) {
        final run = _Run(
          layout,
          this,
          practiced.retrying(attempt),
          random,
          limit,
        ).play();
        if (attempt == 0) {
          first.add(run);
        }
        if (run.ending == Ending.cleared) {
          clearedBy[index] = attempt + 1;
          break;
        }
      }
    }
    return Trial._(limit, first, clearedBy);
  }

  /// The fewest whole seconds, at least [from], that let [share] of [crowd]
  /// clear [board] on the first try and [withinThreeTries] of them within
  /// three tries. When fewer than that clear it even with no clock, no limit
  /// gets there, and this is [giveUpAfter].
  int fairLimit(
    Board board,
    List<Player> crowd, {
    required int experience,
    required double share,
    double withinThreeTries = 0,
    int from = 1,
    int seed = 1,
  }) {
    bool fairAt(int seconds) {
      final run = trial(
        board,
        crowd,
        experience: experience,
        limit: seconds.toDouble(),
        tries: withinThreeTries > 0 ? 3 : 1,
        seed: seed,
      );
      return run.passRate >= share && run.passWithin(3) >= withinThreeTries;
    }

    final untimed = trial(
      board,
      crowd,
      experience: experience,
      limit: giveUpAfter,
      tries: 1,
      seed: seed,
    );
    final quickest = untimed.finishWithin(share);
    final reachable =
        quickest.isFinite &&
        (withinThreeTries <= 0 ||
            trial(
                  board,
                  crowd,
                  experience: experience,
                  limit: giveUpAfter,
                  seed: seed,
                ).passWithin(3) >=
                withinThreeTries);
    if (!reachable) {
      return max(from, giveUpAfter.ceil());
    }
    var seconds = max(from, quickest.floor() - 2);
    while (seconds < giveUpAfter && !fairAt(seconds)) {
      seconds++;
    }
    return seconds;
  }
}

/// Simulated tries of a crowd at one board against one time limit.
final class Trial {
  Trial._(this.limit, this._first, this._clearedBy);

  final double limit;
  final List<Attempt> _first;

  /// For each person, the try they cleared the board on (1-based), or 0.
  final Uint8List _clearedBy;

  int get people => _first.length;

  /// Share of people who clear the board on the first try.
  double get passRate => _share((attempt) => attempt.ending == Ending.cleared);

  /// Share of people who clear it in at most [tries] tries.
  double passWithin(int tries) =>
      _clearedBy.where((by) => by > 0 && by <= tries).length / people;

  /// Share of [among] (indices into the crowd) who clear it first try.
  double passRateAmong(List<int> among) =>
      among.where((index) => _first[index].ending == Ending.cleared).length /
      among.length;

  /// Share of [among] whose first try ends with the clock.
  double outOfTimeRateAmong(List<int> among) =>
      among.where((index) => _first[index].ending == Ending.outOfTime).length /
      among.length;

  double get outOfStarsRate =>
      _share((attempt) => attempt.ending == Ending.outOfStars);

  double get outOfTimeRate =>
      _share((attempt) => attempt.ending == Ending.outOfTime);

  double get averageBumps =>
      _first.fold(0, (sum, attempt) => sum + attempt.bumps) / people;

  /// Seconds within which [share] of first tries clear the board (infinite
  /// when fewer ever do).
  double finishWithin(double share) {
    final times = [
      for (final attempt in _first)
        attempt.ending == Ending.cleared ? attempt.seconds : double.infinity,
    ]..sort();
    return times[min(people - 1, max(0, (share * people).ceil() - 1))];
  }

  double _share(bool Function(Attempt attempt) test) =>
      _first.where(test).length / people;
}

/// A board flattened into arrays, shared by every simulated try.
final class _Layout {
  _Layout._(
    this.size,
    this.rows,
    this.columns,
    this.lengths,
    this.facing,
    this.turns,
    this.holders,
    this.grid,
  ) : turners = [
        for (var index = 0; index < turns.length; index++)
          if (turns[index]) index,
      ];

  factory _Layout.of(Board board) {
    final blocks = board.blocks.toList()..sort((a, b) => a.id - b.id);
    final index = {
      for (var position = 0; position < blocks.length; position++)
        blocks[position].id: position,
    };
    final cells = board.size * board.size;
    final grid = Int16List(cells)..fillRange(0, cells, -1);
    for (final block in blocks) {
      for (final cell in block.cells) {
        grid[cell.row * board.size + cell.column] = index[block.id]!;
      }
    }
    final holders = Int16List(blocks.length)..fillRange(0, blocks.length, -1);
    for (final restraint in board.restraints) {
      holders[index[restraint.blockId]!] = index[restraint.holderId]!;
    }
    return _Layout._(
      board.size,
      Int8List.fromList([for (final block in blocks) block.row]),
      Int8List.fromList([for (final block in blocks) block.column]),
      Int8List.fromList([for (final block in blocks) block.length]),
      Int8List.fromList([for (final block in blocks) block.direction.index]),
      [for (final block in blocks) block.turns],
      holders,
      grid,
    );
  }

  final int size;
  final Int8List rows;
  final Int8List columns;
  final Int8List lengths;
  final Int8List facing;
  final List<bool> turns;
  final Int16List holders;
  final Int16List grid;
  final List<int> turners;

  int get count => rows.length;
}

/// One simulated try.
final class _Run {
  _Run(this.layout, this.model, this.player, this.random, double? limit)
    : limit = limit ?? PaceModel.giveUpAfter,
      grid = Int16List.fromList(layout.grid),
      alive = Uint8List(layout.count)..fillRange(0, layout.count, 1),
      known = Int16List.fromList(layout.holders),
      weights = Float64List(layout.count),
      slip = player.slip,
      x = layout.size / 2,
      y = layout.size / 2;

  static final List<int> _rowSteps = [
    for (final direction in Direction.values) direction.rowStep,
  ];
  static final List<int> _columnSteps = [
    for (final direction in Direction.values) direction.columnStep,
  ];

  final _Layout layout;
  final PaceModel model;
  final Player player;
  final Random random;
  final double limit;
  final Int16List grid;
  final Uint8List alive;

  /// For each block, the block the player last saw in its way, or -1.
  final Int16List known;
  final Float64List weights;
  double slip;
  double x;
  double y;
  int moves = 0;
  int left = 0;
  int bumps = 0;
  double seconds = 0;
  int _hit = -1;
  int _steps = 0;

  PaceTiming get timing => model.timing;

  bool get _hurried => seconds > limit * model.pressure.from;

  double get _think => player.think * (_hurried ? model.pressure.think : 1);

  double get _slip => slip * (_hurried ? model.pressure.slip : 1);

  Attempt play() {
    seconds = timing.orient * _think;
    while (left < layout.count) {
      if (seconds > limit) {
        return (seconds: limit, bumps: bumps, ending: Ending.outOfTime);
      }
      final block = _pick();
      final holder = layout.holders[block];
      int? blocker;
      if (holder >= 0 && alive[holder] == 1) {
        seconds += timing.lockGlance * _think;
        known[block] = holder;
        if (random.nextDouble() >= _slip * 0.15) {
          continue;
        }
        blocker = holder;
      } else {
        _walk(block, _facing(block));
        seconds +=
            (timing.fixate +
                timing.perCell * _steps +
                (layout.turns[block] ? timing.turnRead : 0)) *
            _think;
        if (_hit >= 0) {
          known[block] = _hit;
          final misread =
              _slip *
              min(1.6, 0.35 + 0.2 * _steps) *
              (layout.turns[block] ? 1.8 : 1);
          if (random.nextDouble() >= misread) {
            continue;
          }
          blocker = _hit;
        }
      }
      seconds += timing.decide * _think;
      _reach(block);
      if (seconds > limit) {
        return (seconds: limit, bumps: bumps, ending: Ending.outOfTime);
      }
      if (blocker == null) {
        _leave(block);
      } else {
        bumps++;
        seconds += timing.bumpRecover * _think;
        slip *= 0.65;
        if (bumps >= model.maxBumps) {
          return (seconds: seconds, bumps: bumps, ending: Ending.outOfStars);
        }
      }
    }
    return (seconds: seconds, bumps: bumps, ending: Ending.cleared);
  }

  int _facing(int block) => layout.turns[block]
      ? (layout.facing[block] + moves) % 4
      : layout.facing[block];

  /// Picks the block the player looks at next, by how eye-catching it is.
  int _pick() {
    var total = 0.0;
    for (var block = 0; block < layout.count; block++) {
      var weight = 0.0;
      if (alive[block] == 1) {
        final seen = known[block];
        if (seen >= 0) {
          weight = alive[seen] == 1 ? 0.06 : 5;
        } else {
          weight =
              (layout.turns[block] ? 1.15 : 1) /
              (1 + 0.3 * _toEdge(block, _facing(block)));
        }
      }
      weights[block] = weight;
      total += weight;
    }
    var roll = random.nextDouble() * total;
    var last = 0;
    for (var block = 0; block < layout.count; block++) {
      if (weights[block] > 0) {
        last = block;
        roll -= weights[block];
        if (roll <= 0) {
          return block;
        }
      }
    }
    return last;
  }

  bool _vertical(int block) =>
      layout.lengths[block] > 1 && layout.facing[block].isEven;

  int _frontRow(int block, int direction) => direction == 2 && _vertical(block)
      ? layout.rows[block] + layout.lengths[block] - 1
      : layout.rows[block];

  int _frontColumn(int block, int direction) =>
      direction == 1 && !_vertical(block)
      ? layout.columns[block] + layout.lengths[block] - 1
      : layout.columns[block];

  int _toEdge(int block, int direction) => switch (direction) {
    0 => _frontRow(block, direction),
    1 => layout.size - 1 - _frontColumn(block, direction),
    2 => layout.size - 1 - _frontRow(block, direction),
    _ => _frontColumn(block, direction),
  };

  /// Traces the path of [block] facing [direction]: sets [_hit] to the first
  /// block in the way (or -1) and [_steps] to the empty cells before it.
  void _walk(int block, int direction) {
    final size = layout.size;
    final rowStep = _rowSteps[direction];
    final columnStep = _columnSteps[direction];
    var row = _frontRow(block, direction) + rowStep;
    var column = _frontColumn(block, direction) + columnStep;
    var steps = 0;
    while (row >= 0 && row < size && column >= 0 && column < size) {
      final id = grid[row * size + column];
      if (id >= 0) {
        _hit = id;
        _steps = steps;
        return;
      }
      steps++;
      row += rowStep;
      column += columnStep;
    }
    _hit = -1;
    _steps = steps;
  }

  /// Moves the finger to [block] (Fitts' law with a one-cell target).
  void _reach(int block) {
    final vertical = _vertical(block);
    final length = layout.lengths[block];
    final targetX = layout.columns[block] + (vertical ? 0.5 : length / 2);
    final targetY = layout.rows[block] + (vertical ? length / 2 : 0.5);
    final dx = targetX - x;
    final dy = targetY - y;
    seconds +=
        (timing.reachBase +
            timing.reachPerBit * log(1 + sqrt(dx * dx + dy * dy)) / ln2) *
        player.hand;
    x = targetX;
    y = targetY;
  }

  void _leave(int block) {
    alive[block] = 0;
    left++;
    moves++;
    final size = layout.size;
    final vertical = _vertical(block);
    for (var offset = 0; offset < layout.lengths[block]; offset++) {
      final row = layout.rows[block] + (vertical ? offset : 0);
      final column = layout.columns[block] + (vertical ? 0 : offset);
      grid[row * size + column] = -1;
    }
    for (final turner in layout.turners) {
      known[turner] = -1;
    }
    seconds += timing.react * _think;
  }
}
