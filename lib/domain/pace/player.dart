import 'dart:math';

/// How one simulated person plays.
final class Player {
  const Player({required this.think, required this.hand, required this.slip});

  /// Multiplies the time spent looking and deciding. 1 is a typical newcomer.
  final double think;

  /// Multiplies the time the finger takes to reach a block.
  final double hand;

  /// The chance of misreading a blocked path as clear while looking at it.
  final double slip;

  /// The same person after playing [levels] levels. Looking and deciding
  /// speed up the most with practice, following the power law of practice,
  /// and each skill has a floor it never goes below.
  Player practiced(int levels) => Player(
    think: think * _practice(levels, floor: 0.45, pace: 10),
    hand: hand * _practice(levels, floor: 0.85, pace: 20),
    slip: slip * _practice(levels, floor: 0.6, pace: 25),
  );

  /// The same person on a later try at the same board: they remember part of
  /// it, so they look less and misread less.
  Player retrying(int earlierTries) => earlierTries == 0
      ? this
      : Player(
          think: think * max(0.72, pow(0.86, earlierTries).toDouble()),
          hand: hand,
          slip: slip * pow(0.8, earlierTries),
        );

  static double _practice(
    int levels, {
    required double floor,
    required double pace,
  }) => floor + (1 - floor) / sqrt(1 + levels / pace);
}

/// The crowd of people the timer is tuned for.
abstract final class Crowd {
  /// Spread of the natural log of [Player.think], [Player.hand] and
  /// [Player.slip] between people.
  static const double thinkSpread = 0.28;
  static const double handSpread = 0.15;
  static const double slipSpread = 0.55;
  static const double typicalSlip = 0.075;

  /// [count] newcomers whose skills cover the population evenly: each skill
  /// is drawn from evenly spaced quantiles of a log-normal distribution and
  /// the three are paired at random (Latin hypercube sampling), so a small
  /// crowd still represents everyone from the fastest to the slowest.
  static List<Player> sample(int count, Random random) {
    List<double> spread(double sigma) => [
      for (var index = 0; index < count; index++)
        exp(sigma * _normalQuantile((index + 0.5) / count)),
    ]..shuffle(random);
    final think = spread(thinkSpread);
    final hand = spread(handSpread);
    final slip = spread(slipSpread);
    return [
      for (var index = 0; index < count; index++)
        Player(
          think: think[index],
          hand: hand[index],
          slip: (typicalSlip * slip[index]).clamp(0.004, 0.2),
        ),
    ];
  }

  /// The inverse of the standard normal distribution (Acklam's rational
  /// approximation, accurate to about 1e-9).
  static double _normalQuantile(double p) {
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];
    const low = 0.02425;
    if (p < low || p > 1 - low) {
      final q = sqrt(-2 * log(p < low ? p : 1 - p));
      final x =
          (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
      return p < low ? x : -x;
    }
    final q = p - 0.5;
    final r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
            a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }
}
