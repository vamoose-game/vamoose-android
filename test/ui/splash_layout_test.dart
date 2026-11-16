import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/ui/screens/splash_screen.dart';

import '../support/pumping.dart';
import '../support/test_services.dart';

void main() {
  testWidgets('splash content is centred on screen', (tester) async {
    await tester.launch(buildTestServices(), home: const SplashScreen());
    await tester.wait(const Duration(milliseconds: 1600));

    final screenCentre = tester.getCenter(find.byType(SplashScreen)).dx;
    for (final text in [
      'vamoose',
      'The calm block puzzle',
      'Setting up your puzzles…',
    ]) {
      expect(
        tester.getCenter(find.text(text)).dx,
        moreOrLessEquals(screenCentre, epsilon: 1),
        reason: text,
      );
    }

    await tester.close();
  });
}
