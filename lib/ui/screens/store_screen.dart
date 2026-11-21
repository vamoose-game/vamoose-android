import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/economy.dart';
import '../../services/ads/ad_service.dart';
import '../../state/coin_wallet.dart';
import '../../state/extra_time_wallet.dart';
import '../../state/lives_controller.dart';
import '../../state/streak_controller.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
import '../widgets/every_second.dart';
import '../widgets/heart.dart';
import '../widgets/key_button.dart';
import '../widgets/page_header.dart';
import '../widgets/toast.dart';
import 'themes_panel.dart';

enum StoreTab { items, themes }

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.tab = StoreTab.items});

  final StoreTab tab;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late StoreTab _tab = widget.tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(title: 'Store', trailing: CoinChip()),
              const SizedBox(height: 16),
              _Tabs(
                selected: _tab,
                onSelected: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.toggle,
                  child: switch (_tab) {
                    StoreTab.items => const _Items(key: ValueKey('items')),
                    StoreTab.themes => const ThemesPanel(
                      key: ValueKey('themes'),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final StoreTab selected;
  final ValueChanged<StoreTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (final tab in StoreTab.values) ...[
            if (tab != StoreTab.values.first) const SizedBox(width: 5),
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == selected,
                child: GestureDetector(
                  onTap: () => onSelected(tab),
                  child: AnimatedContainer(
                    duration: Motion.toggle,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab == selected ? Palette.ink : Palette.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      switch (tab) {
                        StoreTab.items => 'Items',
                        StoreTab.themes => 'Themes',
                      },
                      style: AppText.button.copyWith(
                        fontSize: 17,
                        color: tab == selected ? Palette.white : Palette.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({super.key});

  Future<void> _pay(
    BuildContext context,
    Future<bool> Function() buy, {
    required int price,
  }) async {
    final services = context.read<AppServices>();
    if (!services.coins.canAfford(price)) {
      Toast.show(context, 'Not enough coins');
      return;
    }
    if (await buy()) {
      services.feedback.themeUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lives = context.watch<LivesController>();
    final extraTime = context.watch<ExtraTimeWallet>().count;
    final freezes = context.watch<StreakController>().freezes;
    final services = context.read<AppServices>();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ItemRow(
          icon: const HeartGlyph(size: 30),
          tint: Palette.orangeTint,
          title: 'Full lives',
          detail: '${lives.count}/${Economy.maxLives}',
          action: lives.isFull
              ? const _Chip('Full')
              : _PriceKey(
                  price: Economy.refillLivesPrice,
                  label: 'Refill all lives',
                  onPressed: () => _pay(
                    context,
                    () => lives.refillAll(services.coins),
                    price: Economy.refillLivesPrice,
                  ),
                ),
        ),
        const _VideoLifeRow(),
        _ItemRow(
          icon: const Icon(Icons.more_time_rounded, color: Palette.mintText),
          tint: Palette.mint,
          title: 'Extra time',
          detail:
              '+${Economy.fewestExtraSeconds}–${Economy.mostExtraSeconds} s'
              ' · ×$extraTime',
          action: _PriceKey(
            price: Economy.extraTimePrice,
            label: 'Buy extra time',
            onPressed: () => _pay(
              context,
              services.extraTime.buy,
              price: Economy.extraTimePrice,
            ),
          ),
        ),
        _ItemRow(
          icon: const Icon(Icons.ac_unit_rounded, color: Palette.ice),
          tint: Palette.iceTint,
          title: 'Streak freeze',
          detail: '$freezes/${Economy.maxFreezes}',
          action: freezes >= Economy.maxFreezes
              ? const _Chip('Max')
              : _PriceKey(
                  price: Economy.freezePrice,
                  label: 'Buy a streak freeze',
                  onPressed: () => _pay(
                    context,
                    services.streak.buyFreeze,
                    price: Economy.freezePrice,
                  ),
                ),
        ),
      ],
    );
  }
}

class _VideoLifeRow extends StatefulWidget {
  const _VideoLifeRow();

  @override
  State<_VideoLifeRow> createState() => _VideoLifeRowState();
}

class _VideoLifeRowState extends State<_VideoLifeRow> {
  bool _loading = false;

  Future<void> _watch() async {
    final services = context.read<AppServices>();
    setState(() => _loading = true);
    final outcome = await services.ads.showRewarded();
    if (outcome == RewardOutcome.earned) {
      await services.lives.add(1);
      services.feedback.lifeGained();
    }
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (outcome == RewardOutcome.unavailable) {
      Toast.show(context, 'No video right now');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lives = context.read<LivesController>();
    return EverySecond(
      onTick: lives.refresh,
      builder: (context) {
        final full = context.watch<LivesController>().isFull;
        final ready = context.read<AppServices>().ads.isReady;
        return _ItemRow(
          icon: const Icon(
            Icons.play_circle_outline_rounded,
            color: Palette.ink,
          ),
          tint: Palette.cream,
          title: '+1 life',
          detail: full
              ? 'Video'
              : 'Next in ${Formatting.clockLeft(lives.untilNext ?? Duration.zero)}',
          action: switch ((full, _loading)) {
            (true, _) => const _Chip('Full'),
            (_, true) => const SizedBox.square(
              dimension: 50,
              child: Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Palette.ink,
                  backgroundColor: Palette.creamEdge,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            _ => Opacity(
              opacity: ready ? 1 : 0.5,
              child: KeyButton(
                tone: KeyTone.primary,
                height: 50,
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                semanticLabel: 'Watch a video for one life',
                onPressed: ready ? _watch : null,
                child: const Text('Watch', style: TextStyle(fontSize: 16)),
              ),
            ),
          },
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.detail,
    required this.action,
  });

  final Widget icon;
  final Color tint;
  final String title;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: IconTheme.merge(
              data: const IconThemeData(size: 28),
              child: icon,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading.copyWith(fontSize: 18)),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }
}

class _PriceKey extends StatelessWidget {
  const _PriceKey({
    required this.price,
    required this.label,
    required this.onPressed,
  });

  final int price;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final affordable = context.watch<CoinWallet>().canAfford(price);
    return Opacity(
      opacity: affordable ? 1 : 0.55,
      child: KeyButton(
        tone: KeyTone.hint,
        height: 50,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        semanticLabel: '$label for $price coins',
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinGlyph(size: 22),
            const SizedBox(width: 6),
            Text(
              Formatting.grouped(price),
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.line,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppText.bodyStrong.copyWith(color: Palette.slate, fontSize: 15),
      ),
    );
  }
}
