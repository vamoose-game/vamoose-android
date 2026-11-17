import 'package:flutter_test/flutter_test.dart';
import 'package:vamoose/state/daily_controller.dart';

import '../support/fixed_clock.dart';
import '../support/memory_store.dart';

void main() {
  late MemoryStore store;
  late FixedClock clock;

  DailyController controller() => DailyController(store, clock);

  setUp(() {
    store = MemoryStore();
    clock = FixedClock(DateTime(2026, 11, 15, 17, 47, 20));
  });

  test('starts unsolved', () {
    expect(controller().isTodayCompleted, isFalse);
  });

  test('completing today counts once', () async {
    final daily = controller();

    expect(await daily.completeToday(), isTrue);
    expect(await daily.completeToday(), isFalse);
    expect(daily.isTodayCompleted, isTrue);
  });

  test('a new day brings a new puzzle', () async {
    await controller().completeToday();

    clock.current = DateTime(2026, 11, 16, 8);

    expect(controller().isTodayCompleted, isFalse);
    expect(controller().isCompleted(DateTime(2026, 11, 15)), isTrue);
  });

  test('counts down to the next midnight', () {
    expect(
      controller().timeUntilNextPuzzle,
      const Duration(hours: 6, minutes: 12, seconds: 40),
    );
  });

  test('reset forgets every day', () async {
    final daily = controller();
    await daily.completeToday();

    await daily.reset();

    expect(daily.isTodayCompleted, isFalse);
  });
}
