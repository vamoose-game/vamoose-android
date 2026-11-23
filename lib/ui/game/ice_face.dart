import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/glyphs.dart';
import '../widgets/looping.dart';
import 'countdown_face.dart';

/// A frozen block: the block in its direction's color under a sheet of ice,
/// with a snowflake badge on its corner. There is no number: thicker ice
/// is frostier, has more rims and hides the arrow more, and each block that
/// leaves next to it cracks the ice more, with a flash and a few chips
/// flying off, until the last one shatters it. A tap while frozen makes the
/// ice wobble.
class IceFace extends StatefulWidget {
  const IceFace({
    super.key,
    required this.direction,
    required this.ice,
    this.cracks = 0,
    this.variant = 0,
    this.shakes = 0,
    this.ringColor,
    this.ringWidth = 0,
  });

  final Direction direction;

  /// Layers of ice left, 1 or more.
  final int ice;

  /// Layers already cracked: each shows one more stage of cracks.
  final int cracks;

  /// Picks one of the ways the cracks run, so blocks side by side differ.
  final int variant;

  /// Each change wobbles the ice.
  final int shakes;
  final Color? ringColor;
  final double ringWidth;

  @override
  State<IceFace> createState() => _IceFaceState();
}

class _IceFaceState extends State<IceFace> with TickerProviderStateMixin {
  static const List<Keyframe> _wobbleTurns = [
    (0, 0),
    (0.18, -4),
    (0.38, 3.5),
    (0.58, -2.5),
    (0.78, 1.5),
    (1, 0),
  ];
  static const List<Keyframe> _jolt = [
    (0, 0),
    (0.15, 2.2),
    (0.35, -1.6),
    (0.6, 0.8),
    (1, 0),
  ];

  late final AnimationController _crack = AnimationController(
    vsync: this,
    duration: Motion.iceCrack,
  );
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: Motion.iceWobble,
  );

  @override
  void didUpdateWidget(IceFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cracks > oldWidget.cracks) {
      _crack.forward(from: 0);
    }
    if (widget.shakes != oldWidget.shakes) {
      _wobble.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _crack.dispose();
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thickness = widget.ice + widget.cracks;
    return AnimatedBuilder(
      animation: Listenable.merge([_crack, _wobble]),
      builder: (context, _) {
        final cracking = _crack.isAnimating;
        final growing = cracking ? Curves.easeOut.transform(_crack.value) : 1.0;
        final wobble = _wobble.isAnimating
            ? keyframes(_wobble.value, _wobbleTurns, curve: Curves.easeOut)
            : 0.0;
        final jolt = cracking ? keyframes(_crack.value, _jolt) : 0.0;
        return Transform.translate(
          offset: Offset(jolt, 0),
          child: CornerBadge(
            face: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                BlockFace(
                  direction: widget.direction,
                  ringColor: widget.ringColor,
                  ringWidth: widget.ringWidth,
                  arrowOpacity: IcePainter.arrowOpacityUnder(thickness),
                ),
                Transform.rotate(
                  angle: wobble * pi / 180,
                  child: CustomPaint(
                    painter: IcePainter(
                      thickness: thickness,
                      cracks: widget.cracks,
                      growing: growing,
                      flash: cracking ? 1 - _crack.value : 0,
                      variant: widget.variant,
                    ),
                  ),
                ),
                if (cracking)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ChipsPainter(
                        progress: _crack.value,
                        variant: widget.variant,
                      ),
                    ),
                  ),
              ],
            ),
            badge: (size) => Transform.rotate(
              angle: wobble * 1.6 * pi / 180,
              child: IceBadge(size: size),
            ),
          ),
        );
      },
    );
  }
}

/// The ice-blue snowflake badge of a frozen block.
class IceBadge extends StatelessWidget {
  const IceBadge({super.key, required this.size, this.framed = true});

  final double size;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B8FD8), Palette.ice],
        ),
        shape: BoxShape.circle,
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x4D1B2340),
                  offset: Offset(0, 2),
                  blurRadius: 5,
                ),
                BoxShadow(color: Palette.white, spreadRadius: 2),
              ]
            : null,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: SnowflakeGlyph(size: size * 0.62)),
      ),
    );
  }
}

