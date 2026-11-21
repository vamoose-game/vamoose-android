import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/ui/formatting.dart';

void main() {
  test('a wait rounds up, so 0:00 shows only once it is over', () {
    expect(Formatting.clockLeft(const Duration(minutes: 20)), '20:00');
    expect(
      Formatting.clockLeft(const Duration(minutes: 19, milliseconds: 59100)),
      '20:00',
    );
    expect(Formatting.clockLeft(const Duration(milliseconds: 300)), '0:01');
    expect(Formatting.clockLeft(Duration.zero), '0:00');
    expect(Formatting.clockLeft(const Duration(seconds: -2)), '0:00');
  });
}
