import 'package:flutter/widgets.dart';

import '../../domain/direction.dart';

abstract final class Palette {
  static const Color mist = Color(0xFFEEF1F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color well = Color(0xFFF1F4FA);
  static const Color edge = Color(0xFFDCE2EE);
  static const Color ink = Color(0xFF1B2340);
  static const Color slate = Color(0xFF4F5978);
  static const Color up = Color(0xFF3B63F0);
  static const Color right = Color(0xFFEF5A3C);
  static const Color down = Color(0xFF0E9F8A);
  static const Color left = Color(0xFF8457F0);
  static const Color sun = Color(0xFFFFC23D);
  static const Color silver = Color(0xFFC9D0E4);
  static const Color alert = Color(0xFFD9472A);
  static const Color line = Color(0xFFE3E8F3);
  static const Color muted = Color(0xFFC5CDDF);
  static const Color lockedText = Color(0xFF5E6888);
  static const Color sunEdge = Color(0xFFD99A12);
  static const Color starStroke = Color(0xFFC98A00);
  static const Color cream = Color(0xFFFFF4D6);
  static const Color creamEdge = Color(0xFFF2D98E);
  static const Color blueTint = Color(0xFFE6ECFE);
  static const Color orangeTint = Color(0xFFFDE9E4);
  static const Color switchOff = Color(0xFF8C96B3);
  static const Color danger = Color(0xFFC2391D);
  static const Color dashed = Color(0xFFAEB7CE);
  static const Color scrim = Color(0x8C1B2340);

  static Color forDirection(Direction direction) => switch (direction) {
    Direction.up => up,
    Direction.right => right,
    Direction.down => down,
    Direction.left => left,
  };

  static Color darken(Color color, double amount) =>
      Color.alphaBlend(Color.fromRGBO(0, 0, 0, amount), color);

  static Color lighten(Color color, double amount) =>
      Color.alphaBlend(Color.fromRGBO(255, 255, 255, amount), color);
}
