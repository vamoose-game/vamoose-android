import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';

/// The round badge with a countdown block's moves left: ink from 3 up, sun
/// at 2 and red at 1. The number alone tells the story; the color helps.
class CountdownBadge extends StatelessWidget {
  const CountdownBadge({
    super.key,
    required this.count,
    required this.size,
    this.framed = true,
  });

  final int count;
  final double size;

  /// Whether a shadow and a white ring lift it off the block it sits on.
  final bool framed;

  static Color colorFor(int count) => switch (count) {
    <= 1 => Palette.alert,
    2 => Palette.sun,
    _ => Palette.ink,
  };

  static Color numberColorFor(int count) =>
      count == 2 ? Palette.ink : Palette.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.countdownColor,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorFor(count),
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
      alignment: Alignment.center,
      child: AnimatedDefaultTextStyle(
        duration: Motion.countdownColor,
        style: AppText.number.copyWith(
          fontSize: size * 16 / 28,
          height: 1,
          color: numberColorFor(count),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        child: Text('$count', textScaler: TextScaler.noScaling),
      ),
    );
  }
}

/// [face] with the badge [badge] builds, at its size, on the top-right
/// corner, sized for the block.
class CornerBadge extends StatelessWidget {
  const CornerBadge({super.key, required this.face, required this.badge});

  final Widget face;
  final Widget Function(double size) badge;

  /// The badge size for a block whose shorter side is [shortest].
  static double sizeFor(double shortest) => (shortest * 0.64).clamp(18.0, 28.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = sizeFor(constraints.biggest.shortestSide);
        final inset = -size * 9 / 28;
        // Each on its own layer, so a moving badge leaves the face be.
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: face),
            Positioned(
              top: inset,
              right: inset,
              width: size,
              height: size,
              child: RepaintBoundary(child: badge(size)),
            ),
          ],
        );
      },
    );
  }
}

/// A countdown block: a block in its direction's color with the moves it
/// has left in a badge on its corner. The badge pops as it counts down;
/// on its last move it pulses and the block wiggles to hurry the player.
class CountdownFace extends StatefulWidget {
  const CountdownFace({
    super.key,
    required this.direction,
    required this.count,
    this.ringColor,
    this.ringWidth = 0,
    this.lively = true,
  });

  final Direction direction;
  final int count;
  final Color? ringColor;
  final double ringWidth;

  /// Whether it pops and hurries; a block on its way out holds still.
  final bool lively;

  @override
  State<CountdownFace> createState() => _CountdownFaceState();
}

class _CountdownFaceState extends State<CountdownFace>
    with TickerProviderStateMixin {
  static const List<Keyframe> _tickScale = [(0, 1), (0.35, 1.3), (1, 1)];
  static const List<Keyframe> _pulseScale = [(0, 1), (0.5, 1.2), (1, 1)];
  static const List<Keyframe> _hurryShift = [
    (0.6, 0),
    (0.66, -3),
    (0.72, 3),
    (0.78, -2),
    (0.84, 0),
  ];

  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: Motion.countdownTick,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.lastMovePulse,
  );
  late final AnimationController _hurry = AnimationController(
    vsync: this,
    duration: Motion.hurry,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLastMove();
  }

  @override
  void didUpdateWidget(CountdownFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lively && widget.count < oldWidget.count) {
      _tick.forward(from: 0);
    }
    _syncLastMove();
  }

  void _syncLastMove() {
    final last =
        widget.lively &&
        widget.count <= 1 &&
        !MediaQuery.disableAnimationsOf(context);
    if (last && !_pulse.isAnimating) {
      _pulse.repeat();
      _hurry.repeat();
    } else if (!last && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
      _hurry
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    _pulse.dispose();
    _hurry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.direction.isVertical;
    return AnimatedBuilder(
      animation: _hurry,
      child: CornerBadge(
        face: BlockFace(
          direction: widget.direction,
          ringColor: widget.ringColor,
          ringWidth: widget.ringWidth,
        ),
        badge: (size) => AnimatedBuilder(
          animation: Listenable.merge([_tick, _pulse]),
          child: CountdownBadge(count: widget.count, size: size),
          builder: (context, badge) => Transform.scale(
            scale:
                keyframes(_tick.value, _tickScale, curve: Curves.easeOut) *
                keyframes(_pulse.value, _pulseScale, curve: Curves.easeInOut),
            child: badge,
          ),
        ),
      ),
      builder: (context, child) {
        final shift = keyframes(_hurry.value, _hurryShift);
        return Transform.translate(
          offset: vertical ? Offset(0, shift) : Offset(shift, 0),
          child: child,
        );
      },
    );
  }
}

/// The "0" that pops off a countdown block as it runs out, [progress] of
/// the way through: it swells, then shrinks, rises and fades.
class RunOutBadge extends StatelessWidget {
  const RunOutBadge({super.key, required this.progress, required this.size});

  static const List<Keyframe> _scale = [(0, 1), (0.3, 1.4), (1, 0.2)];
  static const List<Keyframe> _rise = [(0.3, 0), (1, -18)];
  static const List<Keyframe> _fade = [(0.3, 1), (1, 0)];

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return IgnorePointer(
      child: Opacity(
        opacity: keyframes(t, _fade),
        child: Transform.translate(
          offset: Offset(0, keyframes(t, _rise)),
          child: Transform.scale(
            scale: keyframes(t, _scale),
            child: CountdownBadge(count: 0, size: size),
          ),
        ),
      ),
    );
  }
}
