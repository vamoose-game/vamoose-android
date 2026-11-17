import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/economy.dart';
import '../../domain/tap_outcome.dart';
import '../../state/coin_wallet.dart';
import '../../state/daily_controller.dart';
import '../../state/game_session.dart';
import '../../state/hint_wallet.dart';
import '../../state/progress_controller.dart';
import '../formatting.dart';
import '../game/board_view.dart';
import '../game/game_mode.dart';
import '../game/level_result.dart';
import '../game/locks_intro.dart';
import '../game/hint_sheet.dart';
import '../game/pause_dialog.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/key_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/stars_row.dart';
import '../widgets/surface_card.dart';
import 'level_complete_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final AppServices _services = context.read<AppServices>();
  late final GameSession _session = GameSession(
    widget.mode.boardFrom(_services),
  );
  int _round = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _introduceLocks());
  }

  Future<void> _introduceLocks() async {
    final settings = _services.settings;
    if (!mounted ||
        !LocksIntro.appliesTo(_session.board) ||
        settings.hasSeenIntro(LocksIntro.id)) {
      return;
    }
    _session.pause();
    await LocksIntro.show(context, chapter: widget.mode.chapter);
    await settings.markIntroSeen(LocksIntro.id);
    if (!mounted) {
      return;
    }
    setState(() => _round++);
    _session.resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _session.resume();
    } else {
      _session.pause();
    }
  }

  void _onOutcome(TapOutcome outcome) {
    final feedback = _services.feedback;
    switch (outcome) {
      case BlockLeaves():
        feedback.blockLeft(streak: _session.streak);
        if (_session.isCleared) {
          unawaited(_finish());
        }
      case BlockBumps():
        feedback.blockBumped();
    }
  }

  Future<void> _finish() async {
    final opening = Future<void>.delayed(Motion.resultsDelay);
    final progress = context.read<ProgressController>();
    final daily = context.read<DailyController>();
    final coins = context.read<CoinWallet>();
    final earned = switch (widget.mode) {
      CampaignMode(:final level) => Economy.levelReward(
        bestBefore: progress.starsFor(level),
        stars: _session.stars,
      ),
      DailyMode() => daily.isTodayCompleted ? 0 : Economy.dailyPuzzleReward,
    };
    switch (widget.mode) {
      case CampaignMode(:final level):
        await progress.record(level, _session.stars);
      case DailyMode():
        await daily.completeToday();
    }
    await coins.earn(earned);
    if (!mounted) {
      return;
    }
    _services.feedback.boardCleared();
    final result = LevelResult(
      mode: widget.mode,
      bumps: _session.bumps,
      stars: _session.stars,
      coins: earned,
    );
    await opening;
    if (!mounted || !_session.isCleared) {
      return;
    }
    unawaited(
      Navigator.of(context).pushReplacement(
        Navigation.page<void>(LevelCompleteScreen(result: result)),
      ),
    );
  }

  Future<void> _hint() async {
    if (_session.hasActiveHint || _session.isCleared) {
      return;
    }
    final hasHint = await context.read<HintWallet>().spend();
    if (!mounted) {
      return;
    }
    if (hasHint || await HintSheet.show(context)) {
      _session.revealHint();
      _services.feedback.hintShown();
    }
  }

  void _restart() {
    setState(() => _round++);
    _session.restart();
  }

  Future<void> _pause() async {
    if (_session.isCleared) {
      return;
    }
    _session.pause();
    final choice = await PauseDialog.show(
      context,
      subtitle:
          '${widget.mode.title} · ${Formatting.plural(_session.blocksLeft, 'block')} left',
    );
    if (!mounted) {
      return;
    }
    switch (choice) {
      case PauseChoice.resume:
        _session.resume();
      case PauseChoice.restart:
        _restart();
      case PauseChoice.levels:
        Navigation.levels(context);
      case PauseChoice.home:
        Navigation.home(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hints = context.select<HintWallet, int>((wallet) => wallet.count);
    final colors = BoardColors.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.statusBar(colors.brightness),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(title: widget.mode.title, onPause: _pause),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: _session,
                  builder: (context, _) => _Stats(session: _session),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SurfaceCard(
                        radius: 28,
                        raised: true,
                        color: colors.board,
                        padding: const EdgeInsets.all(13),
                        child: ListenableBuilder(
                          listenable: _session,
                          builder: (context, _) => BoardView(
                            key: ValueKey(_round),
                            session: _session,
                            onOutcome: _onOutcome,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: KeyButton(
                        onPressed: _restart,
                        child: const _ButtonLabel(
                          icon: Icons.restart_alt_rounded,
                          text: 'Restart',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KeyButton(
                        tone: KeyTone.hint,
                        onPressed: _hint,
                        semanticLabel: hints > 0
                            ? 'Use a hint, $hints left'
                            : 'Get a hint with coins or a short video',
                        child: hints > 0
                            ? _ButtonLabel(
                                icon: Icons.lightbulb_outline_rounded,
                                text: 'Hint',
                                trailing: _CountBadge(count: hints),
                              )
                            : const _ButtonLabel(
                                icon: Icons.lightbulb_outline_rounded,
                                text: 'Get hint',
                              ),
                      ),
                    ),
                  ],
                ),
                const AdBannerSlot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onPause});

  final String title;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconKey(
          icon: Icons.chevron_left_rounded,
          semanticLabel: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: Text(
            title,
            style: AppText.pageTitle.copyWith(
              color: BoardColors.of(context).ink,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconKey(
          icon: Icons.pause_rounded,
          semanticLabel: 'Pause',
          onPressed: onPause,
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final cleared = 1 - session.blocksLeft / session.totalBlocks;
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${session.blocksLeft}',
                        style: AppText.number.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'blocks left',
                        style: AppText.body.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    child: ProgressBar(value: cleared, height: 8),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 32, thickness: 1, color: Palette.line),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bumps ',
                        style: AppText.body.copyWith(fontSize: 15),
                      ),
                      TextSpan(
                        text: '${session.bumps}',
                        style: AppText.bodyStrong.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                StarsRow(stars: session.stars, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.icon, required this.text, this.trailing});

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 17)),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppText.bodyStrong.copyWith(
          color: Palette.white,
          fontSize: 14,
          height: 1,
        ),
      ),
    );
  }
}
