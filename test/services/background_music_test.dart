import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/services/background_music.dart';
import 'package:vamoose/state/settings_controller.dart';

import '../support/memory_store.dart';
import '../support/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsController settings;
  late FakeMusicPlayer player;
  late BackgroundMusic music;

  setUp(() {
    settings = SettingsController(MemoryStore());
    player = FakeMusicPlayer();
    music = BackgroundMusic(player, settings);
  });

  tearDown(() => music.stop());

  test('plays when the app starts with music on', () {
    music.start();

    expect(player.calls, ['play']);
    expect(music.isPlaying, isTrue);
  });

  test('stays silent when music is off', () async {
    await settings.setMusic(false);

    music.start();

    expect(player.calls, isEmpty);
  });

  test('follows the music switch', () async {
    music.start();

    await settings.setMusic(false);
    await settings.setMusic(true);

    expect(player.calls, ['play', 'pause', 'play']);
  });

  test('pauses in the background and resumes on return', () {
    music
      ..start()
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.paused)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(player.calls, ['play', 'pause', 'play']);
  });

  test('other settings do not restart the music', () async {
    music.start();

    await settings.setVibration(false);
    await settings.setBiggerText(true);

    expect(player.calls, ['play']);
  });
}
