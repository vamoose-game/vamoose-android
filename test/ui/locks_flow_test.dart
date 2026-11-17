import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/locks_intro.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/level_complete_screen.dart';
import 'package:vamoose/ui/theme/motion.dart';

import '../support/boards.dart';
import '../support/locks.dart';
import '../support/pumping.dart';
import '../support/test_services.dart';

final Duration landing = Motion.flyInDelay + Motion.blockLeaves;

Finder blockFinder(int id) => find.byKey(ValueKey('block-$id'));

final Finder lockedLabel = find.bySemanticsLabel(
  RegExp('locked: clear the block with the key first'),
);

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  Future<void> play(WidgetTester tester, int level) async {
    await tester.launch(services, home: GameScreen(mode: CampaignMode(level)));
    await tester.wait(landing);
  }

  testWidgets('the locks intro shows once when locks first appear', (
    tester,
  ) async {
    await play(tester, 12);

    expect(find.text('Locked blocks'), findsOneWidget);
    expect(find.text('NEW IN CHAPTER WARM-UP'), findsOneWidget);

    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(find.text('Locked blocks'), findsNothing);
    expect(services.settings.hasSeenIntro(LocksIntro.id), isTrue);
    await tester.close();

    await play(tester, 13);
    expect(find.text('Locked blocks'), findsNothing);
    await tester.close();
  });

  testWidgets('levels without locks skip the intro', (tester) async {
    await play(tester, 11);

    expect(find.text('Locked blocks'), findsNothing);
    expect(services.settings.hasSeenIntro(LocksIntro.id), isFalse);
    await tester.close();
  });

  testWidgets('a locked block bumps until its key leaves, then goes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(12).board;
    final lock = locksOf(board).single;
    await services.settings.markIntroSeen(LocksIntro.id);
    await play(tester, 12);

    expect(lockedLabel, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('carries a key')), findsOneWidget);

    await tester.tapAndWait(blockFinder(lock.blockId));
    expect(find.text('Bumps 1'), findsOneWidget);
    expect(blockFinder(lock.blockId), findsOneWidget);

    var current = board;
    while (current.contains(lock.keyId)) {
      final next = current.movableBlocks.first;
      await tester.tapAndWait(blockFinder(next.id));
      current = current.without(next.id);
    }
    expect(lockedLabel, findsNothing);

    await tester.tapAndWait(blockFinder(lock.blockId));
    expect(blockFinder(lock.blockId), findsNothing);
    expect(find.text('Bumps 1'), findsOneWidget);

    semantics.dispose();
    await tester.close();
  });

  testWidgets('hints never point at a locked block', (tester) async {
    final semantics = tester.ensureSemantics();
    await services.settings.markIntroSeen(LocksIntro.id);
    await play(tester, 12);

    await tester.tapAndWait(find.text('Hint'));

    expect(find.bySemanticsLabel(RegExp('hint: this one can go')), findsOne);
    expect(
      find.bySemanticsLabel(RegExp('locked.*hint: this one can go')),
      findsNothing,
    );

    semantics.dispose();
    await tester.close();
  });

  testWidgets('a level with two lock pairs can be cleared', (tester) async {
    final board = services.levels.byNumber(77).board;
    expect(locksOf(board), hasLength(2));
    await services.settings.markIntroSeen(LocksIntro.id);
    await play(tester, 77);

    for (final id in solutionOrder(board)) {
      await tester.tapAndWait(
        blockFinder(id),
        const Duration(milliseconds: 100),
      );
    }
    await tester.wait(const Duration(seconds: 2));

    expect(find.byType(LevelCompleteScreen), findsOneWidget);
    expect(services.progress.starsFor(77), 3);
    await tester.close();
  });
}
