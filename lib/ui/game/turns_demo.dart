import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'turn_face.dart';

/// The turning intro loop: a block leaves, so the round block turns from up
/// to right and leaves too, which frees the block it was holding back.
class TurnsDemo extends StatelessWidget {
  const TurnsDemo({super.key});

  static const double _width = 302;
  static const double _tile = 50;
  static const double _badge = 22;

  static const List<Keyframe> _sideMove = [(0.14, 0), (0.28, -200), (0.29, 0)];
  static const List<Keyframe> _sideScale = [
    (0.28, 1),
    (0.29, 0.5),
    (0.9, 0.5),
    (0.98, 1),
  ];
  static const List<Keyframe> _sideFade = [
    (0.14, 1),
    (0.28, 0),
    (0.9, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _turn = [
    (0.3, 0),
    (0.38, 1.09),
    (0.42, 1),
    (0.9, 1),
    (0.98, 0),
  ];
  static const List<Keyframe> _tint = [(0.3, 0), (0.4, 1), (0.9, 1), (0.98, 0)];
  static const List<Keyframe> _roundMove = [(0.5, 0), (0.66, 220), (0.67, 0)];
  static const List<Keyframe> _roundScale = [
    (0.66, 1),
    (0.67, 0.5),
    (0.9, 0.5),
    (0.98, 1),
  ];
  static const List<Keyframe> _roundFade = [
    (0.5, 1),
    (0.66, 0),
    (0.9, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _topMove = [(0.66, 0), (0.8, 160), (0.81, 0)];
  static const List<Keyframe> _topScale = [
    (0.8, 1),
    (0.81, 0.5),
    (0.9, 0.5),
    (0.98, 1),
  ];
  static const List<Keyframe> _topFade = [
    (0.66, 1),
    (0.8, 0),
    (0.9, 0),
    (0.98, 1),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
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
                period: Motion.turnsDemo,
                builder: (context, t, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _at(
                      shift + 126,
                      16,
                      _slide(
                        t,
                        move: _topMove,
                        scale: _topScale,
                        fade: _topFade,
                        vertical: true,
                        child: const BlockFace(direction: Direction.down),
                      ),
                    ),
                    _at(
                      shift + 40,
                      84,
                      _slide(
                        t,
                        move: _sideMove,
                        scale: _sideScale,
                        fade: _sideFade,
                        child: const BlockFace(direction: Direction.left),
                      ),
                    ),
                    _at(
                      shift + 126,
                      84,
                      _slide(
                        t,
                        move: _roundMove,
                        scale: _roundScale,
                        fade: _roundFade,
                        child: Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            RoundFace(
                              color: Color.lerp(
                                colors.up,
                                colors.right,
                                keyframes(t, _tint),
                              )!,
                              quarters: keyframes(
                                t,
                                _turn,
                                curve: Curves.easeOut,
                              ),
                            ),
                            const Positioned(
                              top: -_badge * 0.32,
                              right: -_badge * 0.32,
                              width: _badge,
                              height: _badge,
                              child: TurnBadge(size: _badge),
                            ),
                          ],
                        ),
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

  Widget _at(double left, double top, Widget child) => Positioned(
    left: left,
    top: top,
    width: _tile,
    height: _tile,
    child: child,
  );

  Widget _slide(
    double t, {
    required List<Keyframe> move,
    required List<Keyframe> scale,
    required List<Keyframe> fade,
    required Widget child,
    bool vertical = false,
  }) {
    final travel = keyframes(t, move, curve: Motion.leaveCurve);
    return Opacity(
      opacity: keyframes(t, fade, curve: Motion.leaveCurve),
      child: Transform.translate(
        offset: vertical ? Offset(0, travel) : Offset(travel, 0),
        child: Transform.scale(
          scale: keyframes(t, scale, curve: Motion.leaveCurve),
          child: child,
        ),
      ),
    );
  }
}
