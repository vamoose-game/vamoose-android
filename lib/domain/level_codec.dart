import 'dart:convert';

import 'block.dart';
import 'board.dart';
import 'direction.dart';
import 'level.dart';
import 'restraint.dart';

/// Reads and writes `assets/levels/levels.json`: one entry per level, as
/// `{"size":6,"time":12,"blocks":[[row,column,length,"u"]],"locks":[[lockedId,keyId]],"turns":[id]}`.
/// Block ids are their positions in `blocks`; `locks` and `turns` are left
/// out when empty.
abstract final class LevelCodec {
  static const Duration defaultTimeLimit = Duration(seconds: 60);

  static String encode(Iterable<Level> levels) =>
      '[\n${levels.map((level) => jsonEncode(encodeLevel(level))).join(',\n')}\n]\n';

  static List<Level> decode(String source) {
    final entries = jsonDecode(source) as List<dynamic>;
    return [
      for (var index = 0; index < entries.length; index++)
        decodeLevel(index + 1, entries[index] as Map<String, dynamic>),
    ];
  }

  static Map<String, Object> encodeLevel(Level level) {
    final board = encodeBoard(level.board);
    return {
      'size': board.remove('size')!,
      'time': level.timeLimit.inSeconds,
      ...board,
    };
  }

  static Level decodeLevel(int number, Map<String, dynamic> json) => Level(
    number: number,
    board: decodeBoard(json),
    timeLimit: switch (json['time']) {
      final int seconds => Duration(seconds: seconds),
      _ => defaultTimeLimit,
    },
  );

  static Map<String, Object> encodeBoard(Board board) {
    final blocks = board.blocks.toList()..sort((a, b) => a.id - b.id);
    final index = {
      for (var position = 0; position < blocks.length; position++)
        blocks[position].id: position,
    };
    return {
      'size': board.size,
      'blocks': [
        for (final block in blocks)
          [block.row, block.column, block.length, block.direction.code],
      ],
      ..._encodeRestraints(board.restraints, index),
      if (blocks.any((block) => block.turns))
        'turns': [
          for (final block in blocks)
            if (block.turns) index[block.id]!,
        ],
    };
  }

  static Board decodeBoard(Map<String, dynamic> json) {
    final rows = json['blocks'] as List<dynamic>;
    final locks = json['locks'] as List<dynamic>? ?? const [];
    final turns = {...?(json['turns'] as List<dynamic>?)?.cast<int>()};
    return Board(
      size: json['size'] as int,
      blocks: [
        for (var id = 0; id < rows.length; id++)
          _decodeBlock(
            id,
            rows[id] as List<dynamic>,
            turns: turns.contains(id),
          ),
      ],
      restraints: [
        for (final pair in locks.cast<List<dynamic>>())
          Lock(blockId: pair[0] as int, keyId: pair[1] as int),
      ],
    );
  }

  static Map<String, Object> _encodeRestraints(
    List<Restraint> restraints,
    Map<int, int> index,
  ) {
    final locks = <List<int>>[];
    for (final restraint in restraints) {
      switch (restraint) {
        case Lock(:final blockId, :final keyId):
          // A lock whose block or key has left holds nothing any more.
          if ((index[blockId], index[keyId]) case (final block?, final key?)) {
            locks.add([block, key]);
          }
      }
    }
    return {if (locks.isNotEmpty) 'locks': locks};
  }

  static Block _decodeBlock(int id, List<dynamic> row, {required bool turns}) =>
      Block(
        id: id,
        row: row[0] as int,
        column: row[1] as int,
        length: row[2] as int,
        direction: Direction.fromCode(row[3] as String),
        turns: turns,
      );
}
