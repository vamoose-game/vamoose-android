import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/palette.dart';

class ArrowGlyph extends StatelessWidget {
  const ArrowGlyph({
    super.key,
    required this.direction,
    required this.size,
    this.color = Palette.white,
    this.strokeWidth = 3.2,
  });

  final Direction direction;
  final double size;
  final Color color;
  final double strokeWidth;

  static const Map<Direction, double> _turns = {
    Direction.up: -0.25,
    Direction.right: 0,
    Direction.down: 0.25,
    Direction.left: 0.5,
  };

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _turns[direction]! * 2 * pi,
      child: CustomPaint(
        size: Size.square(size),
        painter: _ArrowPainter(color, strokeWidth),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawLine(const Offset(5, 12), const Offset(18, 12), paint)
      ..drawPath(
        Path()
          ..moveTo(12.5, 6)
          ..lineTo(18.5, 12)
          ..lineTo(12.5, 18),
        paint,
      );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class StarGlyph extends StatelessWidget {
  const StarGlyph({
    super.key,
    required this.size,
    this.filled = true,
    this.outlined = true,
    this.strokeWidth = 1.2,
  });

  final double size;
  final bool filled;
  final bool outlined;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(
        fill: filled ? Palette.sun : (outlined ? Palette.line : Palette.edge),
        stroke: outlined ? (filled ? Palette.starStroke : Palette.muted) : null,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  static final Path _star = Path()
    ..moveTo(12, 2.5)
    ..lineTo(14.9, 8.5)
    ..lineTo(21.5, 9.4)
    ..lineTo(16.7, 14)
    ..lineTo(17.9, 20.5)
    ..lineTo(12, 17.4)
    ..lineTo(6.1, 20.5)
    ..lineTo(7.3, 14)
    ..lineTo(2.5, 9.4)
    ..lineTo(9.1, 8.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(_star, Paint()..color = fill);
    final outline = stroke;
    if (outline != null) {
      canvas.drawPath(
        _star,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}

class KeyGlyph extends StatelessWidget {
  const KeyGlyph({super.key, required this.size, this.color = Palette.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(color, (path) {
        path
          ..addOval(
            Rect.fromCircle(center: const Offset(7.5, 15.5), radius: 5.5),
          )
          ..moveTo(21, 2)
          ..lineTo(11.4, 11.6)
          ..moveTo(15.5, 7.5)
          ..lineTo(18.5, 10.5)
          ..lineTo(22, 7)
          ..lineTo(19, 4);
      }),
    );
  }
}

class PadlockGlyph extends StatelessWidget {
  const PadlockGlyph({
    super.key,
    required this.size,
    this.open = false,
    this.color = Palette.ink,
  });

  final double size;
  final bool open;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(color, (path) {
        path
          ..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(5, 11, 14, 10),
              const Radius.circular(2),
            ),
          )
          ..moveTo(8, 11)
          ..lineTo(8, 7);
        if (open) {
          path.arcToPoint(
            const Offset(15.5, 5),
            radius: const Radius.circular(4),
          );
        } else {
          path
            ..arcToPoint(const Offset(16, 7), radius: const Radius.circular(4))
            ..lineTo(16, 11);
        }
      }),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.color, this.trace);

  final Color color;
  final void Function(Path path) trace;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = Path();
    trace(path);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => oldDelegate.color != color;
}
