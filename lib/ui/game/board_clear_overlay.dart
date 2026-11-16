import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/confetti.dart';
import '../widgets/entrance.dart';
import '../widgets/key_button.dart';

class BoardClearOverlay extends StatelessWidget {
  const BoardClearOverlay({super.key, required this.onSeeResults});

  final VoidCallback onSeeResults;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Confetti(
              pieces: Confetti.burst,
              fall: constraints.maxHeight + 30,
              turns: 1.5,
              curve: Curves.easeIn,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Entrance(
                    delay: Duration(milliseconds: 380),
                    duration: Motion.badge,
                    curve: Motion.popCurve,
                    fromScale: 0.3,
                    child: SizedBox.square(
                      dimension: 96,
                      child: KeyButton(
                        tone: KeyTone.success,
                        height: 96,
                        radius: 30,
                        padding: EdgeInsets.zero,
                        onPressed: null,
                        child: Icon(
                          Icons.check_rounded,
                          size: 52,
                          color: Palette.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Entrance(
                    delay: Duration(milliseconds: 560),
                    duration: Duration(milliseconds: 420),
                    fromScale: 0.3,
                    child: Text(
                      'Board clear!',
                      style: TextStyle(
                        fontFamily: AppText.family,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: -0.5,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Entrance(
                    delay: const Duration(milliseconds: 760),
                    duration: const Duration(milliseconds: 400),
                    fromScale: 0.3,
                    child: IntrinsicWidth(
                      child: KeyButton(
                        tone: KeyTone.primary,
                        height: 56,
                        radius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        onPressed: onSeeResults,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('See results'),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
