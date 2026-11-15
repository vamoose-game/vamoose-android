import 'package:flutter/widgets.dart';

import 'palette.dart';

abstract final class AppText {
  static const String family = 'Lexend';

  static const TextStyle logo = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 54,
    height: 1,
    letterSpacing: -1.5,
    color: Palette.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.15,
    color: Palette.ink,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.2,
    color: Palette.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 1.2,
    color: Palette.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.4,
    color: Palette.slate,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.3,
    color: Palette.ink,
  );

  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 1.2,
    letterSpacing: 1.4,
    color: Palette.slate,
  );

  static const TextStyle number = TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.w800,
    fontSize: 26,
    height: 1.1,
    color: Palette.ink,
  );
}
