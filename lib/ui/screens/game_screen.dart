import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/tap_outcome.dart';
import '../../state/daily_controller.dart';
import '../../state/game_session.dart';
import '../../state/hint_wallet.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../formatting.dart';
import '../game/board_view.dart';
import '../game/game_mode.dart';
import '../game/level_result.dart';
import '../game/out_of_hints_sheet.dart';
import '../game/pause_dialog.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
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
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
        feedback.blockLeft();
        if (_session.isCleared) {
          unawaited(_finish());
        }
      case BlockBumps():
        feedback.blockBumped();
    }
  }

  Future<void> _finish() async {
    _finishing = true;
    final progress = context.read<ProgressController>();
    final daily = context.read<DailyController>();
    final hints = context.read<HintWallet>();
    final navigator = Navigator.of(context);
    var earnedHint = false;
    switch (widget.mode) {
      case CampaignMode(:final level):
        await progress.record(level, _session.stars);
      case DailyMode():
        earnedHint = await daily.completeToday();
        if (earnedHint) {
          await hints.add(1);
        }
    }
    await Future<void>.delayed(
      Motion.blockLeaves + const Duration(milliseconds: 250),
    );
    if (!mounted) {
      return;
    }
    _services.feedback.boardCleared();
    unawaited(
      navigator.pushReplacement(
        Navigation.page<void>(
          LevelCompleteScreen(
            result: LevelResult(
              mode: widget.mode,
              blocks: _session.totalBlocks,
              bumps: _session.bumps,
              time: _session.elapsed,
              stars: _session.stars,
              earnedHint: earnedHint,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _hint() async {
    if (_session.hasActiveHint || _finishing) {
      return;
    }
    final wallet = context.read<HintWallet>();
    var hasHint = await wallet.spend();
    if (!hasHint && mounted) {
      hasHint = await OutOfHintsSheet.show(context) && await wallet.spend();
    }
    if (hasHint && mounted) {
      _session.revealHint();
      _services.feedback.hintShown();
    }
  }

  void _restart() {
    if (_finishing) {
      return;
    }
    setState(() => _round++);
    _session.restart();
  }

  Future<void> _pause() async {
    if (_finishing) {
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
    final easyMode = context.select<SettingsController, bool>(
      (settings) => settings.easyMode,
    );
    final hints = context.select<HintWallet, int>((wallet) => wallet.count);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: ListenableBuilder(
            listenable: _session,
            builder: (context, _) => Column(
              children: [
                _Header(mode: widget.mode, onPause: _pause),
                const SizedBox(height: 16),
                _Stats(session: _session),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SurfaceCard(
                        radius: 28,
                        padding: const EdgeInsets.all(12),
                        child: BoardView(
                          key: ValueKey(_round),
                          session: _session,
                          easyMode: easyMode,
                          onOutcome: _onOutcome,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SurfaceCard(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Tap a block. If nothing is in its way, it slides off the board.',
                      style: TextStyle(
                        fontFamily: AppText.family,
                        fontSize: 16,
                        height: 1.4,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: KeyButton(
                        onPressed: _restart,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restart_alt_rounded),
                              SizedBox(width: 10),
                              Text('Restart'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KeyButton(
                        tone: KeyTone.hint,
                        onPressed: _hint,
                        semanticLabel: 'Hint, $hints left',
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded),
                              const SizedBox(width: 8),
                              const Text('Hint'),
                              const SizedBox(width: 10),
                              _CountBadge(count: hints),
                            ],
                          ),
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
  const _Header({required this.mode, required this.onPause});

  final GameMode mode;
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
          child: Column(
            children: [
              Text(mode.label, style: AppText.label),
              const SizedBox(height: 2),
              Text(
                mode.title,
                style: AppText.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${session.blocksLeft}',
                          style: AppText.number,
                        ),
                        const TextSpan(
                          text: '  blocks left',
                          style: AppText.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: cleared, color: Palette.down, height: 8),
                ],
              ),
            ),
            const VerticalDivider(width: 32, thickness: 1, color: Palette.edge),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Bumps ', style: AppText.body),
                      TextSpan(
                        text: '${session.bumps}',
                        style: AppText.bodyStrong.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                StarsRow(stars: session.stars, size: 22),
              ],
            ),
          ],
        ),
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
