import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../domain/block.dart';
import '../../domain/cell.dart';
import '../../domain/tap_outcome.dart';
import '../../state/game_session.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/looping.dart';
import 'block_marks.dart';
import 'countdown_face.dart';
import 'ice_face.dart';
import 'turn_face.dart';

final Curve _fade = Interval(
  Motion.blockFadeDelay.inMilliseconds / Motion.blockLeaves.inMilliseconds,
  1,
  curve: Curves.easeIn,
);

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.session,
    required this.onOutcome,
    this.onLanded,
  });

  final GameSession session;
  final ValueChanged<TapOutcome> onOutcome;

  /// Called once the blocks have flown in and can be tapped.
  final VoidCallback? onLanded;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  static const double _gap = 3;

  final List<_Leaving> _leaving = [];
  final Map<int, int> _bumps = {};
  final Map<int, int> _hits = {};
  final Map<int, int> _shakes = {};
  final Map<int, int> _runOuts = {};
  final Map<int, int> _thaws = {};

  /// For each twin pair, how often its tether has flashed.
  final Map<int, int> _tethers = {};
  final Map<int, (Object, Widget)> _slots = {};
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: Motion.flyInDelay + Motion.blockLeaves,
  );
  late final Animation<double> _flight = CurvedAnimation(
    parent: _arrival,
    curve: Interval(
      Motion.flyInDelay.inMilliseconds / _arrival.duration!.inMilliseconds,
      1,
    ),
  );

  @override
  void initState() {
    super.initState();
    _arrival.forward().whenCompleteOrCancel(() {
      if (mounted && _arrival.isCompleted) {
        widget.onLanded?.call();
      }
    });
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  void _tap(Block block) {
    if (!_arrival.isCompleted) {
      return;
    }
    final marks = BlockMarks.of(widget.session.board);
    final outcome = widget.session.tap(block.id);
    if (outcome == null) {
      return;
    }
    void count(Map<int, int> counts, int id) =>
        counts[id] = (counts[id] ?? 0) + 1;
    setState(() {
      switch (outcome) {
        case BlockLeaves(
          :final travel,
          :final runOuts,
          :final twin,
          :final twinTravel,
          :final thawed,
        ):
          _leaving.add(_Leaving(block, travel, marks[block.id]));
          _slots.remove(block.id);
          if (twin != null) {
            _leaving.add(_Leaving(twin, twinTravel, marks[twin.id]));
            _slots.remove(twin.id);
          }
          for (final ranOut in runOuts) {
            count(_runOuts, ranOut.id);
          }
          for (final thaw in thawed) {
            count(_thaws, thaw.id);
          }
        case BlockBumps(
          :final blocker,
          :final restraint,
          :final twin,
          :final frozen,
          :final stuck,
        ):
          count(_bumps, block.id);
          if (twin != null) {
            count(_bumps, twin.id);
            count(_shakes, block.id);
            count(_shakes, twin.id);
            if (marks[block.id] case (role: MarkRole.twin, :final pair)) {
              count(_tethers, pair);
            }
          }
          if (frozen) {
            count(_shakes, stuck.id);
          }
          if (blocker != null) {
            count(_hits, blocker.id);
            if (restraint != null) {
              count(_shakes, stuck.id);
              count(_shakes, blocker.id);
            }
          }
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
            final marks = BlockMarks.of(board);
            final hintedTwin = hinted != null && board.contains(hinted)
                ? board.twinOf(board.blockById(hinted))?.id
                : null;
            // Badges stand out over the blocks next to them.
            int layer(Block block) => marks[block.id] != null
                ? 3
                : block.turns
                ? 1
                : block.isFrozen ||
                      _thaws.containsKey(block.id) ||
                      _counted(block)
                ? 2
                : 0;
            final order = board.blocks.toList()
              ..sort(
                (a, b) =>
                    layer(a) != layer(b) ? layer(a) - layer(b) : a.id - b.id,
              );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _WellsPainter(
                        size: board.size,
                        gap: _gap,
                        color: BoardColors.of(context).well,
                      ),
                    ),
                  ),
                ),
                for (final id in [?hinted, ?hintedTwin])
                  if (board.contains(id))
                    _HintDots(
                      key: ValueKey('hint-$id'),
                      path: board.blockById(id).pathWithin(board.size),
                      cell: cell,
                    ),
                for (final block in order)
                  _slot(
                    block,
                    cell,
                    hinted: block.id == hinted || block.id == hintedTwin,
                    mark: marks[block.id],
                    locked: board.holdOn(block) != null,
                  ),
                for (var pair = 0; pair < board.twins.length; pair++)
                  if (board.contains(board.twins[pair].first) &&
                      board.contains(board.twins[pair].second) &&
                      (_tethers.containsKey(pair) ||
                          board.twins[pair].first == hinted ||
                          board.twins[pair].second == hinted))
                    _Tether(
                      key: ValueKey('tether-$pair'),
                      from: _badgeCenter(
                        board.blockById(board.twins[pair].first),
                        cell,
                      ),
                      to: _badgeCenter(
                        board.blockById(board.twins[pair].second),
                        cell,
                      ),
                      color:
                          BlockMarks.pairColors[min(
                            pair,
                            BlockMarks.pairColors.length - 1,
                          )],
                      flashes: _tethers[pair] ?? 0,
                      steady:
                          board.twins[pair].first == hinted ||
                          board.twins[pair].second == hinted,
                    ),
                for (final leaving in _leaving)
                  _place(
                    ObjectKey(leaving),
                    leaving.block,
                    cell,
                    _LeavingBlock(
                      block: leaving.block,
                      mark: leaving.mark,
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

  /// Whether [block] shows a countdown, or has run out of one.
  bool _counted(Block block) =>
      block.hasCountdown || _runOuts.containsKey(block.id);

  /// Where the badge on the top-right corner of [block] sits.
  Offset _badgeCenter(Block block, double cell) {
    final width = (block.isVertical ? 1 : block.length) * cell - _gap * 2;
    final height = (block.isVertical ? block.length : 1) * cell - _gap * 2;
    final badge = (min(width, height) * 0.62).clamp(18.0, 26.0);
    return Offset(
      block.column * cell + _gap + width + badge * 8 / 26 - badge / 2,
      block.row * cell + _gap - badge * 8 / 26 + badge / 2,
    );
  }

  Widget _slot(
    Block block,
    double cell, {
    required bool hinted,
    required BlockMark? mark,
    required bool locked,
  }) {
    final bumps = _bumps[block.id] ?? 0;
    final hits = _hits[block.id] ?? 0;
    final shakes = _shakes[block.id] ?? 0;
    final runOuts = _runOuts[block.id] ?? 0;
    final thaws = _thaws[block.id] ?? 0;
    final inputs = (
      cell,
      hinted,
      bumps,
      hits,
      shakes,
      mark,
      locked,
      block.direction,
      block.count,
      runOuts,
      block.ice,
      thaws,
    );
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
        mark: mark,
        locked: locked,
        shakes: shakes,
        runOuts: runOuts,
        thaws: thaws,
        arrival: _flight,
        flyIn:
            cell *
            widget.session.board.size *
            (block.isVertical ? Motion.flyInVertical : Motion.flyInHorizontal),
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
  const _WellsPainter({
    required this.size,
    required this.gap,
    required this.color,
  });

  final int size;
  final double gap;
  final Color color;

  @override
  void paint(Canvas canvas, Size area) {
    final cell = area.width / size;
    final radius = Radius.circular(cell * 0.22);
    final paint = Paint()..color = color;
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
      oldDelegate.size != size ||
      oldDelegate.gap != gap ||
      oldDelegate.color != color;
}

class _Leaving {
  _Leaving(this.block, this.travel, this.mark);

  final Block block;
  final int travel;
  final BlockMark? mark;
}

class _PlayableBlock extends StatefulWidget {
  const _PlayableBlock({
    required this.block,
    required this.hinted,
    required this.bumpCount,
    required this.hitCount,
    required this.mark,
    required this.locked,
    required this.shakes,
    required this.runOuts,
    required this.thaws,
    required this.arrival,
    required this.flyIn,
    required this.onTap,
  });

  final Block block;
  final bool hinted;
  final int bumpCount;
  final int hitCount;
  final BlockMark? mark;
  final bool locked;
  final int shakes;

  /// How often its countdown has run out: each change plays the run-out.
  final int runOuts;

  /// How often its ice has broken: each change plays the shatter.
  final int thaws;
  final Animation<double> arrival;
  final double flyIn;
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

  static const List<Keyframe> _haloPath = [(0, 0), (0.3, 6), (0.55, 6), (1, 0)];

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
  late final AnimationController _runOut = AnimationController(
    vsync: this,
    duration: Motion.runOut,
  );
  late final AnimationController _shatter = AnimationController(
    vsync: this,
    duration: Motion.iceShatter,
  );
  late final Listenable _motion = Listenable.merge([
    _bump,
    _hit,
    _pulse,
    _runOut,
    _shatter,
    widget.arrival,
  ]);
  late Widget _restingFace = _resting();

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_PlayableBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hinted != oldWidget.hinted ||
        widget.mark != oldWidget.mark ||
        widget.locked != oldWidget.locked ||
        widget.shakes != oldWidget.shakes ||
        widget.block.direction != oldWidget.block.direction ||
        widget.block.count != oldWidget.block.count ||
        widget.block.ice != oldWidget.block.ice) {
      _restingFace = _resting();
    }
    if (widget.runOuts != oldWidget.runOuts) {
      _runOut.forward(from: 0);
    }
    if (widget.thaws != oldWidget.thaws) {
      _shatter.forward(from: 0);
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
    _runOut.dispose();
    _shatter.dispose();
    super.dispose();
  }

  Widget _resting() =>
      _face(ringColor: widget.hinted ? Palette.sun : null, ringWidth: 4);

  Widget _face({required Color? ringColor, required double ringWidth}) {
    final block = widget.block;
    return RepaintBoundary(
      child: switch (widget.mark) {
        _ when block.turns => TurnFace(
          direction: block.direction,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
        final mark? => MarkedFace(
          direction: block.direction,
          mark: mark,
          locked: widget.locked,
          shakes: widget.shakes,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
        null when block.isFrozen => IceFace(
          direction: block.direction,
          ice: block.ice,
          cracks: block.cracks,
          variant: block.id,
          shakes: widget.shakes,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
        null when block.count != null => CountdownFace(
          direction: block.direction,
          count: block.count!,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
        null => BlockFace(
          direction: block.direction,
          ringColor: ringColor,
          ringWidth: ringWidth,
        ),
      },
    );
  }

  /// The block just after its countdown ran out: a red halo flashes round
  /// it as the "0" pops off its corner.
  Widget _ranOut() {
    final t = _runOut.value;
    final badge =
        t * Motion.runOut.inMilliseconds / Motion.runOutBadge.inMilliseconds;
    return CornerBadge(
      face: _face(
        ringColor: Palette.alert.withValues(alpha: 0.4),
        ringWidth: keyframes(t, _haloPath, curve: Curves.easeOut),
      ),
      badge: (size) => badge < 1
          ? RunOutBadge(progress: badge, size: size)
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final direction = widget.block.direction;
    final countdown = switch (widget.block.count) {
      null => '',
      1 => ', countdown 1: take it out now',
      final count => ', countdown $count: must leave within $count moves',
    };
    final frozen = switch (widget.block.ice) {
      0 => '',
      1 => ', frozen: a block next to it has to leave first',
      final ice => ', frozen: $ice blocks next to it have to leave first',
    };
    final twin = switch (widget.mark) {
      (role: MarkRole.twin, :final pair) =>
        ', twin: leaves with the other ${BlockMarks.nameOf(pair)} twin',
      _ => '',
    };
    return Semantics(
      button: true,
      label:
          '${direction.name} ${widget.block.turns ? 'turning ' : ''}block'
          '$countdown$frozen$twin'
          '${widget.locked ? ', locked: clear the block with the key first' : ''}'
          '${widget.mark?.role == MarkRole.key ? ', carries a key' : ''}'
          '${widget.hinted ? ', hint: this one can go' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _motion,
          child: _restingFace,
          builder: (context, restingFace) {
            final arrival = widget.arrival.value;
            final travel =
                _bumpPath.transform(Curves.easeOut.transform(_bump.value)) *
                    Motion.bumpDistance +
                (1 - Motion.leaveCurve.transform(arrival)) * widget.flyIn;
            final scale =
                1 +
                (Motion.hintScale - 1) *
                    Curves.easeInOut.transform(_pulse.value);
            return Opacity(
              opacity: _fade.transform(arrival),
              child: Transform.translate(
                offset: Offset(
                  direction.columnStep * travel,
                  direction.rowStep * travel,
                ),
                child: Transform.scale(
                  scale: scale,
                  child: _hit.isAnimating
                      ? _face(
                          ringColor: BoardColors.of(context).ink,
                          ringWidth: _ringPath.transform(
                            Curves.easeOut.transform(_hit.value),
                          ),
                        )
                      : _runOut.isAnimating
                      ? _ranOut()
                      : _shatter.isAnimating
                      ? Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            restingFace!,
                            IceShatter(progress: _shatter.value),
                          ],
                        )
                      : restingFace,
                ),
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
    required this.mark,
    required this.distance,
    required this.onDone,
  });

  final Block block;
  final BlockMark? mark;
  final double distance;
  final VoidCallback onDone;

  @override
  State<_LeavingBlock> createState() => _LeavingBlockState();
}

class _LeavingBlockState extends State<_LeavingBlock>
    with SingleTickerProviderStateMixin {
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
        child: RepaintBoundary(
          child: switch (widget.mark) {
            _ when widget.block.turns => TurnFace(direction: direction),
            final mark? => MarkedFace(
              direction: direction,
              mark: mark,
              locked: false,
              shakes: 0,
            ),
            null when widget.block.count != null => CountdownFace(
              direction: direction,
              count: widget.block.count!,
              lively: false,
            ),
            null => BlockFace(direction: direction),
          },
        ),
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

/// A dotted chain between the badges of two twins: steady while the pair
/// is hinted, a short flash each time it bumps.
class _Tether extends StatefulWidget {
  const _Tether({
    super.key,
    required this.from,
    required this.to,
    required this.color,
    required this.flashes,
    required this.steady,
  });

  final Offset from;
  final Offset to;
  final Color color;
  final int flashes;
  final bool steady;

  @override
  State<_Tether> createState() => _TetherState();
}

class _TetherState extends State<_Tether> with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: Motion.tether,
  );

  @override
  void initState() {
    super.initState();
    if (widget.flashes > 0) {
      _flash.forward();
    }
  }

  @override
  void didUpdateWidget(_Tether oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashes != oldWidget.flashes) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _flash,
          builder: (context, _) {
            final flash = _flash.isAnimating ? 1 - _flash.value : 0.0;
            final strength = max(widget.steady ? 0.85 : 0.0, flash);
            return strength <= 0
                ? const SizedBox.shrink()
                : CustomPaint(
                    painter: _TetherPainter(
                      widget.from,
                      widget.to,
                      widget.color,
                      strength,
                    ),
                  );
          },
        ),
      ),
    );
  }
}

class _TetherPainter extends CustomPainter {
  const _TetherPainter(this.from, this.to, this.color, this.strength);

  final Offset from;
  final Offset to;
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final span = to - from;
    final length = span.distance;
    if (length < 30) {
      return;
    }
    final along = span / length;
    final halo = Paint()..color = Palette.white.withValues(alpha: strength);
    final dot = Paint()..color = color.withValues(alpha: strength);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Palette.ink.withValues(alpha: 0.35 * strength);
    for (var at = 16.0; at <= length - 16; at += 11) {
      final center = from + along * at;
      canvas
        ..drawCircle(center, 4.2, halo)
        ..drawCircle(center, 3, dot)
        ..drawCircle(center, 3, edge);
    }
  }

  @override
  bool shouldRepaint(_TetherPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.color != color ||
      oldDelegate.strength != strength;
}
