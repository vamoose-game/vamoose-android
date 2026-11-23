import 'package:material_ui/material_ui.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'countdown_face.dart';

/// The countdown intro loop, a step every [Motion.countdownDemoStep]: a
/// block leaves and the countdown goes from 3 to 2, another leaves and it
/// shows 1 and hurries, then the countdown block leaves itself, out in
/// time.
class CountdownDemo extends StatelessWidget {
  const CountdownDemo({super.key});

  static const double _width = 302;
  static const double _tile = 44;
  static const int _steps = 9;

  static double get _period =>
      (Motion.countdownDemoStep * _steps).inMilliseconds.toDouble();

  static double _at(int step) => step / _steps;

  static double _span(Duration duration) => duration.inMilliseconds / _period;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Palette.well,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shift = (constraints.maxWidth - _width) / 2;
              return Looping(
                period: Motion.countdownDemoStep * _steps,
                builder: (context, t, _) {
                  final step = (t * _steps).floor();
                  final count = switch (step) {
                    < 1 || 8 => 3,
                    < 3 => 2,
                    _ => 1,
                  };
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _block(
                        t,
                        left: shift + 232,
                        top: 14,
                        leaves: 1,
                        distance: -120,
                        child: const BlockFace(direction: Direction.up),
                      ),
                      _block(
                        t,
                        left: shift + 132,
                        top: 62,
                        leaves: 3,
                        distance: 130,
                        child: const BlockFace(direction: Direction.down),
                      ),
                      _block(
                        t,
                        left: shift + 28,
                        top: 62,
                        width: 94,
                        leaves: 5,
                        distance: 300,
                        horizontal: true,
                        child: _counting(t, count),
                      ),
                      if (step == 6 || step == 7)
                        Positioned(
                          left: shift + _width / 2 - 74,
                          top: 53,
                          width: 148,
                          height: 44,
                          child: _OutInTime(t: (t - _at(6)) / _span(_chipIn)),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static const Duration _chipIn = Duration(milliseconds: 300);

  /// The countdown block: its badge pops as it counts down, and on its last
  /// move it pulses while the block wiggles.
  Widget _counting(double t, int count) {
    final ms = t * _period;
    final lastFrom = _at(3) * _period;
    final last = count == 1 && ms >= lastFrom;
    var scale = 1.0;
    for (final ticked in const [1, 3]) {
      final local = (t - _at(ticked)) / _span(Motion.countdownTick);
      if (local >= 0 && local < 1) {
        scale = keyframes(local, const [
          (0, 1),
          (0.35, 1.3),
          (1, 1),
        ], curve: Curves.easeOut);
      }
    }
    var wiggle = 0.0;
    if (last) {
      final since = ms - lastFrom;
      scale = keyframes(
        since %
            Motion.lastMovePulse.inMilliseconds /
            Motion.lastMovePulse.inMilliseconds,
        const [(0, 1), (0.5, 1.2), (1, 1)],
        curve: Curves.easeInOut,
      );
      wiggle = keyframes(
        since % Motion.hurry.inMilliseconds / Motion.hurry.inMilliseconds,
        const [(0.6, 0), (0.66, -3), (0.72, 3), (0.78, -2), (0.84, 0)],
      );
    }
    return Transform.translate(
      offset: Offset(wiggle, 0),
      child: CornerBadge(
        face: const BlockFace(direction: Direction.right),
        badge: (size) => Transform.scale(
          scale: scale,
          child: CountdownBadge(count: count, size: size),
        ),
      ),
    );
  }

  /// A block at ([left], [top]) that leaves on step [leaves], [distance]
  /// along its way, and comes back as the loop starts again.
  Widget _block(
    double t, {
    required double left,
    required double top,
    required int leaves,
    required double distance,
    required Widget child,
    double width = _tile,
    bool horizontal = false,
  }) {
    final from = _at(leaves);
    final gone = from + _span(Motion.blockLeaves);
    final fading = from + _span(Motion.blockFadeDelay);
    final travel = keyframes(t, [
      (from, 0),
      (gone, distance),
      (gone + 0.001, 0),
    ], curve: Motion.leaveCurve);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: _tile,
      child: Opacity(
        opacity: keyframes(t, [(fading, 1), (gone, 0), (0.9, 0), (0.98, 1)]),
        child: Transform.translate(
          offset: horizontal ? Offset(travel, 0) : Offset(0, travel),
          child: Transform.scale(
            scale: keyframes(t, [
              (gone, 1),
              (gone + 0.001, 0.5),
              (0.9, 0.5),
              (0.98, 1),
            ]),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OutInTime extends StatelessWidget {
  const _OutInTime({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final shown = Curves.easeOut.transform(t.clamp(0.0, 1.0));
    return Opacity(
      opacity: shown,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - shown)),
        child: Transform.scale(
          scale: 0.9 + 0.1 * shown,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.mint,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Palette.mintText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Out in time',
                  style: AppText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Palette.mintText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the badge colors mean: moves left, and the last move.
class CountdownLegend extends StatelessWidget {
  const CountdownLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppText.bodyStrong.copyWith(fontSize: 15);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final (count, text) in const [(4, 'Moves left'), (1, 'Last move')])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountdownBadge(count: count, size: 26, framed: false),
              const SizedBox(width: 8),
              Text(text, style: style),
            ],
          ),
      ],
    );
  }
}
