import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/card_dialog.dart';
import '../widgets/key_button.dart';

enum PauseChoice { resume, restart, levels, home }

abstract final class PauseDialog {
  static Future<PauseChoice> show(
    BuildContext context, {
    required String subtitle,
  }) async {
    final choice = await CardDialog.show<PauseChoice>(
      context,
      label: 'Resume',
      builder: (context) => _PauseCard(subtitle: subtitle),
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
    return DialogCard(
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
          Text(subtitle, style: AppText.body, textAlign: TextAlign.center),
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
              text: 'Restart',
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
                  text: 'Sound',
                  on: settings.sound,
                  onPressed: () => settings.setSound(!settings.sound),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleKey(
                  icon: settings.music
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  text: 'Music',
                  on: settings.music,
                  onPressed: () => settings.setMusic(!settings.music),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleKey(
                  icon: Icons.vibration_rounded,
                  text: 'Vibration',
                  on: settings.vibration,
                  onPressed: () => settings.setVibration(!settings.vibration),
                ),
              ),
            ],
          ),
        ],
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
      semanticLabel: '$text ${on ? 'on' : 'off'}',
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: AppText.bodyStrong.copyWith(fontSize: 14, color: color),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
