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
  static const Color bronze = Color(0xFFE29A5C);
  static const Color alert = Color(0xFFD9472A);
  static const Color line = Color(0xFFE3E8F3);
  static const Color muted = Color(0xFFC5CDDF);
  static const Color lockedText = Color(0xFF5E6888);
  static const Color sunEdge = Color(0xFFD99A12);
  static const Color starStroke = Color(0xFFC98A00);
  static const Color coinRing = Color(0xFFE0A21C);
  static const Color cream = Color(0xFFFFF4D6);
  static const Color mint = Color(0xFFE6F6F2);
  static const Color ice = Color(0xFF1F6FB8);
  static const Color iceDeep = Color(0xFF123E66);
  static const Color iceTint = Color(0xFFDDEEFB);
  static const Color iceNode = Color(0xFFCDE5F8);
  static const Color iceEdge = Color(0xFF9CC6EA);
  static const Color iceSlot = Color(0xFF8DB8DD);
  static const Color iceKeyEdge = Color(0xFFB9D9F2);
  static const Color streakText = Color(0xFFC9D0E4);
  static const Color mintText = Color(0xFF0B7A6A);
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
