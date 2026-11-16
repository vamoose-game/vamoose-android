import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/direction.dart';
import '../../state/settings_controller.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';
import '../widgets/surface_card.dart';
import '../widgets/tap_ring.dart';
import 'home_screen.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, this.returnsToCaller = false});

  final bool returnsToCaller;

  Future<void> _done(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<SettingsController>().markTutorialSeen();
    if (returnsToCaller) {
      navigator.pop();
    } else {
      await navigator.pushReplacement(
        Navigation.page<void>(const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => _done(context),
                    child: Text(
                      'Skip',
                      style: AppText.button.copyWith(
                        color: Palette.slate,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'THREE THINGS TO KNOW',
                      style: AppText.label.copyWith(color: Palette.alert),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How to play',
                      style: AppText.title.copyWith(
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _Step(
                      illustration: _SlideDemo(),
                      title: 'Tap a block',
                      body: 'It slides the way its arrow points. A clear path means it leaves.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      illustration: _BumpDemo(),
                      title: 'Blocked? It bumps',
                      body: 'The block in the way lights up. Move that one first.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      illustration: _StarsDemo(),
                      title: 'Clear the board',
                      body: 'No bumps earns 3 stars. You can never get stuck.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              KeyButton(
                tone: KeyTone.primary,
                height: 64,
                radius: 22,
                onPressed: () => _done(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Let\'s play', style: TextStyle(fontSize: 19)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded),
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

class _Step extends StatelessWidget {
  const _Step({
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 112,
              height: 88,
              child: ColoredBox(color: Palette.well, child: illustration),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading.copyWith(fontSize: 19)),
                const SizedBox(height: 6),
                Text(body, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideDemo extends StatelessWidget {
  const _SlideDemo();

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(seconds: 3),
      builder: (context, t, _) {
        final x = keyframes(t, const [
          (0.32, 0),
          (0.58, 130),
        ], curve: Motion.leaveCurve);
        final away = t > 0.58 && t < 0.72;
        final scale = keyframes(t, const [
          (0.58, 1),
          (0.59, 0.4),
          (0.72, 0.4),
          (0.86, 1),
        ]);
        final opacity = keyframes(t, const [
          (0.32, 1),
          (0.58, 0),
          (0.72, 0),
          (0.86, 1),
        ]);
        return Stack(
          children: [
            for (final dx in const [72.0, 86.0, 100.0])
              Positioned(
                left: dx,
                top: 41,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Palette.muted,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned(
              left: 16,
              top: 22,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(away ? 0 : x, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: const SizedBox.square(
                      dimension: 44,
                      child: BlockFace(
                        direction: Direction.right,
                        arrowSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 24,
              child: TapRing(t: t, start: 0.10, size: 40),
            ),
          ],
        );
      },
    );
  }
}

class _BumpDemo extends StatelessWidget {
  const _BumpDemo();

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(milliseconds: 2600),
      builder: (context, t, _) {
        final nudge = keyframes(t, const [
          (0.30, 0),
          (0.40, 9),
          (0.50, -3),
          (0.58, 0),
        ], curve: Curves.easeOut);
        final ring = keyframes(t, const [
          (0.34, 0),
          (0.42, 4),
          (0.66, 4),
          (0.78, 0),
        ], curve: Curves.easeOut);
        return Stack(
          children: [
            Positioned(
              left: 10,
              top: 22,
              child: Transform.translate(
                offset: Offset(nudge, 0),
                child: const SizedBox.square(
                  dimension: 44,
                  child: BlockFace(direction: Direction.right, arrowSize: 22),
                ),
              ),
            ),
            Positioned(
              left: 58,
              top: 22,
              child: SizedBox.square(
                dimension: 44,
                child: BlockFace(
                  direction: Direction.up,
                  arrowSize: 22,
                  ringColor: Palette.ink,
                  ringWidth: ring,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StarsDemo extends StatelessWidget {
  const _StarsDemo();

  @override
  Widget build(BuildContext context) {
    Widget star(double size, Duration delay) => Looping(
      period: const Duration(milliseconds: 2800),
      delay: delay,
      child: StarGlyph(size: size),
      builder: (context, t, child) => Transform.scale(
        scale: keyframes(t, const [
          (0, 0),
          (0.12, 1.25),
          (0.20, 1),
          (0.82, 1),
          (0.94, 0),
        ], curve: Curves.easeOut),
        child: child,
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        star(30, Duration.zero),
        const SizedBox(width: 2),
        star(36, const Duration(milliseconds: 180)),
        const SizedBox(width: 2),
        star(30, const Duration(milliseconds: 360)),
      ],
    );
  }
}
