import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

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
    unawaited(_progress.forward().whenComplete(_continue));
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
