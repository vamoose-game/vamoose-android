import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/ui/game/block_marks.dart';
import 'package:vamoose/ui/game/turn_face.dart';
import 'package:vamoose/ui/screens/levels_screen.dart';
import 'package:vamoose/app/app_info.dart';
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

    expect(find.text('31–60 · 6×6'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('30 / 90'), findsOneWidget);

    await tester.tapAndWait(find.text('PLAY'));
    expect(find.text('Level 41'), findsOneWidget);

    await tester.close();
  });

  testWidgets('chapter cards show both mechanic badges at one size', (
    tester,
  ) async {
    await tester.launch(buildTestServices(), home: const LevelsScreen());

    expect(tester.getSize(find.byType(BlockBadge).first), const Size(22, 22));
    expect(tester.getSize(find.byType(TurnBadge).first), const Size(22, 22));

    await tester.close();
  });

  testWidgets('settings toggles save right away', (tester) async {
    final services = buildTestServices();
    await tester.launch(services, home: const SettingsScreen());

    await tester.tapAndWait(find.text('Vibration'));

    expect(services.settings.vibration, isFalse);

    await tester.tapAndWait(find.text('Music'));
    expect(services.settings.music, isFalse);
    expect(find.text('Easy mode'), findsNothing);
    expect(find.text('Bigger text'), findsNothing);

    await tester.scrollUntilVisible(find.text('Version 1.0.0'), 200);
    expect(find.text('Version 1.0.0'), findsOneWidget);

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

  testWidgets('privacy policy opens the published page', (tester) async {
    final services = buildTestServices();
    await tester.launch(services, home: const SettingsScreen());

    await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
    await tester.tapAndWait(find.text('Privacy policy'));

    expect((services.links as RecordingLinkOpener).opened, [
      Uri.parse(AppInfo.privacyPolicyUrl),
    ]);

    await tester.close();
  });
}
