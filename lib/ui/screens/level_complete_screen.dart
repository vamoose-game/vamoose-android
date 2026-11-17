import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/star_rating.dart';
import '../../services/ads/ad_service.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../game/level_result.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
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

enum _Doubling { none, offer, loading, done }

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  static const Duration _firstStar = Duration(milliseconds: 500);
  static const Duration _spinStart = Duration(milliseconds: 1150);
  static const Duration _countStart = Duration(milliseconds: 1200);
  static const int _countSteps = 14;
  static const Offset _rise = Offset(0, 16);

  late final AppServices _services = context.read<AppServices>();
  late final List<AnimationController> _stars = [
    for (var index = 0; index < StarRating.max; index++)
      AnimationController(vsync: this, duration: Motion.starPop),
  ];
  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: Motion.coinCount,
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Motion.coinSpin,
  );
  final List<Timer> _timers = [];
  late int _earned = _result.coins;
  int _countedFrom = 0;
  late _Doubling _doubling =
      _result.coins > 0 &&
          _services.ads.isReady &&
          !_services.coins.hasDoubled(_result.rewardKey)
      ? _Doubling.offer
      : _Doubling.none;

  LevelResult get _result => widget.result;

  int get _shown {
    final step = (_count.value * _countSteps).floor();
    return _countedFrom +
        ((_earned - _countedFrom) * step / _countSteps).round();
  }

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
    if (_result.coins > 0) {
      _timers
        ..add(Timer(_spinStart, _spin.forward))
        ..add(Timer(_countStart, _count.forward));
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
    _count.dispose();
    _spin.dispose();
    super.dispose();
  }

  String get _message {
    final subject = switch (_result.mode) {
      CampaignMode(:final level) => 'Level $level',
      DailyMode() => 'Today\'s puzzle',
    };
    return _result.bumps == 0
        ? '$subject done. No bumps at all.'
        : '$subject done with ${Formatting.plural(_result.bumps, 'bump')}.';
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

  Future<void> _double() async {
    final wallet = _services.coins;
    setState(() => _doubling = _Doubling.loading);
    final outcome = await _services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await wallet.earn(_earned);
      await wallet.markDoubled(_result.rewardKey);
    }
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case RewardOutcome.earned:
        setState(() {
          _doubling = _Doubling.done;
          _countedFrom = _earned;
          _earned *= 2;
        });
        _count.forward(from: 0);
        _spin.forward(from: 0);
      case RewardOutcome.unavailable:
        setState(() => _doubling = _Doubling.offer);
        Toast.show(context, 'No video right now. Try again soon.');
      case RewardOutcome.skipped:
        setState(() => _doubling = _Doubling.offer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCampaign = _result.mode is CampaignMode;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _count,
                    builder: (context, _) =>
                        CoinChip(pending: _earned - _shown),
                  ),
                  const Spacer(),
                  IconKey(
                    icon: Icons.close_rounded,
                    semanticLabel: 'Close and go to levels',
                    onPressed: () => Navigation.levels(context),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Entrance(
                          duration: Duration(milliseconds: 600),
                          curve: Motion.popCurve,
                          fromScale: 0.2,
                          fromTurns: -20 / 360,
                          child: _Badge(),
                        ),
                        const SizedBox(height: 18),
                        Entrance(
                          delay: const Duration(milliseconds: 250),
                          offset: _rise,
                          child: Column(
                            children: [
                              Text(
                                'Board clear!',
                                style: AppText.title.copyWith(fontSize: 30),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _message,
                                style: AppText.body.copyWith(fontSize: 17),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _StarRow(controllers: _stars),
                        if (_result.coins > 0) ...[
                          const SizedBox(height: 20),
                          Entrance(
                            delay: const Duration(seconds: 1),
                            offset: _rise,
                            child: _CoinsCard(
                              spin: _spin,
                              count: _count,
                              shown: () => _shown,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Entrance(
                delay: const Duration(milliseconds: 1150),
                offset: _rise,
                child: Column(
                  children: [
                    if (_doubling != _Doubling.none) ...[
                      _DoubleKey(doubling: _doubling, onPressed: _double),
                      const SizedBox(height: 12),
                    ],
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
                            height: 56,
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
                            height: 56,
                            onPressed: () => Navigation.levels(context),
                            child: const _IconLabel(
                              icon: Icons.grid_view_rounded,
                              text: 'Levels',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinsCard extends StatelessWidget {
  const _CoinsCard({
    required this.spin,
    required this.count,
    required this.shown,
  });

  final Animation<double> spin;
  final Animation<double> count;
  final int Function() shown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SurfaceCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: spin,
              builder: (context, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(Curves.easeOut.transform(spin.value) * 4 * pi),
                child: child,
              ),
              child: const CoinGlyph(size: 52),
            ),
            const SizedBox(width: 14),
            AnimatedBuilder(
              animation: count,
              builder: (context, _) => Text(
                '+${shown()}',
                style: AppText.number.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoubleKey extends StatelessWidget {
  const _DoubleKey({required this.doubling, required this.onPressed});

  final _Doubling doubling;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return switch (doubling) {
      _Doubling.loading => const _Status(
        color: Palette.cream,
        child: Text('Loading video…', style: TextStyle(fontSize: 17)),
      ),
      _Doubling.done => const _Status(
        color: Palette.mint,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Palette.mintText),
            SizedBox(width: 8),
            Text(
              'Doubled',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Palette.mintText,
              ),
            ),
          ],
        ),
      ),
      _ => KeyButton(
        tone: KeyTone.reward,
        height: 58,
        radius: 20,
        onPressed: onPressed,
        child: const _IconLabel(
          icon: Icons.play_circle_outline_rounded,
          text: 'Double it ×2',
        ),
      ),
    };
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle.merge(
        style: AppText.bodyStrong.copyWith(color: Palette.ink),
        child: child,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
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
        height: 104,
        radius: 34,
        padding: EdgeInsets.zero,
        onPressed: null,
        child: Icon(Icons.check_rounded, size: 58, color: Palette.white),
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

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
