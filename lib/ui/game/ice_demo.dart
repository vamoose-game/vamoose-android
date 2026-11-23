import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'countdown_face.dart';
import 'ice_face.dart';

/// The frozen intro loop: the block next to a frozen one slides away, the
/// ice cracks and shatters, and the freed block leaves too.
class IceDemo extends StatelessWidget {
  const IceDemo({super.key});

  static const double _width = 302;
  static const double _tile = 48;

  static const List<Keyframe> _neighbourMove = [
    (0.18, 0),
    (0.32, 230),
    (0.33, 0),
  ];
  static const List<Keyframe> _neighbourFade = [
    (0.2, 1),
    (0.32, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _frozenMove = [(0.55, 0), (0.7, -200), (0.71, 0)];
  static const List<Keyframe> _frozenFade = [
    (0.57, 1),
    (0.7, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _comeBack = [
    (0.32, 1),
    (0.33, 0.5),
    (0.88, 0.5),
    (0.98, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Palette.well,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shift = (constraints.maxWidth - _width) / 2;
              return Looping(
                period: Motion.iceDemo,
                builder: (context, t, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: shift + 168,
                      top: 51,
                      width: 100,
                      height: _tile,
                      child: _slide(
                        t,
                        move: _neighbourMove,
                        fade: _neighbourFade,
                        child: const BlockFace(direction: Direction.right),
                      ),
                    ),
                    Positioned(
                      left: shift + 114,
                      top: 51,
                      width: _tile,
                      height: _tile,
                      child: _slide(
                        t,
                        move: _frozenMove,
                        fade: _frozenFade,
                        child: _frozen(t),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The frozen block: iced until the neighbour has gone, then cracking and
  /// shattering, then a plain block.
  Widget _frozen(double t) {
    const face = BlockFace(direction: Direction.left, arrowOpacity: 0.62);
    if (t >= 0.36 && t < 0.88) {
      final shatter = (t - 0.36) / 0.13;
      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          const BlockFace(direction: Direction.left),
          if (shatter < 1) IceShatter(progress: shatter),
        ],
      );
    }
    final crack = t >= 0.3 && t < 0.36 ? (t - 0.3) / 0.06 : 0.0;
    return CornerBadge(
      face: Stack(
        fit: StackFit.expand,
        children: [
          face,
          CustomPaint(
            painter: IcePainter(layers: 1, crack: crack, flash: crack),
          ),
        ],
      ),
      badge: (size) => IceBadge(size: size),
    );
  }

  Widget _slide(
    double t, {
    required List<Keyframe> move,
    required List<Keyframe> fade,
    required Widget child,
  }) => Opacity(
    opacity: keyframes(t, fade, curve: Motion.leaveCurve),
    child: Transform.translate(
      offset: Offset(keyframes(t, move, curve: Motion.leaveCurve), 0),
      child: Transform.scale(
        scale: t > 0.86 || t < 0.2 ? keyframes(t, _comeBack) : 1,
        child: child,
      ),
    ),
  );
}
