import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/star_rating.dart';
import '../../services/ads/ad_service.dart';
import '../../state/hint_wallet.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../game/level_result.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/confetti.dart';
import '../widgets/entrance.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/surface_card.dart';
import '../widgets/toast.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key, required this.result});

  final LevelResult result;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  static const Duration _firstStar = Duration(milliseconds: 500);
  static const Offset _rise = Offset(0, 16);

  late final AppServices _services = context.read<AppServices>();
  late final List<AnimationController> _stars = [
    for (var index = 0; index < StarRating.max; index++)
      AnimationController(vsync: this, duration: Motion.starPop),
  ];
  final List<Timer> _timers = [];

  LevelResult get _result => widget.result;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < _result.stars; index++) {
      _timers.add(
        Timer(_firstStar + Motion.starGap * index, () {
          _stars[index].forward();
          _services.feedback.starEarned(index);
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final star in _stars) {
      star.dispose();
    }
    super.dispose();
  }

  String get _message {
    final subject = switch (_result.mode) {
      CampaignMode(:final level) => 'Level $level',
      DailyMode() => 'Today\'s puzzle',
    };
    final outcome = _result.bumps == 0
        ? '$subject done. No bumps at all.'
        : '$subject done with ${Formatting.plural(_result.bumps, 'bump')}.';
    return _result.earnedHint ? '$outcome +1 hint for you.' : outcome;
  }

  Future<void> _next() async {
    final mode = _result.mode;
    if (mode is! CampaignMode) {
      Navigator.of(context).pop();
      return;
    }
    if (mode.level >= _services.levels.count) {
      Navigation.levels(context);
      return;
    }
    if (_services.interstitials.shouldShowAfterClearing(mode.level)) {
      await _services.ads.showInterstitial();
    }
    if (mounted) {
      await Navigation.replay(context, CampaignMode(mode.level + 1));
    }
  }

  Future<void> _watchAd() async {
    final wallet = context.read<HintWallet>();
    final outcome = await _services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await wallet.add(1);
    }
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case RewardOutcome.earned:
        Toast.show(context, '+1 hint added');
      case RewardOutcome.unavailable:
        Toast.show(context, 'No video right now. Try again soon.');
      case RewardOutcome.skipped:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCampaign = _result.mode is CampaignMode;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Confetti(
                pieces: Confetti.drift,
                fall: constraints.maxHeight * 0.65,
                turns: 420 / 360,
                loop: true,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconKey(
                      icon: Icons.close_rounded,
                      semanticLabel: 'Close and go to levels',
                      onPressed: () => Navigation.levels(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const Entrance(
                            duration: Duration(milliseconds: 600),
                            curve: Motion.popCurve,
                            fromScale: 0.2,
                            fromTurns: -20 / 360,
                            child: _Badge(),
                          ),
                          const SizedBox(height: 22),
                          Entrance(
                            delay: const Duration(milliseconds: 250),
                            offset: _rise,
                            child: Column(
                              children: [
                                Text(
                                  'Board clear!',
                                  style: AppText.title.copyWith(fontSize: 32),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _message,
                                  style: AppText.body.copyWith(fontSize: 17),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          _StarRow(controllers: _stars),
                          const SizedBox(height: 22),
                          Entrance(
                            delay: const Duration(seconds: 1),
                            offset: _rise,
                            child: Row(
                              children: [
                                _Stat(
                                  value: '${_result.blocks}',
                                  label: 'blocks',
                                ),
                                const SizedBox(width: 10),
                                _Stat(
                                  value: '${_result.bumps}',
                                  label: 'bumps',
                                ),
                                const SizedBox(width: 10),
                                _Stat(
                                  value: Formatting.clock(_result.time),
                                  label: 'time',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Entrance(
                    delay: const Duration(milliseconds: 1150),
                    offset: _rise,
                    child: Column(
                      children: [
                        KeyButton(
                          tone: KeyTone.primary,
                          height: 66,
                          radius: 22,
                          onPressed: _next,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isCampaign ? 'Next level' : 'Done',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: KeyButton(
                                height: 58,
                                onPressed: () =>
                                    Navigation.replay(context, _result.mode),
                                child: const _IconLabel(
                                  icon: Icons.restart_alt_rounded,
                                  text: 'Replay',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: KeyButton(
                                height: 58,
                                onPressed: () => Navigation.levels(context),
                                child: const _IconLabel(
                                  icon: Icons.grid_view_rounded,
                                  text: 'Levels',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_services.ads.isReady) ...[
                          const SizedBox(height: 12),
                          KeyButton(
                            tone: KeyTone.reward,
                            height: 56,
                            onPressed: _watchAd,
                            child: const _IconLabel(
                              icon: Icons.videocam_outlined,
                              text: 'Watch a short ad for +1 hint',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400E9F8A),
            offset: Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      child: const KeyButton(
        tone: KeyTone.success,
        height: 120,
        radius: 38,
        padding: EdgeInsets.zero,
        onPressed: null,
        child: Icon(Icons.check_rounded, size: 66, color: Palette.white),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.controllers});

  static final Animatable<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.25), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 40),
  ]);

  static final Animatable<double> _turns = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: -30 / 360, end: 8 / 360),
      weight: 60,
    ),
    TweenSequenceItem(tween: Tween(begin: 8 / 360, end: 0.0), weight: 40),
  ]);

  final List<AnimationController> controllers;

  @override
  Widget build(BuildContext context) {
    Widget star(int index, double size, double lift) => Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: Stack(
        alignment: Alignment.center,
        children: [
          StarGlyph(size: size, filled: false, strokeWidth: 1),
          AnimatedBuilder(
            animation: controllers[index],
            builder: (context, child) {
              final t = Curves.easeOut.transform(controllers[index].value);
              return Opacity(
                opacity: (t / 0.6).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: _turns.transform(t) * 6.283185307179586,
                  child: Transform.scale(
                    scale: _scale.transform(t),
                    child: child,
                  ),
                ),
              );
            },
            child: StarGlyph(size: size, strokeWidth: 1),
          ),
        ],
      ),
    );
    return Semantics(
      label: 'Stars earned',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          star(0, 54, 0),
          const SizedBox(width: 8),
          star(1, 72, 12),
          const SizedBox(width: 8),
          star(2, 54, 0),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfaceCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: AppText.number.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppText.body.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({
    required this.icon,
    required this.text,
    this.fontSize = 17,
  });

  final IconData icon;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
