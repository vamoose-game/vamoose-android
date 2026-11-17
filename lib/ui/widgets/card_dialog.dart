import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import '../theme/palette.dart';

abstract final class CardDialog {
  static const Duration _cardDelay = Duration(milliseconds: 60);
  static const Duration _cardIn = Duration(milliseconds: 320);

  static Future<T?> show<T>(
    BuildContext context, {
    required String label,
    required WidgetBuilder builder,
    bool dismissible = true,
  }) {
    final total = _cardDelay + _cardIn;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: label,
      barrierColor: Colors.transparent,
      transitionDuration: total,
      pageBuilder: (context, _, _) => builder(context),
      transitionBuilder: (context, animation, _, child) {
        final scrim = CurvedAnimation(
          parent: animation,
          curve: Interval(
            0,
            Motion.scrimFade.inMilliseconds / total.inMilliseconds,
            curve: Curves.easeOut,
          ),
        );
        final card = CurvedAnimation(
          parent: animation,
          curve: Interval(
            _cardDelay.inMilliseconds / total.inMilliseconds,
            1,
            curve: Motion.cardCurve,
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: scrim,
                  builder: (context, _) => BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 6 * scrim.value,
                      sigmaY: 6 * scrim.value,
                    ),
                    child: ColoredBox(
                      color: Palette.scrim.withValues(
                        alpha: 0.55 * scrim.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: card,
              child: child,
              builder: (context, child) => Opacity(
                opacity: card.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - card.value)),
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * card.value,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DialogCard extends StatelessWidget {
  const DialogCard({super.key, required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x401B2340),
                offset: Offset(0, 30),
                blurRadius: 60,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
