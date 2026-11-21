import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/lives_controller.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/card_dialog.dart';
import '../widgets/every_second.dart';
import '../widgets/key_button.dart';
import '../widgets/lives_row.dart';
import 'life_actions.dart';

/// Shown when a level would start with no lives: the next life fills up
/// while the clock runs down, or get one now.
abstract final class OutOfLives {
  /// True once there is a life to play with.
  static Future<bool> show(BuildContext context) async =>
      await CardDialog.show<bool>(
        context,
        label: 'Not now',
        builder: (context) => const _OutOfLivesCard(),
      ) ??
      false;
}

class _OutOfLivesCard extends StatelessWidget {
  const _OutOfLivesCard();

  @override
  Widget build(BuildContext context) {
    final lives = context.read<LivesController>();
    return DialogCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
      child: EverySecond(
        onTick: lives.refresh,
        builder: (context) {
          final count = context.watch<LivesController>().count;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                switch (count) {
                  0 => 'Out of lives',
                  1 => '1 life ready',
                  _ => '$count lives ready',
                },
                style: AppText.title.copyWith(letterSpacing: -0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: LivesRow(
                  count: count,
                  refill: lives.refillProgress,
                  size: 38,
                ),
              ),
              if (count == 0) ...[
                const SizedBox(height: 14),
                Text(
                  'Next life in',
                  style: AppText.bodyStrong.copyWith(
                    color: Palette.slate,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  Formatting.clockLeft(lives.untilNext ?? Duration.zero),
                  style: AppText.number.copyWith(
                    fontSize: 46,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (count > 0) ...[
                KeyButton(
                  tone: KeyTone.primary,
                  height: 64,
                  radius: 22,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded),
                      SizedBox(width: 8),
                      Text('Play', style: TextStyle(fontSize: 19)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const LifeActions(),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Not now',
                    style: AppText.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
