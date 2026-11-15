import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/star_rating.dart';
import '../../state/hint_wallet.dart';
import '../formatting.dart';
import '../game/game_mode.dart';
import '../game/level_result.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/confetti.dart';
import '../widgets/key_button.dart';
import '../widgets/surface_card.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key, required this.result});

  final LevelResult result;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late final AppServices _services = context.read<AppServices>();
  late final AnimationController _badge = AnimationController(
    vsync: this,
    duration: Motion.badge,
  )..forward();
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
        Timer(Motion.badge + Motion.starGap * index, () {
          _stars[index].forward();
          _services.feedback.starEarned();
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _badge.dispose();
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
    if (await _services.ads.showRewarded()) {
      await wallet.add(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCampaign = _result.mode is CampaignMode;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: Confetti()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconKey(
                      icon: Icons.close_rounded,
                      semanticLabel: 'Close',
                      onPressed: () => Navigation.home(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: CurvedAnimation(
                              parent: _badge,
                              curve: Motion.badgeCurve,
                            ),
                            child: const SizedBox.square(
                              dimension: 124,
                              child: KeyButton(
                                tone: KeyTone.success,
                                height: 124,
                                radius: 32,
                                padding: EdgeInsets.zero,
                                onPressed: null,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 72,
                                  color: Palette.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text('Board clear!', style: AppText.title),
                          const SizedBox(height: 8),
                          Text(
                            _message,
                            style: AppText.body,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          _StarRow(controllers: _stars),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              _Stat(
                                value: '${_result.blocks}',
                                label: 'blocks',
                              ),
                              const SizedBox(width: 10),
                              _Stat(value: '${_result.bumps}', label: 'bumps'),
                              const SizedBox(width: 10),
                              _Stat(
                                value: Formatting.clock(_result.time),
                                label: 'time',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  KeyButton(
                    tone: KeyTone.primary,
                    height: 70,
                    onPressed: _next,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isCampaign ? 'Next level' : 'Done'),
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
                  if (_services.ads.offersRewardedAds) ...[
                    const SizedBox(height: 12),
                    KeyButton(
                      tone: KeyTone.reward,
                      height: 56,
                      onPressed: _watchAd,
                      child: const _IconLabel(
                        icon: Icons.videocam_outlined,
                        text: 'Watch a short ad for +1 hint',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.controllers});

  final List<AnimationController> controllers;

  @override
  Widget build(BuildContext context) {
    Widget star(int index, double size, double lift) => Padding(
      padding: EdgeInsets.only(bottom: lift),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.star_rounded, size: size, color: Palette.edge),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: controllers[index],
              curve: Motion.badgeCurve,
            ),
            child: Icon(Icons.star_rounded, size: size, color: Palette.sun),
          ),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [star(0, 64, 0), star(1, 84, 22), star(2, 64, 0)],
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: AppText.number),
            const SizedBox(height: 4),
            Text(label, style: AppText.body.copyWith(fontSize: 15)),
          ],
        ),
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
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
