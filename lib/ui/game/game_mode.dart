import '../../app/app_services.dart';
import '../../domain/board.dart';
import '../../domain/chapters.dart';
import '../../domain/daily_puzzle.dart';

sealed class GameMode {
  const GameMode();

  Board boardFrom(AppServices services);

  String get label;

  String get title;
}

final class CampaignMode extends GameMode {
  const CampaignMode(this.level);

  final int level;

  @override
  Board boardFrom(AppServices services) =>
      services.levels.byNumber(level).board;

  @override
  String get label {
    final chapter = Chapters.of(level);
    return '${chapter.name.toUpperCase()} · ${chapter.boardSize}×${chapter.boardSize}';
  }

  @override
  String get title => 'Level $level';
}

final class DailyMode extends GameMode {
  const DailyMode(this.day);

  final DateTime day;

  @override
  Board boardFrom(AppServices services) => services.dailyPuzzle.boardFor(day);

  @override
  String get label {
    final size = DailyPuzzle.spec.size;
    return '${DailyPuzzle.difficulty.toUpperCase()} · $size×$size';
  }

  @override
  String get title => 'Daily puzzle';
}
