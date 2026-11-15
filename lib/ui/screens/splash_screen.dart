import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../state/settings_controller.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/logo.dart';
import '../widgets/progress_bar.dart';
import 'home_screen.dart';
import 'how_to_play_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration duration = Duration(milliseconds: 1400);
  static const Duration storeTimeout = Duration(seconds: 8);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final services = context.read<AppServices>();
    await Future.wait([_progress.forward(), _prepare(services)]);
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

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            children: [
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LogoMark(),
                    SizedBox(height: 40),
                    FittedBox(child: Wordmark()),
                    SizedBox(height: 10),
                    Text('The calm block puzzle', style: AppText.body),
                  ],
                ),
              ),
              SizedBox(
                width: 188,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => ProgressBar(
                    value: Curves.easeInOut.transform(_progress.value),
                    color: Palette.ink,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Setting up your puzzles…', style: AppText.body),
            ],
          ),
        ),
      ),
    );
  }
}
