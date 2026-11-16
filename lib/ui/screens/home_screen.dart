import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/block.dart';
import '../../domain/board.dart';
import '../../domain/chapters.dart';
import '../../domain/direction.dart';
import '../../state/daily_controller.dart';
import '../../state/hint_wallet.dart';
import '../../state/progress_controller.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/key_button.dart';
import '../widgets/logo.dart';
import '../widgets/mini_board.dart';
import '../widgets/pill.dart';
import '../widgets/surface_card.dart';
import 'daily_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final Board _hero = Board(
    size: 3,
    blocks: const [
      Block(id: 0, row: 0, column: 0, length: 1, direction: Direction.up),
      Block(id: 1, row: 0, column: 1, length: 2, direction: Direction.right),
      Block(id: 2, row: 1, column: 0, length: 2, direction: Direction.down),
      Block(id: 3, row: 1, column: 1, length: 1, direction: Direction.left),
      Block(id: 4, row: 2, column: 1, length: 1, direction: Direction.down),
      Block(id: 5, row: 1, column: 2, length: 2, direction: Direction.up),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final hints = context.watch<HintWallet>().count;
    final progress = context.watch<ProgressController>();
    final daily = context.watch<DailyController>();
    final level = progress.currentLevel;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Pill(
                    icon: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Palette.sun,
                      size: 22,
                    ),
                    text: Formatting.plural(hints, 'hint'),
                  ),
                  const Spacer(),
                  IconKey(
                    icon: Icons.settings_outlined,
                    semanticLabel: 'Settings',
                    onPressed: () => Navigator.of(context)
                        .push(Navigation.page<void>(const SettingsScreen())),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 206,
                          child: SurfaceCard(
                            radius: 30,
                            padding: const EdgeInsets.all(14),
                            child: MiniBoard(board: _hero, fadedIds: const {1}),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const FittedBox(child: Wordmark(withKey: true)),
                        const SizedBox(height: 10),
                        const Text(
                          'Slide every block off the board.',
                          style: AppText.body,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              KeyButton(
                tone: KeyTone.primary,
                height: 82,
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                semanticLabel: 'Play level $level',
                onPressed: () => Navigation.play(context, CampaignMode(level)),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Palette.sun,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Palette.ink,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Play',
                            style: AppText.heading.copyWith(
                              color: Palette.white,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'Level $level · ${Chapters.of(level).name}',
                            style: AppText.body.copyWith(
                              color: const Color(0xFFC9CFE0),
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 26),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MenuCard(
                      icon: Icons.grid_view_rounded,
                      color: Palette.up,
                      tint: Palette.blueTint,
                      title: 'Levels',
                      detailIcon: const Icon(
                        Icons.star_rounded,
                        color: Palette.sun,
                        size: 18,
                      ),
                      detail: '${progress.totalStars} of ${progress.maxStars}',
                      onPressed: () => Navigation.levels(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MenuCard(
                      icon: Icons.calendar_today_outlined,
                      color: Palette.alert,
                      tint: Palette.orangeTint,
                      title: 'Daily puzzle',
                      detailIcon: const Icon(
                        Icons.local_fire_department_outlined,
                        color: Palette.alert,
                        size: 18,
                      ),
                      detail: daily.currentStreak > 0
                          ? '${daily.currentStreak}-day streak'
                          : (daily.isTodayCompleted
                                ? 'Solved today'
                                : 'New today'),
                      onPressed: () =>
                          Navigator.of(context)
                              .push(Navigation.page<void>(const DailyScreen())),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.detailIcon,
    required this.detail,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final Widget detailIcon;
  final String detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return KeyButton(
      height: 136,
      radius: 22,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      semanticLabel: title,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.button,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  detailIcon,
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      detail,
                      style: AppText.body.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
