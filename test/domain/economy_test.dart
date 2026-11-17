import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/domain/economy.dart';

void main() {
  test('a first clear pays 10 plus 5 a star', () {
    expect(Economy.levelReward(bestBefore: 0, stars: 3), 25);
    expect(Economy.levelReward(bestBefore: 0, stars: 1), 15);
  });

  test('a replay pays only for new stars', () {
    expect(Economy.levelReward(bestBefore: 2, stars: 3), 5);
    expect(Economy.levelReward(bestBefore: 3, stars: 3), 0);
    expect(Economy.levelReward(bestBefore: 3, stars: 1), 0);
  });
}
