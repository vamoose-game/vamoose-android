import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../services/ads/ad_service.dart';
import '../../state/hint_wallet.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/key_button.dart';

abstract final class OutOfHintsSheet {
  static Future<bool> show(BuildContext context) async {
    final earned = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Palette.scrim,
      sheetAnimationStyle: const AnimationStyle(
        duration: Motion.sheet,
        curve: Motion.sheetCurve,
      ),
      builder: (context) => const _OutOfHints(),
    );
    return earned ?? false;
  }
}

class _OutOfHints extends StatefulWidget {
  const _OutOfHints();

  @override
  State<_OutOfHints> createState() => _OutOfHintsState();
}

class _OutOfHintsState extends State<_OutOfHints> {
  bool _noVideo = false;

  Future<void> _watch() async {
    final services = context.read<AppServices>();
    final wallet = context.read<HintWallet>();
    final navigator = Navigator.of(context);
    final outcome = await services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await wallet.add(1);
      navigator.pop(true);
    } else if (mounted) {
      setState(() => _noVideo = outcome == RewardOutcome.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Palette.edge,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Center(
              child: SizedBox.square(
                dimension: 92,
                child: KeyButton(
                  tone: KeyTone.hint,
                  height: 92,
                  radius: 24,
                  padding: EdgeInsets.zero,
                  onPressed: null,
                  child: Icon(Icons.lightbulb_outline_rounded, size: 44),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Out of hints',
              style: AppText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Watch a short video and we will show you a block that can go.',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            KeyButton(
              tone: KeyTone.primary,
              onPressed: _watch,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_outlined),
                  SizedBox(width: 10),
                  Flexible(child: Text('Watch video · +1 hint')),
                ],
              ),
            ),
            if (_noVideo)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'No video right now. Try again soon.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Not now',
                style: AppText.button.copyWith(fontSize: 17),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: Palette.slate),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'You also get 1 free hint every day',
                    style: AppText.body,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
