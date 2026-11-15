import 'package:flutter/widgets.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.icon,
    required this.text,
    this.color = Palette.white,
  });

  final Widget icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Palette.edge, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(text, style: AppText.bodyStrong),
          ],
        ),
      ),
    );
  }
}
