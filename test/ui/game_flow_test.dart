import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/screens/game_screen.dart';

import '../support/boards.dart';
import '../support/pumping.dart';
import '../support/test_services.dart';

Finder blockFinder(int id) => find.byKey(ValueKey('block-$id'));

Future<void> solve(WidgetTester tester, Board board) async {
  for (final id in solutionOrder(board)) {
    await tester.tapAndWait(blockFinder(id));
  }
  await tester.wait(const Duration(milliseconds: 1400));
}

Future<void> seeResults(WidgetTester tester) async {
  await tester.tapAndWait(
    find.text('See results'),
    const Duration(milliseconds: 1600),
  );
}

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  testWidgets('clearing a level without bumps earns three stars', (
    tester,
  ) async {
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(1)),
    );

    await solve(tester, services.levels.byNumber(1).board);

    expect(find.text('Board clear!'), findsOneWidget);
    expect(find.text('See results'), findsOneWidget);
    expect(services.progress.starsFor(1), 3);

    await seeResults(tester);
    expect(find.text('Level 1 done. No bumps at all.'), findsOneWidget);
    expect(services.progress.starsFor(1), 3);
    expect(services.progress.currentLevel, 2);

    await tester.close();
  });

  testWidgets('tapping a blocked block counts a bump', (tester) async {
    final board = services.levels.byNumber(2).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(2)),
    );

    await tester.tapAndWait(blockFinder(blocked.id));

    expect(find.text('Bumps 1'), findsOneWidget);
    expect(blockFinder(blocked.id), findsOneWidget);

    await tester.close();
  });

  testWidgets('bumps lower the stars on the result', (tester) async {
    final board = services.levels.byNumber(2).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(2)),
    );

    await tester.tapAndWait(blockFinder(blocked.id));
    await solve(tester, board);
    await seeResults(tester);

    expect(find.text('Level 2 done with 1 bump.'), findsOneWidget);
    expect(services.progress.starsFor(2), 2);

    await tester.close();
  });

  testWidgets('hint spends one and restart keeps the board whole', (
    tester,
  ) async {
    final board = services.levels.byNumber(30).board;
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(30)),
    );

    await tester.tapAndWait(find.text('Hint'));
    expect(services.hints.count, 2);

    await tester.tapAndWait(find.text('Hint'));
    expect(services.hints.count, 2);

    await tester.tapAndWait(blockFinder(solutionOrder(board).first));
    await tester.tapAndWait(find.text('Restart'));
    expect(find.text('${board.blockCount}'), findsOneWidget);

    await tester.close();
  });

  testWidgets('out of hints offers a video', (tester) async {
    for (var index = 0; index < 3; index++) {
      await services.hints.spend();
    }
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(5)),
    );

    expect(find.text('Hint'), findsNothing);
    await tester.tapAndWait(find.text('Get hint'));
    expect(find.text('Out of hints'), findsOneWidget);
    expect(find.text('Watch video · +1 hint'), findsOneWidget);

    await tester.tapAndWait(find.text('Not now'));
    expect(find.text('Out of hints'), findsNothing);

    await tester.close();
  });

  testWidgets('pause offers resume and restart', (tester) async {
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(3)),
    );

    await tester.tapAndWait(find.byIcon(Icons.pause_rounded));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Music on'), findsOneWidget);

    await tester.tapAndWait(find.text('Music on'));
    expect(services.settings.music, isFalse);
    expect(find.text('Music off'), findsOneWidget);

    await tester.tapAndWait(find.text('Resume'));
    expect(find.text('Paused'), findsNothing);

    await tester.close();
  });

  testWidgets('daily puzzle rewards a hint once', (tester) async {
    final today = services.daily.today;
    await tester.launch(services, home: GameScreen(mode: DailyMode(today)));

    await solve(tester, services.dailyPuzzle.boardFor(today));
    await seeResults(tester);

    expect(find.text('Board clear!'), findsOneWidget);
    expect(services.daily.isTodayCompleted, isTrue);
    expect(services.hints.count, 4);

    await tester.close();
  });

  testWidgets('keys tick and leaving blocks climb the scale', (tester) async {
    final sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
    final board = services.levels.byNumber(1).board;
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(1)),
    );

    final order = solutionOrder(board);
    for (final id in order) {
      await tester.tapAndWait(blockFinder(id));
    }
    expect(
      sounds.played
          .where((played) => played.$1 == Sound.leave)
          .map((played) => played.$2),
      [for (var index = 0; index < order.length; index++) index],
    );

    await tester.wait(const Duration(milliseconds: 1400));
    sounds.played.clear();
    await tester.tapAndWait(find.text('See results'));
    expect(sounds.played.first, (Sound.tap, 0));

    await tester.close();
  });
}
