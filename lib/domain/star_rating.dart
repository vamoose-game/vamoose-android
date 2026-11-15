abstract final class StarRating {
  static const int max = 3;

  static int forBumps(int bumps) {
    if (bumps == 0) {
      return 3;
    }
    if (bumps <= 2) {
      return 2;
    }
    return 1;
  }
}
