import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/ui/screens/levels_screen.dart';
import 'package:vamoose/ui/screens/settings_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  testWidgets('levels shows the current level and its chapter', (tester) async {
    final services = buildTestServices();
    for (var level = 1; level <= 40; level++) {
      await services.progress.record(level, 3);
    }
    await tester.launch(services, home: const LevelsScreen());

    expect(find.text('Levels 31–60 · 6×6 board'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('30 / 90'), findsOneWidget);

    await tester.tapAndWait(find.text('PLAY'));
    expect(find.text('Level 41'), findsOneWidget);

    await tester.close();
  });

  testWidgets('settings toggles save right away', (tester) async {
    final services = buildTestServices();
    await tester.launch(services, home: const SettingsScreen());

    await tester.tapAndWait(find.text('Easy mode'));
    await tester.tapAndWait(find.text('Bigger text'));

    expect(services.settings.easyMode, isTrue);
    expect(services.settings.biggerText, isTrue);

    await tester.scrollUntilVisible(find.text('Vamoose · version 1.0.0'), 200);
    expect(find.text('Vamoose · version 1.0.0'), findsOneWidget);

    await tester.close();
  });

  testWidgets('reset progress asks first', (tester) async {
    final services = buildTestServices();
    await services.progress.record(1, 3);
    await tester.launch(services, home: const SettingsScreen());

    await tester.scrollUntilVisible(find.text('Reset progress'), 200);
    await tester.tapAndWait(find.text('Reset progress'));
    await tester.tapAndWait(find.text('Cancel'));
    expect(services.progress.totalStars, 3);

    await tester.tapAndWait(find.text('Reset progress'));
    await tester.tapAndWait(find.text('Reset'));
    expect(services.progress.totalStars, 0);

    await tester.close();
  });
}
