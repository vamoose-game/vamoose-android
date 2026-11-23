import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/star_rating.dart';

void main() {
  test('a level starts with three stars', () {
    expect(StarRating.forMisses(0), 3);
  });

  test('each miss costs a star', () {
    expect(StarRating.forMisses(1), 2);
    expect(StarRating.forMisses(2), 1);
  });

  test('the third miss takes the last star', () {
    expect(StarRating.forMisses(3), 0);
    expect(StarRating.forMisses(40), 0);
  });
}
