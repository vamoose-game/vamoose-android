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
                      body: 'It slides the way it points.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      illustration: _BumpDemo(),
                      title: 'Bumps cost stars',
                      body: 'Three bumps, you’re out.',
                    ),
                    const SizedBox(height: 12),
                    const _Step(
                      illustration: _ClockDemo(),
                      title: 'Beat the clock',
                      body: 'Clear the board in time.',
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
            Positioned(
              right: 6,
              top: 4,
              child: Transform.scale(
                scale: keyframes(t, const [
                  (0.36, 1),
                  (0.44, 1.4),
                  (0.52, 0.85),
                  (0.6, 1),
                ], curve: Curves.easeOut),
                child: StarGlyph(size: 20, filled: t < 0.4 || t > 0.92),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClockDemo extends StatelessWidget {
  const _ClockDemo();

  @override
  Widget build(BuildContext context) {
    return Looping(
      period: const Duration(seconds: 4),
      builder: (context, t, _) {
        final seconds = (5 - (t * 5.5).floor()).clamp(0, 5);
        final low = seconds <= 2;
        return Center(
          child: Transform.scale(
            scale: low ? 1 + 0.06 * (1 - (t * 5.5 % 1)) : 1,
            child: Container(
              height: 40,
              padding: const EdgeInsets.fromLTRB(8, 0, 11, 0),
              decoration: BoxDecoration(
                color: low ? Palette.orangeTint : Palette.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: low ? Palette.danger : Palette.ink,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '0:0$seconds',
                    style: AppText.number.copyWith(
                      fontSize: 17,
                      color: low ? Palette.danger : Palette.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
