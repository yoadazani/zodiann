// ZOD-UI-007: ZodiannPressable's four additive parameters for the switch, the
// orb stepper and the body chip: `toggled` and `checked` (semantics),
// `slotAlignment` (where the drawn child sits in the 44 x 44 slot) and
// `focusRingRadius`. Their defaults must leave every existing node and look
// as it was.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';

Widget _pressable({
  bool? toggled,
  bool? checked,
  AlignmentGeometry? slotAlignment,
  double? focusRingRadius,
  Size size = const Size.square(34),
}) => ZodiannPressable(
  onPressed: () {},
  semanticLabel: 'Item',
  toggled: toggled,
  checked: checked,
  slotAlignment: slotAlignment ?? Alignment.center,
  focusRingRadius: focusRingRadius ?? ZodiannRadius.md,
  child: SizedBox.fromSize(size: size, key: const Key('drawn')),
);

void main() {
  testWidgets('toggled marks the node on or off, the default marks neither', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final on in [true, false]) {
      await pumpInApp(tester, _pressable(toggled: on));
      expect(
        tester.getSemantics(find.byType(ZodiannPressable)),
        isSemantics(hasToggledState: true, isToggled: on, isButton: true),
        reason: 'toggled: $on',
      );
    }
    await pumpInApp(tester, _pressable());
    expect(
      tester.getSemantics(find.byType(ZodiannPressable)),
      isSemantics(hasToggledState: false, hasCheckedState: false),
    );
    handle.dispose();
  });

  testWidgets('checked marks the node checked or not, the default neither', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final on in [true, false]) {
      await pumpInApp(tester, _pressable(checked: on));
      expect(
        tester.getSemantics(find.byType(ZodiannPressable)),
        isSemantics(hasCheckedState: true, isChecked: on, isButton: true),
        reason: 'checked: $on',
      );
    }
    handle.dispose();
  });

  testWidgets('slotAlignment places the drawn child inside the 44 slot', (
    tester,
  ) async {
    final slot = find.byType(ZodiannPressable);
    // Default: centred (5 px each side of a 34 px child).
    await pumpInApp(tester, _pressable());
    final slotBox = tester.getRect(slot);
    expect(slotBox.size, const Size.square(44));
    final centred = tester.getTopLeft(find.byKey(const Key('drawn')));
    expect(centred - slotBox.topLeft, const Offset(5, 5));

    await pumpInApp(
      tester,
      _pressable(slotAlignment: AlignmentDirectional.centerStart),
    );
    final start = tester.getTopLeft(find.byKey(const Key('drawn')));
    expect(start - tester.getRect(slot).topLeft, const Offset(0, 5));

    await pumpInApp(
      tester,
      _pressable(slotAlignment: AlignmentDirectional.centerEnd),
      hebrew: true,
    );
    // RTL: the end side is the left edge.
    final end = tester.getTopLeft(find.byKey(const Key('drawn')));
    expect(end - tester.getRect(slot).topLeft, const Offset(0, 5));
  });

  testWidgets('the slot stays 44 x 44 whatever the alignment', (tester) async {
    await pumpInApp(
      tester,
      _pressable(
        slotAlignment: Alignment.centerRight,
        size: const Size(34, 20),
      ),
    );
    final box = tester.renderObject<RenderBox>(find.byType(ZodiannPressable));
    expect(box.size, const Size.square(44));
  });

  testWidgets('focusRingRadius sets the ring corner, the default is 8', (
    tester,
  ) async {
    ZodiannFocusRingPainter painter() =>
        tester
                .widgetList<CustomPaint>(find.byType(CustomPaint))
                .firstWhere(
                  (w) => w.foregroundPainter is ZodiannFocusRingPainter,
                )
                .foregroundPainter!
            as ZodiannFocusRingPainter;

    await pumpInApp(tester, _pressable());
    expect(painter().radius, ZodiannRadius.md);
    await pumpInApp(tester, _pressable(focusRingRadius: 12));
    expect(painter().radius, 12);
  });
}
