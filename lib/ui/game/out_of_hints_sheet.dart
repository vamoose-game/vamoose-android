import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../services/ads/ad_service.dart';
import '../../state/hint_wallet.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/entrance.dart';
import '../widgets/key_button.dart';

abstract final class OutOfHintsSheet {
  static Future<bool> show(BuildContext context) async {
    final earned = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: Palette.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Motion.sheet,
        curve: Motion.sheetCurve,
      ),
      builder: (context) => const _OutOfHints(),
    );
    return earned ?? false;
  }
}

enum _Stage { offer, loading, unavailable, granted }

class _OutOfHints extends StatefulWidget {
  const _OutOfHints();

  @override
  State<_OutOfHints> createState() => _OutOfHintsState();
}

class _OutOfHintsState extends State<_OutOfHints> {
  _Stage _stage = _Stage.offer;

  Future<void> _watch() async {
    final services = context.read<AppServices>();
    final wallet = context.read<HintWallet>();
    setState(() => _stage = _Stage.loading);
    final outcome = await services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await wallet.add(1);
    }
    if (mounted) {
      setState(
        () => _stage = switch (outcome) {
          RewardOutcome.earned => _Stage.granted,
          RewardOutcome.unavailable => _Stage.unavailable,
          RewardOutcome.skipped => _Stage.offer,
        },
      );
    }
  }

  void _close() => Navigator.of(context).pop(_stage == _Stage.granted);

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
                _Stage.offer => _Offer(onWatch: _watch, onClose: _close),
                _Stage.loading => const _Loading(),
                _Stage.unavailable => _Unavailable(
                  onRetry: () => setState(() => _stage = _Stage.offer),
                  onClose: _close,
                ),
                _Stage.granted => _Granted(onClose: _close),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Offer extends StatelessWidget {
  const _Offer({required this.onWatch, required this.onClose});

  final VoidCallback onWatch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: _Glow(
            child: _StageKey(
              tone: KeyTone.hint,
              icon: Icons.lightbulb_outline_rounded,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _Message(
          title: 'Out of hints',
          body: 'Watch a short video and we will show you a block that can go.',
        ),
        const SizedBox(height: 18),
        KeyButton(
          tone: KeyTone.primary,
          radius: 22,
          onPressed: onWatch,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_outlined),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Watch video · +1 hint',
                  style: TextStyle(fontSize: 19),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _TextKey(text: 'Not now', onPressed: onClose),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: Palette.slate),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'You also get 1 free hint every day',
                style: AppText.body,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 44, 0, 60),
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
          SizedBox(height: 8),
          Text('Your hint is on its way.', style: AppText.body),
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
          child: _StageKey(
            tone: KeyTone.soft,
            icon: Icons.wifi_off_rounded,
            iconColor: Palette.slate,
          ),
        ),
        const SizedBox(height: 18),
        const _Message(
          title: 'No video right now',
          body: 'Check your internet and try again in a moment.',
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

class _Granted extends StatelessWidget {
  const _Granted({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: _StageKey(tone: KeyTone.success, icon: Icons.check_rounded),
        ),
        const SizedBox(height: 18),
        const _Message(
          title: '+1 hint added',
          body: 'Thanks for watching. Tap Hint to use it.',
        ),
        const SizedBox(height: 18),
        KeyButton(
          tone: KeyTone.primary,
          radius: 22,
          onPressed: onClose,
          child: const Text(
            'Back to the puzzle',
            style: TextStyle(fontSize: 19),
          ),
        ),
      ],
    );
  }
}

class _StageKey extends StatelessWidget {
  const _StageKey({required this.tone, required this.icon, this.iconColor});

  final KeyTone tone;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 92,
      child: KeyButton(
        tone: tone,
        height: 92,
        radius: 30,
        padding: EdgeInsets.zero,
        onPressed: null,
        child: Icon(icon, size: 44, color: iconColor),
      ),
    );
  }
}

class _Glow extends StatefulWidget {
  const _Glow({required this.child});

  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppText.title.copyWith(fontSize: 26),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: AppText.body.copyWith(fontSize: 17),
          textAlign: TextAlign.center,
        ),
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
