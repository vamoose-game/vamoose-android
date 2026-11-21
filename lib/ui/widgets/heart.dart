import 'package:flutter/widgets.dart';

import '../theme/palette.dart';

/// A heart drawn in code: the face over a darker copy 1.3 units lower, with
/// a white shine. [fill] fills it from the bottom, for a life coming back.
class HeartGlyph extends StatelessWidget {
  const HeartGlyph({super.key, required this.size, this.fill = 1});

  final double size;

  /// 0 is an empty heart, 1 a full one.
  final double fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HeartPainter(fill.clamp(0, 1)),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter(this.fill);

  /// The heart shape covers 7 % to 87.5 % of the box from the bottom.
  static const double _bottom = 0.07;
  static const double _shape = 0.805;
  static const double _edgeDrop = 1.3;

  static final Path _heart = Path()
    ..moveTo(19, 14)
    ..cubicTo(20.49, 12.54, 22, 10.79, 22, 8.5)
    ..arcToPoint(
      const Offset(16.5, 3),
      radius: const Radius.circular(5.5),
      clockwise: false,
    )
    ..cubicTo(14.74, 3, 13.5, 3.5, 12, 5)
    ..cubicTo(10.5, 3.5, 9.26, 3, 7.5, 3)
    ..arcToPoint(
      const Offset(2, 8.5),
      radius: const Radius.circular(5.5),
      clockwise: false,
    )
    ..cubicTo(2, 10.8, 3.5, 12.55, 5, 14)
    ..lineTo(12, 21)
    ..close();

  static final Path _shine = Path()
    ..moveTo(5.6, 7.4)
    ..arcToPoint(const Offset(8.2, 5.4), radius: const Radius.circular(2.8));

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    if (fill < 1) {
      _draw(canvas, Palette.heartEmpty, Palette.heartEmptyEdge);
    }
    if (fill <= 0) {
      return;
    }
    canvas.save();
    if (fill < 1) {
      final top = 24 * (1 - _bottom - _shape * fill);
      canvas.clipRect(Rect.fromLTRB(0, top, 24, 26));
    }
    _draw(canvas, Palette.heart, Palette.heartEdge);
    canvas.drawPath(
      _shine,
      Paint()
        ..color = Palette.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _draw(Canvas canvas, Color face, Color edge) {
    canvas
      ..drawPath(
        _heart.shift(const Offset(0, _edgeDrop)),
        Paint()..color = edge,
      )
      ..drawPath(_heart, Paint()..color = face);
  }

  @override
  bool shouldRepaint(_HeartPainter oldDelegate) => oldDelegate.fill != fill;
}
