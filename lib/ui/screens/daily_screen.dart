import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/daily_puzzle.dart';
import '../../domain/economy.dart';
import '../../state/daily_controller.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/coin.dart';
import '../widgets/entrance.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';
import '../widgets/mini_board.dart';
import '../widgets/page_header.dart';
import '../widgets/surface_card.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyController>();
    final today = daily.today;
    final board = context.read<AppServices>().dailyPuzzle.boardFor(today);
    final week = daily.currentWeek;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              const PageHeader(title: 'Daily puzzle'),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const _FlameKey(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${daily.currentStreak}-day streak',
                                    style: AppText.heading,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _streakHint(daily),
                                    style: AppText.body.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Best',
                                  style: AppText.body.copyWith(fontSize: 15),
                                ),
                                Text(
                                  '${daily.bestStreak}',
                                  style: AppText.heading,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var index = 0; index < week.length; index++) ...[
                            if (index > 0) const SizedBox(width: 6),
                            Expanded(
                              child: week[index] == today
                                  ? _DayChip(day: week[index], daily: daily)
                                  : Entrance(
                                      delay: Duration(milliseconds: index * 50),
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      offset: const Offset(0, 12),
                                      child: _DayChip(
                                        day: week[index],
                                        daily: daily,
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      SurfaceCard(
                        radius: 26,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TODAY',
                                        style: AppText.label.copyWith(
                                          color: Palette.alert,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        Formatting.longDate(today),
                                        style: AppText.heading,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Palette.cream,
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CoinGlyph(size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        '+${Economy.dailyPuzzleReward}',
                                        style: AppText.bodyStrong.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 166,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Palette.well,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: MiniBoard(board: board, gap: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 130,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Fact(
                                        label: 'Board',
                                        value: '${board.size}×${board.size}',
                                      ),
                                      _Fact(
                                        label: 'Blocks',
                                        value: '${board.blockCount}',
                                      ),
                                      const _Fact(
                                        label: 'Level',
                                        value: DailyPuzzle.difficulty,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            KeyButton(
                              tone: KeyTone.primary,
                              height: 62,
                              onPressed: () =>
                                  Navigation.play(context, DailyMode(today)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow_rounded),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      daily.isTodayCompleted
                                          ? 'Play again'
                                          : 'Play today\'s puzzle',
                                      style: const TextStyle(fontSize: 19),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Countdown(daily: daily),
            ],
          ),
        ),
      ),
    );
  }
}

String _streakHint(DailyController daily) {
  if (daily.isTodayCompleted) {
    return 'Solved today. See you tomorrow.';
  }
  if (daily.currentStreak == 0) {
    return 'Solve today to start a streak';
  }
  return 'Solve today to make it ${daily.currentStreak + 1}';
}

class _FlameKey extends StatelessWidget {
  const _FlameKey();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 54,
      child: ShadedTile(
        color: Palette.right,
        radius: BorderRadius.circular(18),
        edge: 5,
        child: Looping(
          period: const Duration(milliseconds: 1600),
          child: const Icon(
            Icons.local_fire_department_outlined,
            color: Palette.white,
            size: 30,
          ),
          builder: (context, t, child) {
            final wave = keyframes(t, const [
              (0, 0),
              (0.5, 1),
              (1, 0),
            ], curve: Curves.easeInOut);
            return Transform.rotate(
              angle: -4 / 180 * 3.141592653589793 * wave,
              child: Transform.scale(scale: 1 + 0.08 * wave, child: child),
            );
          },
        ),
      ),
    );
  }
}

class _Countdown extends StatefulWidget {
  const _Countdown({required this.daily});

  final DailyController daily;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule_rounded, size: 18, color: Palette.slate),
        const SizedBox(width: 8),
        Text('New puzzle in ', style: AppText.body.copyWith(fontSize: 15)),
        Text(
          Formatting.countdown(widget.daily.timeUntilNextPuzzle),
          style: AppText.bodyStrong.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.daily});

  final DateTime day;
  final DailyController daily;

  @override
  Widget build(BuildContext context) {
    final isToday = day == daily.today;
    final done = daily.isCompleted(day);
    final missed = !done && day.isBefore(daily.today);
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          child: Text(
            Formatting.weekdayShort(day),
            style: AppText.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            '${day.day}',
            style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox.square(
          dimension: 22,
          child: done
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.down,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Palette.white,
                  ),
                )
              : isToday
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.sun,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
              : Center(
                  child: missed
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Palette.muted,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
        ),
      ],
    );
    if (!isToday) {
      return SizedBox(
        height: 88,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: content,
        ),
      );
    }
    return Looping(
      period: const Duration(milliseconds: 1800),
      child: content,
      builder: (context, t, child) {
        final wave = keyframes(t, const [
          (0, 0),
          (0.5, 1),
          (1, 0),
        ], curve: Curves.easeInOut);
        return SizedBox(
          height: 88,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.ink, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Palette.ink.withValues(alpha: 0.12 * wave),
                  spreadRadius: 5 * wave,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.bodyStrong.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
