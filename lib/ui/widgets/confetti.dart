import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../theme/palette.dart';

class ConfettiPiece {
  const ConfettiPiece({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
    required this.duration,
    required this.delay,
    this.round = false,
  });

  final double x;
  final double width;
  final double height;
  final Color color;
  final Duration duration;
  final Duration delay;
  final bool round;
}

class Confetti extends StatefulWidget {
  const Confetti({
    super.key,
    required this.pieces,
    required this.fall,
    required this.turns,
    this.loop = false,
    this.curve = Curves.linear,
  });

  final List<ConfettiPiece> pieces;
  final double fall;
  final double turns;
  final bool loop;
  final Curve curve;

  static const List<ConfettiPiece> drift = [
    ConfettiPiece(
      x: 34 / 390,
      width: 14,
      height: 14,
      color: Palette.right,
      duration: Duration(milliseconds: 3200),
      delay: Duration(milliseconds: 200),
    ),
    ConfettiPiece(
      x: 92 / 390,
      width: 10,
      height: 16,
      color: Palette.up,
      duration: Duration(milliseconds: 3800),
      delay: Duration(milliseconds: 900),
    ),
    ConfettiPiece(
      x: 150 / 390,
      width: 12,
      height: 12,
      color: Palette.sun,
      duration: Duration(milliseconds: 3400),
      delay: Duration(milliseconds: 500),
      round: true,
    ),
    ConfettiPiece(
      x: 214 / 390,
      width: 14,
      height: 14,
      color: Palette.down,
      duration: Duration(milliseconds: 4000),
      delay: Duration(milliseconds: 1300),
    ),
    ConfettiPiece(
      x: 268 / 390,
      width: 10,
      height: 16,
      color: Palette.left,
      duration: Duration(milliseconds: 3600),
      delay: Duration(milliseconds: 100),
    ),
    ConfettiPiece(
      x: 326 / 390,
      width: 12,
      height: 12,
      color: Palette.right,
      duration: Duration(milliseconds: 3300),
      delay: Duration(milliseconds: 1600),
      round: true,
    ),
    ConfettiPiece(
      x: 60 / 390,
      width: 12,
      height: 12,
      color: Palette.sun,
      duration: Duration(milliseconds: 4200),
      delay: Duration(milliseconds: 2000),
      round: true,
    ),
    ConfettiPiece(
      x: 300 / 390,
      width: 14,
      height: 14,
      color: Palette.up,
      duration: Duration(milliseconds: 3900),
      delay: Duration(milliseconds: 2400),
    ),
  ];

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _elapsed.value = elapsed)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(widget, _elapsed),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.config, this.elapsed) : super(repaint: elapsed);

  final Confetti config;
  final ValueNotifier<Duration> elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final now = elapsed.value.inMicroseconds;
    for (final piece in config.pieces) {
      final since = now - piece.delay.inMicroseconds;
      if (since < 0) {
        continue;
      }
      final length = piece.duration.inMicroseconds;
      if (!config.loop && since > length) {
        continue;
      }
      final t = config.curve.transform((since % length) / length);
      final opacity = t < 0.1 ? t / 0.1 : 1 - (t - 0.1) / 0.9;
      final paint = Paint()
        ..color = piece.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas
        ..save()
        ..translate(
          piece.x * size.width + piece.width / 2,
          -30 + t * config.fall,
        )
        ..rotate(t * config.turns * 2 * pi);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        height: piece.height,
      );
      if (piece.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
