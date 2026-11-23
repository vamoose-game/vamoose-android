import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/countdowns.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/ui/game/countdown_face.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/intros.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/theme/motion.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

final Duration landing = Motion.flyInDelay + Motion.blockLeaves;

Finder blockFinder(int id) => find.byKey(ValueKey('block-$id'));

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  Future<void> play(WidgetTester tester, int level) async {
    await tester.launch(services, home: GameScreen(mode: CampaignMode(level)));
    await tester.wait(landing);
  }

  Future<void> seeEarlierIntros() async {
    for (final intro in Intros.all) {
      if (intro != Intros.countdowns) {
        await services.settings.markIntroSeen(intro.id);
      }
    }
  }

  testWidgets('the countdown intro shows once when countdown blocks appear', (
    tester,
  ) async {
    await seeEarlierIntros();
    await play(tester, 171);

    expect(find.text('Countdown blocks'), findsOneWidget);
    expect(find.text('Moves left'), findsOneWidget);
    expect(find.text('Last move'), findsOneWidget);

    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(find.text('Countdown blocks'), findsNothing);
    expect(services.settings.hasSeenIntro(Intros.countdowns.id), isTrue);
    await tester.close();

    await play(tester, 174);
    expect(find.text('Countdown blocks'), findsNothing);
    await tester.close();
  });

  testWidgets('the hint clears the way of the countdown block', (tester) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(171).board;
    final countdown = board.blocks.singleWhere((block) => block.hasCountdown);
    final hinted = Countdowns.nextMove(board)!;
    await seeEarlierIntros();
    await services.settings.markIntroSeen(Intros.countdowns.id);
    await play(tester, 171);

    await tester.tapAndWait(find.text('Hint'));

    expect(board.waitsOn(countdown), contains(hinted.id));
    expect(
      find.descendant(
        of: blockFinder(hinted.id),
        matching: find.bySemanticsLabel(RegExp('hint: this one can go')),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.close();
  });

  testWidgets('the badge counts down, and running out costs a star', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
    final board = services.levels.byNumber(171).board;
    final countdown = board.blocks.singleWhere((block) => block.hasCountdown);
    final count = countdown.count!;
    await seeEarlierIntros();
    await services.settings.markIntroSeen(Intros.countdowns.id);
    await play(tester, 171);

    Finder badge(int number) => find.descendant(
      of: blockFinder(countdown.id),
      matching: find.widgetWithText(CountdownBadge, '$number'),
    );
    expect(badge(count), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('countdown $count: must leave within $count moves'),
      ),
      findsOneWidget,
    );

    var current = board;
    for (var move = 1; move <= count; move++) {
      final other = current.movableBlocks.firstWhere(
        (block) => block.id != countdown.id,
      );
      await tester.tapAndWait(
        blockFinder(other.id),
        const Duration(seconds: 1),
      );
      current = current.without(other.id);
      if (move < count) {
        expect(badge(count - move), findsOneWidget, reason: 'move $move');
      }
      if (move == count - 1) {
        expect(
          find.bySemanticsLabel(RegExp('countdown 1: take it out now')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('3 of 3 stars left'), findsOneWidget);
      }
    }

    expect(find.bySemanticsLabel(RegExp('countdown')), findsNothing);
    expect(find.byType(CountdownBadge), findsNothing);
    expect(find.bySemanticsLabel('2 of 3 stars left'), findsOneWidget);
    expect(
      sounds.played.where((played) => played.$1 == Sound.bump),
      hasLength(1),
    );
    semantics.dispose();
    await tester.close();
  });
}
