import 'package:material_ui/material_ui.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'block_marks.dart';

/// The twins intro loop: tapping a twin while the other is blocked bumps
/// both; the block in the way leaves; then one tap sends both twins off.
class TwinsDemo extends StatelessWidget {
  const TwinsDemo({super.key});

  static const double _width = 302;
  static const double _tile = 46;
  static const double _badge = 24;

  static const List<Keyframe> _bump = [
    (0.15, 0),
    (0.17, 8),
    (0.2, -3),
    (0.23, 1),
    (0.25, 0),
  ];
  static const List<Keyframe> _ring = [
    (0.15, 0),
    (0.18, 5),
    (0.27, 5),
    (0.32, 0),
  ];
  static const List<Keyframe> _blockerMove = [
    (0.34, 0),
    (0.48, -220),
    (0.49, 0),
  ];
  static const List<Keyframe> _blockerFade = [
    (0.36, 1),
    (0.48, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _twinsMove = [(0.6, 0), (0.75, 200), (0.76, 0)];
  static const List<Keyframe> _twinsFade = [
    (0.62, 1),
    (0.75, 0),
    (0.88, 0),
    (0.98, 1),
  ];

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
                period: Motion.twinsDemo,
                builder: (context, t, _) {
                  final bump = keyframes(t, _bump, curve: Curves.easeOut);
                  final leave = keyframes(
                    t,
                    _twinsMove,
                    curve: Motion.leaveCurve,
                  );
                  final fade = keyframes(
                    t,
                    _twinsFade,
                    curve: Motion.leaveCurve,
                  );
                  final chain = t < 0.6
                      ? 1.0
                      : (1 - (t - 0.6) / 0.05).clamp(0.0, 1.0);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (chain > 0)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ChainPainter(
                              Offset(shift + 66 + _tile - 4, 22),
                              Offset(shift + 196 + _tile - 4, 22),
                              chain,
                            ),
                          ),
                        ),
                      Positioned(
                        left: shift + 150,
                        top: 88,
                        width: 98,
                        height: _tile,
                        child: Opacity(
                          opacity: keyframes(t, _blockerFade),
                          child: Transform.translate(
                            offset: Offset(
                              keyframes(
                                t,
                                _blockerMove,
                                curve: Motion.leaveCurve,
                              ),
                              0,
                            ),
                            child: BlockFace(
                              direction: Direction.left,
                              ringColor: Palette.ink,
                              ringWidth: keyframes(t, _ring),
                            ),
                          ),
                        ),
                      ),
                      _twin(
                        left: shift + 66,
                        top: 30,
                        direction: Direction.right,
                        offset: Offset(bump + leave, 0),
                        fade: fade,
                      ),
                      _twin(
                        left: shift + 196,
                        top: 30,
                        direction: Direction.down,
                        offset: Offset(0, bump + leave * 0.55),
                        fade: fade,
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

  Widget _twin({
    required double left,
    required double top,
    required Direction direction,
    required Offset offset,
    required double fade,
  }) => Positioned(
    left: left,
    top: top,
    width: _tile,
    height: _tile,
    child: Opacity(
      opacity: fade,
      child: Transform.translate(
        offset: offset,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            BlockFace(direction: direction),
            const Positioned(
              top: -8,
              right: -8,
              width: _badge,
              height: _badge,
              child: BlockBadge(icon: BadgeIcon.link, size: _badge),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChainPainter extends CustomPainter {
  const _ChainPainter(this.from, this.to, this.strength);

  final Offset from;
  final Offset to;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final span = to - from;
    final along = span / span.distance;
    final halo = Paint()..color = Palette.white.withValues(alpha: strength);
    final dot = Paint()..color = Palette.sun.withValues(alpha: strength);
    for (var at = 18.0; at <= span.distance - 18; at += 11) {
      final center = from + along * at;
      canvas
        ..drawCircle(center, 4.2, halo)
        ..drawCircle(center, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_ChainPainter oldDelegate) =>
      oldDelegate.strength != strength || oldDelegate.from != from;
}

/// What the badge colors mean: twins with the same color are one pair.
class TwinsLegend extends StatelessWidget {
  const TwinsLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppText.bodyStrong.copyWith(fontSize: 15);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final (pair, text) in const [(0, 'One pair'), (1, 'Another pair')])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var twin = 0; twin < 2; twin++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: BlockBadge(
                    icon: BadgeIcon.link,
                    size: 24,
                    color: BlockMarks.pairColors[pair],
                    framed: false,
                  ),
                ),
              const SizedBox(width: 4),
              Text(text, style: style),
            ],
          ),
      ],
    );
  }
}
