import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/glyphs.dart';
import '../widgets/looping.dart';
import 'countdown_face.dart';

/// A frozen block: the block in its direction's color under a sheet of ice,
/// with a snowflake badge on its corner. Thick ice is frostier, with a
/// second rim and a 2 on the badge. When a layer cracks, cracks run across
/// the ice with a flash; a tap while frozen makes the ice wobble.
class IceFace extends StatefulWidget {
  const IceFace({
    super.key,
    required this.direction,
    required this.ice,
    this.shakes = 0,
    this.ringColor,
    this.ringWidth = 0,
  });

  final Direction direction;

  /// Layers of ice left, 1 or more.
  final int ice;

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

  late final AnimationController _crack = AnimationController(
    vsync: this,
    duration: Motion.iceCrack,
  );
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: Motion.iceWobble,
  );
  bool _cracked = false;

  @override
  void didUpdateWidget(IceFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ice < oldWidget.ice) {
      _cracked = true;
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
    return AnimatedBuilder(
      animation: Listenable.merge([_crack, _wobble]),
      builder: (context, _) {
        final crack = _crack.isAnimating
            ? Curves.easeOut.transform(_crack.value)
            : _cracked
            ? 1.0
            : 0.0;
        final wobble = _wobble.isAnimating
            ? keyframes(_wobble.value, _wobbleTurns, curve: Curves.easeOut)
            : 0.0;
        return CornerBadge(
          face: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              BlockFace(
                direction: widget.direction,
                ringColor: widget.ringColor,
                ringWidth: widget.ringWidth,
                arrowOpacity: 0.62,
              ),
              Transform.rotate(
                angle: wobble * pi / 180,
                child: CustomPaint(
                  painter: IcePainter(
                    layers: widget.ice,
                    crack: crack,
                    flash: _crack.isAnimating ? 1 - _crack.value : 0,
                  ),
                ),
              ),
            ],
          ),
          badge: (size) => Transform.rotate(
            angle: wobble * 1.6 * pi / 180,
            child: IceBadge(size: size, layers: widget.ice),
          ),
        );
      },
    );
  }
}

/// The ice-blue snowflake badge of a frozen block, with the layers left
/// when there is more than one.
class IceBadge extends StatelessWidget {
  const IceBadge({
    super.key,
    required this.size,
    this.layers = 1,
    this.framed = true,
  });

  final double size;
  final int layers;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final pip = size * 0.56;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
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
        ),
        if (layers > 1)
          // Bottom left, over the frozen block itself, so no neighbour
          // covers it.
          Positioned(
            left: -pip * 0.42,
            bottom: -pip * 0.42,
            width: pip,
            height: pip,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Palette.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x401B2340),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$layers',
                  textScaler: TextScaler.noScaling,
                  style: AppText.number.copyWith(
                    fontSize: pip * 0.7,
                    height: 1,
                    color: Palette.iceDeep,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A sheet of ice over a block: a frosty gradient, a white inner rim (two
/// for thick ice), a deeper band along the bottom, a glossy streak, frost
/// specks, and cracks drawn [crack] of the way when a layer has cracked.
class IcePainter extends CustomPainter {
  const IcePainter({required this.layers, this.crack = 0, this.flash = 0});

  final int layers;
  final double crack;
  final double flash;

  static const List<List<Offset>> _cracks = [
    [Offset(0.6, 0.42), Offset(0.74, 0.26), Offset(0.9, 0.1)],
    [Offset(0.6, 0.42), Offset(0.82, 0.5), Offset(0.98, 0.62)],
    [Offset(0.6, 0.42), Offset(0.44, 0.26), Offset(0.3, 0.06)],
    [Offset(0.6, 0.42), Offset(0.46, 0.64), Offset(0.36, 0.94)],
    [Offset(0.46, 0.64), Offset(0.22, 0.7), Offset(0.06, 0.62)],
  ];

  static const List<(Offset, double)> _frost = [
    (Offset(0.84, 0.18), 1.6),
    (Offset(0.9, 0.3), 1.1),
    (Offset(0.12, 0.76), 1.4),
    (Offset(0.2, 0.86), 1.0),
    (Offset(0.78, 0.84), 1.2),
    (Offset(0.66, 0.12), 0.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final rect = (Offset.zero & size).inflate(2);
    final radius = Radius.circular(min(18, shortest * 0.27) + 2);
    final sheet = RRect.fromRectAndRadius(rect, radius);
    final thick = layers > 1;
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
            Palette.white.withValues(alpha: thick ? 0.9 : 0.8),
            Palette.iceTint.withValues(alpha: thick ? 0.82 : 0.68),
            Palette.iceEdge.withValues(alpha: thick ? 0.86 : 0.74),
          ],
          const [0, 0.55, 1],
        ),
    );
    canvas.drawRect(
      Rect.fromLTRB(rect.left, rect.bottom - 6, rect.right, rect.bottom),
      Paint()..color = Palette.iceDeep.withValues(alpha: 0.16),
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
    canvas.drawLine(glossStart, glossEnd, gloss);
    canvas.drawCircle(
      glossEnd + Offset(shortest * 0.12, -shortest * 0.02),
      gloss.strokeWidth * 0.42,
      gloss,
    );
    final frost = Paint()..color = Palette.white.withValues(alpha: 0.85);
    for (final (at, radius) in _frost) {
      canvas.drawCircle(
        Offset(at.dx * size.width, at.dy * size.height),
        radius * shortest / 42,
        frost,
      );
    }
    if (crack > 0) {
      _paintCracks(canvas, size);
    }
    if (flash > 0) {
      canvas.drawRRect(
        sheet,
        Paint()..color = Palette.white.withValues(alpha: 0.4 * flash),
      );
    }
    canvas.restore();
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.white.withValues(alpha: 0.9);
    canvas.drawRRect(sheet.deflate(1.5), rim);
    if (thick) {
      canvas.drawRRect(
        sheet.deflate(5),
        rim
          ..strokeWidth = 1.4
          ..color = Palette.iceEdge.withValues(alpha: 0.9),
      );
    }
  }

  void _paintCracks(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final crackLine in _cracks) {
      final path = Path()
        ..moveTo(
          crackLine.first.dx * size.width,
          crackLine.first.dy * size.height,
        );
      for (final point in crackLine.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      for (final metric in path.computeMetrics()) {
        final drawn = metric.extractPath(0, metric.length * crack);
        canvas
          ..drawPath(
            drawn.shift(const Offset(0.8, 0.8)),
            line
              ..strokeWidth = 1.8
              ..color = Palette.iceDeep.withValues(alpha: 0.35),
          )
          ..drawPath(
            drawn,
            line
              ..strokeWidth = 1.6
              ..color = Palette.white,
          );
      }
    }
  }

  @override
  bool shouldRepaint(IcePainter oldDelegate) =>
      oldDelegate.layers != layers ||
      oldDelegate.crack != crack ||
      oldDelegate.flash != flash;
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
