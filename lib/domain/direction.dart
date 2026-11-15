enum Direction {
  up(-1, 0, 'u'),
  right(0, 1, 'r'),
  down(1, 0, 'd'),
  left(0, -1, 'l');

  const Direction(this.rowStep, this.columnStep, this.code);

  final int rowStep;
  final int columnStep;
  final String code;

  bool get isVertical => columnStep == 0;

  static Direction fromCode(String code) =>
      values.firstWhere((direction) => direction.code == code);
}
