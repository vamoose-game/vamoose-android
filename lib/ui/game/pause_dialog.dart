import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/key_button.dart';

enum PauseChoice { resume, restart, levels, home }

abstract final class PauseDialog {
  static const Duration _cardDelay = Duration(milliseconds: 60);
  static const Duration _cardIn = Duration(milliseconds: 320);

  static Future<PauseChoice> show(
    BuildContext context, {
    required String subtitle,
  }) async {
    final total = _cardDelay + _cardIn;
    final choice = await showGeneralDialog<PauseChoice>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Resume',
      barrierColor: Colors.transparent,
      transitionDuration: total,
      pageBuilder: (context, _, _) => _PauseCard(subtitle: subtitle),
      transitionBuilder: (context, animation, _, child) {
        final scrim = CurvedAnimation(
          parent: animation,
          curve: Interval(
            0,
            Motion.scrimFade.inMilliseconds / total.inMilliseconds,
            curve: Curves.easeOut,
          ),
        );
        final card = CurvedAnimation(
          parent: animation,
          curve: Interval(
            _cardDelay.inMilliseconds / total.inMilliseconds,
            1,
            curve: Motion.cardCurve,
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: scrim,
                  builder: (context, _) => BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 6 * scrim.value,
                      sigmaY: 6 * scrim.value,
                    ),
                    child: ColoredBox(
                      color: Palette.scrim.withValues(
                        alpha: 0.55 * scrim.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: card,
              child: child,
              builder: (context, child) => Opacity(
                opacity: card.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - card.value)),
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * card.value,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return choice ?? PauseChoice.resume;
  }
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    void choose(PauseChoice choice) => Navigator.of(context).pop(choice);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x401B2340),
                offset: Offset(0, 30),
                blurRadius: 60,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Paused',
                    style: AppText.title.copyWith(fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppText.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  KeyButton(
                    tone: KeyTone.primary,
                    height: 62,
                    onPressed: () => choose(PauseChoice.resume),
                    child: const _Label(
                      icon: Icons.play_arrow_rounded,
                      text: 'Resume',
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 10),
                  KeyButton(
                    tone: KeyTone.soft,
                    height: 56,
                    radius: 18,
                    onPressed: () => choose(PauseChoice.restart),
                    child: const _Label(
                      icon: Icons.restart_alt_rounded,
                      text: 'Restart level',
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: KeyButton(
                          tone: KeyTone.soft,
                          height: 56,
                          radius: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => choose(PauseChoice.levels),
                          child: const _Label(
                            icon: Icons.grid_view_rounded,
                            text: 'Levels',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KeyButton(
                          tone: KeyTone.soft,
                          height: 56,
                          radius: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () => choose(PauseChoice.home),
                          child: const _Label(
                            icon: Icons.home_outlined,
                            text: 'Home',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, color: Palette.line),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _ToggleKey(
                          icon: settings.sound
                              ? Icons.volume_up_outlined
                              : Icons.volume_off_outlined,
                          text: settings.sound ? 'Sound on' : 'Sound off',
                          on: settings.sound,
                          onPressed: () => settings.setSound(!settings.sound),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ToggleKey(
                          icon: Icons.vibration_rounded,
                          text: settings.vibration
                              ? 'Vibration on'
                              : 'Vibration off',
                          on: settings.vibration,
                          onPressed: () =>
                              settings.setVibration(!settings.vibration),
                        ),
                      ),
                    ],
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

class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.text,
    required this.fontSize,
  });

  final IconData icon;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontSize >= 19 ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleKey extends StatelessWidget {
  const _ToggleKey({
    required this.icon,
    required this.text,
    required this.on,
    required this.onPressed,
  });

  final IconData icon;
  final String text;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = on ? Palette.white : Palette.slate;
    return KeyButton(
      tone: on ? KeyTone.primary : KeyTone.soft,
      height: 76,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      semanticLabel: text,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            text,
            style: AppText.bodyStrong.copyWith(fontSize: 15, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
