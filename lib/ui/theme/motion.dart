import 'package:flutter/animation.dart';

abstract final class Motion {
  static const Duration blockLeaves = Duration(milliseconds: 520);
  static const Duration blockFadeDelay = Duration(milliseconds: 200);
  static const Duration bump = Duration(milliseconds: 340);
  static const double bumpDistance = 10;
  static const Duration inTheWay = Duration(milliseconds: 900);
  static const Duration hintPulse = Duration(milliseconds: 700);
  static const double hintScale = 1.06;
  static const Duration badge = Duration(milliseconds: 520);
  static const Duration confetti = Duration(seconds: 2);
  static const Duration starPop = Duration(milliseconds: 520);
  static const Duration starGap = Duration(milliseconds: 200);
  static const Duration sheet = Duration(milliseconds: 360);
  static const Duration keyPress = Duration(milliseconds: 90);
  static const double keyTravel = 3;

  static const Curve leaveCurve = Curves.easeInCubic;
  static const Curve badgeCurve = Curves.easeOutBack;
  static const Curve sheetCurve = Curves.easeOutCubic;
}
