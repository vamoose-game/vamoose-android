import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/app_services.dart';
import '../../domain/chapter.dart';
import '../../domain/chapters.dart';
import '../../domain/star_rating.dart';
import '../../state/progress_controller.dart';
import '../game/block_marks.dart';
import '../game/countdown_face.dart';
import '../game/game_mode.dart';
import '../game/turn_face.dart';
import '../navigation.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/dashed_box.dart';
import '../widgets/entrance.dart';
import '../widgets/glyphs.dart';
import '../widgets/key_button.dart';
import '../widgets/looping.dart';
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
    final unlocked = progress.isChapterUnlocked(_chapter);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              PageHeader(
                title: 'Levels',
                trailing: Pill(
                  icon: const StarGlyph(size: 20),
                  text: '${progress.totalStars}',
                ),
              ),
              const SizedBox(height: 18),
              _ChapterTabs(
                selected: _chapter,
                isUnlocked: progress.isChapterUnlocked,
                onSelected: (chapter) => setState(() => _chapter = chapter),
              ),
              const SizedBox(height: 14),
              _ChapterSummary(chapter: _chapter, progress: progress),
              const SizedBox(height: 14),
              Expanded(
                child: unlocked
                    ? GridView.builder(
                        key: ValueKey(_chapter.index),
                        padding: const EdgeInsets.only(bottom: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              mainAxisExtent: 60,
                            ),
                        itemCount: Chapter.levelCount,
                        itemBuilder: (context, index) => Entrance(
                          delay: Duration(milliseconds: index * 18),
                          duration: const Duration(milliseconds: 320),
                          offset: const Offset(0, 10),
                          fromScale: 0.92,
                          child: _LevelTile(
                            level: _chapter.firstLevel + index,
                            progress: progress,
                          ),
                        ),
                      )
                    : _LockedChapter(
                        chapter: _chapter,
                        currentLevel: progress.currentLevel,
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
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Chapters.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chapter = Chapters.all[index];
          final unlocked = isUnlocked(chapter);
          final active = chapter.index == selected.index;
          final color = active ? Palette.white : Palette.ink;
          return Semantics(
            button: true,
            selected: active,
            label: unlocked ? chapter.name : '${chapter.name}, locked',
            child: GestureDetector(
              onTap: () => onSelected(chapter),
              child: AnimatedContainer(
                duration: Motion.toggle,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active ? Palette.ink : Palette.white,
                  borderRadius: BorderRadius.circular(23),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!unlocked) ...[
                      Icon(Icons.lock_outline_rounded, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      chapter.name,
                      style: AppText.bodyStrong.copyWith(color: color),
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.name, style: AppText.heading),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${chapter.firstLevel}–${chapter.lastLevel} · ${chapter.boardSize}×${chapter.boardSize}',
                          style: AppText.body.copyWith(fontSize: 15),
                        ),
                        for (final mechanic in _mechanicsIn(context))
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: mechanic,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: StarGlyph(size: 16),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '${progress.starsIn(chapter)} / ${Chapter.levelCount * StarRating.max}',
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ProgressBar(value: cleared / Chapter.levelCount)),
              const SizedBox(width: 10),
              Text(
                '$cleared/${Chapter.levelCount}',
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on _ChapterSummary {
  /// A badge for each mechanic the chapter's levels use.
  List<Widget> _mechanicsIn(BuildContext context) {
    final levels = context.read<AppServices>().levels;
    final boards = [
      for (var level = chapter.firstLevel; level <= chapter.lastLevel; level++)
        levels.byNumber(level).board,
    ];
    return [
      if (boards.any((board) => board.restraints.isNotEmpty))
        Semantics(
          label: 'locks',
          child: const BlockBadge(icon: BadgeIcon.key, size: 22, framed: false),
        ),
      if (boards.any((board) => board.hasTurningBlocks))
        Semantics(
          label: 'turning blocks',
          child: const TurnBadge(size: 22, framed: false),
        ),
      if (boards.any((board) => board.hasCountdowns))
        Semantics(
          label: 'countdown blocks',
          child: const CountdownBadge(count: 3, size: 22, framed: false),
        ),
    ];
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
                size: 16,
                color: Palette.lockedText,
              ),
              const SizedBox(height: 4),
              Text(
                '$level',
                style: AppText.bodyStrong.copyWith(
                  fontSize: 13,
                  color: Palette.lockedText,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!progress.isCleared(level)) {
      return _CurrentTile(level: level);
    }
    return KeyButton(
      height: 60,
      radius: 16,
      padding: EdgeInsets.zero,
      semanticLabel: 'Level $level, ${progress.starsFor(level)} of 3 stars',
      onPressed: () => Navigation.play(context, CampaignMode(level)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$level',
              style: AppText.heading.copyWith(fontSize: 18, height: 1),
            ),
            const SizedBox(height: 5),
            StarsRow(
              stars: progress.starsFor(level),
              size: 11,
              outlined: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentTile extends StatelessWidget {
  const _CurrentTile({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play level $level',
      child: GestureDetector(
        onTap: () => Navigation.play(context, CampaignMode(level)),
        child: Looping(
          period: const Duration(milliseconds: 1800),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$level',
                  style: AppText.heading.copyWith(
                    fontSize: 18,
                    height: 1,
                    color: Palette.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PLAY',
                  style: AppText.label.copyWith(
                    color: Palette.sun,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          builder: (context, t, child) {
            final wave = keyframes(t, const [
              (0, 0),
              (0.5, 1),
              (1, 0),
            ], curve: Curves.easeInOut);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.ink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Palette.ink.withValues(alpha: 0.35 * (1 - wave)),
                    spreadRadius: 6 * wave,
                  ),
                ],
              ),
              child: Center(child: child),
            );
          },
        ),
      ),
    );
  }
}

class _LockedChapter extends StatelessWidget {
  const _LockedChapter({required this.chapter, required this.currentLevel});

  final Chapter chapter;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final previous = Chapters.all[chapter.index - 1];
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: DashedBox(
          color: Palette.muted,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 68,
                      child: KeyButton(
                        height: 68,
                        radius: 22,
                        padding: EdgeInsets.zero,
                        onPressed: null,
                        child: Icon(Icons.lock_outline_rounded, size: 30),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${chapter.name} is locked',
                      style: AppText.heading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Finish ${previous.name} first',
                      style: AppText.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    IntrinsicWidth(
                      child: KeyButton(
                        tone: KeyTone.primary,
                        height: 54,
                        radius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        onPressed: () => Navigation.play(
                          context,
                          CampaignMode(currentLevel),
                        ),
                        child: Text(
                          'Play level $currentLevel',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
