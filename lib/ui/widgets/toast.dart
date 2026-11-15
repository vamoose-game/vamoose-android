import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';

abstract final class Toast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppText.bodyStrong.copyWith(color: Palette.white),
          ),
          backgroundColor: Palette.ink,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }
}
