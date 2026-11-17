import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/economy.dart';
import '../../services/ads/ad_service.dart';
import '../../state/coin_wallet.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
import '../widgets/entrance.dart';
import '../widgets/key_button.dart';

abstract final class HintSheet {
  static Future<bool> show(BuildContext context) async {
    final granted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      barrierColor: Palette.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Motion.sheet,
        curve: Motion.sheetCurve,
      ),
      builder: (context) => const _HintSheet(),
    );
    return granted ?? false;
  }
}

enum _Stage { choose, loading, unavailable }

class _HintSheet extends StatefulWidget {
  const _HintSheet();

  @override
  State<_HintSheet> createState() => _HintSheetState();
}

class _HintSheetState extends State<_HintSheet> {
  _Stage _stage = _Stage.choose;

  Future<void> _pay() async {
    final paid = await context.read<CoinWallet>().spend(Economy.hintPrice);
    if (paid && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _watch() async {
    final services = context.read<AppServices>();
    setState(() => _stage = _Stage.loading);
    final outcome = await services.ads.showRewarded();
    if (!mounted) {
      return;
    }
    switch (outcome) {
      case RewardOutcome.earned:
        Navigator.of(context).pop(true);
      case RewardOutcome.unavailable:
        setState(() => _stage = _Stage.unavailable);
      case RewardOutcome.skipped:
        setState(() => _stage = _Stage.choose);
    }
  }

  void _close() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
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
            const SizedBox(height: 18),
            Entrance(
              key: ValueKey(_stage),
              duration: const Duration(milliseconds: 260),
              offset: const Offset(0, 10),
              child: switch (_stage) {
                _Stage.choose => _Choose(
                  onPay: _pay,
                  onWatch: _watch,
                  onClose: _close,
                ),
                _Stage.loading => const _Loading(),
                _Stage.unavailable => _Unavailable(
                  onRetry: () => setState(() => _stage = _Stage.choose),
                  onClose: _close,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Choose extends StatelessWidget {
  const _Choose({
    required this.onPay,
    required this.onWatch,
    required this.onClose,
  });

  final VoidCallback onPay;
  final VoidCallback onWatch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final affordable = context.watch<CoinWallet>().canAfford(Economy.hintPrice);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Need a hint?',
                style: AppText.title.copyWith(fontSize: 26),
              ),
            ),
            const CoinChip(height: 40),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'A hint lights up a block that can go and shows its path.',
          style: AppText.body.copyWith(fontSize: 17, height: 1.45),
        ),
        const SizedBox(height: 18),
        if (affordable)
          KeyButton(
            tone: KeyTone.primary,
            height: 66,
            radius: 22,
            semanticLabel: 'Use ${Economy.hintPrice} coins for a hint',
            onPressed: onPay,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Use', style: TextStyle(fontSize: 19)),
                SizedBox(width: 10),
                CoinGlyph(size: 26),
                SizedBox(width: 6),
                Text('${Economy.hintPrice}', style: TextStyle(fontSize: 19)),
              ],
            ),
          )
        else
          Container(
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.line,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'Not enough coins (a hint is ${Economy.hintPrice})',
              style: AppText.bodyStrong.copyWith(color: Palette.slate),
            ),
          ),
        const SizedBox(height: 12),
        KeyButton(
          tone: KeyTone.reward,
          height: 62,
          radius: 20,
          onPressed: onWatch,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline_rounded),
                SizedBox(width: 10),
                Text(
                  'Watch a short video: free hint',
                  style: TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        _TextKey(text: 'Not now', onPressed: onClose),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 40, 0, 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 60,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: Palette.ink,
              backgroundColor: Palette.line,
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(height: 18),
          Text('Loading video…', style: AppText.heading),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: SizedBox.square(
            dimension: 92,
            child: KeyButton(
              tone: KeyTone.soft,
              height: 92,
              radius: 30,
              padding: EdgeInsets.zero,
              onPressed: null,
              child: Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: Palette.slate,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No video right now',
          style: AppText.title.copyWith(fontSize: 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Check your internet and try again in a moment.',
          style: AppText.body.copyWith(fontSize: 17),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        KeyButton(
          tone: KeyTone.soft,
          height: 60,
          onPressed: onRetry,
          child: const Text('Try again', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 10),
        _TextKey(text: 'Back to the puzzle', onPressed: onClose),
      ],
    );
  }
}

class _TextKey extends StatelessWidget {
  const _TextKey({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: AppText.button.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
