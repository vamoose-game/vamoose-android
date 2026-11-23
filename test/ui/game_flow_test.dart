import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/app/app_services.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/economy.dart';
import 'package:vamoose/services/sound_effects.dart';
import 'package:vamoose/ui/formatting.dart';
import 'package:vamoose/ui/game/board_view.dart';
import 'package:vamoose/ui/game/game_hud.dart';
import 'package:vamoose/ui/game/game_mode.dart';
import 'package:vamoose/ui/game/intros.dart';
import 'package:vamoose/ui/screens/game_screen.dart';
import 'package:vamoose/ui/screens/home_screen.dart';
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

Future<void> seeAllIntros(AppServices services) async {
  for (final intro in Intros.all) {
    await services.settings.markIntroSeen(intro.id);
  }
}

Future<void> runOutOfTime(WidgetTester tester, Duration limit) =>
    tester.wait(limit + const Duration(seconds: 2));

/// The extra-time key's label on a level with [limit].
String extraTimeKey(Duration limit) =>
    '+${Economy.extraTimeFor(limit).inSeconds}s';

/// Plays on until about a fifth of a second is left on the clock.
Future<void> waitForLastMoment(WidgetTester tester) async {
  for (var frames = 0; frames < 2000; frames++) {
    if (find.text('0:01').evaluate().isNotEmpty) {
      break;
    }
    await tester.pump(frame);
  }
  await tester.wait(const Duration(milliseconds: 800));
}

/// Opens the next level from Home, so leaving it goes back somewhere.
Future<void> playFromHome(WidgetTester tester, AppServices services) async {
  await services.settings.markTutorialSeen();
  await tester.launch(services, home: const HomeScreen());
  await tester.tapAndWait(find.text('Play'));
}

