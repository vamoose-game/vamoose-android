import 'dart:math';

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/palette.dart';

class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 26});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.confetti,
  )..forward();
  late final List<_Piece> _pieces = _Piece.scatter(widget.pieces, Random(7));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_pieces, _controller),
      ),
    );
  }
}

class _Piece {
  const _Piece(
    this.x,
    this.delay,
    this.speed,
    this.spin,
    this.color,
    this.size,
  );

  static const List<Color> _colors = [
    Palette.up,
    Palette.right,
    Palette.down,
    Palette.left,
    Palette.sun,
  ];

  final double x;
  final double delay;
  final double speed;
  final double spin;
  final Color color;
  final Size size;

  static List<_Piece> scatter(int count, Random random) => [
    for (var index = 0; index < count; index++)
      _Piece(
        random.nextDouble(),
        random.nextDouble() * 0.3,
        0.5 + random.nextDouble() * 0.6,
        random.nextDouble() * 6 - 3,
        _colors[index % _colors.length],
        Size(8 + random.nextDouble() * 8, 6 + random.nextDouble() * 6),
      ),
  ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final t = ((progress.value - piece.delay) / (1 - piece.delay)).clamp(
        0.0,
        1.0,
      );
      if (t == 0) {
        continue;
      }
      final opacity = t > 0.75 ? (1 - t) / 0.25 : 1.0;
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(piece.x * size.width, t * piece.speed * size.height * 0.7)
        ..rotate(piece.spin * t * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size.width,
            height: piece.size.height,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
