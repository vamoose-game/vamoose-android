import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import '../theme/palette.dart';

class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: Motion.toggle,
          width: 56,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? Palette.down : Palette.switchOff,
            borderRadius: BorderRadius.circular(17),
          ),
          child: AnimatedAlign(
            duration: Motion.toggle,
            curve: Motion.switchCurve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Palette.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x401B2340),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
