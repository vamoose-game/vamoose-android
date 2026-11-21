import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/star_rating.dart';

void main() {
  test('a level starts with three stars', () {
    expect(StarRating.forBumps(0), 3);
  });

  test('each bump costs a star', () {
    expect(StarRating.forBumps(1), 2);
    expect(StarRating.forBumps(2), 1);
  });

  test('the third bump takes the last star', () {
    expect(StarRating.forBumps(3), 0);
    expect(StarRating.forBumps(40), 0);
  });
}
