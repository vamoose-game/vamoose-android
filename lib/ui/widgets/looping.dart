import 'dart:async';

import 'package:flutter/widgets.dart';

typedef Keyframe = (double at, double value);

double keyframes(
  double t,
  List<Keyframe> frames, {
  Curve curve = Curves.linear,
}) {
  if (t <= frames.first.$1) {
    return frames.first.$2;
  }
  for (var index = 1; index < frames.length; index++) {
    final (end, to) = frames[index];
    if (t <= end) {
      final (start, from) = frames[index - 1];
      final span = end - start;
      final local = span == 0 ? 1.0 : (t - start) / span;
      return from + (to - from) * curve.transform(local);
    }
  }
  return frames.last.$2;
}

class Looping extends StatefulWidget {
  const Looping({
    super.key,
    required this.period,
    required this.builder,
    this.delay = Duration.zero,
    this.child,
  });

  final Duration period;
  final Duration delay;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<Looping> createState() => _LoopingState();
}

class _LoopingState extends State<Looping> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _start;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    _start = Timer(widget.delay, _controller.repeat);
  }

  @override
  void dispose() {
    _start.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) =>
          widget.builder(context, _controller.value, child),
    );
  }
}
