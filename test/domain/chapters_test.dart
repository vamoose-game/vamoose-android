import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/chapter.dart';
import 'package:vamoose/domain/chapters.dart';

void main() {
  test('twelve chapters hold 360 levels', () {
    expect(Chapters.all, hasLength(12));
    expect(Chapters.levelCount, 360);
  });

  test('chapters cover consecutive level ranges', () {
    for (final chapter in Chapters.all) {
      expect(chapter.firstLevel, chapter.index * Chapter.levelCount + 1);
      expect(chapter.lastLevel - chapter.firstLevel + 1, Chapter.levelCount);
    }
  });

  test('finds the chapter of a level', () {
    expect(Chapters.of(1).name, 'Warm-up');
    expect(Chapters.of(41).name, 'Easy');
    expect(Chapters.of(41).boardSize, 6);
    expect(Chapters.of(61).name, 'Steady');
    expect(Chapters.of(360).name, 'Zen');
  });

  test('board sizes never shrink', () {
    for (var index = 1; index < Chapters.all.length; index++) {
      expect(
        Chapters.all[index].boardSize,
        greaterThanOrEqualTo(Chapters.all[index - 1].boardSize),
      );
    }
  });
}
