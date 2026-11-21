import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/economy.dart';
import '../../domain/star_rating.dart';
import '../../state/extra_time_wallet.dart';
import '../../state/game_session.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';

/// Sizes for the row above the board: regular, or compact on narrow phones.
final class HudMetrics {
  const HudMetrics({
    required this.height,
    required this.star,
    required this.starGap,
    required this.padding,
    required this.icon,
    required this.fontSize,
    required this.gap,
  });

  static const HudMetrics regular = HudMetrics(
    height: 52,
    star: 30,
    starGap: 4,
    padding: 14,
    icon: 22,
    fontSize: 22,
    gap: 10,
  );

  static const HudMetrics compact = HudMetrics(
    height: 48,
    star: 26,
    starGap: 3,
    padding: 11,
    icon: 20,
    fontSize: 20,
    gap: 8,
  );

  final double height;
  final double star;
  final double starGap;
  final double padding;
  final double icon;
  final double fontSize;
  final double gap;

  double get radius => height * 0.35;
}

/// The row above the board: stars left, the extra-time key and the clock.
///
/// On narrow phones it switches to [HudMetrics.compact], and the key and
/// clock scale down rather than overflow if space is still short.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.session, required this.onAddTime});

  /// Widths below this get the compact sizes.
  static const double compactBelow = 345;

  final GameSession session;
  final VoidCallback onAddTime;

  /// The clock turns red for the last quarter of the time, at least 3 s.
  static int lowFrom(Duration limit) =>
      max(3, (limit.inSeconds * 0.25).round());

  @override
  Widget build(BuildContext context) {
    final boosters = context.select<ExtraTimeWallet, int>(
      (wallet) => wallet.count,
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = constraints.maxWidth < compactBelow
              ? HudMetrics.compact
              : HudMetrics.regular;
          return ListenableBuilder(
            listenable: session,
            builder: (context, _) => Row(
              children: [
                RepaintBoundary(
                  child: StarsPill(stars: session.stars, metrics: metrics),
                ),
                SizedBox(width: metrics.gap),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Keyed, so the clock keeps its state (and its
                          // +time float) when the extra-time key goes.
                          if (boosters > 0 && session.canAddTime) ...[
                            RepaintBoundary(
                              key: const ValueKey('extra-time'),
                              child: ExtraTimeKey(
                                count: boosters,
                                seconds: Economy.extraTimeFor(session.timeLimit)
                                    .inSeconds,
                                metrics: metrics,
                                onPressed: onAddTime,
                              ),
                            ),
                            SizedBox(width: metrics.gap),
                          ],
                          RepaintBoundary(
                            key: const ValueKey('timer'),
                            child: TimerPill(
                              seconds: session.secondsLeft,
                              lowFrom: lowFrom(session.timeLimit),
                              bonus: session.bonus,
                              over: session.isOver,
                              metrics: metrics,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StarsPill extends StatefulWidget {
  const StarsPill({
    super.key,
    required this.stars,
    this.metrics = HudMetrics.regular,
  });

  final int stars;
  final HudMetrics metrics;

  @override
  State<StarsPill> createState() => _StarsPillState();
}

class _StarsPillState extends State<StarsPill>
    with SingleTickerProviderStateMixin {
  static const List<Keyframe> _scale = [
    (0, 1),
    (0.3, 1.4),
    (0.6, 0.85),
    (1, 1),
  ];
  static const List<Keyframe> _turn = [(0, 0), (0.3, -16), (0.6, 8), (1, 0)];

  late final AnimationController _lose = AnimationController(
    vsync: this,
    duration: Motion.starLose,
  );
  int? _lost;

  @override
  void didUpdateWidget(StarsPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stars < oldWidget.stars) {
      _lost = widget.stars;
      _lose.forward(from: 0);
    } else if (widget.stars > oldWidget.stars) {
      _lost = null;
      _lose.value = 0;
    }
  }

  @override
  void dispose() {
    _lose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    return Semantics(
      label: '${widget.stars} of ${StarRating.max} stars left',
      child: ExcludeSemantics(
        child: _Pill(
          metrics: metrics,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < StarRating.max; index++)
                Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : metrics.starGap,
                  ),
                  child: index == _lost
                      ? AnimatedBuilder(
                          animation: _lose,
                          builder: (context, child) {
                            final t = Curves.easeOut.transform(_lose.value);
                            return Transform.rotate(
                              angle: keyframes(t, _turn) * pi / 180,
                              child: Transform.scale(
                                scale: keyframes(t, _scale),
                                child: child,
                              ),
                            );
                          },
                          child: StarGlyph(size: metrics.star, filled: false),
                        )
                      : StarGlyph(
                          size: metrics.star,
                          filled: index < widget.stars,
                          strokeWidth: 1.3,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The countdown. Red and pulsing near the end; shows the extra time as it
/// is added.
class TimerPill extends StatefulWidget {
  const TimerPill({
    super.key,
    required this.seconds,
    required this.lowFrom,
    this.bonus = Duration.zero,
    this.over = false,
    this.metrics = HudMetrics.regular,
  });

  final ValueListenable<int> seconds;
  final int lowFrom;
  final Duration bonus;
  final bool over;
  final HudMetrics metrics;

  @override
  State<TimerPill> createState() => _TimerPillState();
}

class _TimerPillState extends State<TimerPill> with TickerProviderStateMixin {
  late final AnimationController _added = AnimationController(
    vsync: this,
    duration: Motion.plusFloat,
  );

  @override
  void didUpdateWidget(TimerPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bonus > oldWidget.bonus) {
      _added.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _added.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.seconds,
      builder: (context, seconds, _) {
        final low = seconds <= widget.lowFrom && !widget.over;
        final time = Formatting.clock(Duration(seconds: seconds));
        final metrics = widget.metrics;
        final pill = AnimatedContainer(
          duration: Motion.progress,
          height: metrics.height,
          padding: EdgeInsets.fromLTRB(
            metrics.padding,
            0,
            metrics.padding + 4,
            0,
          ),
          decoration: BoxDecoration(
            color: low ? Palette.orangeTint : Palette.white,
            borderRadius: BorderRadius.circular(metrics.radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: metrics.icon,
                color: low ? Palette.danger : Palette.ink,
              ),
              SizedBox(width: metrics.gap - 2),
              Text(
                time,
                style: AppText.number.copyWith(
                  fontSize: metrics.fontSize,
                  fontWeight: FontWeight.w700,
                  color: low ? Palette.danger : Palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
        return Semantics(
          label: '$time left',
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (low)
                  Looping(
                    period: Motion.timerPulse,
                    child: pill,
                    builder: (context, t, child) => Transform.scale(
                      scale: keyframes(t, const [
                        (0, 1),
                        (0.5, 1.06),
                        (1, 1),
                      ], curve: Curves.easeInOut),
                      child: child,
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: _added,
                    child: pill,
                    builder: (context, child) => Transform.scale(
                      scale: _added.isAnimating
                          ? keyframes(_added.value, const [
                              (0, 1),
                              (0.2, 1.14),
                              (0.64, 1),
                            ])
                          : 1,
                      child: child,
                    ),
                  ),
                Positioned(
                  left: -64,
                  width: 56,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _PlusTime(added: _added, bonus: widget.bonus),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlusTime extends StatelessWidget {
  const _PlusTime({required this.added, required this.bonus});

  final Animation<double> added;
  final Duration bonus;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: added,
        builder: (context, child) {
          if (!added.isAnimating) {
            return const SizedBox.shrink();
          }
          final t = Curves.easeOut.transform(added.value);
          return Opacity(
            opacity: keyframes(t, const [(0, 0), (0.25, 1), (1, 0)]),
            child: Transform.translate(
              offset: Offset(0, 6 - 26 * t),
              child: child,
            ),
          );
        },
        child: Text(
          '+${Formatting.clock(bonus)}',
          style: AppText.number.copyWith(fontSize: 16, color: Palette.mintText),
        ),
      ),
    );
  }
}

/// Spends one extra-time booster for +[seconds] s.
class ExtraTimeKey extends StatefulWidget {
  const ExtraTimeKey({
    super.key,
    required this.count,
    required this.seconds,
    required this.onPressed,
    this.metrics = HudMetrics.regular,
  });

  final int count;
  final int seconds;
  final VoidCallback onPressed;
  final HudMetrics metrics;

  @override
  State<ExtraTimeKey> createState() => _ExtraTimeKeyState();
}

class _ExtraTimeKeyState extends State<ExtraTimeKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrive = AnimationController(
    vsync: this,
    duration: Motion.boosterDelay + Motion.boosterIn,
  )..forward();

  late final Animation<double> _in = CurvedAnimation(
    parent: _arrive,
    curve: Interval(
      Motion.boosterDelay.inMilliseconds / _arrive.duration!.inMilliseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void dispose() {
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _in,
      child: ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(_in),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            KeyButton(
              tone: KeyTone.boost,
              height: widget.metrics.height,
              radius: widget.metrics.radius,
              padding: EdgeInsets.fromLTRB(
                widget.metrics.padding - 3,
                0,
                widget.metrics.padding,
                0,
              ),
              semanticLabel:
                  'Add ${widget.seconds} seconds, ${widget.count} left',
              onPressed: widget.onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_time_rounded, size: widget.metrics.icon - 2),
                  const SizedBox(width: 5),
                  Text(
                    '+${widget.seconds}s',
                    style: TextStyle(
                      fontSize: widget.metrics.fontSize - 4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -7,
              right: -7,
              child: IgnorePointer(child: CountDot(count: widget.count)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small dark count bubble for a key.
class CountDot extends StatelessWidget {
  const CountDot({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Palette.mist, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppText.bodyStrong.copyWith(
          color: Palette.white,
          fontSize: 12,
          height: 1,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.metrics, required this.child});

  final HudMetrics metrics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: metrics.height,
      padding: EdgeInsets.symmetric(horizontal: metrics.padding),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(metrics.radius),
      ),
      child: child,
    );
  }
}
