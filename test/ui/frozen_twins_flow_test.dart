import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/block.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/ui/game/block_marks.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/ice_face.dart';
import 'package:vamoose/ui/game/intros.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/theme/motion.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

final Duration landing = Motion.flyInDelay + Motion.blockLeaves;

Finder blockFinder(int id) => find.byKey(ValueKey('block-$id'));

void main() {
  late AppServices services;
  late RecordingSounds sounds;

  setUp(() {
    sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
  });

  Future<void> play(WidgetTester tester, int level) async {
    await tester.launch(services, home: GameScreen(mode: CampaignMode(level)));
    await tester.wait(landing);
  }

  Future<void> seeIntrosBut([Intro? but]) async {
    for (final intro in Intros.all) {
      if (intro != but) {
        await services.settings.markIntroSeen(intro.id);
      }
    }
  }

  /// Plays blocks that can go, those [prefer] picks first, never [avoid],
  /// until [done]; returns the board as it then stands.
  Future<Board> playUntil(
    WidgetTester tester,
    Board board, {
    required bool Function(Board board) done,
    bool Function(Block block)? prefer,
    Set<int> avoid = const {},
  }) async {
    var current = board;
    while (!done(current)) {
      final free = current.movableBlocks
          .where((block) => !avoid.contains(block.id))
          .toList();
      final next = free.where(prefer ?? (_) => false).firstOrNull ?? free.first;
      await tester.tapAndWait(blockFinder(next.id), const Duration(seconds: 1));
      current = current.without(next.id);
    }
    return current;
  }

  testWidgets('the frozen intro shows once when frozen blocks appear', (
    tester,
  ) async {
    await seeIntrosBut(Intros.ice);
    await play(tester, 91);

    expect(find.text('Frozen blocks'), findsOneWidget);
    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(services.settings.hasSeenIntro(Intros.ice.id), isTrue);
    await tester.close();

    await play(tester, 92);
    expect(find.text('Frozen blocks'), findsNothing);
    await tester.close();
  });

  testWidgets('a frozen block bumps until a block next to it leaves', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(91).board;
    final frozen = board.blocks.singleWhere((block) => block.isFrozen);
    await seeIntrosBut();
    await play(tester, 91);

    final ice = find.descendant(
      of: blockFinder(frozen.id),
      matching: find.byType(IceFace),
    );
    expect(ice, findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('frozen: a block next')),
      findsOneWidget,
    );

    await tester.tapAndWait(blockFinder(frozen.id));
    expect(find.bySemanticsLabel('2 of 3 stars left'), findsOneWidget);
    expect(ice, findsOneWidget);

    final neighbours = board.neighboursOf(frozen);
    final thawed = await playUntil(
      tester,
      board,
      done: (current) => !current.blockById(frozen.id).isFrozen,
      prefer: (block) => neighbours.contains(block.id),
      avoid: {frozen.id},
    );

    expect(ice, findsNothing);
    expect(find.bySemanticsLabel(RegExp('frozen')), findsNothing);
    expect(sounds.played.where((played) => played.$1 == Sound.shatter), [
      (Sound.shatter, 0),
    ]);
    if (thawed.canLeave(thawed.blockById(frozen.id))) {
      await tester.tapAndWait(
        blockFinder(frozen.id),
        const Duration(seconds: 1),
      );
      expect(blockFinder(frozen.id), findsNothing);
    }
    semantics.dispose();
    await tester.close();
  });

  testWidgets('thick ice shows its intro once, at level 201', (tester) async {
    await seeIntrosBut(Intros.thickIce);
    await play(tester, 201);

    expect(find.text('Thick ice'), findsOneWidget);
    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    expect(services.settings.hasSeenIntro(Intros.thickIce.id), isTrue);
    await tester.close();

    await play(tester, 202);
    expect(find.text('Thick ice'), findsNothing);
    await tester.close();
  });

  testWidgets('the thickest ice has no number and cracks more with each '
      'block that leaves next to it, then shatters', (tester) async {
    final number = [for (var number = 281; number <= 360; number++) number]
        .firstWhere(
          (number) => services.levels
              .byNumber(number)
              .board
              .blocks
              .any((block) => block.ice == 3),
        );
    final board = services.levels.byNumber(number).board;
    final thick = board.blocks.firstWhere((block) => block.ice == 3);
    await seeIntrosBut();
    await play(tester, number);

    final ice = find.descendant(
      of: blockFinder(thick.id),
      matching: find.byType(IceFace),
    );
    IceFace face() => tester.widget<IceFace>(ice);
    expect(face().ice, 3);
    expect(face().cracks, 0);
    expect(
      find.descendant(of: blockFinder(thick.id), matching: find.byType(Text)),
      findsNothing,
    );

    final neighbours = board.neighboursOf(thick);
    var current = board;
    final seen = <int>{};
    while (current.blockById(thick.id).isFrozen) {
      final before = current.blockById(thick.id).ice;
      current = await playUntil(
        tester,
        current,
        done: (now) => now.blockById(thick.id).ice < before,
        prefer: (block) => neighbours.contains(block.id),
        avoid: {thick.id},
      );
      final now = current.blockById(thick.id);
      if (now.isFrozen) {
        expect(face().ice, now.ice);
        expect(face().cracks, now.cracks);
        seen.add(now.cracks);
      }
    }

    expect(seen, contains(1), reason: 'the first crack showed');
    expect(ice, findsNothing);
    final cracks = sounds.played.where((played) => played.$1 == Sound.crack);
    expect(cracks, hasLength(seen.length));
    expect(
      sounds.played.where((played) => played.$1 == Sound.shatter),
      isNotEmpty,
    );
    await tester.close();
  });

  testWidgets('twins show their intro, bump together and leave together', (
    tester,
  ) async {
    final board = services.levels.byNumber(131).board;
    final pair = board.twins.single;
    final first = board.blockById(pair.first);
    final second = board.blockById(pair.second);
    await seeIntrosBut(Intros.twins);
    await play(tester, 131);

    expect(find.text('Twin blocks'), findsOneWidget);
    expect(find.text('One pair'), findsOneWidget);
    await tester.tapAndWait(find.text('Got it'), const Duration(seconds: 1));
    await tester.wait(landing);
    expect(services.settings.hasSeenIntro(Intros.twins.id), isTrue);

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('twin: leaves with the other gold twin')),
      findsNWidgets(2),
    );
    var stars = 3;
    if (!board.canLeave(first)) {
      await tester.tapAndWait(blockFinder(first.id));
      stars--;
      expect(find.bySemanticsLabel('$stars of 3 stars left'), findsOneWidget);
      expect(blockFinder(first.id), findsOneWidget);
      expect(blockFinder(second.id), findsOneWidget);
    }

    final ready = await playUntil(
      tester,
      board,
      done: (current) => current.canLeave(current.blockById(first.id)),
      prefer: (block) =>
          board.waitsOn(first).contains(block.id) ||
          board.waitsOn(second).contains(block.id),
      avoid: {first.id, second.id},
    );
    expect(ready.contains(second.id), isTrue);

    await tester.tapAndWait(blockFinder(second.id), const Duration(seconds: 1));
    expect(blockFinder(first.id), findsNothing);
    expect(blockFinder(second.id), findsNothing);
    expect(find.bySemanticsLabel('$stars of 3 stars left'), findsOneWidget);
    semantics.dispose();
    await tester.close();
  });

  testWidgets('each pair of twins wears its own color', (tester) async {
    final number = [
      for (var level = 1; level <= services.levels.count; level++)
        if (services.levels.byNumber(level).board.twins.length >= 2) level,
    ].first;
    await seeIntrosBut();
    await play(tester, number);

    final colors = {
      for (final badge in tester.widgetList<BlockBadge>(
        find.byWidgetPredicate(
          (widget) => widget is BlockBadge && widget.icon == BadgeIcon.link,
        ),
      ))
        badge.color,
    };
    expect(
      colors,
      hasLength(services.levels.byNumber(number).board.twins.length),
    );
    await tester.close();
  });
}
