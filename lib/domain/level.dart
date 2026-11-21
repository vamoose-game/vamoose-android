import 'board.dart';

/// A board to clear and the time it gives.
typedef Puzzle = ({Board board, Duration timeLimit});

class Level {
  const Level({
    required this.number,
    required this.board,
    required this.timeLimit,
  });

  final int number;
  final Board board;
  final Duration timeLimit;

  Puzzle get puzzle => (board: board, timeLimit: timeLimit);
}
