import '../../app/app_services.dart';
import '../../domain/level.dart';

sealed class GameMode {
  const GameMode();

  Puzzle puzzleFrom(AppServices services);

  String get title;
}

final class CampaignMode extends GameMode {
  const CampaignMode(this.level);

  final int level;

  @override
  Puzzle puzzleFrom(AppServices services) =>
      services.levels.byNumber(level).puzzle;

  @override
  String get title => 'Level $level';
}

final class DailyMode extends GameMode {
  const DailyMode(this.day);

  final DateTime day;

  @override
  Puzzle puzzleFrom(AppServices services) =>
      services.dailyPuzzle.puzzleFor(day);

  @override
  String get title => 'Daily puzzle';
}
