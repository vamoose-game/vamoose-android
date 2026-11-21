import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/board.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/domain/level_codec.dart';
import 'package:vamoose/domain/restraint.dart';

import '../support/boards.dart';

void main() {
  test('a board keeps its locks through the codec', () {
    final board = Board(
      size: 3,
      blocks: [
        block(0, 0, 0, 1, Direction.up),
        block(1, 2, 2, 1, Direction.down),
      ],
      restraints: const [Lock(blockId: 1, keyId: 0)],
    );

    final decoded = LevelCodec.decodeBoard(LevelCodec.encodeBoard(board));

    expect(decoded.restraints, hasLength(1));
    expect(decoded.canLeave(decoded.blockById(1)), isFalse);
  });

  test('a lock whose key has left is not written', () {
    final board = Board(
      size: 3,
      blocks: [
        block(0, 0, 0, 1, Direction.up),
        block(1, 2, 2, 1, Direction.down),
      ],
      restraints: const [Lock(blockId: 1, keyId: 0)],
    ).without(0);

    final decoded = LevelCodec.decodeBoard(LevelCodec.encodeBoard(board));

    expect(decoded.blockCount, 1);
    expect(decoded.restraints, isEmpty);
    expect(decoded.canLeave(decoded.blocks.single), isTrue);
  });
}
