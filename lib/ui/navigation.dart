import 'package:material_ui/material_ui.dart';

import 'game/game_mode.dart';
import 'screens/game_screen.dart';
import 'screens/levels_screen.dart';

abstract final class Navigation {
  static Route<T> page<T>(Widget screen) =>
      MaterialPageRoute<T>(builder: (_) => screen);

  static void home(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  static void levels(BuildContext context) => Navigator.of(context)
      .pushAndRemoveUntil(
        page<void>(const LevelsScreen()),
        (route) => route.isFirst,
      );

  static Future<void> play(BuildContext context, GameMode mode) =>
      Navigator.of(context).push(page<void>(GameScreen(mode: mode)));

  static Future<void> replay(BuildContext context, GameMode mode) =>
      Navigator.of(context).pushReplacement(page<void>(GameScreen(mode: mode)));
}
