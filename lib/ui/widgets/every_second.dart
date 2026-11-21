import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds once a second while it is on screen, for countdowns. It stops
/// while its route is covered or the app is in the background, and catches
/// up as soon as it shows again.
class EverySecond extends StatefulWidget {
  const EverySecond({super.key, required this.builder, this.onTick});

  final WidgetBuilder builder;

  /// Runs before each rebuild, for example to refresh what is shown.
  final VoidCallback? onTick;

  @override
  State<EverySecond> createState() => _EverySecondState();
}

class _EverySecondState extends State<EverySecond> with WidgetsBindingObserver {
  Timer? _timer;
  bool _shown = true;
  bool _foreground = true;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = _inForeground(WidgetsBinding.instance.lifecycleState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = TickerMode.valuesOf(context).enabled;
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = _inForeground(state);
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final run = _shown && _foreground;
    if (run && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      if (!_first) {
        // Out of the build, as the tick may tell other widgets to rebuild.
        Timer.run(_tick);
      }
    } else if (!run) {
      _timer?.cancel();
      _timer = null;
    }
    _first = false;
  }

  void _tick() {
    if (!mounted) {
      return;
    }
    widget.onTick?.call();
    setState(() {});
  }

  static bool _inForeground(AppLifecycleState? state) => switch (state) {
    AppLifecycleState.hidden ||
    AppLifecycleState.paused ||
    AppLifecycleState.detached => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
