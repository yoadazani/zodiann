// ZOD-UI-003: MASTER.md §4's per-breakpoint layout values and §6's
// breakpoint boundaries (phone < 700, tablet 700–1099, desktop ≥ 1100).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('phone values are 16/16/16/52 and tablet/desktop values are '
      '24/20/20/56', () {
    const phone = ZodiannLayout.phone;
    expect(phone.gutter, 16);
    expect(phone.panelGap, 16);
    expect(phone.panelPadding, 16);
    expect(phone.panelHeadHeight, 52);

    const regular = ZodiannLayout.regular;
    expect(regular.gutter, 24);
    expect(regular.panelGap, 20);
    expect(regular.panelPadding, 20);
    expect(regular.panelHeadHeight, 56);
  });

  test('breakpoint boundaries', () {
    for (final w in [0.0, 699.9]) {
      expect(
        ZodiannBreakpoint.forWidth(w),
        ZodiannBreakpoint.phone,
        reason: '$w',
      );
    }
    for (final w in [700.0, 1099.9]) {
      expect(
        ZodiannBreakpoint.forWidth(w),
        ZodiannBreakpoint.tablet,
        reason: '$w',
      );
    }
    for (final w in [1100.0, 1440.0, 2560.0]) {
      expect(
        ZodiannBreakpoint.forWidth(w),
        ZodiannBreakpoint.desktop,
        reason: '$w',
      );
    }
    expect(ZodiannLayout.forWidth(699.9), ZodiannLayout.phone);
    expect(ZodiannLayout.forWidth(700), ZodiannLayout.regular);
    expect(ZodiannLayout.forWidth(1100), ZodiannLayout.regular);
  });

  test('layouts compare by value', () {
    const a = ZodiannLayout(
      gutter: 16,
      panelGap: 16,
      panelPadding: 16,
      panelHeadHeight: 52,
    );
    expect(a, ZodiannLayout.phone);
    expect(a.hashCode, ZodiannLayout.phone.hashCode);
    expect(a, isNot(ZodiannLayout.regular));
  });

  Future<ZodiannLayout> layoutAt(WidgetTester tester, Size size) async {
    late ZodiannLayout seen;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            seen = ZodiannLayout.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return seen;
  }

  testWidgets('of(context) follows MediaQuery', (tester) async {
    expect(await layoutAt(tester, const Size(390, 844)), ZodiannLayout.phone);
    expect(
      await layoutAt(tester, const Size(1440, 900)),
      ZodiannLayout.regular,
    );
  });
}
