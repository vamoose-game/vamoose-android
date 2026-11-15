import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/daily_puzzle.dart';
import '../../state/daily_controller.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/key_button.dart';
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
    final streak = daily.currentStreak;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              const PageHeader(title: 'Daily puzzle'),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SurfaceCard(
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Palette.alert,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_outlined,
                                color: Palette.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$streak-day streak',
                                    style: AppText.heading,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _streakHint(daily),
                                    style: AppText.body.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Best',
                                  style: AppText.body.copyWith(fontSize: 15),
                                ),
                                Text(
                                  '${daily.bestStreak}',
                                  style: AppText.number,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final day in daily.currentWeek) ...[
                            if (day != daily.currentWeek.first)
                              const SizedBox(width: 6),
                            Expanded(
                              child: _DayChip(day: day, daily: daily),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      SurfaceCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatting.longDate(today),
                                        style: AppText.heading.copyWith(
                                          fontSize: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 18,
                                        color: Palette.ink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+1 hint',
                                        style: AppText.bodyStrong.copyWith(
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Palette.mist,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: MiniBoard(board: board, gap: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 9,
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
                            const SizedBox(height: 20),
                            KeyButton(
                              tone: KeyTone.primary,
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
        const SizedBox(width: 6),
        const Text('New puzzle in ', style: AppText.body),
        Text(
          Formatting.countdown(widget.daily.timeUntilNextPuzzle),
          style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: Palette.ink, width: 2.5) : null,
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              Formatting.weekdayShort(day),
              style: AppText.body.copyWith(fontSize: 13),
            ),
          ),
          FittedBox(
            child: Text(
              '${day.day}',
              style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox.square(
            dimension: 22,
            child: done
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.down,
                      borderRadius: BorderRadius.circular(6),
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                : Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: missed ? Palette.edge : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body.copyWith(fontSize: 15)),
          Text(value, style: AppText.heading.copyWith(fontSize: 18)),
        ],
      ),
    );
  }
}
