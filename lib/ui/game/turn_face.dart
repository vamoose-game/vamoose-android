import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/glyphs.dart';

/// A turning block: round, the color of the way it faces now, with a turn
/// badge and a slowly circling dashed ring. Whenever [direction] changes it
/// turns a quarter clockwise with a small overshoot and takes on the new
/// color, carrying on from wherever a turn still under way has got to.
class TurnFace extends StatefulWidget {
  const TurnFace({
    super.key,
    required this.direction,
    this.ringColor,
    this.ringWidth = 0,
    this.badge = true,
  });

  final Direction direction;
  final Color? ringColor;
  final double ringWidth;
  final bool badge;

  @override
  State<TurnFace> createState() => _TurnFaceState();
}

class _TurnFaceState extends State<TurnFace> with TickerProviderStateMixin {
  static final Curve _turning = Interval(
    Motion.turnDelay.inMilliseconds / _total.inMilliseconds,
    1,
    curve: Motion.popCurve,
  );
  static final Curve _recolor = Interval(
    (Motion.turnDelay.inMilliseconds + 20) / _total.inMilliseconds,
    (Motion.turnDelay + Motion.turnColor).inMilliseconds /
        _total.inMilliseconds,
    curve: Curves.ease,
  );
  static const Duration _total = Duration(milliseconds: 500);

  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: _total,
    value: 1,
  );
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: Motion.orbit,
  );
  late double _from = widget.direction.index.toDouble();
  late double _to = _from;
  Color? _fromColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _orbit.isAnimating) {
      _orbit.stop();
    } else if (!still && !_orbit.isAnimating) {
      _orbit.repeat();
    }
  }

  @override
  void didUpdateWidget(TurnFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction) {
      final quarters =
          (widget.direction.index - oldWidget.direction.index) %
          Direction.values.length;
      _fromColor = _color(BoardColors.of(context), oldWidget.direction);
      _from = _quarters;
      _to += quarters;
      _turn.forward(from: 0);
    }
  }

  double get _quarters =>
      _from + (_to - _from) * _turning.transform(_turn.value);

  Color _color(BoardColors colors, Direction direction) {
    final target = colors.forDirection(direction);
    return Color.lerp(
      _fromColor ?? target,
      target,
      _recolor.transform(_turn.value),
    )!;
  }

  @override
  void dispose() {
    _turn.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final badge = (shortest * 0.48).clamp(16.0, 22.0);
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _turn,
              builder: (context, _) {
                return RoundFace(
                  color: _color(colors, widget.direction),
                  quarters: _quarters,
                  orbit: _orbit,
                  ringColor: widget.ringColor,
                  ringWidth: widget.ringWidth,
                );
              },
            ),
            if (widget.badge)
              Positioned(
                top: -badge * 0.35,
                right: -badge * 0.35,
                width: badge,
                height: badge,
                child: TurnBadge(size: badge),
              ),
          ],
        );
      },
    );
  }
}

/// The round body of a turning block, its arrow [quarters] quarter turns
/// clockwise from up and its dashed ring turned by [orbit].
class RoundFace extends StatelessWidget {
  const RoundFace({
    super.key,
    required this.color,
    required this.quarters,
    this.orbit,
    this.ringColor,
    this.ringWidth = 0,
  });

  final Color color;
  final double quarters;
  final Animation<double>? orbit;
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final ring = ringColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: ring == null || ringWidth <= 0
                ? null
                : Border.all(
                    color: ring,
                    width: ringWidth,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
          ),
          child: ShadedTile(
            color: color,
            radius: BorderRadius.circular(shortest / 2),
            edge: (shortest * 0.09).clamp(3.0, 5.0),
            child: SizedBox.expand(
              child: Transform.rotate(
                angle: (quarters - 1) * pi / 2,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(shortest * 0.1),
                        child: CustomPaint(
                          painter: _OrbitRing(
                            orbit ?? kAlwaysCompleteAnimation,
                          ),
                        ),
                      ),
                    ),
                    ArrowGlyph(
                      direction: Direction.right,
                      size: min(22, shortest * 0.4),
                      strokeWidth: 3.4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The yellow badge with a turn arrow that marks a turning block.
class TurnBadge extends StatelessWidget {
  const TurnBadge({super.key, required this.size, this.framed = true});

  final double size;

  /// Whether a shadow and a white ring lift it off the block it sits on.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.sun,
        shape: BoxShape.circle,
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x4D1B2340),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
                BoxShadow(color: Palette.white, spreadRadius: 2),
              ]
            : null,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: TurnGlyph(size: size * 0.6)),
      ),
    );
  }
}

class _OrbitRing extends CustomPainter {
  _OrbitRing(this.orbit) : super(repaint: orbit);

  final Animation<double> orbit;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = Palette.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashes = 12;
    const sweep = 2 * pi / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = orbit.value * 2 * pi;
    for (var dash = 0; dash < dashes; dash++) {
      canvas.drawArc(rect, start + dash * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbitRing oldDelegate) => oldDelegate.orbit != orbit;
}
