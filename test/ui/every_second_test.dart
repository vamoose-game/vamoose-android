import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/ui/widgets/every_second.dart';

void main() {
  testWidgets('ticks only while on screen, and catches up on return', (
    tester,
  ) async {
    var ticks = 0;
    Widget countdown({required bool shown}) => TickerMode(
      enabled: shown,
      child: EverySecond(
        onTick: () => ticks++,
        builder: (_) => const SizedBox(),
      ),
    );

    await tester.pumpWidget(countdown(shown: true));
    await tester.pump(const Duration(seconds: 3));
    expect(ticks, 3);

    await tester.pumpWidget(countdown(shown: false));
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 3);

    await tester.pumpWidget(countdown(shown: true));
    await tester.pump(Duration.zero);
    expect(ticks, 4);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 4);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(Duration.zero);
    expect(ticks, 5);
  });
}
