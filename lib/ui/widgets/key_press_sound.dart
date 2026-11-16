import 'package:flutter/widgets.dart';

class KeyPressSound extends InheritedWidget {
  const KeyPressSound({super.key, required this.onPress, required super.child});

  final VoidCallback onPress;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KeyPressSound>()?.onPress;

  @override
  bool updateShouldNotify(KeyPressSound oldWidget) =>
      onPress != oldWidget.onPress;
}
