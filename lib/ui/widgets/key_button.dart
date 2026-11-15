import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';

enum KeyTone {
  primary(face: Palette.ink, edge: Color(0xFF0B1028), content: Palette.white),
  secondary(face: Palette.white, edge: Palette.edge, content: Palette.ink),
  hint(face: Palette.sun, edge: Color(0xFFE0A21F), content: Palette.ink),
  success(face: Palette.down, edge: Color(0xFF0A7A6A), content: Palette.white),
  soft(face: Palette.mist, edge: Palette.edge, content: Palette.ink),
  reward(
    face: Color(0xFFFFF3D6),
    edge: Color(0xFFF5DA9A),
    content: Palette.ink,
  );

  const KeyTone({
    required this.face,
    required this.edge,
    required this.content,
  });

  final Color face;
  final Color edge;
  final Color content;
}

class KeyButton extends StatefulWidget {
  const KeyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tone = KeyTone.secondary,
    this.height = 64,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.semanticLabel,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final KeyTone tone;
  final double height;
  final double radius;
  final EdgeInsets padding;
  final String? semanticLabel;
  final AlignmentGeometry alignment;

  @override
  State<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<KeyButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed != null && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;
    final radius = BorderRadius.circular(widget.radius);
    final travel = _pressed ? Motion.keyTravel : 0.0;
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                top: Motion.keyTravel,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.edge,
                    borderRadius: radius,
                  ),
                ),
              ),
              AnimatedPadding(
                duration: Motion.keyPress,
                padding: EdgeInsets.only(
                  top: travel,
                  bottom: Motion.keyTravel - travel,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.face,
                    borderRadius: radius,
                  ),
                  child: Padding(
                    padding: widget.padding,
                    child: DefaultTextStyle(
                      style: AppText.button.copyWith(color: tone.content),
                      child: IconTheme(
                        data: IconThemeData(color: tone.content, size: 22),
                        child: Align(
                          alignment: widget.alignment,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconKey extends StatelessWidget {
  const IconKey({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: KeyButton(
        onPressed: onPressed,
        height: size,
        radius: 16,
        padding: EdgeInsets.zero,
        semanticLabel: semanticLabel,
        child: Icon(icon, size: 24),
      ),
    );
  }
}
