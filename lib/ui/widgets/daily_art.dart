import 'dart:math';

import 'package:flutter/widgets.dart';

import '../theme/palette.dart';
import 'looping.dart';

class FlameGlyph extends StatelessWidget {
  const FlameGlyph({super.key, this.width = 76});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(milliseconds: 1800),
      builder: (context, t, child) {
        final wave = sin(t * 2 * pi);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(
            1 + 0.03 * wave,
            1 - 0.035 * wave,
            1,
          )..rotateZ(0.03 * sin(t * 4 * pi)),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(width, width * 80 / 64),
        painter: const _FlamePainter(),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final outer = Path()
      ..moveTo(32, 3)
      ..cubicTo(41, 17, 55, 27, 55, 48)
      ..arcToPoint(const Offset(9, 48), radius: const Radius.circular(23))
      ..cubicTo(9, 36, 15, 28, 21, 22)
      ..cubicTo(21, 32, 25, 38, 31, 40)
      ..cubicTo(29, 28, 27, 16, 32, 3)
      ..close();
    final inner = Path()
      ..moveTo(32, 30)
      ..cubicTo(37, 38, 45, 42, 45, 54)
      ..arcToPoint(const Offset(19, 54), radius: const Radius.circular(13))
      ..cubicTo(19, 46, 24, 42, 27, 38)
      ..cubicTo(28, 44, 30, 46, 32, 47)
      ..cubicTo(31, 41, 31, 35, 32, 30)
      ..close();
    canvas
      ..drawPath(outer, Paint()..color = Palette.right)
      ..drawPath(inner, Paint()..color = Palette.sun)
      ..drawOval(
        Rect.fromCenter(center: const Offset(32, 62), width: 12, height: 14),
        Paint()..color = Palette.cream,
      );
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => false;
}

class ChestGlyph extends StatelessWidget {
  const ChestGlyph({super.key, this.width = 150});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(milliseconds: 2600),
      builder: (context, t, _) => CustomPaint(
        size: Size(width, width * 118 / 150),
        painter: _ChestPainter(t),
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter(this.t);

  static const List<(Offset, double, double)> _sparkles = [
    (Offset(14, 39), 9, 0),
    (Offset(136, 21), 7, 0.5 / 1.6),
    (Offset(140, 71), 5.6, 1 / 1.6),
  ];

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 150);
    final bob = sin(t * 2 * pi);
    canvas
      ..save()
      ..translate(75, 100)
      ..rotate(-1.5 * pi / 180 * (1 - bob) / 2)
      ..translate(-75, -100 - 5 * (1 - bob) / 2);
    _chest(canvas);
    canvas.restore();
    final seconds = t * 2.6;
    for (final (center, reach, delay) in _sparkles) {
      final phase = ((seconds / 1.6) - delay) % 1;
      final glow = 0.5 - 0.5 * cos(phase * 2 * pi);
      _sparkle(canvas, center, reach * (0.4 + 0.6 * glow), 0.2 + 0.8 * glow);
    }
  }

  void _chest(Canvas canvas) {
    Paint fill(Color color) => Paint()..color = color;
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(75, 108), width: 104, height: 14),
        fill(Palette.ink.withValues(alpha: 0.12)),
      )
      ..drawPath(
        Path()
          ..moveTo(28, 52)
          ..lineTo(28, 40)
          ..arcToPoint(
            const Offset(122, 40),
            radius: const Radius.elliptical(47, 30),
          )
          ..lineTo(122, 52)
          ..close(),
        fill(const Color(0xFFD9783A)),
      )
      ..drawPath(
        Path()
          ..moveTo(34, 50)
          ..lineTo(34, 42)
          ..arcToPoint(
            const Offset(116, 42),
            radius: const Radius.elliptical(41, 24),
          )
          ..lineTo(116, 50),
        stroke(const Color(0xFFB85F2A), 2),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 50, 102, 54),
          const Radius.circular(10),
        ),
        fill(const Color(0xFFC4652F)),
      )
      ..drawLine(
        const Offset(28, 72),
        const Offset(122, 72),
        stroke(const Color(0xFFA9532A), 2),
      )
      ..drawLine(
        const Offset(28, 88),
        const Offset(122, 88),
        stroke(const Color(0xFFA9532A), 2),
      );
    final rim = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 48, 102, 9),
      const Radius.circular(4),
    );
    canvas
      ..drawRRect(rim, fill(Palette.sun))
      ..drawRRect(rim, stroke(Palette.starStroke, 1.5));
    for (final x in [38.0, 112.0]) {
      canvas.drawLine(
        Offset(x, 16),
        Offset(x, 104),
        stroke(Palette.sun, 9)..strokeCap = StrokeCap.butt,
      );
      for (var y = 16.0; y < 104; y += 8) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, min(y + 2, 104)),
          stroke(Palette.starStroke.withValues(alpha: 0.25), 9)
            ..strokeCap = StrokeCap.butt,
        );
      }
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(63, 44, 24, 28),
          const Radius.circular(6),
        ),
        fill(Palette.ink),
      )
      ..drawCircle(const Offset(75, 55), 4, fill(Palette.sun))
      ..drawLine(
        const Offset(75, 57),
        const Offset(75, 64),
        stroke(Palette.sun, 3),
      );
  }

  void _sparkle(Canvas canvas, Offset center, double reach, double opacity) {
    final inner = reach * 0.28;
    final path = Path()..moveTo(center.dx, center.dy - reach);
    for (var point = 0; point < 4; point++) {
      final angle = point * pi / 2;
      final corner = angle + pi / 4;
      path
        ..lineTo(
          center.dx + inner * sin(corner),
          center.dy - inner * cos(corner),
        )
        ..lineTo(
          center.dx + reach * sin(angle + pi / 2),
          center.dy - reach * cos(angle + pi / 2),
        );
    }
    canvas.drawPath(
      path..close(),
      Paint()..color = Palette.sun.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_ChestPainter oldDelegate) => oldDelegate.t != t;
}

class RoadPainter extends CustomPainter {
  const RoadPainter({required this.filled});

  static const double width = 350;
  static const double height = 286;
  static const List<Offset> stops = [
    Offset(32, 50),
    Offset(112, 50),
    Offset(192, 50),
    Offset(272, 50),
    Offset(272, 200),
    Offset(192, 200),
    Offset(78, 200),
  ];

  final int filled;

  static Path get road => Path()
    ..moveTo(32, 50)
    ..lineTo(272, 50)
    ..arcToPoint(const Offset(272, 200), radius: const Radius.circular(75))
    ..lineTo(78, 200);

  static double distanceTo(int stop) => switch (stop) {
    <= 3 => stop * 80.0,
    4 => 240 + 75 * pi,
    5 => 320 + 75 * pi,
    _ => 434 + 75 * pi,
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = road;
    canvas.drawPath(path, base..color = Palette.edge);
    if (filled > 0) {
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, distanceTo(filled - 1) + 0.01),
        base..color = Palette.down,
      );
    }
  }

  @override
  bool shouldRepaint(RoadPainter oldDelegate) => oldDelegate.filled != filled;
}
