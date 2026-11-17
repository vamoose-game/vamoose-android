import 'package:material_ui/material_ui.dart';

import '../../domain/board_theme.dart';
import '../../domain/direction.dart';
import 'palette.dart';

class BoardColors extends ThemeExtension<BoardColors> {
  const BoardColors({
    required this.name,
    required this.brightness,
    required this.background,
    required this.board,
    required this.well,
    required this.ink,
    required this.inkSoft,
    required this.up,
    required this.right,
    required this.down,
    required this.left,
  });

  static const BoardColors classic = BoardColors(
    name: 'Classic',
    brightness: Brightness.light,
    background: Palette.mist,
    board: Palette.white,
    well: Palette.well,
    ink: Palette.ink,
    inkSoft: Palette.slate,
    up: Palette.up,
    right: Palette.right,
    down: Palette.down,
    left: Palette.left,
  );

  static const BoardColors wood = BoardColors(
    name: 'Wood',
    brightness: Brightness.light,
    background: Color(0xFFEADFCF),
    board: Color(0xFFFAF4EA),
    well: Color(0xFFF1E6D4),
    ink: Palette.ink,
    inkSoft: Color(0xFF66594A),
    up: Color(0xFF3F6F9F),
    right: Color(0xFFC4553B),
    down: Color(0xFF4E8A5A),
    left: Color(0xFF8B5C9E),
  );

  static const BoardColors night = BoardColors(
    name: 'Night',
    brightness: Brightness.dark,
    background: Color(0xFF151A2E),
    board: Color(0xFF1F2640),
    well: Color(0xFF28304F),
    ink: Palette.mist,
    inkSoft: Color(0xFFA9B2CF),
    up: Color(0xFF5B8CFF),
    right: Color(0xFFFF6B4A),
    down: Color(0xFF22B89B),
    left: Color(0xFFA07CFF),
  );

  static BoardColors from(BoardTheme theme) => switch (theme) {
    BoardTheme.classic => classic,
    BoardTheme.wood => wood,
    BoardTheme.night => night,
  };

  static BoardColors of(BuildContext context) =>
      Theme.of(context).extension<BoardColors>() ?? classic;

  final String name;
  final Brightness brightness;
  final Color background;
  final Color board;
  final Color well;
  final Color ink;
  final Color inkSoft;
  final Color up;
  final Color right;
  final Color down;
  final Color left;

  Color forDirection(Direction direction) => switch (direction) {
    Direction.up => up,
    Direction.right => right,
    Direction.down => down,
    Direction.left => left,
  };

  @override
  BoardColors copyWith() => this;

  @override
  BoardColors lerp(BoardColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color from, Color to) => Color.lerp(from, to, t)!;
    final settled = t < 0.5 ? this : other;
    return BoardColors(
      name: settled.name,
      brightness: settled.brightness,
      background: mix(background, other.background),
      board: mix(board, other.board),
      well: mix(well, other.well),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      up: mix(up, other.up),
      right: mix(right, other.right),
      down: mix(down, other.down),
      left: mix(left, other.left),
    );
  }
}
