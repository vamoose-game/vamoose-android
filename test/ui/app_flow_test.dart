import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  testWidgets('first launch shows how to play, then home', (tester) async {
    final services = buildTestServices();
    await tester.launch(services);

    expect(find.text('Setting up your puzzles…'), findsOneWidget);

    await tester.wait(const Duration(milliseconds: 1800));
    expect(find.text('How to play'), findsOneWidget);

    await tester.tapAndWait(find.text('Let\'s play'));
    expect(find.text('Slide every block off the board.'), findsOneWidget);
    expect(services.settings.tutorialSeen, isTrue);

    await tester.close();
  });

  testWidgets('returning player goes straight home', (tester) async {
    final services = buildTestServices();
    await services.settings.markTutorialSeen();
    await tester.launch(services);

    await tester.wait(const Duration(milliseconds: 1800));

    expect(find.text('How to play'), findsNothing);
    expect(find.text('3 hints'), findsOneWidget);
    expect(find.text('Level 1 · Warm-up'), findsOneWidget);

    await tester.close();
  });

  testWidgets('play opens the current level', (tester) async {
    final services = buildTestServices();
    await services.settings.markTutorialSeen();
    await services.progress.record(1, 3);
    await tester.launch(services);
    await tester.wait(const Duration(milliseconds: 1800));

    await tester.tapAndWait(find.text('Play'));

    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('WARM-UP · 5×5'), findsOneWidget);

    await tester.close();
  });

  testWidgets('skip on how to play also goes home', (tester) async {
    final services = buildTestServices();
    await tester.launch(services);
    await tester.wait(const Duration(milliseconds: 1800));

    await tester.tapAndWait(find.text('Skip'));

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.close();
  });
}
