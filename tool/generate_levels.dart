import 'dart:io';
import 'dart:math';

import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/domain/daily_puzzle.dart';
import 'package:vamoose/domain/economy.dart';
import 'package:vamoose/domain/level.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/level_generator.dart';
import 'package:vamoose/domain/level_spec.dart';
import 'package:vamoose/domain/pace/pace_model.dart';
import 'package:vamoose/domain/pace/player.dart';

import 'curriculum.dart';

/// Builds `assets/levels/levels.json` and `tool/levels_report.md`.
///
/// A crowd of simulated players (PaceModel) plays every level with the
/// practice of the levels before it. Timers come in tiers of 10 to 20
/// levels, starting at [firstTierSeconds]: each tier gets the fewest whole
/// seconds, more than the tier before, that still let
/// - the tier's first-try floor of everyone clear each of its levels,
/// - [threeTriesFloor] of everyone clear each level within three tries, and
/// - the clock end the first try of at most [expertTimeOuts] of the quickest
///   [expertShare] of players.
/// The last levels of a tier get tight, the next tier breathes again, and
/// no level is ever out of reach.
///
/// No level may be easier than the level with its number in build 9
/// ([previousLevels]): the crowd must take at least as long to clear it with
/// no clock. A level that comes out easier is drawn again, and then gets a
/// block more. The first tier's clock is fixed, so its boards must also be
/// fair at [firstTierSeconds]. Build 9 had no clock: where its own board
/// would not be fair at [firstTierSeconds], the level takes the hardest fair
/// board drawn instead.
const int crowdSize = 400;
const double expertShare = 0.15;
const double threeTriesFloor = 0.9;
const double expertTimeOuts = 0.05;
const int searchSpan = 90;
const int firstTierSeconds = 10;
const String previousLevels = 'test/fixtures/levels_build9.json';
const int draws = 12;
const int fixedClockDraws = 60;
const int maxExtraBlocks = 4;

/// First-try floor for the tier starting at [first]: gentler early on.
double firstTryFloor(int first) => switch (first) {
  <= 10 => 0.78,
  <= 20 => 0.72,
  <= 30 => 0.68,
  <= 60 => 0.64,
  _ => 0.6,
};

int tierLength(int first) => switch (first) {
  <= 30 => 10,
  <= 120 => 15,
  _ => 20,
};

List<(int, int)> timerTiers() => [
  for (var first = 1; first <= Chapters.levelCount;)
    (first, (first += tierLength(first)) - 1),
];

