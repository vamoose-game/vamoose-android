import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/direction.dart';

import '../support/boards.dart';

void main() {
  group('Block', () {
    test('horizontal block covers cells to the right of its origin', () {
      final cells = block(0, 2, 1, 3, Direction.right).cells;

      expect(cells, [
        (row: 2, column: 1),
        (row: 2, column: 2),
        (row: 2, column: 3),
      ]);
    });

    test('vertical block covers cells below its origin', () {
      final cells = block(0, 1, 4, 2, Direction.up).cells;

      expect(cells, [(row: 1, column: 4), (row: 2, column: 4)]);
    });

    test('front is the cell facing the direction of travel', () {
      expect(block(0, 1, 1, 3, Direction.right).front, (row: 1, column: 3));
      expect(block(0, 1, 1, 3, Direction.left).front, (row: 1, column: 1));
      expect(block(0, 1, 1, 3, Direction.down).front, (row: 3, column: 1));
      expect(block(0, 1, 1, 3, Direction.up).front, (row: 1, column: 1));
    });

    test('path walks from the front to the board edge', () {
      final path = block(0, 2, 1, 2, Direction.right).pathWithin(5);

      expect(path, [(row: 2, column: 3), (row: 2, column: 4)]);
    });

    test('path is empty when the front touches the edge', () {
      expect(block(0, 0, 0, 2, Direction.up).pathWithin(5), isEmpty);
    });
  });
}
