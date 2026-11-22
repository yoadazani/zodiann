// ZOD-NAV-002: ZodiannPressable's optional selected state and hint (the
// drawer's active item). The default node must carry no selected state at
// all (in Flutter 3.50 "not selected" is a state of its own), so every
// existing button's accessibility node stays as it was.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/button_harness.dart';

const _box = SizedBox.square(dimension: 40);

Future<void> _pump(
  WidgetTester tester, {
  bool selected = false,
  String? hint,
}) => pumpInApp(
  tester,
  ZodiannPressable(
    onPressed: () {},
    semanticLabel: 'Item',
    selected: selected,
    semanticHint: hint,
    child: _box,
  ),
);

void main() {
  testWidgets('inMutuallyExclusiveGroup marks the node, the default does not', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpInApp(
      tester,
      ZodiannPressable(
        onPressed: () {},
        semanticLabel: 'Item',
        selected: true,
        inMutuallyExclusiveGroup: true,
        child: _box,
      ),
    );
    expect(
      tester.getSemantics(find.byType(ZodiannPressable)),
      isSemantics(isInMutuallyExclusiveGroup: true, isSelected: true),
    );
    await _pump(tester);
    expect(
      tester.getSemantics(find.byType(ZodiannPressable)),
      isNot(isSemantics(isInMutuallyExclusiveGroup: true)),
    );
    handle.dispose();
  });
  testWidgets('selected: true marks the node selected', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, selected: true);
    expect(
      tester.getSemantics(find.byType(ZodiannPressable)),
      isSemantics(
        label: 'Item',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the hint is the node hint', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, hint: 'Planet positions');
    expect(
      tester.getSemantics(find.byType(ZodiannPressable)),
      isSemantics(label: 'Item', hint: 'Planet positions'),
    );
    handle.dispose();
  });

  testWidgets('the default node has no selected state at all', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final node = tester.getSemantics(find.byType(ZodiannPressable));
    expect(node, isNot(isSemantics(hasSelectedState: true)));
    expect(node, isNot(isSemantics(isSelected: true)));
    // Unchanged otherwise: one enabled button with a tap action.
    expect(
      node,
      isSemantics(
        label: 'Item',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
