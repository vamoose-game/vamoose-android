import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../state/coin_wallet.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';

class CoinGlyph extends StatelessWidget {
  const CoinGlyph({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CoinPainter(bold: size <= 32),
    );
  }
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter({required this.bold});

  static const Offset _center = Offset(12, 12);

  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawCircle(_center, 10, Paint()..color = Palette.sun)
      ..drawCircle(_center, 10, stroke(Palette.starStroke, bold ? 1.5 : 1.2))
      ..drawCircle(_center, 6.2, stroke(Palette.coinRing, bold ? 1.6 : 1.4))
      ..drawPath(
        Path()
          ..moveTo(9.5, 8.5)
          ..lineTo(12, 15.5)
          ..lineTo(14.5, 8.5),
        stroke(Palette.starStroke, bold ? 1.8 : 1.6),
      );
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => oldDelegate.bold != bold;
}

class CoinChip extends StatefulWidget {
  const CoinChip({super.key, this.pending = 0, this.height = 44});

  final int pending;
  final double height;

  @override
  State<CoinChip> createState() => _CoinChipState();
}

class _CoinChipState extends State<CoinChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  int? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _show(context.read<CoinWallet>().balance - widget.pending);
  }

  @override
  void didUpdateWidget(CoinChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pending != widget.pending) {
      _show(context.read<CoinWallet>().balance - widget.pending);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _show(int balance) {
    if (_shown != null && _shown != balance) {
      _pulse.forward(from: 0);
    }
    _shown = balance;
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<CoinWallet>().balance - widget.pending;
    return Semantics(
      label: '${Formatting.grouped(balance)} coins',
      child: ScaleTransition(
        scale: TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 60),
        ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.fromLTRB(9, 0, 16, 0),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoinGlyph(size: widget.height - 16),
              const SizedBox(width: 7),
              ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: balance.toDouble()),
                  duration: Motion.coinCount,
                  curve: Curves.easeOut,
                  builder: (context, value, _) => Text(
                    Formatting.grouped(value.round()),
                    style: AppText.number.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