/// A sheet of ice over a block. [thickness] is how many layers it had: the
/// thicker, the frostier, with one inner rim per layer. [cracks] layers have
/// cracked: each adds a stage of cracks, a big crack first, then many more,
/// the newest stage drawn [growing] of the way. [variant] mirrors the
/// cracks, so neighbouring blocks don't crack alike.
class IcePainter extends CustomPainter {
  const IcePainter({
    required this.thickness,
    this.cracks = 0,
    this.growing = 1,
    this.flash = 0,
    this.variant = 0,
  });

  final int thickness;
  final int cracks;
  final double growing;
  final double flash;
  final int variant;

  /// How much of the arrow shows through ice of [thickness] layers.
  static double arrowOpacityUnder(int thickness) => switch (thickness) {
    <= 1 => 0.62,
    2 => 0.5,
    _ => 0.38,
  };

  /// Cracks by stage, with the width they are drawn at, as lines through
  /// points in fractions of the block: long, bold cracks from the point of
  /// impact first, then many more out to the edges, with a web around the
  /// impact.
  static const List<(double, List<List<Offset>>)> _stages = [
    (
      2.6,
      [
        [
          Offset(0.62, 0.4),
          Offset(0.69, 0.3),
          Offset(0.77, 0.21),
          Offset(0.86, 0.1),
        ],
        [
          Offset(0.62, 0.4),
          Offset(0.74, 0.43),
          Offset(0.84, 0.5),
          Offset(0.93, 0.54),
        ],
        [
          Offset(0.62, 0.4),
          Offset(0.54, 0.31),
          Offset(0.44, 0.25),
          Offset(0.33, 0.15),
        ],
        [
          Offset(0.62, 0.4),
          Offset(0.58, 0.52),
          Offset(0.51, 0.63),
          Offset(0.46, 0.76),
        ],
        [Offset(0.62, 0.4), Offset(0.5, 0.45), Offset(0.37, 0.47)],
        [Offset(0.77, 0.21), Offset(0.87, 0.27)],
        [Offset(0.51, 0.63), Offset(0.62, 0.71)],
      ],
    ),
    (
      2,
      [
        [Offset(0.86, 0.1), Offset(0.94, 0.02)],
        [Offset(0.93, 0.54), Offset(1, 0.62)],
        [Offset(0.33, 0.15), Offset(0.2, 0.1), Offset(0.06, 0.02)],
        [Offset(0.46, 0.76), Offset(0.41, 0.88), Offset(0.37, 1)],
        [Offset(0.37, 0.47), Offset(0.22, 0.53), Offset(0, 0.5)],
        [
          Offset(0.69, 0.3),
          Offset(0.74, 0.43),
          Offset(0.58, 0.52),
          Offset(0.5, 0.45),
          Offset(0.54, 0.31),
          Offset(0.69, 0.3),
        ],
        [Offset(0.77, 0.21), Offset(0.82, 0.37), Offset(0.84, 0.5)],
        [Offset(0.51, 0.63), Offset(0.41, 0.58), Offset(0.37, 0.47)],
        [Offset(0.22, 0.53), Offset(0.17, 0.74), Offset(0.06, 0.9)],
        [Offset(0.84, 0.5), Offset(0.76, 0.75), Offset(0.84, 0.97)],
        [Offset(0.44, 0.25), Offset(0.4, 0.05)],
        [Offset(0.62, 0.71), Offset(0.66, 0.9)],
      ],
    ),
  ];

  static const List<(Offset, double)> _frost = [
    (Offset(0.84, 0.18), 1.6),
    (Offset(0.9, 0.3), 1.1),
    (Offset(0.12, 0.76), 1.4),
    (Offset(0.2, 0.86), 1.0),
    (Offset(0.78, 0.84), 1.2),
    (Offset(0.66, 0.12), 0.9),
    (Offset(0.32, 0.9), 1.3),
    (Offset(0.06, 0.4), 1.0),
    (Offset(0.94, 0.72), 1.2),
  ];

