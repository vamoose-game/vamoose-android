import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/settings_controller.dart';

import '../support/memory_store.dart';

void main() {
  test('defaults match the design', () {
    final settings = SettingsController(MemoryStore());

    expect(settings.biggerText, isFalse);
    expect(settings.sound, isTrue);
    expect(settings.vibration, isTrue);
    expect(settings.tutorialSeen, isFalse);
    expect(settings.textScale, 1);
  });

  test('bigger text scales by 1.2', () async {
    final settings = SettingsController(MemoryStore());

    await settings.setBiggerText(true);

    expect(settings.textScale, 1.2);
  });

  test('changes persist and notify', () async {
    final store = MemoryStore();
    final settings = SettingsController(store);
    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setSound(false);
    await settings.setVibration(false);
    await settings.markTutorialSeen();

    final reloaded = SettingsController(store);
    expect(reloaded.sound, isFalse);
    expect(reloaded.vibration, isFalse);
    expect(reloaded.tutorialSeen, isTrue);
    expect(notified, 3);
  });
}
