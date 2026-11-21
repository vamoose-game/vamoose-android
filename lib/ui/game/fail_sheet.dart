import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/game_session.dart';
import '../../state/lives_controller.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/every_second.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/lives_row.dart';
import 'life_actions.dart';

enum FailChoice { retry, levels }

/// "Time's up" or "Out of stars": the lost heart flies off, then try again,
/// or get a life first when none are left.
abstract final class FailSheet {
  static Future<FailChoice> show(
    BuildContext context, {
    required Failure failure,
  }) async {
    final choice = await showModalBottomSheet<FailChoice>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      barrierColor: Palette.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Motion.sheet,
        curve: Motion.sheetCurve,
      ),
      builder: (context) => _FailSheet(failure: failure),
    );
    return choice ?? FailChoice.levels;
  }
}

class _FailSheet extends StatefulWidget {
  const _FailSheet({required this.failure});

  final Failure failure;

  @override
  State<_FailSheet> createState() => _FailSheetState();
}

class _FailSheetState extends State<_FailSheet> {
  late final int _lostAt = context.read<LivesController>().count;

  void _choose(FailChoice choice) => Navigator.of(context).pop(choice);

  @override
  Widget build(BuildContext context) {
    final lives = context.read<LivesController>();
    final outOfTime = widget.failure == Failure.outOfTime;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _choose(FailChoice.levels);
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          child: EverySecond(
            onTick: lives.refresh,
            builder: (context) {
              final count = context.watch<LivesController>().count;
              return Column(
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
                  const SizedBox(height: 16),
                  Center(child: _FailIcon(outOfTime: outOfTime)),
                  const SizedBox(height: 14),
                  Text(
                    outOfTime ? 'Time’s up' : 'Out of stars',
                    style: AppText.title.copyWith(letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: LivesRow(
                      count: count,
                      losing: count == _lostAt ? _lostAt : null,
                      refill: lives.refillProgress,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    livesLine(lives),
                    style: AppText.bodyStrong.copyWith(color: Palette.slate),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (count > 0)
                    KeyButton(
                      tone: KeyTone.primary,
                      height: 64,
                      radius: 22,
                      onPressed: () => _choose(FailChoice.retry),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restart_alt_rounded),
                          SizedBox(width: 10),
                          Text('Try again', style: TextStyle(fontSize: 19)),
                        ],
                      ),
                    )
                  else
                    const LifeActions(),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => _choose(FailChoice.levels),
                      child: Text(
                        'Levels',
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
        ),
      ),
    );
  }
}

class _FailIcon extends StatelessWidget {
  const _FailIcon({required this.outOfTime});

  final bool outOfTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Palette.orangeTint,
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.center,
      child: outOfTime
          ? const Icon(Icons.timer_off_outlined, size: 40, color: Palette.alert)
          : const SizedBox.square(
              dimension: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  StarGlyph(size: 40, filled: false, strokeWidth: 1.6),
                  _Slash(),
                ],
              ),
            ),
    );
  }
}

class _Slash extends StatelessWidget {
  const _Slash();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 4,
        height: 46,
        decoration: BoxDecoration(
          color: Palette.alert,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Palette.orangeTint, width: 1),
        ),
      ),
    );
  }
}
