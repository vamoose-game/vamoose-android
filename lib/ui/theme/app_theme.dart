import 'package:material_ui/material_ui.dart';

import 'app_text.dart';
import 'palette.dart';

abstract final class AppTheme {
  static ThemeData build() => ThemeData(
    fontFamily: AppText.family,
    scaffoldBackgroundColor: Palette.mist,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.ink,
      primary: Palette.ink,
      surface: Palette.mist,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Palette.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Palette.down
            : const Color(0xFF8E96B0),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.white,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}