void main() {
  final clock = Stopwatch()..start();
  const generator = LevelGenerator();
  const model = PaceModel();
  final crowd = Crowd.sample(crowdSize, Random(2026));
  final experts =
      ([for (var index = 0; index < crowd.length; index++) index]
            ..sort((a, b) => crowd[a].think.compareTo(crowd[b].think)))
          .take((crowd.length * expertShare).round())
          .toList();
  bool fair(Trial trial, double floor) =>
      trial.passRate >= floor &&
      trial.passWithin(3) >= threeTriesFloor &&
      trial.outOfTimeRateAmong(experts) <= expertTimeOuts;
  double untimed(Board board, int level) => model
      .trial(
        board,
        crowd,
        experience: level - 1,
        limit: PaceModel.giveUpAfter,
        tries: 1,
        seed: level,
      )
      .finishWithin(0.5);
  final build9 = LevelCodec.decode(File(previousLevels).readAsStringSync());
  final floors = [
    for (var level = 1; level <= Chapters.levelCount; level++)
      untimed(build9[level - 1].board, level),
  ];

  bool fairAtFixedClock(Board board, int level) => fair(
    model.trial(
      board,
      crowd,
      experience: level - 1,
      limit: firstTierSeconds.toDouble(),
      seed: level,
    ),
    firstTryFloor(1),
  );
  final fixedClocks = [
    for (var level = 1; level <= tierLength(1); level++) level,
  ];
  final unfairBefore = {
    for (final level in fixedClocks)
      if (!fairAtFixedClock(build9[level - 1].board, level)) level,
  };

  Board boardFor(int level) {
    final spec = Curriculum.specFor(level);
    final floor = floors[level - 1];
    final fixedClock = fixedClocks.contains(level);
    final matchBuild9 = !unfairBefore.contains(level);
    Board? hardest;
    var hardestTime = 0.0;
    for (var extra = 0; extra <= (fixedClock ? 0 : maxExtraBlocks); extra++) {
      final sized = _withBlocks(spec, spec.blockCount + extra);
      for (
        var draw = 0;
        draw < (fixedClock ? fixedClockDraws : draws);
        draw++
      ) {
        final Board board;
        try {
          board = generator.generate(sized, Random(level + 1000 * draw));
        } on StateError {
          break;
        }
        final time = untimed(board, level);
        if (!time.isFinite || fixedClock && !fairAtFixedClock(board, level)) {
          continue;
        }
        if (matchBuild9 && time >= floor) {
          return board;
        }
        if (time > hardestTime) {
          hardest = board;
          hardestTime = time;
        }
      }
    }
    if (matchBuild9) {
      stderr.writeln(
        'Level $level stays under build 9: '
        '${hardestTime.toStringAsFixed(1)} s against '
        '${floor.toStringAsFixed(1)} s',
      );
    }
    return hardest ?? generator.generate(spec, Random(level));
  }

  final boards = [
    for (var level = 1; level <= Chapters.levelCount; level++) boardFor(level),
  ];
  stdout.writeln('Boards ready in ${clock.elapsed.inSeconds} s');
  final trials = <(int, int), Trial>{};
  Trial trialAt(int level, int seconds) =>
      trials[(level, seconds)] ??= model.trial(
        boards[level - 1],
        crowd,
        experience: level - 1,
        limit: seconds.toDouble(),
        seed: level,
      );
  bool fits(int level, int seconds, double floor) =>
      fair(trialAt(level, seconds), floor);

  final limits = <int>[];
  var previous = firstTierSeconds - 1;
  for (final (first, last) in timerTiers()) {
    final floor = firstTryFloor(first);
    final range = [for (var level = first; level <= last; level++) level];
    var seconds = previous + 1;
    if (first == 1) {
      for (final level in range.where(
        (level) => !fits(level, seconds, floor),
      )) {
        stderr.writeln('Level $level misses a floor at $seconds s');
      }
    } else {
      final cap = previous + searchSpan;
      for (final level in range) {
        while (seconds < cap && !fits(level, seconds, floor)) {
          seconds++;
        }
      }
      while (seconds < cap &&
          !range.every((level) => fits(level, seconds, floor))) {
        seconds++;
      }
      if (seconds == cap) {
        stderr.writeln('Levels $first–$last hit the search cap');
      }
    }
    limits.addAll([for (final _ in range) seconds]);
    previous = seconds;
    stdout.writeln('Levels $first–$last: $seconds s');
  }

  final levels = [
    for (var index = 0; index < boards.length; index++)
      Level(
        number: index + 1,
        board: boards[index],
        timeLimit: Duration(seconds: limits[index]),
      ),
  ];
  File('assets/levels/levels.json')
      .writeAsStringSync(LevelCodec.encode(levels));
  File('tool/levels_report.md').writeAsStringSync(
    _Report(
      levels,
      trialAt,
      experts,
      model,
      untimed: [
        for (var level = 1; level <= boards.length; level++)
          untimed(boards[level - 1], level),
      ],
      previous: floors,
      unfairBefore: unfairBefore,
    ).build(),
  );
  stdout.writeln(
    'Generated ${levels.length} levels in ${clock.elapsed.inSeconds} s',
  );
}

LevelSpec _withBlocks(LevelSpec spec, int blockCount) => LevelSpec(
  size: spec.size,
  blockCount: blockCount,
  twist: spec.twist,
  locks: spec.locks,
  keyDepth: spec.keyDepth,
  turners: spec.turners,
);

class _Report {
  _Report(
    this.levels,
    this.trialAt,
    this.experts,
    this.model, {
    required this.untimed,
    required this.previous,
    required this.unfairBefore,
  });

  final List<Level> levels;
  final Trial Function(int level, int seconds) trialAt;
  final List<int> experts;
  final PaceModel model;

  /// Median seconds to clear each level with no clock, and the same for the
  /// level with its number in build 9.
  final List<double> untimed;
  final List<double> previous;

  /// Levels whose build 9 board would not be fair at the first tier's clock.
  final Set<int> unfairBefore;
  final StringBuffer _out = StringBuffer();

  String build() {
    _out
      ..writeln('# Levels and timers')
      ..writeln()
      ..writeln(
        'Made by `dart run tool/generate_levels.dart`. $crowdSize simulated '
        'players (`lib/domain/pace`) play each level with the practice of '
        'the levels before it. A pass is a clear before the clock ends and '
        'before a third bump. Experts are the quickest '
        '${_pct(expertShare)} of players. The extra-time column is the '
        'first-try pass with the extra-time booster, a fifth of the clock '
        '(${Economy.fewestExtraSeconds}–${Economy.mostExtraSeconds} s).',
      )
      ..writeln()
      ..writeln(_againstBuild9())
      ..writeln();
    _tiers();
    _levels();
    _daily();
    return _out.toString();
  }

