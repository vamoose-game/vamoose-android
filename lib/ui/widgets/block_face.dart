import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../domain/direction.dart';
import '../theme/palette.dart';

enum BlockLook { normal, faded, hinted, inTheWay }

class BlockFace extends StatelessWidget {
  const BlockFace({
    super.key,
    required this.direction,
    this.look = BlockLook.normal,
    this.pressed = false,
  });

  final Direction direction;
  final BlockLook look;
  final bool pressed;

  static const Map<Direction, IconData> _arrows = {
    Direction.up: Icons.arrow_upward_rounded,
    Direction.right: Icons.arrow_forward_rounded,
    Direction.down: Icons.arrow_downward_rounded,
    Direction.left: Icons.arrow_back_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final radius = BorderRadius.circular(min(14, shortest * 0.26));
        final edgeHeight = max(3.0, shortest * 0.07);
        final travel = pressed ? edgeHeight * 0.6 : 0.0;
        final base = Palette.forDirection(direction);
        final face = look == BlockLook.faded ? Palette.faded(base) : base;
        final ring = switch (look) {
          BlockLook.hinted => Palette.sun,
          BlockLook.inTheWay => Palette.ink,
          _ => null,
        };
        return Stack(
          children: [
            Positioned.fill(
              top: edgeHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.shade(face),
                  borderRadius: radius,
                ),
              ),
            ),
            Positioned.fill(
              top: travel,
              bottom: edgeHeight - travel,
              child: DecoratedBox(
                decoration: BoxDecoration(color: face, borderRadius: radius),
                child: Center(
                  child: Icon(
                    _arrows[direction],
                    color: Palette.white,
                    size: shortest * 0.42,
                  ),
                ),
              ),
            ),
            if (ring != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: ring,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
