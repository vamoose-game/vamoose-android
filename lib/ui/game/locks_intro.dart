import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../domain/board.dart';
import '../../domain/direction.dart';
import '../../domain/restraint.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/card_dialog.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';
import 'block_marks.dart';

abstract final class LocksIntro {
  static const String id = 'locks';

  static bool appliesTo(Board board) =>
      board.restraints.any((restraint) => restraint is Lock);

  static Future<void> show(BuildContext context, {required String? chapter}) =>
      CardDialog.show<void>(
        context,
        label: 'Got it',
        dismissible: false,
        builder: (context) => _LocksCard(chapter: chapter),
      );
}

class _LocksCard extends StatelessWidget {
  const _LocksCard({required this.chapter});

  final String? chapter;

  @override
  Widget build(BuildContext context) {
    final where = chapter;
    return DialogCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (where == null ? 'New' : 'New in chapter $where').toUpperCase(),
            style: AppText.label.copyWith(
              color: Palette.alert,
              letterSpacing: 1.56,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Locked blocks',
            style: AppText.title.copyWith(fontSize: 30, letterSpacing: -0.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          const _LocksDemo(),
          const SizedBox(height: 18),
          Text(
            "A block with a padlock can't move yet. Clear the block with the key first, then the lock opens.",
            style: AppText.body.copyWith(fontSize: 17, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(icon: BadgeIcon.key, text: 'Key'),
              SizedBox(width: 20),
              _Legend(icon: BadgeIcon.padlock, text: 'Locked'),
            ],
          ),
          const SizedBox(height: 18),
          KeyButton(
            tone: KeyTone.primary,
            height: 62,
            radius: 20,
            onPressed: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Got it',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.text});

  final BadgeIcon icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlockBadge(icon: icon, size: 26, framed: false),
        const SizedBox(width: 8),
        Text(text, style: AppText.bodyStrong.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _LocksDemo extends StatelessWidget {
  const _LocksDemo();

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