  void _tiers() {
    _out
      ..writeln('## Tiers')
      ..writeln()
      ..writeln(
        '| Levels | Board | Time | First try, lowest–average | 3 tries, lowest | Experts, lowest | Out of time | Out of stars | Extra time |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
    var failed = 0.0;
    for (final (first, last) in timerTiers()) {
      final range = [for (var level = first; level <= last; level++) level];
      final seconds = levels[first - 1].timeLimit.inSeconds;
      final trials = [for (final level in range) trialAt(level, seconds)];
      final boosted = [
        for (final level in range)
          trialAt(
            level,
            seconds +
                Economy.extraTimeFor(Duration(seconds: seconds)).inSeconds,
          ).passRate,
      ];
      final firstTry = [for (final trial in trials) trial.passRate];
      failed += firstTry.fold(0.0, (sum, pass) => sum + 1 - pass);
      final size = levels[first - 1].board.size;
      _out.writeln(
        '| $first–$last | $size×$size | $seconds s '
        '| ${_pct(firstTry.reduce(min))}–${_pct(_mean(firstTry))} '
        '| ${_pct(trials.map((t) => t.passWithin(3)).reduce(min))} '
        '| ${_pct(trials.map((t) => t.passRateAmong(experts)).reduce(min))} '
        '| ${_pct(_mean([for (final t in trials) t.outOfTimeRate]))} '
        '| ${_pct(_mean([for (final t in trials) t.outOfStarsRate]))} '
        '| ${_pct(_mean(boosted))} |',
      );
    }
    _out
      ..writeln()
      ..writeln(
        'Across all levels, ${_pct(failed / levels.length)} of first tries fail.',
      )
      ..writeln();
  }

  String _againstBuild9() {
    String time(double seconds) => '${seconds.toStringAsFixed(1)} s';
    final easier = [
      for (final level in levels)
        if (untimed[level.number - 1] < previous[level.number - 1])
          level.number,
    ];
    final unexplained = easier.where((n) => !unfairBefore.contains(n));
    final explained = [
      for (final n in easier.where(unfairBefore.contains))
        'level $n takes ${time(untimed[n - 1])} against '
            '${time(previous[n - 1])}',
    ];
    final others = easier.isEmpty
        ? 'Every level'
        : 'Every level but '
              '${easier.join(', ')}';
    return [
      '$others takes the crowd at least as long to clear, with no clock, as '
          'the level with its number in build 9.',
      if (explained.isNotEmpty)
        'Build 9 had no clock, and its board would not be fair at '
            '$firstTierSeconds s there, so ${explained.join(', ')}, on the '
            'hardest board fair at $firstTierSeconds s.',
      if (unexplained.isNotEmpty)
        'Levels ${unexplained.join(', ')} are easier than in build 9 for no '
            'reason: regenerate them.',
    ].join(' ');
  }

  void _levels() {
    _out
      ..writeln('## Levels')
      ..writeln()
      ..writeln(
        'Untimed is the median clear with no clock, and build 9 the same '
        'for the level with that number in build 9.',
      )
      ..writeln()
      ..writeln(
        '| Level | Blocks | Locks | Turning | Time | Untimed | Build 9 | First try | 3 tries | Bumps |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
      );
    for (final level in levels) {
      final seconds = level.timeLimit.inSeconds;
      final trial = trialAt(level.number, seconds);
      final board = level.board;
      final index = level.number - 1;
      _out.writeln(
        '| ${level.number} | ${board.blockCount} | ${board.restraints.length} '
        '| ${_turning(board)} | $seconds s '
        '| ${untimed[index].toStringAsFixed(1)} s '
        '| ${previous[index].toStringAsFixed(1)} s '
        '| ${_pct(trial.passRate)} | ${_pct(trial.passWithin(3))} '
        '| ${trial.averageBumps.toStringAsFixed(2)} |',
      );
    }
  }

  void _daily() {
    final daily = DailyPuzzle(pace: model);
    final times = [
      for (var day = 0; day < 60; day++)
        daily
            .puzzleFor(DateTime(2026, 12, 1).add(Duration(days: day)))
            .timeLimit
            .inSeconds,
    ];
    _out
      ..writeln()
      ..writeln('## Daily puzzle')
      ..writeln()
      ..writeln(
        'Each day is timed for its own board, for a new player: at least '
        '${_pct(DailyPuzzle.targetPass)} clear it on the first try and '
        '${_pct(DailyPuzzle.threeTries)} within three tries. '
        'Over 60 days: ${times.reduce(min)}–${times.reduce(max)} s.',
      );
  }

  int _turning(Board board) =>
      board.blocks.where((block) => block.turns).length;

  double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  String _pct(double share) => '${(share * 100).round()} %';
}
