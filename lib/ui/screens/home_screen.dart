import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/direction.dart';
import '../../state/daily_controller.dart';
import '../../state/hint_wallet.dart';
import '../../state/progress_controller.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/entrance.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/logo.dart';
import '../widgets/looping.dart';
import '../widgets/pill.dart';
import '../widgets/surface_card.dart';
import '../widgets/tap_ring.dart';
import 'daily_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hints = context.watch<HintWallet>().count;
    final progress = context.watch<ProgressController>();
    final daily = context.watch<DailyController>();
    final level = progress.currentLevel;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  Pill(
                    icon: const SizedBox.square(
                      dimension: 22,
                      child: Stack(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            color: Palette.sun,
                            size: 22,
                          ),
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Palette.ink,
                            size: 22,
                          ),
                        ],
                      ),
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
              const Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _DemoBoard(),
                        SizedBox(height: 34),
                        Entrance(
                          duration: Duration(milliseconds: 600),
                          offset: Offset(0, 16),
                          child: Column(
                            children: [
                              FittedBox(child: Wordmark(withKey: true)),
                              SizedBox(height: 12),
                              Text(
                                'Slide every block off the board.',
                                style: TextStyle(
                                  fontFamily: AppText.family,
                                  fontSize: 18,
                                  height: 1.4,
                                  color: Palette.slate,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              KeyButton(
                tone: KeyTone.primary,
                height: 76,
                radius: 24,
                padding: const EdgeInsets.fromLTRB(14, 0, 22, 0),
                semanticLabel: 'Play level $level',
                onPressed: () => Navigation.play(context, CampaignMode(level)),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Palette.sun,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Palette.ink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 2),
                          Text(
                            'Level $level',
                            style: AppText.body.copyWith(
                              color: const Color(0xFFC9D0E4),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 26),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MenuCard(
                      icon: Icons.grid_view_rounded,
                      color: Palette.up,
                      tint: Palette.blueTint,
                      title: 'Levels',
                      detailIcon: const StarGlyph(size: 15),
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
                        size: 16,
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

class _DemoBoard extends StatelessWidget {
  const _DemoBoard();

  static const double _board = 174;
  static const double _cell = 58;

  @override
  Widget build(BuildContext context) {
    Widget place(
      int row,
      int column,
      int width,
      int height,
      Direction direction,
    ) => Positioned(
      left: column * _cell + 3,
      top: row * _cell + 3,
      width: width * _cell - 6,
      height: height * _cell - 6,
      child: BlockFace(direction: direction, arrowSize: 24),
    );
    return ExcludeSemantics(
      child: SurfaceCard(
        radius: 30,
        raised: true,
        padding: const EdgeInsets.all(12),
        child: SizedBox.square(
          dimension: _board,
          child: Looping(
            period: const Duration(milliseconds: 3600),
            builder: (context, t, _) {
              final x = keyframes(t, const [
                (0.30, 0),
                (0.55, 230),
              ], curve: Motion.leaveCurve);
              final away = t > 0.55 && t < 0.72;
              final scale = keyframes(t, const [
                (0.55, 1),
                (0.56, 0.4),
                (0.72, 0.4),
                (0.86, 1),
              ]);
              final opacity = keyframes(t, const [
                (0.30, 1),
                (0.55, 0),
                (0.72, 0),
                (0.86, 1),
              ]);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  place(0, 0, 1, 1, Direction.up),
                  place(1, 0, 1, 2, Direction.down),
                  place(1, 1, 1, 1, Direction.left),
                  place(1, 2, 1, 2, Direction.up),
                  place(2, 1, 1, 1, Direction.down),
                  Positioned(
                    left: _cell + 3,
                    top: 3,
                    width: _cell * 2 - 6,
                    height: _cell - 6,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(away ? 0 : x, 0),
                        child: Transform.scale(
                          scale: scale,
                          child: const BlockFace(
                            direction: Direction.right,
                            arrowSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 94,
                    top: 7,
                    child: TapRing(t: t, start: 0.12, size: 44),
                  ),
                ],
              );
            },
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      alignment: Alignment.centerLeft,
      semanticLabel: title,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  detailIcon,
                  const SizedBox(width: 5),
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
