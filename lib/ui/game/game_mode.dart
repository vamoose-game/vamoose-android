import '../../app/app_services.dart';
import '../../domain/board.dart';
import '../../domain/chapters.dart';

sealed class GameMode {
  const GameMode();

  Board boardFrom(AppServices services);

  String get title;

  String? get chapter;
}

final class CampaignMode extends GameMode {
  const CampaignMode(this.level);

  final int level;

  @override
  Board boardFrom(AppServices services) =>
      services.levels.byNumber(level).board;

  @override
  String get title => 'Level $level';

  @override
  String get chapter => Chapters.of(level).name;
}

final class DailyMode extends GameMode {
  const DailyMode(this.day);

  final DateTime day;

  @override
  Board boardFrom(AppServices services) => services.dailyPuzzle.boardFor(day);

  @override
  String get title => 'Daily puzzle';

  @override
  String? get chapter => null;
}
