import 'package:flutter/animation.dart';

abstract final class Motion {
  static const Duration blockLeaves = Duration(milliseconds: 520);
  static const Duration blockFadeDelay = Duration(milliseconds: 200);
  static const Duration flyInDelay = Duration(milliseconds: 300);
  static const double flyInHorizontal = 460 / 336;
  static const double flyInVertical = 620 / 336;
  static const Duration resultsDelay = Duration(milliseconds: 550);
  static const Duration bump = Duration(milliseconds: 340);
  static const double bumpDistance = 10;
  static const Duration inTheWay = Duration(milliseconds: 900);
  static const Duration hintPulse = Duration(milliseconds: 550);
  static const double hintScale = 1.06;
  static const Duration hintDot = Duration(milliseconds: 300);
  static const Duration hintDotGap = Duration(milliseconds: 90);
  static const Duration badge = Duration(milliseconds: 520);
  static const Duration starPop = Duration(milliseconds: 520);
  static const Duration starGap = Duration(milliseconds: 200);
  static const Duration sheet = Duration(milliseconds: 360);
  static const Duration scrimFade = Duration(milliseconds: 220);
  static const Duration keyPress = Duration(milliseconds: 120);
  static const Duration toggle = Duration(milliseconds: 200);
  static const Duration progress = Duration(milliseconds: 400);
  static const double keyTravel = 3;

  static const Curve leaveCurve = Cubic(0.55, 0, 0.75, 0.2);
  static const Curve popCurve = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve sheetCurve = Cubic(0.2, 0.9, 0.3, 1);
  static const Curve cardCurve = Cubic(0.2, 0.9, 0.3, 1.1);
  static const Curve flyInCurve = Cubic(0.2, 0.9, 0.3, 1.15);
  static const Curve switchCurve = Cubic(0.3, 1.4, 0.6, 1);
}
