import 'dart:convert';

import 'block.dart';
import 'board.dart';
import 'direction.dart';
import 'level.dart';

abstract final class LevelCodec {
  static String encode(List<Board> boards) =>
      '[\n${boards.map((board) => jsonEncode(_encodeBoard(board))).join(',\n')}\n]\n';

  static List<Level> decode(String source) {
    final entries = jsonDecode(source) as List<dynamic>;
    return [
      for (var index = 0; index < entries.length; index++)
        Level(
          number: index + 1,
          board: _decodeBoard(entries[index] as Map<String, dynamic>),
        ),
    ];
  }

  static Map<String, Object> _encodeBoard(Board board) => {
    'size': board.size,
    'blocks': [
      for (final block in board.blocks)
        [block.row, block.column, block.length, block.direction.code],
    ],
  };

  static Board _decodeBoard(Map<String, dynamic> json) {
    final rows = json['blocks'] as List<dynamic>;
    return Board(
      size: json['size'] as int,
      blocks: [
        for (var id = 0; id < rows.length; id++)
          _decodeBlock(id, rows[id] as List<dynamic>),
      ],
    );
  }

  static Block _decodeBlock(int id, List<dynamic> row) => Block(
    id: id,
    row: row[0] as int,
    column: row[1] as int,
    length: row[2] as int,
    direction: Direction.fromCode(row[3] as String),
  );
}
