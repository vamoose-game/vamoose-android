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
import '../game/fail_sheet.dart';
import '../game/game_hud.dart';
import '../game/game_mode.dart';
import '../game/hint_sheet.dart';
import '../game/intros.dart';
import '../game/level_result.dart';
import '../game/pause_dialog.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/key_button.dart';
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
    widget.mode.puzzleFrom(_services),
    stopwatch: _services.stopwatch,
  );
  int _round = 0;
  bool _away = false;
  bool _failing = false;
  int? _ticked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session
      ..addListener(_watchSession)
      ..secondsLeft.addListener(_tickDown);
    WidgetsBinding.instance.addPostFrameCallback((_) => _introduce());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final away = state != AppLifecycleState.resumed;
    if (away != _away) {
      _away = away;
      away ? _session.hold() : _session.release();
    }
  }

  /// Shows each rule this level uses for the first time, with the clock
  /// held, then flies the blocks in again.
  Future<void> _introduce() async {
    final settings = _services.settings;
    final fresh = [
      for (final intro in Intros.all)
        if (intro.appliesTo(_session.board) && !settings.hasSeenIntro(intro.id))
          intro,
    ];
    if (!mounted || fresh.isEmpty) {
      return;
    }
    _session.hold();
    for (final intro in fresh) {
      await intro.show(context);
      await settings.markIntroSeen(intro.id);
      if (!mounted) {
        return;
      }
    }
    _session.restart();
    setState(() => _round++);
    _session.release();
  }

  void _watchSession() {
    final failure = _session.failure;
    if (failure != null && !_failing) {
      _failing = true;
      unawaited(_fail(failure));
    }
  }

  void _tickDown() {
    final seconds = _session.secondsLeft.value;
    if (_session.isRunning &&
        seconds > 0 &&
        seconds <= GameHud.lowFrom(_session.timeLimit) &&
        seconds != _ticked) {
      _ticked = seconds;
      _services.feedback.clockTicked();
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

  Future<void> _fail(Failure failure) async {
    _services.feedback.levelFailed();
    await _services.lives.spend();
    await Future<void>.delayed(Motion.failDelay);
    if (!mounted || _session.failure != failure) {
      return;
    }
    final choice = await FailSheet.show(context, failure: failure);
    if (!mounted) {
      return;
    }
    switch (choice) {
      case FailChoice.retry:
        _restart();
      case FailChoice.levels:
        Navigation.levels(context);
    }
  }

  Future<void> _finish() async {
    final opening = Future<void>.delayed(Motion.resultsDelay);
    final progress = context.read<ProgressController>();
    final daily = context.read<DailyController>();
    final coins = context.read<CoinWallet>();
    final stars = _session.stars;
    final earned = switch (widget.mode) {
      CampaignMode(:final level) => Economy.levelReward(
        bestBefore: progress.starsFor(level),
        stars: stars,
      ),
      DailyMode() => daily.isTodayCompleted ? 0 : Economy.dailyPuzzleReward,
    };
    switch (widget.mode) {
      case CampaignMode(:final level):
        await progress.record(level, stars);
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
      stars: stars,
      coins: earned,
      time: _session.elapsed,
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
    if (_session.hasActiveHint || _session.isOver) {
      return;
    }
    var granted = await context.read<HintWallet>().spend();
    if (!mounted) {
      return;
    }
    if (!granted) {
      _session.hold();
      granted = await HintSheet.show(context);
      _session.release();
    }
    if (granted && mounted && !_session.isOver) {
      _session.revealHint();
      _services.feedback.hintShown();
    }
  }

  Future<void> _addTime() async {
    final boosters = _services.extraTime;
    if (!_session.canAddTime || !await boosters.spend()) {
      return;
    }
    if (_session.addTime(Economy.extraTimeFor(_session.timeLimit))) {
      _ticked = null;
      _services.feedback.timeAdded();
    } else {
      await boosters.add(1);
    }
  }

  void _restart() {
    _failing = false;
    _ticked = null;
    _session.restart();
    setState(() => _round++);
  }

  /// A failed go always ends at the fail sheet, which asks for a life when
  /// none are left, so the Restart key waits for it.
  void _restartKey() {
    if (!_failing) {
      _restart();
    }
  }

  Future<void> _pause() async {
    if (_session.isOver) {
      return;
    }
    _session.hold();
    final choice = await PauseDialog.show(
      context,
      subtitle:
          '${widget.mode.title} · ${Formatting.clock(Duration(seconds: _session.secondsLeft.value))}',
    );
    if (!mounted) {
      return;
    }
    // Leaving keeps the clock held, so it can't run out on the way.
    switch (choice) {
      case PauseChoice.resume:
        _session.release();
      case PauseChoice.restart:
        _session.release();
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _session.hold();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.statusBar(colors.brightness),
        child: Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Header(title: widget.mode.title, onPause: _pause),
                  const SizedBox(height: 14),
                  GameHud(session: _session, onAddTime: _addTime),
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
                            builder: (context, _) {
                              final round = _round;
                              return BoardView(
                                key: ValueKey(round),
                                session: _session,
                                onOutcome: _onOutcome,
                                onLanded: () {
                                  if (round == _round) {
                                    _session.start();
                                  }
                                },
                              );
                            },
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
                          onPressed: _restartKey,
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
                              : 'Get a hint',
                          child: hints > 0
                              ? _ButtonLabel(
                                  icon: Icons.lightbulb_outline_rounded,
                                  text: 'Hint',
                                  trailing: _CountBadge(count: hints),
                                )
                              : const _ButtonLabel(
                                  icon: Icons.play_circle_outline_rounded,
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
          if (trailing case final trailing?) ...[
            const SizedBox(width: 10),
            trailing,
          ],
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
