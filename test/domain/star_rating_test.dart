import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/star_rating.dart';

void main() {
  test('no bumps earns three stars', () {
    expect(StarRating.forBumps(0), 3);
  });

  test('one or two bumps earn two stars', () {
    expect(StarRating.forBumps(1), 2);
    expect(StarRating.forBumps(2), 2);
  });

  test('three or more bumps earn one star', () {
    expect(StarRating.forBumps(3), 1);
    expect(StarRating.forBumps(40), 1);
  });
}
