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
  static const Color alert = Color(0xFFD9472A);
  static const Color locked = Color(0xFFE2E7F1);
  static const Color scrim = Color(0x991B2340);

  static Color forDirection(Direction direction) => switch (direction) {
    Direction.up => up,
    Direction.right => right,
    Direction.down => down,
    Direction.left => left,
  };

  static Color shade(Color color) => Color.lerp(color, ink, 0.22)!;

  static Color faded(Color color) => Color.lerp(color, white, 0.62)!;

  static Color tint(Color color) => Color.lerp(color, white, 0.86)!;
}
