import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/ui/game/board_view.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/level_complete_screen.dart';
import 'package:vamoose/ui/theme/motion.dart';
import 'package:vamoose/ui/widgets/block_face.dart';

import '../support/boards.dart';
import '../support/pumping.dart';
import '../support/test_services.dart';

final Duration landing = Motion.flyInDelay + Motion.blockLeaves;

Finder blockFinder(int id) => find.byKey(ValueKey('block-$id'));

Future<void> startGame(
  WidgetTester tester,
  AppServices services,
  GameMode mode,
) async {
  await tester.launch(services, home: GameScreen(mode: mode));
  await tester.wait(landing);
}

Future<void> solve(WidgetTester tester, Board board) async {
  for (final id in solutionOrder(board)) {
    await tester.tapAndWait(blockFinder(id));
  }
  await tester.wait(const Duration(milliseconds: 1400));
}

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  testWidgets('clearing a level without bumps earns three stars', (
    tester,
  ) async {
    await startGame(tester, services, const CampaignMode(1));

    await solve(tester, services.levels.byNumber(1).board);

    expect(find.text('Level 1 done. No bumps at all.'), findsOneWidget);
    expect(services.progress.starsFor(1), 3);
    expect(services.progress.currentLevel, 2);

    await tester.close();
  });

  testWidgets('blocks fly in from the side their arrow points to', (
    tester,
  ) async {
    final block = services.levels.byNumber(2).board.blocks.first;
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(2)),
    );
    final face = find.descendant(
      of: blockFinder(block.id),
      matching: find.byType(BlockFace),
    );
    final start = tester.getCenter(face);

    await tester.wait(landing);
    final away = start - tester.getCenter(face);

    expect(
      away.distance,
      greaterThan(tester.getSize(find.byType(BoardView)).width),
    );
    expect(away.dx.sign, block.direction.columnStep);
    expect(away.dy.sign, block.direction.rowStep);

    await tester.close();
  });

  testWidgets('blocks can be tapped once they have landed', (tester) async {
    final board = services.levels.byNumber(1).board;
    final free = board.blocks.firstWhere(board.canLeave);
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(1)),
    );

    await tester.tap(blockFinder(free.id), warnIfMissed: false);
    await tester.pump();
    expect(blockFinder(free.id), findsOneWidget);

    await tester.wait(landing);
    await tester.tap(blockFinder(free.id));
    await tester.pump();
    expect(blockFinder(free.id), findsNothing);

    await tester.close();
  });

  testWidgets('results open by themselves as the last block leaves', (
    tester,
  ) async {
    final order = solutionOrder(services.levels.byNumber(1).board);
    await startGame(tester, services, const CampaignMode(1));

    for (final id in order.take(order.length - 1)) {
      await tester.tapAndWait(blockFinder(id));
    }
    await tester.tap(blockFinder(order.last));
    await tester.wait(const Duration(milliseconds: 500));
    expect(find.byType(LevelCompleteScreen), findsNothing);
    expect(find.text('See results'), findsNothing);

    await tester.wait(const Duration(seconds: 1));
    expect(find.byType(LevelCompleteScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);

    await tester.close();
  });

  testWidgets('restart right after the last block stays on the board', (
    tester,
  ) async {
    final order = solutionOrder(services.levels.byNumber(1).board);
    await startGame(tester, services, const CampaignMode(1));

    for (final id in order.take(order.length - 1)) {
      await tester.tapAndWait(blockFinder(id));
    }
    await tester.tap(blockFinder(order.last));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAndWait(find.text('Restart'), const Duration(seconds: 2));

    expect(find.byType(LevelCompleteScreen), findsNothing);
    expect(blockFinder(order.first), findsOneWidget);

    await tester.close();
  });

  testWidgets('tapping a blocked block counts a bump', (tester) async {
    final board = services.levels.byNumber(2).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(2));

    await tester.tapAndWait(blockFinder(blocked.id));

    expect(find.text('Bumps 1'), findsOneWidget);
    expect(blockFinder(blocked.id), findsOneWidget);

    await tester.close();
  });

  testWidgets('bumps lower the stars on the result', (tester) async {
    final board = services.levels.byNumber(2).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(2));

    await tester.tapAndWait(blockFinder(blocked.id));
    await solve(tester, board);

    expect(find.text('Level 2 done with 1 bump.'), findsOneWidget);
    expect(services.progress.starsFor(2), 2);

    await tester.close();
  });

  testWidgets('hint spends one and restart keeps the board whole', (
    tester,
  ) async {
    final board = services.levels.byNumber(30).board;
    await startGame(tester, services, const CampaignMode(30));

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
    await startGame(tester, services, DailyMode(today));

    await solve(tester, services.dailyPuzzle.boardFor(today));

    expect(find.text('Board clear!'), findsOneWidget);
    expect(services.daily.isTodayCompleted, isTrue);
    expect(services.hints.count, 4);

    await tester.close();
  });

  testWidgets('keys tick and leaving blocks climb the scale', (tester) async {
    final sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
    final board = services.levels.byNumber(1).board;
    await startGame(tester, services, const CampaignMode(1));

    await tester.tapAndWait(find.text('Restart'), const Duration(seconds: 1));
    expect(sounds.played.first, (Sound.tap, 0));
    sounds.played.clear();

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

    await tester.close();
  });

  testWidgets('fast taps let every leaving block finish its slide', (
    tester,
  ) async {
    final order = solutionOrder(services.levels.byNumber(330).board);
    await startGame(tester, services, const CampaignMode(330));

    await tester.tap(blockFinder(order[0]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final first = leavingOpacities(tester).single;
    await tester.tap(blockFinder(order[1]));
    await tester.pump(const Duration(milliseconds: 16));

    expect(first, lessThan(0.9));
    expect(leavingOpacities(tester), [lessThan(first), 1]);

    await tester.close();
  });

  testWidgets('a sliding block does not repaint the other blocks', (
    tester,
  ) async {
    final board = services.levels.byNumber(330).board;
    await startGame(tester, services, const CampaignMode(330));
    var painted = 0;
    debugOnProfilePaint = (renderObject) {
      if (renderObject is RenderCustomPaint) {
        painted++;
      }
    };
    addTearDown(() => debugOnProfilePaint = null);

    await tester.tap(blockFinder(board.blocks.firstWhere(board.canLeave).id));
    await tester.pump();
    painted = 0;
    await tester.wait(const Duration(milliseconds: 500));

    expect(painted, 0);

    await tester.close();
  });
}

List<double> leavingOpacities(WidgetTester tester) => [
  for (final opacity in tester.widgetList<Opacity>(
    find.descendant(
      of: find.descendant(
        of: find.byType(BoardView),
        matching: find.byType(IgnorePointer),
      ),
      matching: find.byType(Opacity),
    ),
  ))
    opacity.opacity,
];
