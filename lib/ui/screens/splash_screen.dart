import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/direction.dart';
import '../../state/settings_controller.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/entrance.dart';
import '../widgets/looping.dart';
import 'home_screen.dart';
import 'how_to_play_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration duration = Duration(milliseconds: 2600);
  static const Duration storeTimeout = Duration(seconds: 8);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final services = context.read<AppServices>();
    await Future.wait([
      Future<void>.delayed(SplashScreen.duration),
      _prepare(services),
    ]);
    _continue();
  }

  Future<void> _prepare(AppServices services) async {
    await Future.wait([
      _bounded(services.ads.initialize()),
      _bounded(services.purchases.initialize()),
    ]);
  }

  Future<void> _bounded(Future<void> task) async {
    try {
      await task.timeout(SplashScreen.storeTimeout);
    } on Object {
      return;
    }
  }

  void _continue() {
    if (!mounted) {
      return;
    }
    final next = context.read<SettingsController>().tutorialSeen
        ? const HomeScreen()
        : const HowToPlayScreen();
    unawaited(
      Navigator.of(context).pushReplacement(Navigation.page<void>(next)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 40, 24, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FlyingMark(),
                    SizedBox(height: 36),
                    Entrance(
                      delay: Duration(milliseconds: 700),
                      duration: Duration(milliseconds: 600),
                      offset: Offset(0, 14),
                      child: Column(
                        children: [
                          FittedBox(
                            child: Text('vamoose', style: AppText.logo),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'The calm block puzzle',
                            style: TextStyle(
                              fontFamily: AppText.family,
                              fontSize: 17,
                              color: Palette.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Entrance(
                delay: Duration(milliseconds: 900),
                offset: Offset(0, 14),
                child: Column(
                  children: [
                    SizedBox(width: 180, child: _LoadingBar()),
                    SizedBox(height: 14),
                    Text('Setting up your puzzles…', style: AppText.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlyingMark extends StatelessWidget {
  const _FlyingMark();

  static const double _tile = 68;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    Widget fly(
      Direction direction,
      Offset from,
      int order, {
      bool nudge = false,
    }) {
      final block = SizedBox.square(
        dimension: _tile,
        child: BlockFace(direction: direction),
      );
      return Entrance(
        delay: Duration(milliseconds: 120 * order),
        duration: const Duration(milliseconds: 700),
        curve: Motion.flyInCurve,
        offset: from,
        child: nudge
            ? Looping(
                period: const Duration(milliseconds: 2600),
                delay: const Duration(milliseconds: 1200),
                child: block,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(
                    keyframes(t, const [
                      (0.62, 0),
                      (0.74, 14),
                      (0.86, -3),
                      (1, 0),
                    ], curve: Curves.easeInOut),
                    0,
                  ),
                  child: child,
                ),
              )
            : block,
      );
    }

    return Semantics(
      label: 'Vamoose',
      child: SizedBox(
        width: _tile * 2 + _gap,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                fly(Direction.up, const Offset(0, -320), 0),
                fly(Direction.right, const Offset(320, 0), 1, nudge: true),
              ],
            ),
            const SizedBox(height: _gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                fly(Direction.left, const Offset(-320, 0), 2),
                fly(Direction.down, const Offset(0, 420), 3),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(milliseconds: 2400),
      delay: const Duration(milliseconds: 900),
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Palette.edge),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: keyframes(t, const [
                  (0, 0),
                  (0.7, 1),
                  (1, 1),
                ], curve: Curves.easeInOut),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.ink,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
