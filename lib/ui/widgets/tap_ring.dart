import 'package:flutter/widgets.dart';

import '../theme/palette.dart';
import 'looping.dart';

class TapRing extends StatelessWidget {
  const TapRing({
    super.key,
    required this.t,
    required this.start,
    required this.size,
  });

  final double t;
  final double start;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = keyframes(t, [
      (start, 0.4),
      (start + 0.18, 1.6),
    ], curve: Curves.easeOut);
    final opacity = keyframes(t, [
      (start, 0),
      (start + 0.06, 0.9),
      (start + 0.18, 0),
    ]);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Palette.ink, width: 3),
          ),
        ),
      ),
    );
  }
}
