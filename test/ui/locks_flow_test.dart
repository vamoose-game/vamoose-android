import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/ui/formatting.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/intros.dart';
import 'package:vamoose/ui/game/turn_face.dart';
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

  int firstLevelWith(bool Function(int locks, int turners) test) {
    for (var number = 1; number <= services.levels.count; number++) {
      final board = services.levels.byNumber(number).board;
      final turners = board.blocks.where((block) => block.turns).length;
      if (test(locksOf(board).length, turners)) {
        return number;
      }
    }
    throw StateError('No such level');
  }

  testWidgets('the locks intro shows once when locks first appear', (
    tester,
  ) async {
    await play(tester, 11);

    expect(find.text('Locked blocks'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);

    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(find.text('Locked blocks'), findsNothing);
    expect(services.settings.hasSeenIntro(Intros.locks.id), isTrue);
    await tester.close();

    await play(tester, 12);
    expect(find.text('Locked blocks'), findsNothing);
    await tester.close();
  });

  testWidgets('the clock waits while an intro is open', (tester) async {
    final limit = services.levels.byNumber(11).timeLimit;
    await play(tester, 11);
    await tester.wait(limit + const Duration(seconds: 2));

    await tester.tapAndWait(find.text('Got it'));

    expect(find.text('Time’s up'), findsNothing);
    expect(find.text(Formatting.clock(limit)), findsOneWidget);

    await tester.wait(landing + const Duration(seconds: 1));
    expect(
      find.text(Formatting.clock(limit - const Duration(seconds: 1))),
      findsOneWidget,
    );

    await tester.wait(limit);
    expect(find.text('Time’s up'), findsOneWidget);
    await tester.close();
  });

  testWidgets('levels without locks skip the intro', (tester) async {
    await play(tester, 10);

    expect(find.text('Locked blocks'), findsNothing);
    expect(services.settings.hasSeenIntro(Intros.locks.id), isFalse);
    await tester.close();
  });

  testWidgets('the turning intro shows once when turning blocks appear', (
    tester,
  ) async {
    await services.settings.markIntroSeen(Intros.locks.id);
    await play(tester, 21);

    expect(find.text('Turning blocks'), findsOneWidget);
    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(services.settings.hasSeenIntro(Intros.turns.id), isTrue);
    await tester.close();

    await play(tester, 22);
    expect(find.text('Turning blocks'), findsNothing);
    await tester.close();
  });

  testWidgets('a turning block turns each time another block leaves', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(21).board;
    final turner = board.blocks.firstWhere((block) => block.turns);
    final other = board.movableBlocks.firstWhere((block) => !block.turns);
    await services.settings.markIntroSeen(Intros.turns.id);
    await play(tester, 21);

    Finder facing(String direction) =>
        find.bySemanticsLabel(RegExp('^$direction turning block'));
    final face = find.descendant(
      of: blockFinder(turner.id),
      matching: find.byType(TurnFace),
    );
    final round = find.descendant(of: face, matching: find.byType(RoundFace));
    expect(facing(turner.direction.name), findsOneWidget);
    expect(tester.widget<TurnFace>(face).direction, turner.direction);
    final quarters = tester.widget<RoundFace>(round).quarters;

    await tester.tapAndWait(blockFinder(other.id), const Duration(seconds: 1));

    expect(facing(turner.direction.clockwise.name), findsOneWidget);
    expect(tester.widget<TurnFace>(face).direction, turner.direction.clockwise);
    expect(tester.widget<RoundFace>(round).quarters, quarters + 1);
    semantics.dispose();
    await tester.close();
  });

  testWidgets('a locked block bumps until its key leaves, then goes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(11).board;
    final lock = locksOf(board).single;
    await services.settings.markIntroSeen(Intros.locks.id);
    await play(tester, 11);

    expect(lockedLabel, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('carries a key')), findsOneWidget);

    await tester.tapAndWait(blockFinder(lock.blockId));
    expect(find.bySemanticsLabel('2 of 3 stars left'), findsOneWidget);
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
    expect(find.bySemanticsLabel('2 of 3 stars left'), findsOneWidget);

    semantics.dispose();
    await tester.close();
  });

  testWidgets('hints never point at a locked block', (tester) async {
    final semantics = tester.ensureSemantics();
    await services.settings.markIntroSeen(Intros.locks.id);
    await play(tester, 11);

    await tester.tapAndWait(find.text('Hint'));

    expect(find.bySemanticsLabel(RegExp('hint: this one can go')), findsOne);
    expect(
      find.bySemanticsLabel(RegExp('locked.*hint: this one can go')),
      findsNothing,
    );

    semantics.dispose();
    await tester.close();
  });

  testWidgets('a level with two lock pairs and turning blocks clears', (
    tester,
  ) async {
    final number = firstLevelWith(
      (locks, turners) => locks == 2 && turners > 0,
    );
    final board = services.levels.byNumber(number).board;
    for (final intro in Intros.all) {
      await services.settings.markIntroSeen(intro.id);
    }
    await play(tester, number);

    for (final id in solutionOrder(board)) {
      await tester.tapAndWait(
        blockFinder(id),
        const Duration(milliseconds: 100),
      );
    }
    await tester.wait(const Duration(seconds: 2));

    expect(find.byType(LevelCompleteScreen), findsOneWidget);
    expect(services.progress.starsFor(number), 3);
    await tester.close();
  });
}
