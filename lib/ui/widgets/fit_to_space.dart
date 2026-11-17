import 'package:flutter/widgets.dart';

class FitToSpace extends StatelessWidget {
  const FitToSpace({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: constraints.maxWidth, child: child),
      ),
    );
  }
}
