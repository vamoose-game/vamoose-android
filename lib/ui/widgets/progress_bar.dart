import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/palette.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = Palette.down,
    this.height = 10,
    this.track = Palette.line,
  });

  final double value;
  final Color color;
  final double height;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0, 1)),
              duration: Motion.progress,
              curve: Curves.ease,
              builder: (context, width, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
