import 'package:material_ui/material_ui.dart';

import '../../domain/block.dart';
import '../../domain/cell.dart';
import '../../domain/tap_outcome.dart';
import '../../state/game_session.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';

class BoardView extends StatefulWidget {
  const BoardView({super.key, required this.session, required this.onOutcome});

  final GameSession session;
  final ValueChanged<TapOutcome> onOutcome;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  static const double _gap = 3;

  final List<_Leaving> _leaving = [];
  final Map<int, int> _bumps = {};
  final Map<int, int> _hits = {};
  final Map<int, (Object, Widget)> _slots = {};

  void _tap(Block block) {
    final outcome = widget.session.tap(block.id);
    setState(() {
      switch (outcome) {
        case BlockLeaves(:final travel):
          _leaving.add(_Leaving(block, travel));
          _slots.remove(block.id);
        case BlockBumps(:final blocker):
          _bumps[block.id] = (_bumps[block.id] ?? 0) + 1;
          _hits[blocker.id] = (_hits[blocker.id] ?? 0) + 1;
      }
    });
    widget.onOutcome(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final session = widget.session;
            final board = session.board;
            final cell = constraints.maxWidth / board.size;
            final hinted = session.hintedBlockId;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _WellsPainter(size: board.size, gap: _gap),
                    ),
                  ),
                ),
                if (hinted != null && board.contains(hinted))
                  _HintDots(
                    key: ValueKey('hint-$hinted'),
                    path: board.blockById(hinted).pathWithin(board.size),
                    cell: cell,
                  ),
                for (final block in board.blocks)
                  _slot(block, cell, hinted: block.id == hinted),
                for (final leaving in _leaving)
                  _place(
                    ObjectKey(leaving),
                    leaving.block,
                    cell,
                    _LeavingBlock(
                      block: leaving.block,
                      distance:
                          (leaving.travel + leaving.block.length + 1) * cell,
                      onDone: () => setState(() => _leaving.remove(leaving)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _slot(Block block, double cell, {required bool hinted}) {
    final bumps = _bumps[block.id] ?? 0;
    final hits = _hits[block.id] ?? 0;
    final inputs = (cell, hinted, bumps, hits);
    final cached = _slots[block.id];
    if (cached != null && cached.$1 == inputs) {
      return cached.$2;
    }
    final slot = _place(
      ValueKey('block-${block.id}'),
      block,
      cell,
      _PlayableBlock(
        block: block,
        hinted: hinted,
        bumpCount: bumps,
        hitCount: hits,
        onTap: () => _tap(block),
      ),
    );
    _slots[block.id] = (inputs, slot);
    return slot;
  }

  Widget _place(Key key, Block block, double cell, Widget child) => Positioned(
    key: key,
    left: block.column * cell + _gap,
    top: block.row * cell + _gap,
    width: (block.isVertical ? 1 : block.length) * cell - _gap * 2,
    height: (block.isVertical ? block.length : 1) * cell - _gap * 2,
    child: RepaintBoundary(child: child),
  );
}

class _WellsPainter extends CustomPainter {
  const _WellsPainter({required this.size, required this.gap});

  final int size;
  final double gap;

  @override
  void paint(Canvas canvas, Size area) {
    final cell = area.width / size;
    final radius = Radius.circular(cell * 0.22);
    final paint = Paint()..color = Palette.well;
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              column * cell + gap,
              row * cell + gap,
              cell - gap * 2,
              cell - gap * 2,
            ),
            radius,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WellsPainter oldDelegate) =>
      oldDelegate.size != size || oldDelegate.gap != gap;
}

class _Leaving {
  _Leaving(this.block, this.travel);

  final Block block;
  final int travel;
}

class _PlayableBlock extends StatefulWidget {
  const _PlayableBlock({
    required this.block,
    required this.hinted,
    required this.bumpCount,
    required this.hitCount,
    required this.onTap,
  });

  final Block block;
  final bool hinted;
  final int bumpCount;
  final int hitCount;
  final VoidCallback onTap;

  @override
  State<_PlayableBlock> createState() => _PlayableBlockState();
}

class _PlayableBlockState extends State<_PlayableBlock>
    with TickerProviderStateMixin {
  static final Animatable<double> _bumpPath = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: -0.4), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -0.4, end: 0.2), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 20),
  ]);

  static final Animatable<double> _ringPath = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 25),
    TweenSequenceItem(tween: ConstantTween(5.0), weight: 45),
    TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 30),
  ]);

  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: Motion.bump,
  );
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: Motion.inTheWay,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.hintPulse,
  );
  late final Listenable _motion = Listenable.merge([_bump, _hit, _pulse]);
  late Widget _restingFace = _resting();

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_PlayableBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hinted != oldWidget.hinted) {
      _restingFace = _resting();
    }
    if (widget.bumpCount != oldWidget.bumpCount) {
      _bump.forward(from: 0);
    }
    if (widget.hitCount != oldWidget.hitCount) {
      _hit.forward(from: 0);
    }
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.hinted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.hinted && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    _hit.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _resting() =>
      _face(ringColor: widget.hinted ? Palette.sun : null, ringWidth: 4);

  Widget _face({required Color? ringColor, required double ringWidth}) =>
      RepaintBoundary(
        child: BlockFace(
          direction: widget.block.direction,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final direction = widget.block.direction;
    return Semantics(
      button: true,
      label:
          '${direction.name} block${widget.hinted ? ', hint: this one can go' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _motion,
          child: _restingFace,
          builder: (context, restingFace) {
            final nudge =
                _bumpPath.transform(Curves.easeOut.transform(_bump.value)) *
                Motion.bumpDistance;
            final scale =
                1 +
                (Motion.hintScale - 1) *
                    Curves.easeInOut.transform(_pulse.value);
            return Transform.translate(
              offset: Offset(
                direction.columnStep * nudge,
                direction.rowStep * nudge,
              ),
              child: Transform.scale(
                scale: scale,
                child: _hit.isAnimating
                    ? _face(
                        ringColor: Palette.ink,
                        ringWidth: _ringPath.transform(
                          Curves.easeOut.transform(_hit.value),
                        ),
                      )
                    : restingFace,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeavingBlock extends StatefulWidget {
  const _LeavingBlock({
    required this.block,
    required this.distance,
    required this.onDone,
  });

  final Block block;
  final double distance;
  final VoidCallback onDone;

  @override
  State<_LeavingBlock> createState() => _LeavingBlockState();
}

class _LeavingBlockState extends State<_LeavingBlock>
    with SingleTickerProviderStateMixin {
  static final Curve _fade = Interval(
    Motion.blockFadeDelay.inMilliseconds / Motion.blockLeaves.inMilliseconds,
    1,
    curve: Curves.easeIn,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.blockLeaves,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.block.direction;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final travel =
              Motion.leaveCurve.transform(_controller.value) * widget.distance;
          return Opacity(
            opacity: 1 - _fade.transform(_controller.value),
            child: Transform.translate(
              offset: Offset(
                direction.columnStep * travel,
                direction.rowStep * travel,
              ),
              child: child,
            ),
          );
        },
        child: RepaintBoundary(child: BlockFace(direction: direction)),
      ),
    );
  }
}

class _HintDots extends StatefulWidget {
  const _HintDots({super.key, required this.path, required this.cell});

  final List<Cell> path;
  final double cell;

  @override
  State<_HintDots> createState() => _HintDotsState();
}

class _HintDotsState extends State<_HintDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.hintDot + Motion.hintDotGap * widget.path.length,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = widget.cell * 12 / 56;
    final total = _controller.duration!.inMilliseconds;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var index = 0; index < widget.path.length; index++)
          Positioned(
            left: (widget.path[index].column + 0.5) * widget.cell - dot / 2,
            top: (widget.path[index].row + 0.5) * widget.cell - dot / 2,
            width: dot,
            height: dot,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * Motion.hintDotGap.inMilliseconds / total,
                  (index * Motion.hintDotGap.inMilliseconds +
                          Motion.hintDot.inMilliseconds) /
                      total,
                  curve: Curves.easeOut,
                ),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.sun,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Palette.cream, spreadRadius: 3)],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