  Offset _at(Offset fraction, Size size) {
    final x = variant.isOdd ? 1 - fraction.dx : fraction.dx;
    final y = variant % 4 >= 2 ? 1 - fraction.dy : fraction.dy;
    return Offset(x * size.width, y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final rect = (Offset.zero & size).inflate(2);
    final radius = Radius.circular(min(18, shortest * 0.27) + 2);
    final sheet = RRect.fromRectAndRadius(rect, radius);
    final layers = thickness.clamp(1, 3);
    final weaker = 1 - 0.06 * cracks;
    final alphas = switch (layers) {
      1 => (0.8, 0.68, 0.74),
      2 => (0.88, 0.8, 0.84),
      _ => (0.93, 0.88, 0.9),
    };
    canvas
      ..save()
      ..clipRRect(sheet);
    canvas.drawRRect(
      sheet,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [
            Palette.white.withValues(alpha: alphas.$1 * weaker),
            Palette.iceTint.withValues(alpha: alphas.$2 * weaker),
            Palette.iceEdge.withValues(alpha: alphas.$3 * weaker),
          ],
          const [0, 0.55, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.bottom - 6, rect.right, rect.bottom),
      Paint()..color = Palette.iceDeep.withValues(alpha: 0.12 + 0.04 * layers),
    );
    // A glossy streak at the top left, and a spark after it.
    final gloss = Paint()
      ..color = Palette.white.withValues(alpha: 0.95)
      ..strokeWidth = max(3, shortest * 0.085)
      ..strokeCap = StrokeCap.round;
    final glossStart = Offset(size.width * 0.13, size.height * 0.2);
    final glossEnd = Offset(
      size.width * 0.13 + min(size.width * 0.34, shortest * 0.5),
      size.height * 0.2 - shortest * 0.09,
    );
    canvas
      ..drawLine(glossStart, glossEnd, gloss)
      ..drawCircle(
        glossEnd + Offset(shortest * 0.12, -shortest * 0.02),
        gloss.strokeWidth * 0.42,
        gloss,
      );
    final frost = Paint()..color = Palette.white.withValues(alpha: 0.85);
    for (final (at, dot) in _frost.take(3 + 3 * layers)) {
      canvas.drawCircle(
        Offset(at.dx * size.width, at.dy * size.height),
        dot * shortest / 42,
        frost,
      );
    }
    if (cracks > 0) {
      // The point the ice gave way at.
      canvas.drawCircle(
        _at(_stages.first.$2.first.first, size),
        max(2.2, shortest * 0.06) * (cracks == 1 ? growing : 1),
        Paint()..color = Palette.white,
      );
    }
    for (var stage = 0; stage < cracks && stage < _stages.length; stage++) {
      final (width, lines) = _stages[stage];
      _paintStage(
        canvas,
        size,
        lines,
        width: width,
        drawn: stage == cracks - 1 ? growing : 1,
      );
    }
    if (flash > 0) {
      canvas.drawRRect(
        sheet,
        Paint()..color = Palette.white.withValues(alpha: 0.45 * flash),
      );
    }
    canvas.restore();
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.white.withValues(alpha: 0.9);
    canvas.drawRRect(sheet.deflate(1.5), rim);
    rim
      ..strokeWidth = 1.4
      ..color = Palette.iceEdge.withValues(alpha: 0.9);
    for (var inner = 1; inner < layers; inner++) {
      final inset = 1.5 + 3.6 * inner;
      if (inset * 2 < shortest * 0.6) {
        canvas.drawRRect(sheet.deflate(inset), rim);
      }
    }
  }

  void _paintStage(
    Canvas canvas,
    Size size,
    List<List<Offset>> lines, {
    required double width,
    required double drawn,
  }) {
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width + 0.4
      ..color = Palette.iceDeep.withValues(alpha: 0.45);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = Palette.white;
    for (final points in lines) {
      final path = Path();
      final start = _at(points.first, size);
      path.moveTo(start.dx, start.dy);
      for (final point in points.skip(1)) {
        final next = _at(point, size);
        path.lineTo(next.dx, next.dy);
      }
      for (final metric in path.computeMetrics()) {
        final part = metric.extractPath(0, metric.length * drawn);
        canvas
          ..drawPath(part.shift(const Offset(0.8, 0.8)), shadow)
          ..drawPath(part, line);
      }
    }
  }

  @override
  bool shouldRepaint(IcePainter oldDelegate) =>
      oldDelegate.thickness != thickness ||
      oldDelegate.cracks != cracks ||
      oldDelegate.growing != growing ||
      oldDelegate.flash != flash ||
      oldDelegate.variant != variant;
}

/// A few chips of ice flying off as the ice cracks, [progress] of the way.
class _ChipsPainter extends CustomPainter {
  const _ChipsPainter({required this.progress, required this.variant});

