import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/palette.dart';
import 'glyphs.dart';

class BlockFace extends StatelessWidget {
  const BlockFace({
    super.key,
    required this.direction,
    this.faded = false,
    this.ringColor,
    this.ringWidth = 0,
    this.arrowSize,
  });

  final Direction direction;
  final bool faded;
  final Color? ringColor;
  final double ringWidth;
  final double? arrowSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final radius = BorderRadius.circular(min(18, shortest * 0.27));
        final edge = (shortest * 0.1).clamp(3.0, 6.0);
        final color = Palette.forDirection(direction);
        final ring = ringColor;
        return Opacity(
          opacity: faded ? 0.35 : 1,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: ring == null || ringWidth <= 0
                  ? null
                  : Border.all(
                      color: ring,
                      width: ringWidth,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.darken(color, 0.18),
                borderRadius: radius,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: edge),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.lighten(color, 0.22),
                    borderRadius: radius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: radius,
                      ),
                      child: Center(
                        child: ArrowGlyph(
                          direction: direction,
                          size: arrowSize ?? min(28, shortest * 0.52),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
