import 'package:flutter/widgets.dart';

import '../../domain/economy.dart';
import '../theme/motion.dart';
import 'heart.dart';
import 'looping.dart';

/// The five hearts: full ones for the lives there are, the next one filling
/// up as it comes back, and [losing] flying off when a life was just lost.
class LivesRow extends StatelessWidget {
  const LivesRow({
    super.key,
    required this.count,
    this.refill = 0,
    this.size = 34,
    this.gap = 6,
    this.losing,
  });

  final int count;

  /// How far the next heart has filled up, from 0 to 1.
  final double refill;
  final double size;
  final double gap;
  final int? losing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count of ${Economy.maxLives} lives',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < Economy.maxLives; index++)
              Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : gap),
                child: _heart(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heart(int index) {
    if (index < count) {
      return HeartGlyph(size: size);
    }
    if (index == losing) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          HeartGlyph(size: size, fill: 0),
          _FlyingHeart(size: size),
        ],
      );
    }
    if (index == count && refill > 0) {
      return Looping(
        period: Motion.heartBeat,
        child: HeartGlyph(size: size, fill: refill),
        builder: (context, t, child) => Transform.scale(
          scale: keyframes(t, const [
            (0, 1),
            (0.15, 1.08),
            (0.3, 1),
          ], curve: Curves.easeInOut),
          child: child,
        ),
      );
    }
    return HeartGlyph(size: size, fill: 0);
  }
}

class _FlyingHeart extends StatefulWidget {
  const _FlyingHeart({required this.size});

  final double size;

  @override
  State<_FlyingHeart> createState() => _FlyingHeartState();
}

class _FlyingHeartState extends State<_FlyingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: Motion.heartFlyDelay + Motion.heartFly,
  )..forward();

  late final Animation<double> _away = CurvedAnimation(
    parent: _flight,
    curve: Interval(
      Motion.heartFlyDelay.inMilliseconds / _flight.duration!.inMilliseconds,
      1,
      curve: Curves.easeOut,
    ),
  );

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _away,
      child: HeartGlyph(size: widget.size),
      builder: (context, child) => Opacity(
        opacity: 1 - _away.value,
        child: Transform.translate(
          offset: Offset(0, -widget.size * _away.value),
          child: Transform.scale(scale: 1 + 0.4 * _away.value, child: child),
        ),
      ),
    );
  }
}
