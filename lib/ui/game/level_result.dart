import 'game_mode.dart';

class LevelResult {
  const LevelResult({
    required this.mode,
    required this.blocks,
    required this.bumps,
    required this.time,
    required this.stars,
    this.earnedHint = false,
  });

  final GameMode mode;
  final int blocks;
  final int bumps;
  final Duration time;
  final int stars;
  final bool earnedHint;
}
