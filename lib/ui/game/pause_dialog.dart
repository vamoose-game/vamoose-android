import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/key_button.dart';

enum PauseChoice { resume, restart, levels, home }

abstract final class PauseDialog {
  static Future<PauseChoice> show(
    BuildContext context, {
    required String subtitle,
  }) async {
    final choice = await showGeneralDialog<PauseChoice>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Resume',
      barrierColor: Palette.scrim,
      transitionDuration: Motion.sheet,
      pageBuilder: (context, _, _) => _PauseCard(subtitle: subtitle),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Motion.sheetCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
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
        padding: const EdgeInsets.all(20),
        child: Material(
          color: Palette.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Paused',
                  style: AppText.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                KeyButton(
                  tone: KeyTone.primary,
                  onPressed: () => choose(PauseChoice.resume),
                  child: const _Label(
                    icon: Icons.play_arrow_rounded,
                    text: 'Resume',
                  ),
                ),
                const SizedBox(height: 10),
                KeyButton(
                  tone: KeyTone.soft,
                  height: 58,
                  onPressed: () => choose(PauseChoice.restart),
                  child: const _Label(
                    icon: Icons.restart_alt_rounded,
                    text: 'Restart level',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: KeyButton(
                        tone: KeyTone.soft,
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () => choose(PauseChoice.levels),
                        child: const _Label(
                          icon: Icons.grid_view_rounded,
                          text: 'Levels',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KeyButton(
                        tone: KeyTone.soft,
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () => choose(PauseChoice.home),
                        child: const _Label(
                          icon: Icons.home_outlined,
                          text: 'Home',
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1, color: Palette.edge),
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
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
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
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppText.bodyStrong.copyWith(
              fontSize: 15,
              color: on ? Palette.white : Palette.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
