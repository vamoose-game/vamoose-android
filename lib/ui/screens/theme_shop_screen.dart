import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/block.dart';
import '../../domain/board.dart';
import '../../domain/board_theme.dart';
import '../../domain/direction.dart';
import '../../state/coin_wallet.dart';
import '../../state/theme_controller.dart';
import '../formatting.dart';
import '../theme/app_text.dart';
import '../theme/board_colors.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/coin.dart';
import '../widgets/key_button.dart';
import '../widgets/mini_board.dart';
import '../widgets/page_header.dart';
import '../widgets/progress_bar.dart';
import '../widgets/surface_card.dart';

class ThemeShopScreen extends StatefulWidget {
  const ThemeShopScreen({super.key});

  @override
  State<ThemeShopScreen> createState() => _ThemeShopScreenState();
}

class _ThemeShopScreenState extends State<ThemeShopScreen> {
  late BoardTheme _selected = context.read<ThemeController>().active;
  int _pops = 0;

  void _select(BoardTheme theme) {
    if (theme != _selected) {
      setState(() {
        _selected = theme;
        _pops++;
      });
    }
  }

  Future<void> _buy() async {
    final services = context.read<AppServices>();
    if (await services.themes.buy(_selected)) {
      services.feedback.themeUnlocked();
      if (mounted) {
        setState(() => _pops++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = context.watch<ThemeController>();
    final balance = context.watch<CoinWallet>().balance;
    final selected = _selected;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(title: 'Themes', trailing: CoinChip()),
              const SizedBox(height: 16),
              Expanded(
                child: _Preview(
                  colors: BoardColors.from(selected),
                  pops: _pops,
                ),
              ),
              const SizedBox(height: 14),
              for (final theme in BoardTheme.values) ...[
                _ThemeRow(
                  theme: theme,
                  selected: theme == selected,
                  inUse: theme == themes.active,
                  owned: themes.owns(theme),
                  onTap: () => _select(theme),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _Action(
                theme: selected,
                inUse: selected == themes.active,
                owned: themes.owns(selected),
                balance: balance,
                onUse: () => themes.use(selected),
                onBuy: _buy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.colors, required this.pops});

  static const double _maxBoard = 300;

  static final Board _sample = Board(
    size: 5,
    blocks: [
      for (final (index, (row, column, length, direction)) in const [
        (0, 0, 2, Direction.down),
        (0, 1, 2, Direction.right),
        (0, 3, 1, Direction.up),
        (0, 4, 2, Direction.down),
        (1, 1, 2, Direction.left),
        (1, 3, 2, Direction.down),
        (2, 0, 2, Direction.up),
        (2, 1, 1, Direction.right),
        (2, 2, 2, Direction.down),
        (2, 4, 2, Direction.up),
        (3, 1, 1, Direction.left),
        (3, 3, 1, Direction.right),
        (4, 0, 2, Direction.right),
        (4, 2, 1, Direction.down),
        (4, 3, 2, Direction.left),
      ].indexed)
        Block(
          id: index,
          row: row,
          column: column,
          length: length,
          direction: direction,
        ),
    ],
  );

  final BoardColors colors;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedTheme(
        data: Theme.of(context).copyWith(extensions: [colors]),
        duration: Motion.themeSwap,
        child: Builder(
          builder: (context) {
            final shown = BoardColors.of(context);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: shown.background,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Palette.edge, width: 1.5),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = min(
                    _maxBoard,
                    constraints.biggest.shortestSide - 56,
                  );
                  return Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(pops),
                      tween: Tween(begin: pops == 0 ? 1 : 0, end: 1),
                      duration: Motion.themePop,
                      builder: (context, t, child) => Transform.scale(
                        scale: 1 + 0.05 * sin(pi * t),
                        child: child,
                      ),
                      child: SizedBox.square(
                        dimension: max(0, side),
                        child: SurfaceCard(
                          radius: side * 0.09,
                          raised: true,
                          color: shown.board,
                          padding: EdgeInsets.all(side * 0.05),
                          child: MiniBoard(board: _sample),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.theme,
    required this.selected,
    required this.inUse,
    required this.owned,
    required this.onTap,
  });

  final BoardTheme theme;
  final bool selected;
  final bool inUse;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.from(theme);
    final price = Formatting.grouped(theme.price);
    final status = inUse
        ? 'in use'
        : owned
        ? 'owned'
        : 'costs $price coins';
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: Motion.toggle,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected ? Palette.ink : Colors.transparent,
            width: 3,
          ),
        ),
        child: KeyButton(
          height: 62,
          radius: 18,
          padding: const EdgeInsets.fromLTRB(11, 0, 16, 0),
          semanticLabel: '${colors.name}, $status',
          onPressed: onTap,
          child: Row(
            children: [
              _Swatch(colors: colors),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  colors.name,
                  style: AppText.bodyStrong.copyWith(fontSize: 17),
                ),
              ),
              if (inUse)
                const _InUseChip()
              else if (owned)
                Text(
                  'Owned',
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                _Price(price: price, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.colors});

  final BoardColors colors;

  @override
  Widget build(BuildContext context) {
    Widget tile(Color color) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.edge),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile(colors.up),
                const SizedBox(width: 3),
                tile(colors.right),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile(colors.down),
                const SizedBox(width: 3),
                tile(colors.left),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InUseChip extends StatelessWidget {
  const _InUseChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Palette.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 16, color: Palette.mintText),
          const SizedBox(width: 5),
          Text(
            'In use',
            style: AppText.bodyStrong.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Palette.mintText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.price, required this.size});

  final String price;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinGlyph(size: size),
        const SizedBox(width: 5),
        Text(
          price,
          style: AppText.bodyStrong.copyWith(
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.theme,
    required this.inUse,
    required this.owned,
    required this.balance,
    required this.onUse,
    required this.onBuy,
  });

  static const double _height = 62;

  final BoardTheme theme;
  final bool inUse;
  final bool owned;
  final int balance;
  final VoidCallback onUse;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final name = BoardColors.from(theme).name;
    const label = TextStyle(fontSize: 19, fontWeight: FontWeight.w700);
    if (inUse) {
      return _Notice(child: Text('$name is your theme', style: _noticeText));
    }
    if (owned) {
      return KeyButton(
        tone: KeyTone.primary,
        height: _height,
        radius: 20,
        onPressed: onUse,
        child: Text('Use $name', style: label),
      );
    }
    if (balance >= theme.price) {
      final price = Formatting.grouped(theme.price);
      return KeyButton(
        tone: KeyTone.hint,
        height: _height,
        radius: 20,
        semanticLabel: 'Buy $name for $price coins',
        onPressed: onBuy,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Buy $name for', style: label),
            const SizedBox(width: 8),
            _Price(price: price, size: 22),
          ],
        ),
      );
    }
    return _Notice(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${Formatting.grouped(theme.price - balance)} more coins needed',
            style: _noticeText,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 168,
            child: ProgressBar(
              value: balance / theme.price,
              height: 6,
              color: Palette.sun,
              track: Palette.white,
            ),
          ),
        ],
      ),
    );
  }

  static final TextStyle _noticeText = AppText.body.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _Action._height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.line,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
