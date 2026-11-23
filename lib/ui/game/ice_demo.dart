import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'countdown_face.dart';
import 'ice_face.dart';

/// The frozen intro loop: the block next to a frozen one slides away, the
/// ice shatters, and the freed block leaves too.
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

  /// The frozen block: iced until the neighbour has gone, then shattering,
  /// then a plain block.
  Widget _frozen(double t) {
    final face = BlockFace(
      direction: Direction.left,
      arrowOpacity: IcePainter.arrowOpacityUnder(1),
    );
    if (t >= 0.3 && t < 0.88) {
      final shatter = (t - 0.3) / 0.13;
      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          const BlockFace(direction: Direction.left),
          if (shatter < 1) IceShatter(progress: shatter),
        ],
      );
    }
    return CornerBadge(
      face: Stack(
        fit: StackFit.expand,
        children: [
          face,
          const CustomPaint(painter: IcePainter(thickness: 1)),
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
  }) => _leaving(t, move: move, fade: fade, comeBack: _comeBack, child: child);
}

/// The thick ice intro loop: the block on one side of a frozen block
/// leaves and the ice cracks across, the block on the other side leaves and
/// it shatters, and the freed block leaves too.
class ThickIceDemo extends StatelessWidget {
  const ThickIceDemo({super.key});

  static const double _tile = 48;
  static const double _gap = 6;
  static const double _crackAt = 0.23;
  static const double _crackFor = 0.07;
  static const double _shatterAt = 0.53;
  static const double _shatterFor = 0.13;

  static const List<Keyframe> _rightMove = [(0.12, 0), (0.24, 180), (0.25, 0)];
  static const List<Keyframe> _rightFade = [
    (0.14, 1),
    (0.24, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _leftMove = [(0.42, 0), (0.54, -180), (0.55, 0)];
  static const List<Keyframe> _leftFade = [
    (0.44, 1),
    (0.54, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _frozenMove = [(0.68, 0), (0.8, -150), (0.81, 0)];
  static const List<Keyframe> _frozenFade = [
    (0.7, 1),
    (0.8, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _comeBack = [
    (0.2, 1),
    (0.21, 0.5),
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
              final middle = (constraints.maxWidth - _tile) / 2;
              return Looping(
                period: Motion.thickIceDemo,
                builder: (context, t, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _place(
                      left: middle - _tile - _gap,
                      child: _leaving(
                        t,
                        move: _leftMove,
                        fade: _leftFade,
                        comeBack: _comeBack,
                        child: const BlockFace(direction: Direction.left),
                      ),
                    ),
                    _place(
                      left: middle + _tile + _gap,
                      child: _leaving(
                        t,
                        move: _rightMove,
                        fade: _rightFade,
                        comeBack: _comeBack,
                        child: const BlockFace(direction: Direction.right),
                      ),
                    ),
                    _place(
                      left: middle,
                      child: _leaving(
                        t,
                        move: _frozenMove,
                        fade: _frozenFade,
                        comeBack: _comeBack,
                        vertical: true,
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

  Widget _place({required double left, required Widget child}) => Positioned(
    left: left,
    top: 51,
    width: _tile,
    height: _tile,
    child: child,
  );

  /// The frozen block: under thick ice, cracked across once a neighbour
  /// has gone, shattering when the other goes too, then a plain block.
  Widget _frozen(double t) {
    if (t >= _shatterAt && t < 0.88) {
      final shatter = (t - _shatterAt) / _shatterFor;
      return Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          const BlockFace(direction: Direction.up),
          if (shatter < 1) IceShatter(progress: shatter),
        ],
      );
    }
    final cracked = t >= _crackAt && t < 0.88;
    final growing = cracked
        ? Curves.easeOut.transform(((t - _crackAt) / _crackFor).clamp(0, 1))
        : 1.0;
    return CornerBadge(
      face: Stack(
        fit: StackFit.expand,
        children: [
          BlockFace(
            direction: Direction.up,
            arrowOpacity: IcePainter.arrowOpacityUnder(2),
          ),
          CustomPaint(
            painter: IcePainter(
              thickness: 2,
              cracks: cracked ? 1 : 0,
              growing: growing,
              flash: cracked ? 1 - growing : 0,
            ),
          ),
        ],
      ),
      badge: (size) => IceBadge(size: size),
    );
  }
}

/// A demo block sliding off along [move] (down the board when [vertical])
/// and fading by [fade], then growing back in by [comeBack].
Widget _leaving(
  double t, {
  required List<Keyframe> move,
  required List<Keyframe> fade,
  required List<Keyframe> comeBack,
  bool vertical = false,
  required Widget child,
}) {
  final travel = keyframes(t, move, curve: Motion.leaveCurve);
  return Opacity(
    opacity: keyframes(t, fade, curve: Motion.leaveCurve),
    child: Transform.translate(
      offset: vertical ? Offset(0, travel) : Offset(travel, 0),
      child: Transform.scale(
        scale: t > 0.86 || t < 0.2 ? keyframes(t, comeBack) : 1,
        child: child,
      ),
    ),
  );
}
