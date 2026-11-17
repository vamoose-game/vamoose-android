import '../../core/calendar_day.dart';
import 'game_mode.dart';

class LevelResult {
  const LevelResult({
    required this.mode,
    required this.bumps,
    required this.stars,
    this.coins = 0,
  });

  final GameMode mode;
  final int bumps;
  final int stars;
  final int coins;

  String get rewardKey => switch (mode) {
    CampaignMode(:final level) => 'level.$level',
    DailyMode(:final day) => 'daily.${day.dayKey}',
  };
}
