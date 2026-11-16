import 'package:flutter/widgets.dart';

import '../theme/palette.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.color = Palette.white,
    this.raised = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: raised
            ? const [
                BoxShadow(
                  color: Color(0x171B2340),
                  offset: Offset(0, 18),
                  blurRadius: 40,
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
