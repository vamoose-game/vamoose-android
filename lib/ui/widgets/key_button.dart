import 'package:material_ui/material_ui.dart';

import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';

enum KeyTone {
  primary(
    face: Palette.ink,
    edge: Color(0xFF11172A),
    depth: 5,
    content: Palette.white,
  ),
  secondary(
    face: Palette.white,
    edge: Palette.edge,
    depth: 4,
    content: Palette.ink,
  ),
  hint(
    face: Palette.sun,
    edge: Palette.sunEdge,
    depth: 4,
    content: Palette.ink,
  ),
  soft(face: Palette.well, edge: Palette.edge, depth: 4, content: Palette.ink),
  reward(
    face: Palette.cream,
    edge: Palette.creamEdge,
    depth: 4,
    content: Palette.ink,
  ),
  success(
    face: Palette.down,
    edge: Color(0xFF0B7F6E),
    depth: 6,
    content: Palette.white,
  );

  const KeyTone({
    required this.face,
    required this.edge,
    required this.depth,
    required this.content,
  });

  final Color face;
  final Color edge;
  final double depth;
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
          child: AnimatedSlide(
            duration: Motion.keyPress,
            offset: Offset(0, _pressed ? Motion.keyTravel / widget.height : 0),
            child: DecoratedBox(
              decoration: BoxDecoration(color: tone.edge, borderRadius: radius),
              child: AnimatedPadding(
                duration: Motion.keyPress,
                padding: EdgeInsets.only(bottom: _pressed ? 0 : tone.depth),
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
            ),
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
    this.size = 48,
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
