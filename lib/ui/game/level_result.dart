import '../../core/calendar_day.dart';
import 'game_mode.dart';

class LevelResult {
  const LevelResult({
    required this.mode,
    required this.bumps,
    required this.stars,
    this.coins = 0,
    this.time = Duration.zero,
  });

  final GameMode mode;
  final int bumps;
  final int stars;
  final int coins;

  /// How long the clear took on the clock.
  final Duration time;

  String get rewardKey => switch (mode) {
    CampaignMode(:final level) => 'level.$level',
    DailyMode(:final day) => 'daily.${day.dayKey}',
  };
}
