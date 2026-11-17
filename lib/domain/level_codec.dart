import 'dart:convert';

import 'block.dart';
import 'board.dart';
import 'direction.dart';
import 'level.dart';
import 'restraint.dart';

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
    ..._encodeRestraints(board.restraints),
  };

  static Map<String, Object> _encodeRestraints(List<Restraint> restraints) {
    final locks = <List<int>>[];
    for (final restraint in restraints) {
      switch (restraint) {
        case Lock(:final blockId, :final keyId):
          locks.add([blockId, keyId]);
      }
    }
    return {if (locks.isNotEmpty) 'locks': locks};
  }

  static Board _decodeBoard(Map<String, dynamic> json) {
    final rows = json['blocks'] as List<dynamic>;
    final locks = json['locks'] as List<dynamic>? ?? const [];
    return Board(
      size: json['size'] as int,
      blocks: [
        for (var id = 0; id < rows.length; id++)
          _decodeBlock(id, rows[id] as List<dynamic>),
      ],
      restraints: [
        for (final pair in locks.cast<List<dynamic>>())
          Lock(blockId: pair[0] as int, keyId: pair[1] as int),
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
