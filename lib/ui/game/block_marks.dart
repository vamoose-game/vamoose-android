import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/board.dart';
import '../../domain/direction.dart';
import '../../domain/restraint.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/glyphs.dart';
import '../widgets/looping.dart';

enum MarkRole { key, lock }

typedef BlockMark = ({MarkRole role, int pair});

abstract final class BlockMarks {
  static const List<Color> pairColors = [Palette.sun, Palette.silver];

  static Map<int, BlockMark> of(Board board) {
    final marks = <int, BlockMark>{};
    var pair = 0;
    for (final restraint in board.restraints) {
      switch (restraint) {
        case Lock(:final blockId, :final keyId):
          marks[blockId] = (role: MarkRole.lock, pair: pair);
          marks[keyId] = (role: MarkRole.key, pair: pair);
          pair++;
      }
    }
    return marks;
  }

  static Color colorOf(BlockMark mark) =>
      pairColors[min(mark.pair, pairColors.length - 1)];
}

enum BadgeIcon { key, padlock, openPadlock }

class BlockBadge extends StatelessWidget {
  const BlockBadge({
    super.key,
    required this.icon,
    required this.size,
    this.color = Palette.sun,
    this.framed = true,
  });

  final BadgeIcon icon;
  final double size;
  final Color color;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final glyph = size * 14 / 26;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x4D1B2340),
                  offset: Offset(0, 2),
                  blurRadius: 5,
                ),
                BoxShadow(color: Palette.white, spreadRadius: 2),
              ]
            : null,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: switch (icon) {
            BadgeIcon.key => KeyGlyph(size: glyph),
            BadgeIcon.padlock => PadlockGlyph(size: glyph),
            BadgeIcon.openPadlock => PadlockGlyph(size: glyph, open: true),
          },
        ),
      ),
    );
  }
}

class MarkedFace extends StatefulWidget {
  const MarkedFace({
    super.key,
    required this.direction,
    required this.mark,
    required this.locked,
    required this.shakes,
    this.ringColor,
    this.ringWidth = 0,
  });

  final Direction direction;
  final BlockMark mark;
  final bool locked;
  final int shakes;
  final Color? ringColor;
  final double ringWidth;

  @override
  State<MarkedFace> createState() => _MarkedFaceState();
}

class _MarkedFaceState extends State<MarkedFace> with TickerProviderStateMixin {
  static final Curve _opening = Interval(
    Motion.unlockFadeDelay.inMilliseconds / Motion.unlock.inMilliseconds,
    (Motion.unlockFadeDelay + Motion.unlockFade).inMilliseconds /
        Motion.unlock.inMilliseconds,
    curve: Curves.ease,
  );
  static const List<Keyframe> _shakeTurns = [
    (0, 0),
    (0.2, -18),
    (0.4, 15),
    (0.6, -10),
    (0.8, 6),
    (1, 0),
  ];
  static const List<Keyframe> _popScale = [
    (0, 1),
    (0.18, 1.15),
    (0.34, 1.15),
    (0.55, 1.4),
    (1, 0.2),
  ];
  static const List<Keyframe> _popTurns = [
    (0, 0),
    (0.18, -14),
    (0.34, 12),
    (0.55, 0),
  ];
  static const List<Keyframe> _popRise = [(0.55, 0), (1, -14)];
  static const List<Keyframe> _popFade = [(0.55, 1), (1, 0)];

  late final AnimationController _unlock = AnimationController(
    vsync: this,
    duration: Motion.unlock,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: _shakeDelay + Motion.badgeShake,
  );

  Duration get _shakeDelay =>
      widget.mark.role == MarkRole.key ? Motion.keyShakeDelay : Duration.zero;

  @override
  void didUpdateWidget(MarkedFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked && !widget.locked) {
      _unlock.forward(from: 0);
    }
    if (oldWidget.shakes != widget.shakes) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _unlock.dispose();
    _shake.dispose();
    super.dispose();
  }

  double get _opened {
    if (widget.mark.role == MarkRole.key) {
      return 1;
    }
    if (widget.locked) {
      return 0;
    }
    return _unlock.isAnimating ? _opening.transform(_unlock.value) : 1;
  }

  double get _shakeTurn {
    if (!_shake.isAnimating) {
      return 0;
    }
    final total = _shake.duration!.inMilliseconds;
    final local =
        (_shake.value * total - _shakeDelay.inMilliseconds) /
        Motion.badgeShake.inMilliseconds;
    return keyframes(local.clamp(0.0, 1.0), _shakeTurns, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_unlock, _shake]),
      builder: (context, _) {
        final opened = _opened;
        final lock = widget.mark.role == MarkRole.lock;
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = (constraints.biggest.shortestSide * 0.62).clamp(
              18.0,
              26.0,
            );
            final badge = _badge(size);
            return Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                BlockFace(
                  direction: widget.direction,
                  ringColor: widget.ringColor,
                  ringWidth: widget.ringWidth,
                  stripes: lock ? 1 - opened : 0,
                  arrowOpacity: lock ? 0.45 + 0.55 * opened : 1,
                ),
                if (badge != null)
                  Positioned(
                    top: -size * 8 / 26,
                    right: -size * 8 / 26,
                    width: size,
                    height: size,
                    child: badge,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _badge(double size) {
    final color = BlockMarks.colorOf(widget.mark);
    if (widget.mark.role == MarkRole.key || widget.locked) {
      return Transform.rotate(
        angle: _shakeTurn * pi / 180,
        child: BlockBadge(
          icon: widget.mark.role == MarkRole.key
              ? BadgeIcon.key
              : BadgeIcon.padlock,
          size: size,
          color: color,
        ),
      );
    }
    if (!_unlock.isAnimating) {
      return null;
    }
    final t = _unlock.value;
    return Opacity(
      opacity: keyframes(t, _popFade, curve: Curves.easeOut),
      child: Transform.scale(
        scale: keyframes(t, _popScale, curve: Curves.easeOut),
        child: Transform.rotate(
          angle: keyframes(t, _popTurns, curve: Curves.easeOut) * pi / 180,
          child: Transform.translate(
            offset: Offset(0, keyframes(t, _popRise, curve: Curves.easeOut)),
            child: BlockBadge(
              icon: BadgeIcon.openPadlock,
              size: size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
