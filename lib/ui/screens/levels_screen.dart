import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/chapter.dart';
import '../../domain/chapters.dart';
import '../../domain/star_rating.dart';
import '../../state/progress_controller.dart';
import '../game/game_mode.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/key_button.dart';
import '../widgets/page_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/stars_row.dart';
import '../widgets/surface_card.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  late Chapter _chapter = Chapters.of(
    context.read<ProgressController>().currentLevel,
  );

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              PageHeader(
                title: 'Levels',
                trailing: Pill(
                  icon: const Icon(
                    Icons.star_rounded,
                    color: Palette.sun,
                    size: 22,
                  ),
                  text: '${progress.totalStars}',
                ),
              ),
              const SizedBox(height: 18),
              _ChapterTabs(
                selected: _chapter,
                isUnlocked: progress.isChapterUnlocked,
                onSelected: (chapter) => setState(() => _chapter = chapter),
              ),
              const SizedBox(height: 16),
              _ChapterSummary(chapter: _chapter, progress: progress),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: Chapter.levelCount,
                  itemBuilder: (context, index) => _LevelTile(
                    level: _chapter.firstLevel + index,
                    progress: progress,
                  ),
                ),
              ),
              const AdBannerSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterTabs extends StatelessWidget {
  const _ChapterTabs({
    required this.selected,
    required this.isUnlocked,
    required this.onSelected,
  });

  final Chapter selected;
  final bool Function(Chapter chapter) isUnlocked;
  final ValueChanged<Chapter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Chapters.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chapter = Chapters.all[index];
          final unlocked = isUnlocked(chapter);
          final active = chapter.index == selected.index;
          return KeyButton(
            tone: active ? KeyTone.primary : KeyTone.secondary,
            height: 50,
            radius: 25,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            semanticLabel: unlocked ? chapter.name : '${chapter.name}, locked',
            onPressed: unlocked ? () => onSelected(chapter) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!unlocked) ...[
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Palette.slate,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  chapter.name,
                  style: AppText.button.copyWith(
                    fontSize: 17,
                    color: active
                        ? Palette.white
                        : (unlocked ? Palette.ink : Palette.slate),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChapterSummary extends StatelessWidget {
  const _ChapterSummary({required this.chapter, required this.progress});

  final Chapter chapter;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final cleared = progress.clearedIn(chapter);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chapter.name,
                  style: AppText.heading.copyWith(fontSize: 22),
                ),
              ),
              const Icon(Icons.star_rounded, color: Palette.sun, size: 22),
              const SizedBox(width: 4),
              Text(
                '${progress.starsIn(chapter)} / ${Chapter.levelCount * StarRating.max}',
                style: AppText.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Levels ${chapter.firstLevel}–${chapter.lastLevel} · ${chapter.boardSize}×${chapter.boardSize} board',
            style: AppText.body,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ProgressBar(value: cleared / Chapter.levelCount)),
              const SizedBox(width: 12),
              Text('$cleared/${Chapter.levelCount}', style: AppText.body),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.progress});

  final int level;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    if (!progress.isUnlocked(level)) {
      return Semantics(
        label: 'Level $level, locked',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.line,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Palette.slate,
              ),
              const SizedBox(height: 4),
              Text('$level', style: AppText.body.copyWith(fontSize: 15)),
            ],
          ),
        ),
      );
    }
    final cleared = progress.isCleared(level);
    return KeyButton(
      tone: cleared ? KeyTone.secondary : KeyTone.primary,
      height: double.infinity,
      radius: 16,
      padding: EdgeInsets.zero,
      semanticLabel: cleared
          ? 'Level $level, ${progress.starsFor(level)} stars'
          : 'Play level $level',
      onPressed: () => Navigation.play(context, CampaignMode(level)),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: AppText.heading.copyWith(
                  color: cleared ? Palette.ink : Palette.white,
                ),
              ),
              const SizedBox(height: 2),
              if (cleared)
                StarsRow(stars: progress.starsFor(level), size: 14)
              else
                Text(
                  'PLAY',
                  style: AppText.label.copyWith(
                    color: Palette.sun,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
