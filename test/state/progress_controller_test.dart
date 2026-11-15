import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/chapters.dart';
import 'package:vamoose/state/progress_controller.dart';

import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late ProgressController progress;

  setUp(() {
    store = MemoryStore();
    progress = ProgressController(store, levelCount: 360);
  });

  test('starts at level one with only it unlocked', () {
    expect(progress.currentLevel, 1);
    expect(progress.isUnlocked(1), isTrue);
    expect(progress.isUnlocked(2), isFalse);
    expect(progress.totalStars, 0);
    expect(progress.maxStars, 1080);
  });

  test('clearing a level unlocks the next one', () async {
    await progress.record(1, 3);

    expect(progress.isCleared(1), isTrue);
    expect(progress.currentLevel, 2);
    expect(progress.isUnlocked(2), isTrue);
    expect(progress.isUnlocked(3), isFalse);
  });

  test('keeps the best stars for a level', () async {
    await progress.record(1, 3);
    await progress.record(1, 1);

    expect(progress.starsFor(1), 3);
  });

  test('counts stars and clears per chapter', () async {
    for (var level = 31; level <= 40; level++) {
      await progress.record(level, 2);
    }

    final easy = Chapters.of(31);
    expect(progress.starsIn(easy), 20);
    expect(progress.clearedIn(easy), 10);
    expect(progress.totalStars, 20);
  });

  test('unlocks a chapter once its first level opens', () async {
    for (var level = 1; level <= 30; level++) {
      await progress.record(level, 3);
    }

    expect(progress.isChapterUnlocked(Chapters.of(31)), isTrue);
    expect(progress.isChapterUnlocked(Chapters.of(61)), isFalse);
  });

  test('stays on the last level when everything is cleared', () async {
    for (var level = 1; level <= 360; level++) {
      await progress.record(level, 1);
    }

    expect(progress.currentLevel, 360);
  });

  test('survives a restart', () async {
    await progress.record(1, 2);
    await progress.record(2, 3);

    final reloaded = ProgressController(store, levelCount: 360);

    expect(reloaded.starsFor(1), 2);
    expect(reloaded.starsFor(2), 3);
    expect(reloaded.currentLevel, 3);
  });

  test('reset clears every level', () async {
    await progress.record(1, 3);

    await progress.reset();

    expect(progress.totalStars, 0);
    expect(progress.currentLevel, 1);
    expect(ProgressController(store, levelCount: 360).totalStars, 0);
  });
}
