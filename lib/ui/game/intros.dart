import 'package:material_ui/material_ui.dart';

import '../../domain/board.dart';
import '../../domain/restraint.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/card_dialog.dart';
import '../widgets/key_button.dart';
import 'countdown_demo.dart';
import 'locks_demo.dart';
import 'turns_demo.dart';

/// A rule shown once, the first time a level uses it.
final class Intro {
  const Intro({
    required this.id,
    required this.title,
    required this.line,
    required this.demo,
    required this.appliesTo,
    this.legend,
  });

  /// Remembered in settings once seen.
  final String id;
  final String title;
  final String line;
  final Widget demo;
  final bool Function(Board board) appliesTo;

  /// Shown under [line], when the rule has signs to explain.
  final Widget? legend;

  Future<void> show(BuildContext context) => CardDialog.show<void>(
    context,
    label: 'Got it',
    dismissible: false,
    builder: (context) => _IntroCard(intro: this),
  );
}

/// Every intro, in the order they would show on one level.
abstract final class Intros {
  static const Intro locks = Intro(
    id: 'locks',
    title: 'Locked blocks',
    line: 'Clear the key first.',
    demo: LocksDemo(),
    appliesTo: _hasLocks,
  );

  static const Intro turns = Intro(
    id: 'turns',
    title: 'Turning blocks',
    line: 'They turn every time a block leaves.',
    demo: TurnsDemo(),
    appliesTo: _hasTurns,
  );

  static const Intro countdowns = Intro(
    id: 'countdowns',
    title: 'Countdown blocks',
    line:
        'Every block that leaves counts it down. Get it out before 0, or '
        'lose a star.',
    demo: CountdownDemo(),
    legend: CountdownLegend(),
    appliesTo: _hasCountdowns,
  );

  static const List<Intro> all = [locks, turns, countdowns];

  static bool _hasLocks(Board board) =>
      board.restraints.any((restraint) => restraint is Lock);

  static bool _hasTurns(Board board) => board.hasTurningBlocks;

  static bool _hasCountdowns(Board board) => board.hasCountdowns;
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.intro});

  final Intro intro;

  @override
  Widget build(BuildContext context) {
    return DialogCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NEW',
            style: AppText.label.copyWith(
              color: Palette.alert,
              letterSpacing: 1.56,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            intro.title,
            style: AppText.title.copyWith(fontSize: 30, letterSpacing: -0.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          intro.demo,
          const SizedBox(height: 18),
          Text(
            intro.line,
            style: AppText.body.copyWith(fontSize: 17, height: 1.45),
            textAlign: TextAlign.center,
          ),
          if (intro.legend case final legend?) ...[
            const SizedBox(height: 14),
            legend,
          ],
          const SizedBox(height: 18),
          KeyButton(
            tone: KeyTone.primary,
            height: 62,
            radius: 20,
            onPressed: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Got it',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
