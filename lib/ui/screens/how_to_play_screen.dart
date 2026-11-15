import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/direction.dart';
import '../../state/settings_controller.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/block_face.dart';
import '../widgets/key_button.dart';
import '../widgets/surface_card.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _done(context),
                  child: Text(
                    'Skip',
                    style: AppText.button.copyWith(
                      color: Palette.slate,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'THREE THINGS TO KNOW',
                      style: AppText.label.copyWith(color: Palette.alert),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'How to play',
                      style: AppText.title.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 18),
                    const _Step(
                      illustration: _SlideIllustration(),
                      title: 'Tap a block',
                      body: 'It slides the way its arrow points. A clear path means it leaves.',
                    ),
                    const SizedBox(height: 14),
                    const _Step(
                      illustration: _BumpIllustration(),
                      title: 'Blocked? It bumps',
                      body: 'The block in the way lights up. Move that one first.',
                    ),
                    const SizedBox(height: 14),
                    const _Step(
                      illustration: _StarsIllustration(),
                      title: 'Clear the board',
                      body: 'No bumps earns 3 stars. You can never get stuck.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              KeyButton(
                tone: KeyTone.primary,
                height: 68,
                onPressed: () => _done(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Let\'s play'),
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 116,
            height: 92,
            decoration: BoxDecoration(
              color: Palette.mist,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: illustration,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading),
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

class _SlideIllustration extends StatelessWidget {
  const _SlideIllustration();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 46,
          height: 42,
          child: BlockFace(direction: Direction.right, look: BlockLook.normal),
        ),
        for (var index = 0; index < 3; index++)
          Container(
            margin: const EdgeInsets.only(left: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Palette.edge.withValues(alpha: 1 - index * 0.25),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _BumpIllustration extends StatelessWidget {
  const _BumpIllustration();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: BlockFace(direction: Direction.right),
        ),
        SizedBox(width: 6),
        SizedBox(
          width: 44,
          height: 44,
          child: BlockFace(direction: Direction.up, look: BlockLook.inTheWay),
        ),
      ],
    );
  }
}

class _StarsIllustration extends StatelessWidget {
  const _StarsIllustration();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.star_rounded, color: Palette.sun, size: 30),
        Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Icon(Icons.star_rounded, color: Palette.sun, size: 38),
        ),
        Icon(Icons.star_rounded, color: Palette.sun, size: 30),
      ],
    );
  }
}
