import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/economy.dart';
import '../../services/ads/ad_service.dart';
import '../../state/coin_wallet.dart';
import '../../state/lives_controller.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
import '../widgets/heart.dart';
import '../widgets/key_button.dart';
import '../widgets/toast.dart';

/// Ways to get lives back now: a video for one, or coins for all.
class LifeActions extends StatefulWidget {
  const LifeActions({super.key});

  @override
  State<LifeActions> createState() => _LifeActionsState();
}

class _LifeActionsState extends State<LifeActions> {
  bool _loading = false;

  Future<void> _watch() async {
    final services = context.read<AppServices>();
    setState(() => _loading = true);
    final outcome = await services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await services.lives.add(1);
      services.feedback.lifeGained();
    }
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (outcome == RewardOutcome.unavailable) {
      Toast.show(context, 'No video right now');
    }
  }

  Future<void> _refill() async {
    final services = context.read<AppServices>();
    if (await services.lives.refillAll(services.coins)) {
      services.feedback.lifeGained();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lives = context.watch<LivesController>();
    final affordable = context.watch<CoinWallet>().canAfford(
      Economy.refillLivesPrice,
    );
    final ads = context.read<AppServices>().ads;
    if (lives.isFull) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ads.isReady) ...[
          if (_loading)
            Container(
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.cream,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Palette.ink,
                  backgroundColor: Palette.creamEdge,
                  strokeCap: StrokeCap.round,
                ),
              ),
            )
          else
            KeyButton(
              tone: KeyTone.hint,
              height: 62,
              semanticLabel: 'Watch a video for one life',
              onPressed: _watch,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline_rounded),
                  SizedBox(width: 10),
                  Text('+1 life', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          const SizedBox(height: 10),
        ],
        Opacity(
          opacity: affordable ? 1 : 0.5,
          child: KeyButton(
            tone: KeyTone.soft,
            height: 58,
            semanticLabel:
                'Refill all lives for ${Economy.refillLivesPrice} coins',
            onPressed: affordable ? _refill : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HeartGlyph(size: 22),
                const SizedBox(width: 8),
                Text('Refill', style: AppText.button.copyWith(fontSize: 17)),
                const SizedBox(width: 10),
                const CoinGlyph(size: 20),
                const SizedBox(width: 5),
                Text(
                  Formatting.grouped(Economy.refillLivesPrice),
                  style: AppText.button.copyWith(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Next life in 12:34", or how many lives are left.
String livesLine(LivesController lives) {
  final count = lives.count;
  if (count == 0) {
    return 'Next life in ${Formatting.clockLeft(lives.untilNext ?? Duration.zero)}';
  }
  return count == 1 ? '1 life left' : '$count lives left';
}
