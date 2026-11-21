import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/economy.dart';
import '../../state/daily_controller.dart';
import '../../state/streak_controller.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
import '../widgets/daily_art.dart';
import '../widgets/dashed_box.dart';
import '../widgets/entrance.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';
import '../widgets/mini_board.dart';
import '../widgets/page_header.dart';
import '../widgets/toast.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late final StreakController _streak = context.read<StreakController>();

  @override
  void initState() {
    super.initState();
    unawaited(_streak.refresh());
  }

  Future<void> _collect() async {
    final feedback = context.read<AppServices>().feedback;
    if (await _streak.collect() > 0) {
      feedback.starEarned(2);
    }
  }

  Future<void> _buyFreeze() async {
    if (!await _streak.buyFreeze() && mounted) {
      Toast.show(context, 'Not enough coins');
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakController>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              const PageHeader(title: 'Daily streak', trailing: CoinChip()),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StreakHero(count: streak.count),
                      const SizedBox(height: 18),
                      _Road(streak: streak),
                      const SizedBox(height: 14),
                      if (streak.canCollect)
                        KeyButton(
                          tone: KeyTone.reward,
                          height: 66,
                          radius: 22,
                          onPressed: _collect,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Collect',
                                style: TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              const CoinGlyph(size: 26),
                              const SizedBox(width: 6),
                              Text(
                                '+${streak.reward}',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      else
                        const _Collected(),
                      const SizedBox(height: 14),
                      _FreezeCard(streak: streak, onBuy: _buyFreeze),
                      const SizedBox(height: 14),
                      const _TodaysPuzzle(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(26, 0, 22, 0),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: '$count-day streak',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Entrance(
                      key: ValueKey(count),
                      duration: const Duration(milliseconds: 450),
                      fromScale: 0.8,
                      child: Text(
                        '$count',
                        style: AppText.number.copyWith(
                          color: Palette.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -2.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'day streak',
                        style: AppText.bodyStrong.copyWith(
                          color: Palette.streakText,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const FlameGlyph(width: 64),
        ],
      ),
    );
  }
}

class _Road extends StatelessWidget {
  const _Road({required this.streak});

  final StreakController streak;

  @override
  Widget build(BuildContext context) {
    final marks = streak.marks;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / RoadPainter.width;
        final node = 62 * scale;
        return SizedBox(
          height: RoadPainter.height * scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: marks.length.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, filled, _) =>
                      CustomPaint(painter: RoadPainter(filled: filled.round())),
                ),
              ),
              for (var day = 1; day < Economy.loginRewards.length; day++)
                Positioned(
                  left: RoadPainter.stops[day - 1].dx * scale - node / 2,
                  top: RoadPainter.stops[day - 1].dy * scale - node / 2,
                  width: node,
                  child: _DayNode(
                    day: day,
                    state: _stateOf(day, marks),
                    size: node,
                  ),
                ),
              Positioned(
                left: 0,
                top: 124 * scale,
                width: 160 * scale,
                child: _ChestNode(
                  ready:
                      streak.canCollect &&
                      streak.day == Economy.loginRewards.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _DayState _stateOf(int day, List<StreakMark> marks) {
    if (day <= marks.length) {
      return marks[day - 1] == StreakMark.saved
          ? _DayState.saved
          : _DayState.done;
    }
    return day == streak.day && streak.canCollect
        ? _DayState.today
        : _DayState.next;
  }
}

enum _DayState { done, saved, today, next }

class _DayNode extends StatelessWidget {
  const _DayNode({required this.day, required this.state, required this.size});

  final int day;
  final _DayState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reward = Economy.loginRewards[day - 1];
    return Semantics(
      label: switch (state) {
        _DayState.done => 'Day $day, $reward coins collected',
        _DayState.saved => 'Day $day, missed, saved by a freeze',
        _DayState.today => 'Day $day, $reward coins ready',
        _DayState.next => 'Day $day, $reward coins',
      },
      child: ExcludeSemantics(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                state == _DayState.today
                    ? Looping(
                        period: const Duration(milliseconds: 1800),
                        builder: (context, t, child) => _circle(
                          glow: keyframes(t, const [
                            (0, 0),
                            (0.5, 1),
                            (1, 0),
                          ], curve: Curves.easeInOut),
                        ),
                      )
                    : _circle(glow: 0),
                if (state == _DayState.today)
                  Positioned(
                    top: -32,
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today',
                        style: AppText.bodyStrong.copyWith(
                          color: Palette.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              state == _DayState.saved ? 'Saved' : '+$reward',
              style: AppText.bodyStrong.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: switch (state) {
                  _DayState.done => Palette.slate,
                  _DayState.saved => Palette.ice,
                  _ => Palette.ink,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle({required double glow}) {
    final (fill, edge) = switch (state) {
      _DayState.done => (Palette.down, Palette.darken(Palette.down, 0.2)),
      _DayState.saved => (Palette.iceNode, Palette.iceEdge),
      _DayState.today => (Palette.sun, Palette.sunEdge),
      _DayState.next => (Palette.white, Palette.edge),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: edge,
        boxShadow: [
          if (state == _DayState.today) ...[
            BoxShadow(
              color: Palette.ink.withValues(alpha: 0.18 * (1 - glow)),
              spreadRadius: 4 + 8 * glow,
            ),
            const BoxShadow(color: Palette.ink, spreadRadius: 4),
          ],
          if (state == _DayState.saved)
            const BoxShadow(color: Palette.white, spreadRadius: 3),
        ],
      ),
      padding: EdgeInsets.only(bottom: size * 0.08),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
        child: Center(
          child: switch (state) {
            _DayState.done => Icon(
              Icons.check_rounded,
              color: Palette.white,
              size: size * 0.48,
            ),
            _DayState.saved => Icon(
              Icons.ac_unit_rounded,
              color: Palette.ice,
              size: size * 0.5,
            ),
            _ => CoinGlyph(size: size * 0.56),
          },
        ),
      ),
    );
  }
}

class _ChestNode extends StatelessWidget {
  const _ChestNode({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Day 7: ${Economy.loginRewards.last} coins and 1 streak freeze${ready ? ', ready' : ''}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Transform.scale(
              scale: ready ? 1.08 : 1,
              child: const ChestGlyph(width: 128),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+${Economy.loginRewards.last}',
                  style: AppText.number.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 26,
                  padding: const EdgeInsets.fromLTRB(6, 0, 9, 0),
                  decoration: BoxDecoration(
                    color: Palette.iceTint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.ac_unit_rounded,
                        size: 16,
                        color: Palette.ice,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+1',
                        style: AppText.bodyStrong.copyWith(
                          color: Palette.ice,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Collected extends StatelessWidget {
  const _Collected();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: Palette.mintText),
          const SizedBox(width: 8),
          Text(
            'See you tomorrow',
            style: AppText.bodyStrong.copyWith(
              color: Palette.mintText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreezeCard extends StatelessWidget {
  const _FreezeCard({required this.streak, required this.onBuy});

  final StreakController streak;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final freezes = streak.freezes;
    final full = freezes >= Economy.maxFreezes;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Palette.iceTint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Palette.iceKeyEdge,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.only(bottom: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.ac_unit_rounded, color: Palette.ice),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak freeze',
                  style: AppText.bodyStrong.copyWith(
                    color: Palette.iceDeep,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Semantics(
                  label: '$freezes of ${Economy.maxFreezes} streak freezes',
                  child: Row(
                    children: [
                      for (var slot = 0; slot < Economy.maxFreezes; slot++) ...[
                        if (slot > 0) const SizedBox(width: 6),
                        slot < freezes
                            ? Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Palette.ice,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              )
                            : const DashedBox(
                                color: Palette.iceSlot,
                                radius: 7,
                                child: SizedBox.square(dimension: 22),
                              ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (full)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Full',
                style: AppText.bodyStrong.copyWith(color: Palette.ice),
              ),
            )
          else
            KeyButton(
              tone: KeyTone.reward,
              height: 50,
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              semanticLabel:
                  'Buy a streak freeze for ${Economy.freezePrice} coins',
              onPressed: onBuy,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CoinGlyph(size: 22),
                  SizedBox(width: 6),
                  Text('${Economy.freezePrice}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TodaysPuzzle extends StatelessWidget {
  const _TodaysPuzzle();

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyController>();
    final puzzle = context.read<AppServices>().dailyPuzzle.puzzleFor(
      daily.today,
    );
    final solved = daily.isTodayCompleted;
    return KeyButton(
      height: 80,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      semanticLabel: solved
          ? 'Play today\'s puzzle again'
          : 'Play today\'s puzzle for ${Economy.dailyPuzzleReward} coins',
      onPressed: () => Navigation.play(context, DailyMode(daily.today)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Palette.well,
              borderRadius: BorderRadius.circular(15),
            ),
            child: MiniBoard(board: puzzle.board, gap: 1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Today\'s puzzle',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                solved
                    ? _NextPuzzle(daily: daily)
                    : Row(
                        children: [
                          const CoinGlyph(size: 18),
                          const SizedBox(width: 5),
                          Text(
                            '+${Economy.dailyPuzzleReward}',
                            style: AppText.bodyStrong.copyWith(
                              color: Palette.slate,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.timer_outlined,
                            size: 17,
                            color: Palette.slate,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatting.clock(puzzle.timeLimit),
                            style: AppText.bodyStrong.copyWith(
                              color: Palette.slate,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Palette.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Palette.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPuzzle extends StatefulWidget {
  const _NextPuzzle({required this.daily});

  final DailyController daily;

  @override
  State<_NextPuzzle> createState() => _NextPuzzleState();
}

class _NextPuzzleState extends State<_NextPuzzle> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Next in ${Formatting.countdown(widget.daily.timeUntilNextPuzzle)}',
      style: AppText.bodyStrong.copyWith(color: Palette.mintText, fontSize: 15),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
