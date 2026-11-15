import 'direction.dart';

typedef Cell = ({int row, int column});

extension CellNavigation on Cell {
  Cell step(Direction direction) =>
      (row: row + direction.rowStep, column: column + direction.columnStep);

  bool isInside(int size) =>
      row >= 0 && row < size && column >= 0 && column < size;
}
