import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/ui/screens/home_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  testWidgets('first launch shows how to play, then home', (tester) async {
    final services = buildTestServices();
    await tester.launch(services);

    expect(find.text('Slide. Clear. Beat the clock.'), findsOneWidget);

    await tester.wait(const Duration(milliseconds: 3000));
    expect(find.text('How to play'), findsOneWidget);

    await tester.tapAndWait(find.text('Let\'s play'));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(services.settings.tutorialSeen, isTrue);

    await tester.close();
  });

  testWidgets('returning player goes straight home', (tester) async {
    final services = buildTestServices();
    await services.settings.markTutorialSeen();
    await tester.launch(services);

    await tester.wait(const Duration(milliseconds: 3000));

    expect(find.text('How to play'), findsNothing);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);

    await tester.close();
  });

  testWidgets('play opens the current level', (tester) async {
    final services = buildTestServices();
    await services.settings.markTutorialSeen();
    await services.progress.record(1, 3);
    await tester.launch(services);
    await tester.wait(const Duration(milliseconds: 3000));

    await tester.tapAndWait(find.text('Play'));

    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('0:10'), findsOneWidget);

    await tester.close();
  });

  testWidgets('skip on how to play also goes home', (tester) async {
    final services = buildTestServices();
    await tester.launch(services);
    await tester.wait(const Duration(milliseconds: 3000));

    await tester.tapAndWait(find.text('Skip'));

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.close();
  });

  testWidgets('follows the phone text size up to 1.2', (tester) async {
    final services = buildTestServices();
    await services.settings.markTutorialSeen();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.launch(services);

    final scaler = MediaQuery.of(tester.element(find.byType(Scaffold).first))
        .textScaler;
    expect(scaler.scale(10), 12);

    await tester.close();
  });
}