  final double progress;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress);
    final shortest = size.shortestSide;
    final impact = Offset(
      (variant.isOdd ? 0.38 : 0.62) * size.width,
      (variant % 4 >= 2 ? 0.6 : 0.4) * size.height,
    );
    final fill = Paint()..color = Palette.white.withValues(alpha: 1 - t);
    for (var chip = 0; chip < 4; chip++) {
      final angle = -pi / 2 + (chip - 1.5) * 0.7 + (variant.isOdd ? 0.3 : 0);
      final at =
          impact +
          Offset(cos(angle), sin(angle)) * shortest * 0.55 * t +
          Offset(0, shortest * 0.4 * t * t);
      final side = shortest * 0.07 * (1 - 0.4 * t);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - side)
          ..lineTo(at.dx + side, at.dy + side * 0.6)
          ..lineTo(at.dx - side * 0.8, at.dy + side * 0.4)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ChipsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.variant != variant;
}

/// Ice breaking off a block that has just thawed, [progress] of the way
/// through: shards burst outward, spin and fade over a white flash, and the
/// snowflake pops off its corner.
class IceShatter extends StatelessWidget {
  const IceShatter({super.key, required this.progress});

  static const List<Keyframe> _badgeScale = [(0, 1), (0.25, 1.35), (1, 0.2)];
  static const List<Keyframe> _badgeRise = [(0.25, 0), (1, -16)];
  static const List<Keyframe> _badgeFade = [(0.25, 1), (1, 0)];

  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return IgnorePointer(
      child: CornerBadge(
        face: CustomPaint(painter: _ShardsPainter(t)),
        badge: (size) => Opacity(
          opacity: keyframes(t, _badgeFade),
          child: Transform.translate(
            offset: Offset(0, keyframes(t, _badgeRise)),
            child: Transform.scale(
              scale: keyframes(t, _badgeScale),
              child: IceBadge(size: size),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShardsPainter extends CustomPainter {
  const _ShardsPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final center = size.center(Offset.zero);
    if (t < 0.45) {
      final flash = 1 - t / 0.45;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).inflate(2),
          Radius.circular(min(18, shortest * 0.27) + 2),
        ),
        Paint()..color = Palette.white.withValues(alpha: 0.6 * flash * flash),
      );
    }
    const shards = 10;
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Palette.white.withValues(alpha: (1 - t) * 0.95);
    for (var index = 0; index < shards; index++) {
      final angle = index * 2 * pi / shards + 0.35 * (index.isEven ? 1 : -1);
      final reach =
          (size.width / 2 + shortest * 0.35) * (0.55 + 0.1 * (index % 3));
      final at =
          center +
          Offset(cos(angle) * size.width / 2, sin(angle) * size.height / 2) *
              0.45 +
          Offset(cos(angle), sin(angle)) * reach * t +
          Offset(0, shortest * 0.5 * t * t);
      final side = shortest * (0.16 + 0.05 * (index % 3)) * (1 - 0.35 * t);
      final turn = angle + t * (index.isEven ? 3.2 : -2.6);
      final path = Path();
      for (var corner = 0; corner < 3; corner++) {
        final cornerAngle =
            turn + corner * 2 * pi / 3 + (corner == 1 ? 0.5 : 0);
        final point =
            at +
            Offset(cos(cornerAngle), sin(cornerAngle)) *
                side *
                (corner == 2 ? 0.7 : 1);
        corner == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
      fill.shader = ui.Gradient.linear(
        at - Offset(side, side),
        at + Offset(side, side),
        [
          Palette.white.withValues(alpha: (1 - t) * 0.95),
          Palette.iceEdge.withValues(alpha: (1 - t) * 0.85),
        ],
      );
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, edge);
    }
  }

  @override
  bool shouldRepaint(_ShardsPainter oldDelegate) => oldDelegate.t != t;
}
