import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/economy.dart';
import '../../state/lives_controller.dart';
import '../formatting.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import 'every_second.dart';
import 'heart.dart';
import 'key_button.dart';
import 'lives_row.dart';
import 'looping.dart';

/// The heart and life count on Home. Tap it for the hearts, the countdown
/// to the next life and a way to get more.
class LivesChip extends StatelessWidget {
  const LivesChip({super.key});

  static const double _height = 48;
  static const double _popoverWidth = 248;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final chip = box.localToGlobal(Offset.zero) & box.size;
    final wantsStore = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close lives',
      barrierColor: Colors.transparent,
      transitionDuration: Motion.popover,
      pageBuilder: (context, _, _) => _Popover(anchor: chip),
      transitionBuilder: (context, animation, _, child) {
        final t = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.2, 0.9, 0.3, 1.2),
        );
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: t,
            child: child,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -8 * (1 - t.value)),
              child: child,
            ),
          ),
        );
      },
    );
    if ((wantsStore ?? false) && context.mounted) {
      await Navigation.store(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lives = context.read<LivesController>();
    return EverySecond(
      onTick: lives.refresh,
      builder: (context) {
        final count = context.watch<LivesController>().count;
        return Semantics(
          button: true,
          label: '$count of ${Economy.maxLives} lives',
          child: GestureDetector(
            onTap: () => _open(context),
            child: Container(
              height: _height,
              padding: const EdgeInsets.fromLTRB(9, 0, 15, 0),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(_height / 2),
              ),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Looping(
                      period: const Duration(seconds: 4),
                      delay: const Duration(seconds: 2),
                      child: HeartGlyph(size: 28, fill: count > 0 ? 1 : 0),
                      builder: (context, t, child) => Transform.scale(
                        scale: keyframes(t, const [
                          (0.62, 1),
                          (0.68, 1.2),
                          (0.74, 1),
                          (0.8, 1.13),
                          (0.88, 1),
                        ]),
                        child: child,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: AppText.number.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Popover extends StatelessWidget {
  const _Popover({required this.anchor});

  final Rect anchor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final left = (anchor.center.dx - LivesChip._popoverWidth / 2)
        .clamp(16.0, max(16.0, width - LivesChip._popoverWidth - 16))
        .toDouble();
    final lives = context.read<LivesController>();
    return Stack(
      children: [
        Positioned(
          left: left,
          top: anchor.bottom + 12,
          width: LivesChip._popoverWidth,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -7,
                  left: anchor.center.dx - left - 8,
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331B2340),
                        offset: Offset(0, 18),
                        blurRadius: 44,
                      ),
                    ],
                  ),
                  child: EverySecond(
                    onTick: lives.refresh,
                    builder: (context) {
                      final current = context.watch<LivesController>();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: LivesRow(
                              count: current.count,
                              refill: current.refillProgress,
                              size: 30,
                              gap: 5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (current.isFull)
                            Text(
                              'Lives full',
                              style: AppText.button.copyWith(fontSize: 17),
                              textAlign: TextAlign.center,
                            )
                          else ...[
                            Text(
                              'Next life in',
                              style: AppText.bodyStrong.copyWith(
                                color: Palette.slate,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              Formatting.clockLeft(
                                current.untilNext ?? Duration.zero,
                              ),
                              style: AppText.number.copyWith(
                                fontSize: 34,
                                letterSpacing: -0.6,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            KeyButton(
                              tone: KeyTone.primary,
                              height: 50,
                              radius: 16,
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Get lives',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
