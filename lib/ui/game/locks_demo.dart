import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../domain/direction.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'block_marks.dart';

/// The locks intro loop: the key block leaves, the padlock opens, then the
/// locked block leaves too.
class LocksDemo extends StatelessWidget {
  const LocksDemo({super.key});

  static const double _width = 302;
  static const double _badge = 26;

  static const List<Keyframe> _keyMove = [
    (0, 0),
    (0.15, 0),
    (0.35, 260),
    (0.36, 0),
  ];
  static const List<Keyframe> _keyScale = [
    (0.35, 1),
    (0.36, 0.5),
    (0.86, 0.5),
    (0.96, 1),
  ];
  static const List<Keyframe> _keyFade = [
    (0.15, 1),
    (0.35, 0),
    (0.86, 0),
    (0.96, 1),
  ];
  static const List<Keyframe> _lockedMove = [
    (0.58, 0),
    (0.76, -260),
    (0.77, 0),
  ];
  static const List<Keyframe> _lockedScale = [
    (0.76, 1),
    (0.77, 0.5),
    (0.88, 0.5),
    (0.98, 1),
  ];
  static const List<Keyframe> _lockedFade = [
    (0.58, 1),
    (0.76, 0),
    (0.88, 0),
    (0.98, 1),
  ];
  static const List<Keyframe> _stripes = [
    (0.44, 1),
    (0.52, 0),
    (0.92, 0),
    (1, 1),
  ];
  static const List<Keyframe> _arrow = [
    (0.44, 0.45),
    (0.52, 1),
    (0.92, 1),
    (1, 0.45),
  ];
  static const List<Keyframe> _closedTurn = [
    (0.36, 0),
    (0.39, -16),
    (0.42, 14),
    (0.44, 0),
  ];
  static const List<Keyframe> _closedFade = [
    (0.42, 1),
    (0.44, 0),
    (0.95, 0),
    (1, 1),
  ];
  static const List<Keyframe> _openScale = [
    (0.43, 1),
    (0.47, 1.35),
    (0.57, 0.2),
  ];
  static const List<Keyframe> _openRise = [(0.47, 0), (0.57, -12)];
  static const List<Keyframe> _openFade = [(0.43, 0), (0.47, 1), (0.57, 0)];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Palette.well,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shift = (constraints.maxWidth - _width) / 2;
              return Looping(
                period: Motion.locksDemo,
                builder: (context, t, _) => Stack(
                  children: [
                    Positioned(
                      left: shift + 30,
                      top: 18,
                      width: 48,
                      height: 48,
                      child: _sliding(
                        t,
                        move: _keyMove,
                        scale: _keyScale,
                        fade: _keyFade,
                        child: _withBadge(
                          const BlockFace(direction: Direction.right),
                          const BlockBadge(icon: BadgeIcon.key, size: _badge),
                        ),
                      ),
                    ),
                    Positioned(
                      left: shift + 132,
                      top: 78,
                      width: 102,
                      height: 48,
                      child: _sliding(
                        t,
                        move: _lockedMove,
                        scale: _lockedScale,
                        fade: _lockedFade,
                        child: _withBadge(
                          BlockFace(
                            direction: Direction.left,
                            stripes: keyframes(t, _stripes),
                            arrowOpacity: keyframes(t, _arrow),
                          ),
                          _padlock(t),
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

  Widget _sliding(
    double t, {
    required List<Keyframe> move,
    required List<Keyframe> scale,
    required List<Keyframe> fade,
    required Widget child,
  }) => Opacity(
    opacity: keyframes(t, fade, curve: Motion.leaveCurve),
    child: Transform.translate(
      offset: Offset(keyframes(t, move, curve: Motion.leaveCurve), 0),
      child: Transform.scale(
        scale: keyframes(t, scale, curve: Motion.leaveCurve),
        child: child,
      ),
    ),
  );

  Widget _withBadge(Widget face, Widget badge) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.expand,
    children: [
      face,
      Positioned(
        top: -8,
        right: -8,
        width: _badge,
        height: _badge,
        child: badge,
      ),
    ],
  );

  Widget _padlock(double t) => Stack(
    clipBehavior: Clip.none,
    children: [
      Opacity(
        opacity: keyframes(t, _closedFade, curve: Curves.easeOut),
        child: Transform.rotate(
          angle: keyframes(t, _closedTurn, curve: Curves.easeOut) * pi / 180,
          child: const BlockBadge(icon: BadgeIcon.padlock, size: _badge),
        ),
      ),
      Opacity(
        opacity: keyframes(t, _openFade, curve: Curves.easeOut),
        child: Transform.scale(
          scale: keyframes(t, _openScale, curve: Curves.easeOut),
          child: Transform.translate(
            offset: Offset(0, keyframes(t, _openRise, curve: Curves.easeOut)),
            child: const BlockBadge(icon: BadgeIcon.openPadlock, size: _badge),
          ),
        ),
      ),
    ],
  );
}
