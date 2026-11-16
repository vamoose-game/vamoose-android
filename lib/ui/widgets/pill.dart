import 'package:flutter/widgets.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';

class Pill extends StatelessWidget {
  const Pill({super.key, required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(text, style: AppText.bodyStrong),
        ],
      ),
    );
  }
}
