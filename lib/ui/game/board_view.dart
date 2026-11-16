import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/block.dart';
import '../../domain/cell.dart';
import '../../domain/tap_outcome.dart';
import '../../state/game_session.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';

enum BlockLook { normal, faded, hinted, inTheWay }

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.session,
    required this.easyMode,
    required this.onOutcome,
  });

  final GameSession session;
  final bool easyMode;
  final ValueChanged<TapOutcome> onOutcome;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  static const double _gap = 3;

  final List<_Leaving> _leaving = [];
  final Map<int, int> _bumps = {};
  int? _inTheWayId;
  Timer? _inTheWayTimer;

  @override
  void dispose() {
    _inTheWayTimer?.cancel();
    super.dispose();
  }

  void _tap(Block block) {
    final outcome = widget.session.tap(block.id);
    setState(() {
      switch (outcome) {
        case BlockLeaves(:final travel):
          _leaving.add(_Leaving(block, travel));
        case BlockBumps(:final blocker):
          _bumps[block.id] = (_bumps[block.id] ?? 0) + 1;
          _inTheWayId = blocker.id;
          _inTheWayTimer?.cancel();
          _inTheWayTimer = Timer(Motion.inTheWay, _clearInTheWay);
      }
    });
    widget.onOutcome(outcome);
  }

  void _clearInTheWay() {
    if (mounted) {
      setState(() => _inTheWayId = null);
    }
  }

  BlockLook _lookOf(Block block) {
    final session = widget.session;
    if (block.id == _inTheWayId) {
      return BlockLook.inTheWay;
    }
    if (block.id == session.hintedBlockId) {
      return BlockLook.hinted;
    }
    if (widget.easyMode && !session.board.canLeave(block)) {
      return BlockLook.faded;
    }
    return BlockLook.normal;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final board = widget.session.board;
          final cell = constraints.maxWidth / board.size;
          final hinted = widget.session.hintedBlockId;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var row = 0; row < board.size; row++)
                for (var column = 0; column < board.size; column++)
                  Positioned(
                    left: column * cell + _gap,
                    top: row * cell + _gap,
                    width: cell - _gap * 2,
                    height: cell - _gap * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Palette.well,
                        borderRadius: BorderRadius.circular(cell * 0.22),
                      ),
                    ),
                  ),
              if (hinted != null && board.contains(hinted))
                ..._hintTrail(board.blockById(hinted), board.size, cell),
              for (final block in board.blocks)
                _place(
                  block,
                  cell,
                  _PlayableBlock(
                    key: ValueKey('block-${block.id}'),
                    block: block,
                    look: _lookOf(block),
                    bumpCount: _bumps[block.id] ?? 0,
                    onTap: () => _tap(block),
                  ),
                ),
              for (final leaving in _leaving)
                _place(
                  leaving.block,
                  cell,
                  _LeavingBlock(
                    key: ObjectKey(leaving),
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
    );
  }

  Widget _place(Block block, double cell, Widget child) => Positioned(
    left: block.column * cell + _gap,
    top: block.row * cell + _gap,
    width: (block.isVertical ? 1 : block.length) * cell - _gap * 2,
    height: (block.isVertical ? block.length : 1) * cell - _gap * 2,
    child: child,
  );

  List<Widget> _hintTrail(Block block, int size, double cell) {
    final path = block.pathWithin(size);
    return [
      for (var index = 0; index < path.length; index++)
        _HintDot(
          key: ValueKey('hint-$index'),
          cell: path[index],
          cellSize: cell,
          index: index,
        ),
    ];
  }
}

class _Leaving {
  _Leaving(this.block, this.travel);

  final Block block;
  final int travel;
}

class _PlayableBlock extends StatefulWidget {
  const _PlayableBlock({
    super.key,
    required this.block,
    required this.look,
    required this.bumpCount,
    required this.onTap,
  });

  final Block block;
  final BlockLook look;
  final int bumpCount;
  final VoidCallback onTap;

  @override
  State<_PlayableBlock> createState() => _PlayableBlockState();
}

class _PlayableBlockState extends State<_PlayableBlock>
    with TickerProviderStateMixin {
  static final Animatable<double> _bumpCurve = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 65,
    ),
  ]);

  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: Motion.bump,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.hintPulse,
  );
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_PlayableBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bumpCount != oldWidget.bumpCount) {
      _bump.forward(from: 0);
    }
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.look == BlockLook.hinted && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.look != BlockLook.hinted && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.block.direction;
    return Semantics(
      button: true,
      label: '${direction.name} block',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bump, _pulse]),
          builder: (context, child) {
            final nudge =
                _bumpCurve.transform(_bump.value) * Motion.bumpDistance;
            final scale =
                1 +
                (Motion.hintScale - 1) *
                    Curves.easeInOut.transform(_pulse.value);
            return Transform.translate(
              offset: Offset(
                direction.columnStep * nudge,
                direction.rowStep * nudge,
              ),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: BlockFace(
            direction: direction,
            faded: widget.look == BlockLook.faded,
            ringColor: switch (widget.look) {
              BlockLook.hinted => Palette.sun,
              BlockLook.inTheWay => Palette.ink,
              _ => null,
            },
            ringWidth: widget.look == BlockLook.hinted ? 4 : 5,
          ),
        ),
      ),
    );
  }
}

class _LeavingBlock extends StatefulWidget {
  const _LeavingBlock({
    super.key,
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
        child: BlockFace(direction: direction),
      ),
    );
  }
}

class _HintDot extends StatefulWidget {
  const _HintDot({
    super.key,
    required this.cell,
    required this.cellSize,
    required this.index,
  });

  static const Duration step = Duration(milliseconds: 90);
  static const Duration cycle = Duration(milliseconds: 1400);

  final Cell cell;
  final double cellSize;
  final int index;

  @override
  State<_HintDot> createState() => _HintDotState();
}

class _HintDotState extends State<_HintDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _HintDot.cycle,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = widget.cellSize * 0.16;
    final start =
        widget.index *
        _HintDot.step.inMilliseconds /
        _HintDot.cycle.inMilliseconds;
    return Positioned(
      left: (widget.cell.column + 0.5) * widget.cellSize - dot / 2,
      top: (widget.cell.row + 0.5) * widget.cellSize - dot / 2,
      width: dot,
      height: dot,
      child: FadeTransition(
        opacity: _controller.drive(
          TweenSequence([
            TweenSequenceItem(
              tween: ConstantTween(0.0),
              weight: start.clamp(0.0, 0.7) * 100 + 0.01,
            ),
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
            TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
          ]),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Palette.sun, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