void main() {
  late AppServices services;

  setUp(() => services = buildTestServices());

  testWidgets('clearing a level without bumps earns three stars', (
    tester,
  ) async {
    await startGame(tester, services, const CampaignMode(1));

    await solve(tester, services.levels.byNumber(1).board);

    expect(find.text('Perfect!'), findsOneWidget);
    expect(services.progress.starsFor(1), 3);
    expect(services.progress.currentLevel, 2);
    expect(services.coins.balance, 125);
    expect(services.lives.isFull, isTrue);

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

  testWidgets('the clock waits for the blocks to land', (tester) async {
    await tester.launch(
      services,
      home: const GameScreen(mode: CampaignMode(1)),
    );
    expect(find.text('0:12'), findsOneWidget);

    await tester.wait(landing + const Duration(milliseconds: 850));
    expect(find.text('0:12'), findsOneWidget);

    await tester.wait(const Duration(milliseconds: 250));
    expect(find.text('0:11'), findsOneWidget);

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

    await tester.wait(const Duration(seconds: 1));
    expect(find.byType(LevelCompleteScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);

    await tester.close();
  });

  testWidgets('restart right after the last block stays on the board', (
    tester,
  ) async {
    final limit = services.levels.byNumber(1).timeLimit;
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

    await tester.wait(const Duration(milliseconds: 500));
    expect(
      find.text(Formatting.clock(limit - const Duration(seconds: 1))),
      findsOneWidget,
    );

    await tester.close();
  });

  testWidgets('a bump costs a star', (tester) async {
    final semantics = tester.ensureSemantics();
    final board = services.levels.byNumber(4).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(4));

    await tester.tapAndWait(blockFinder(blocked.id));

    expect(find.bySemanticsLabel('2 of 3 stars left'), findsOneWidget);
    expect(blockFinder(blocked.id), findsOneWidget);

    semantics.dispose();
    await tester.close();
  });

  testWidgets('the third bump runs out of stars and costs a life', (
    tester,
  ) async {
    final limit = services.levels.byNumber(4).timeLimit;
    final board = services.levels.byNumber(4).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(4));

    for (var bump = 0; bump < 3; bump++) {
      await tester.tapAndWait(blockFinder(blocked.id));
    }
    await tester.wait(const Duration(seconds: 1));

    expect(find.text('Out of stars'), findsOneWidget);
    expect(find.text('4 lives left'), findsOneWidget);
    expect(services.lives.count, 4);
    expect(services.progress.starsFor(4), 0);

    await tester.tapAndWait(find.text('Try again'), const Duration(seconds: 1));
    expect(find.text('Out of stars'), findsNothing);
    expect(find.text(Formatting.clock(limit)), findsOneWidget);
    expect(services.lives.count, 4);

    await tester.wait(const Duration(milliseconds: 1500));
    expect(
      find.text(Formatting.clock(limit - const Duration(seconds: 1))),
      findsOneWidget,
    );

    await tester.close();
  });

  testWidgets('restart waits for the fail sheet', (tester) async {
    for (var life = 1; life < Economy.maxLives; life++) {
      await services.lives.spend();
    }
    final board = services.levels.byNumber(4).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(4));

    await tester.tapAndWait(blockFinder(blocked.id));
    await tester.tapAndWait(blockFinder(blocked.id));
    await tester.tapAndWait(blockFinder(blocked.id), frame);
    await tester.tapAndWait(find.text('Restart'), const Duration(seconds: 1));

    expect(find.text('Out of stars'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(services.lives.count, 0);

    await tester.close();
  });

  testWidgets('running out of time costs a life', (tester) async {
    final limit = services.levels.byNumber(1).timeLimit;
    await startGame(tester, services, const CampaignMode(1));

    await runOutOfTime(tester, limit);

    expect(find.text('Time’s up'), findsOneWidget);
    expect(services.lives.count, 4);

    await tester.tapAndWait(find.text('Levels'), const Duration(seconds: 1));
    expect(find.byType(GameScreen), findsNothing);

    await tester.close();
  });

  testWidgets('with no lives left a fail offers a life by video', (
    tester,
  ) async {
    await services.lives.spend();
    await services.lives.spend();
    await services.lives.spend();
    await services.lives.spend();
    final limit = services.levels.byNumber(1).timeLimit;
    await startGame(tester, services, const CampaignMode(1));

    await runOutOfTime(tester, limit);
    expect(find.text('Next life in 20:00'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    await tester.tapAndWait(find.text('+1 life'));
    expect(services.lives.count, 1);

    await tester.tapAndWait(find.text('Try again'), const Duration(seconds: 1));
    expect(find.text('Time’s up'), findsNothing);

    await tester.close();
  });

  testWidgets('extra time adds a few seconds before the first move', (
    tester,
  ) async {
    final limit = services.levels.byNumber(1).timeLimit;
    await startGame(tester, services, const CampaignMode(1));

    final clock = tester.state(find.byType(TimerPill));

    await tester.tapAndWait(find.text(extraTimeKey(limit)));

    expect(
      find.text(Formatting.clock(limit + Economy.extraTimeFor(limit))),
      findsOneWidget,
    );
    expect(services.extraTime.count, 0);
    expect(find.text(extraTimeKey(limit)), findsNothing);
    expect(tester.state(find.byType(TimerPill)), same(clock));

    await tester.close();
  });

  testWidgets('extra time is gone after the first move', (tester) async {
    final level = services.levels.byNumber(1);
    await startGame(tester, services, const CampaignMode(1));
    expect(find.text(extraTimeKey(level.timeLimit)), findsOneWidget);

    await tester.tapAndWait(blockFinder(level.board.movableBlocks.first.id));

    expect(find.text(extraTimeKey(level.timeLimit)), findsNothing);
    expect(services.extraTime.count, 1);

    await tester.close();
  });

  testWidgets('with no lives a level asks for one before it starts', (
    tester,
  ) async {
    for (var life = 0; life < 5; life++) {
      await services.lives.spend();
    }
    await services.settings.markTutorialSeen();
    await tester.launch(services, home: const HomeScreen());

    await tester.tapAndWait(find.text('Play'));
    expect(find.text('Out of lives'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);

    await tester.tapAndWait(find.text('+1 life'));
    expect(find.text('1 life ready'), findsOneWidget);

    await tester.tapAndWait(find.text('Play').last);
    expect(find.byType(GameScreen), findsOneWidget);

    await tester.close();
  });

  testWidgets('replays only pay for better stars', (tester) async {
    final board = services.levels.byNumber(4).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(4));
    await tester.tapAndWait(blockFinder(blocked.id));
    await solve(tester, board);
    expect(services.coins.balance, 120);
    await tester.close();

    for (final expected in [125, 125]) {
      await startGame(tester, services, const CampaignMode(4));
      await solve(tester, board);
      expect(services.coins.balance, expected);
      await tester.close();
    }
  });

  testWidgets('bumps lower the stars on the result', (tester) async {
    final board = services.levels.byNumber(4).board;
    final blocked = board.blocks.firstWhere((block) => !board.canLeave(block));
    await startGame(tester, services, const CampaignMode(4));

    await tester.tapAndWait(blockFinder(blocked.id));
    await solve(tester, board);

    expect(find.text('Great!'), findsOneWidget);
    expect(services.progress.starsFor(4), 2);

    await tester.close();
  });

  testWidgets('hint spends one and restart keeps the board whole', (
    tester,
  ) async {
    final board = services.levels.byNumber(30).board;
    await seeAllIntros(services);
    await startGame(tester, services, const CampaignMode(30));

    await tester.tapAndWait(find.text('Hint'));
    expect(services.hints.count, 2);

    await tester.tapAndWait(find.text('Hint'));
    expect(services.hints.count, 2);

    final first = solutionOrder(board).first;
    await tester.tapAndWait(blockFinder(first));
    expect(blockFinder(first), findsNothing);
    await tester.tapAndWait(find.text('Restart'));
    expect(blockFinder(first), findsOneWidget);

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
    expect(find.text('Need a hint?'), findsOneWidget);
    expect(find.text('Free with a video'), findsOneWidget);

    await tester.tapAndWait(find.text('Not now'));
    expect(find.text('Need a hint?'), findsNothing);

    await tester.close();
  });

  testWidgets('pause holds the clock and offers resume', (tester) async {
    await startGame(tester, services, const CampaignMode(3));

    await tester.tapAndWait(find.byIcon(Icons.pause_rounded));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Level 3 · 0:12'), findsOneWidget);

    await tester.tapAndWait(find.text('Music'));
    expect(services.settings.music, isFalse);

    await tester.wait(const Duration(seconds: 20));
    await tester.tapAndWait(find.text('Resume'));
    expect(find.text('Paused'), findsNothing);
    expect(find.text('0:12'), findsOneWidget);

    await tester.close();
  });

  testWidgets('the clock holds while the app is in the background', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await startGame(tester, services, const CampaignMode(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.wait(const Duration(seconds: 30));
    expect(services.lives.isFull, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.wait(const Duration(milliseconds: 1500));
    expect(find.text('Time’s up'), findsNothing);
    expect(find.text('0:11'), findsOneWidget);

    await tester.close();
  });

  testWidgets('the hint sheet holds the clock', (tester) async {
    while (services.hints.count > 0) {
      await services.hints.spend();
    }
    await startGame(tester, services, const CampaignMode(1));
    await tester.wait(const Duration(milliseconds: 1250));
    expect(find.text('0:11'), findsOneWidget);

    await tester.tapAndWait(find.text('Get hint'));
    expect(find.text('Need a hint?'), findsOneWidget);

    await tester.wait(const Duration(seconds: 20));
    await tester.tapAndWait(
      find.text('Not now'),
      const Duration(milliseconds: 300),
    );
    expect(find.text('0:11'), findsOneWidget);

    await tester.wait(const Duration(seconds: 1));
    expect(find.text('Need a hint?'), findsNothing);
    expect(find.text('0:10'), findsOneWidget);

    await tester.close();
  });

  testWidgets('leaving from pause as the clock runs out costs no life', (
    tester,
  ) async {
    await playFromHome(tester, services);
    await waitForLastMoment(tester);

    await tester.tapAndWait(find.byIcon(Icons.pause_rounded));
    await tester.tapAndWait(find.text('Levels'), const Duration(seconds: 2));

    expect(find.byType(GameScreen), findsNothing);
    expect(services.lives.count, Economy.maxLives);

    await tester.close();
  });

  testWidgets('going back as the clock runs out costs no life', (tester) async {
    await playFromHome(tester, services);
    await waitForLastMoment(tester);

    await tester.tapAndWait(
      find.byIcon(Icons.chevron_left_rounded),
      const Duration(seconds: 2),
    );

    expect(find.byType(GameScreen), findsNothing);
    expect(services.lives.count, Economy.maxLives);

    await tester.close();
  });

  testWidgets('daily puzzle rewards coins once', (tester) async {
    final today = services.daily.today;
    await startGame(tester, services, DailyMode(today));

    await solve(tester, services.dailyPuzzle.puzzleFor(today).board);

    expect(find.text('Perfect!'), findsOneWidget);
    expect(services.daily.isTodayCompleted, isTrue);
    expect(services.coins.balance, 150);
    expect(services.hints.count, 3);

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

  testWidgets('the last seconds tick', (tester) async {
    final sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
    final limit = services.levels.byNumber(1).timeLimit;
    await startGame(tester, services, const CampaignMode(1));

    await runOutOfTime(tester, limit);

    expect(
      sounds.played.where((played) => played.$1 == Sound.tick),
      hasLength(3),
    );
    expect(
      sounds.played.where((played) => played.$1 == Sound.fail),
      hasLength(1),
    );

    await tester.close();
  });

  testWidgets('the ticks start over after extra time', (tester) async {
    final sounds = RecordingSounds();
    services = buildTestServices(sounds: sounds);
    final limit = services.levels.byNumber(1).timeLimit;
    await startGame(tester, services, const CampaignMode(1));

    await tester.wait(limit - const Duration(milliseconds: 2500));
    expect(find.text('0:03'), findsOneWidget);
    await tester.tapAndWait(find.text(extraTimeKey(limit)));
    await runOutOfTime(tester, limit);

    expect(
      sounds.played.where((played) => played.$1 == Sound.tick),
      hasLength(4),
    );

    await tester.close();
  });

  testWidgets('fast taps let every leaving block finish its slide', (
    tester,
  ) async {
    final order = solutionOrder(services.levels.byNumber(330).board);
    await seeAllIntros(services);
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
    final number = [
      for (var level = 300; level <= services.levels.count; level++)
        if (!services.levels.byNumber(level).board.hasTurningBlocks) level,
    ].first;
    final board = services.levels.byNumber(number).board;
    await seeAllIntros(services);
    await startGame(tester, services, CampaignMode(number));
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
