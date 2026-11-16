import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/settings_controller.dart';

import '../support/memory_store.dart';

void main() {
  test('defaults match the design', () {
    final settings = SettingsController(MemoryStore());

    expect(settings.sound, isTrue);
    expect(settings.music, isTrue);
    expect(settings.vibration, isTrue);
    expect(settings.tutorialSeen, isFalse);
  });

  test('changes persist and notify', () async {
    final store = MemoryStore();
    final settings = SettingsController(store);
    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setSound(false);
    await settings.setMusic(false);
    await settings.setVibration(false);
    await settings.markTutorialSeen();

    final reloaded = SettingsController(store);
    expect(reloaded.sound, isFalse);
    expect(reloaded.music, isFalse);
    expect(reloaded.vibration, isFalse);
    expect(reloaded.tutorialSeen, isTrue);
    expect(notified, 4);
  });
}
