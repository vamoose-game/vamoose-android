import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_info.dart';
import '../../app/app_services.dart';
import '../../services/purchases/purchase_service.dart';
import '../../state/ad_free_controller.dart';
import '../../state/daily_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/page_header.dart';
import '../widgets/surface_card.dart';
import '../widgets/toast.dart';
import 'how_to_play_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final progress = context.read<ProgressController>();
    final daily = context.read<DailyController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.white,
        title: const Text('Reset progress?', style: AppText.heading),
        content: const Text(
          'Stars, unlocked levels and your daily streak will be cleared.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppText.button.copyWith(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reset',
              style: AppText.button.copyWith(
                fontSize: 16,
                color: Palette.alert,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await progress.reset();
      await daily.reset();
    }
  }

  Future<void> _buyRemoveAds(BuildContext context) async {
    final outcome = await context.read<AppServices>().purchases.buyRemoveAds();
    final message = switch (outcome) {
      PurchaseOutcome.purchased => 'Ads removed. Thank you!',
      PurchaseOutcome.pending => 'Payment pending. Ads go away once it clears.',
      PurchaseOutcome.canceled => null,
      PurchaseOutcome.failed => 'Purchase did not go through. Try again.',
      PurchaseOutcome.unavailable => 'The store is not available right now.',
    };
    if (message != null && context.mounted) {
      Toast.show(context, message);
    }
  }

  Future<void> _restore(BuildContext context) async {
    final restored = await context
        .read<AppServices>()
        .purchases
        .restorePurchases();
    if (context.mounted) {
      Toast.show(
        context,
        restored
            ? 'Purchase restored. Ads removed.'
            : 'No purchase to restore.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final services = context.read<AppServices>();
    final adsRemoved = context.watch<AdFreeController>().adsRemoved;
    final price = services.purchases.removeAdsPrice;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'Settings'),
            const _SectionLabel('PLAYING'),
            _Group(
              children: [
                _SwitchRow(
                  title: 'Easy mode',
                  subtitle: 'Blocks that cannot move yet are faded.',
                  value: settings.easyMode,
                  onChanged: settings.setEasyMode,
                ),
                _SwitchRow(
                  title: 'Bigger text',
                  value: settings.biggerText,
                  onChanged: settings.setBiggerText,
                ),
                _SwitchRow(
                  title: 'Sound effects',
                  value: settings.sound,
                  onChanged: settings.setSound,
                ),
                _SwitchRow(
                  title: 'Vibration',
                  value: settings.vibration,
                  onChanged: settings.setVibration,
                ),
              ],
            ),
            const _SectionLabel('ADS & PRIVACY'),
            _Group(
              children: [
                if (adsRemoved)
                  const _LinkRow(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: Palette.down,
                    title: 'Ads removed',
                    onTap: null,
                  )
                else
                  _LinkRow(
                    icon: Icons.block_rounded,
                    iconColor: Palette.alert,
                    title: 'Remove ads',
                    trailing: price == null
                        ? null
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Palette.sun,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              price,
                              style: AppText.label.copyWith(color: Palette.ink),
                            ),
                          ),
                    onTap: () => _buyRemoveAds(context),
                  ),
                _LinkRow(
                  icon: Icons.restore_rounded,
                  title: 'Restore purchase',
                  onTap: () => _restore(context),
                ),
                _LinkRow(
                  icon: Icons.shield_outlined,
                  title: 'Ad privacy choices',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Palette.slate,
                  ),
                  onTap: services.ads.showPrivacyOptions,
                ),
              ],
            ),
            const _SectionLabel('HELP'),
            _Group(
              children: [
                _LinkRow(
                  icon: Icons.info_outline_rounded,
                  title: 'How to play',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Palette.slate,
                  ),
                  onTap: () => Navigator.of(context).push(
                    Navigation.page<void>(
                      const HowToPlayScreen(returnsToCaller: true),
                    ),
                  ),
                ),
                const _LinkRow(
                  icon: Icons.description_outlined,
                  title: 'Privacy policy',
                  trailing: Icon(
                    Icons.north_east_rounded,
                    color: Palette.slate,
                  ),
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: TextButton(
                onPressed: () => _confirmReset(context),
                child: Text(
                  'Reset progress',
                  style: AppText.button.copyWith(
                    color: Palette.alert,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${AppInfo.name} · version ${AppInfo.version}',
              style: AppText.body.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(text, style: AppText.label),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              const Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: Palette.edge,
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyStrong.copyWith(fontSize: 17),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.body.copyWith(fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = Palette.slate,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppText.bodyStrong.copyWith(fontSize: 17),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
