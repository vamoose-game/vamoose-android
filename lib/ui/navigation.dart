import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/lives_controller.dart';
import 'game/game_mode.dart';
import 'game/out_of_lives.dart';
import 'screens/game_screen.dart';
import 'screens/levels_screen.dart';
import 'screens/store_screen.dart';

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

  /// Opens a level; with no lives left, offers ways to get one first.
  static Future<void> play(BuildContext context, GameMode mode) async {
    if (await _hasLife(context) && context.mounted) {
      await Navigator.of(context).push(page<void>(GameScreen(mode: mode)));
    }
  }

  static Future<void> replay(BuildContext context, GameMode mode) async {
    if (await _hasLife(context) && context.mounted) {
      await Navigator.of(context)
          .pushReplacement(page<void>(GameScreen(mode: mode)));
    }
  }

  static Future<void> store(
    BuildContext context, {
    StoreTab tab = StoreTab.items,
  }) => Navigator.of(context).push(page<void>(StoreScreen(tab: tab)));

  static Future<bool> _hasLife(BuildContext context) async {
    final lives = context.read<LivesController>();
    await lives.refresh();
    if (!lives.isEmpty) {
      return true;
    }
    return context.mounted && await OutOfLives.show(context);
  }
}
