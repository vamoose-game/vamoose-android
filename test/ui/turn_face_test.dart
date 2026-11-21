import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vamoose/domain/direction.dart';
import 'package:vamoose/ui/game/turn_face.dart';

void main() {
  Widget face(Direction direction) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: SizedBox.square(
        dimension: 60,
        child: TurnFace(direction: direction),
      ),
    ),
  );

  testWidgets('a turn that cuts into another carries on from where it got', (
    tester,
  ) async {
    double quarters() =>
        tester.widget<RoundFace>(find.byType(RoundFace)).quarters;

    await tester.pumpWidget(face(Direction.up));
    expect(quarters(), 0);

    await tester.pumpWidget(face(Direction.right));
    await tester.pump(const Duration(milliseconds: 250));
    final midway = quarters();
    expect(midway, inExclusiveRange(0, 1.3));

    await tester.pumpWidget(face(Direction.down));
    expect(quarters(), closeTo(midway, 1e-9));

    await tester.pump(const Duration(milliseconds: 600));
    expect(quarters(), 2);
  });
}
