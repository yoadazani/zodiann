// ZOD-UI-013 Task 2: ZodiannDialog, the box. Width, padding, radius, the
// title and message styles, the gaps, the end-aligned actions, wrapping,
// text scale, the floating shadow and the route name. The route (scrolling,
// the keyboard inset, dismissal and focus) is Task 3.
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';

const _title = 'Delete all data?';
const _message =
    'Your settings and 7 saved squares will be removed from this '
    'device. This cannot be undone. Export a backup first if you may need '
    'them.';

List<Widget> _buttons() => [
  ZodiannButton(label: 'Cancel', onPressed: () {}),
  ZodiannButton(
    label: 'Delete all data',
    variant: ZodiannButtonVariant.dangerSolid,
    onPressed: () {},
  ),
];

Future<void> _pump(
  WidgetTester tester,
  Widget dialog, {
  Size size = const Size(1000, 800),
  EdgeInsets margin = EdgeInsets.zero,
  Widget Function(Widget)? around,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Theme(
      data: theme ?? ZodiannTheme.graphite,
      child: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: margin,
                child: around == null ? dialog : around(dialog),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _delete({List<Widget>? actions, String? message = _message}) =>
    ZodiannDialog(
      title: _title,
      message: message,
      actions: actions ?? _buttons(),
    );

Rect _rect(WidgetTester t, Finder f) => t.getRect(f);

void main() {
  setUpAll(loadBundledFonts);

  group('box', () {
    testWidgets('is 420 wide with 24 padding and a 16 radius', (tester) async {
      await _pump(tester, _delete());
      final box = _rect(tester, find.byType(ZodiannDialog));
      expect(box.width, ZodiannSize.dialogWidth);
      final title = _rect(tester, find.text(_title));
      expect(title.left - box.left, ZodiannSpace.s6);
      expect(title.top - box.top, ZodiannSpace.s6);
      final deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(ZodiannDialog),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.borderRadius, ZodiannRadius.dialog);
      expect(
        deco.color,
        ZodiannTheme.graphite.extension<ZodiannSurfaces>()!.surface,
      );
    });

    testWidgets('fills a tight parent up to 420 and a loose one to 420', (
      tester,
    ) async {
      await _pump(
        tester,
        _delete(),
        around: (d) => SizedBox(width: 300, child: d),
      );
      expect(_rect(tester, find.byType(ZodiannDialog)).width, 300);
      await _pump(tester, _delete(), margin: const EdgeInsets.all(16));
      expect(_rect(tester, find.byType(ZodiannDialog)).width, 420);
      // Handed less than 420 (a 300 wide screen less 16 each side), it takes
      // what it is given.
      await _pump(
        tester,
        _delete(),
        size: const Size(300, 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(_rect(tester, find.byType(ZodiannDialog)).width, 268);
    });

    testWidgets('the title is dialogTitle in text; the message is body in '
        'text-2', (tester) async {
      final theme = ZodiannTheme.graphite;
      final s = theme.extension<ZodiannSurfaces>()!;
      final styles = theme.extension<ZodiannTextStyles>()!;
      await _pump(tester, _delete());
      final title = tester.widget<Text>(find.text(_title)).style!;
      expect(title.fontSize, styles.dialogTitle.fontSize);
      expect(title.fontWeight, styles.dialogTitle.fontWeight);
      expect(title.height, styles.dialogTitle.height);
      expect(title.color, s.text);
      final message = tester.widget<Text>(find.text(_message)).style!;
      expect(message.fontSize, styles.body.fontSize);
      expect(message.color, s.text2);
    });

    testWidgets('the gaps are 8 title to message, 24 to the actions, 8 '
        'between buttons', (tester) async {
      await _pump(tester, _delete());
      final title = _rect(tester, find.text(_title));
      final message = _rect(tester, find.text(_message));
      // Text boxes are the line boxes (the role's height multiplier).
      expect(message.top - title.bottom, ZodiannSpace.s2);
      final buttons = find.byType(ZodiannButton);
      final cancel = _rect(tester, buttons.at(0));
      final danger = _rect(tester, buttons.at(1));
      expect(danger.left - cancel.right, ZodiannSpace.s2);
      // The button's tap box is at least 44, drawn 40: compare the drawn box.
      final drawnTop =
          _rect(tester, buttons.at(0)).center.dy - ZodiannSize.control / 2;
      expect(drawnTop - message.bottom, closeTo(ZodiannSpace.s6, 0.01));
      // ...and the drawn buttons end 24 above the box's bottom edge.
      final box = _rect(tester, find.byType(ZodiannDialog));
      expect(
        box.bottom - (cancel.center.dy + ZodiannSize.control / 2),
        closeTo(ZodiannSpace.s6, 0.01),
      );
    });

    testWidgets('no message and no content: the actions follow the title at '
        '24', (tester) async {
      await _pump(tester, _delete(message: null));
      final title = _rect(tester, find.text(_title));
      final cancel = _rect(tester, find.byType(ZodiannButton).first);
      final drawnTop = cancel.center.dy - ZodiannSize.control / 2;
      expect(drawnTop - title.bottom, closeTo(ZodiannSpace.s6, 0.01));
    });

    testWidgets('content sits 16 below the message and 24 above the actions', (
      tester,
    ) async {
      await _pump(
        tester,
        ZodiannDialog(
          title: 'Save square',
          message: 'Saves the mode, anchor, size and highlights.',
          content: const SizedBox(key: Key('content'), height: 40),
          actions: _buttons(),
        ),
      );
      final message = _rect(
        tester,
        find.text('Saves the mode, anchor, size and highlights.'),
      );
      final content = _rect(tester, find.byKey(const Key('content')));
      expect(content.top - message.bottom, ZodiannSpace.s4);
      final cancel = _rect(tester, find.byType(ZodiannButton).first);
      expect(
        cancel.center.dy - ZodiannSize.control / 2 - content.bottom,
        closeTo(ZodiannSpace.s6, 0.01),
      );
    });
  });

  group('actions', () {
    testWidgets('sit at the end edge, first action nearest the start (LTR)', (
      tester,
    ) async {
      await _pump(tester, _delete());
      final box = _rect(tester, find.byType(ZodiannDialog));
      final cancel = _rect(tester, find.byType(ZodiannButton).at(0));
      final danger = _rect(tester, find.byType(ZodiannButton).at(1));
      expect(danger.right, closeTo(box.right - ZodiannSpace.s6, 0.01));
      expect(cancel.right, lessThan(danger.left));
    });

    testWidgets('sit at the end edge, first action nearest the start (RTL)', (
      tester,
    ) async {
      await _pump(tester, _delete(), direction: TextDirection.rtl);
      final box = _rect(tester, find.byType(ZodiannDialog));
      final cancel = _rect(tester, find.byType(ZodiannButton).at(0));
      final danger = _rect(tester, find.byType(ZodiannButton).at(1));
      expect(danger.left, closeTo(box.left + ZodiannSpace.s6, 0.01));
      expect(cancel.left, greaterThan(danger.right));
      // Title and message start at the right edge in RTL.
      final title = _rect(tester, find.text(_title));
      expect(title.right, closeTo(box.right - ZodiannSpace.s6, 0.01));
    });

    testWidgets('a button row wider than the box wraps', (tester) async {
      await _pump(
        tester,
        ZodiannDialog(
          title: _title,
          actions: [
            ZodiannButton(label: 'A rather long first label', onPressed: () {}),
            ZodiannButton(label: 'A rather long second one', onPressed: () {}),
          ],
        ),
        size: const Size(400, 800),
        margin: const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(tester.takeException(), isNull);
      final first = _rect(tester, find.byType(ZodiannButton).at(0));
      final second = _rect(tester, find.byType(ZodiannButton).at(1));
      expect(second.top, greaterThan(first.top));
    });
  });

  group('text scale and shadow', () {
    testWidgets('2x text wraps the message and the box grows', (tester) async {
      await _pump(tester, _delete());
      final normal = _rect(tester, find.byType(ZodiannDialog)).height;
      await _pump(tester, _delete(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(
        _rect(tester, find.byType(ZodiannDialog)).height,
        greaterThan(normal),
      );
      expect(_rect(tester, find.byType(ZodiannDialog)).width, 420);
    });

    for (final entry in {
      'Graphite': ZodiannTheme.graphite,
      'Porcelain': ZodiannTheme.porcelain,
    }.entries) {
      testWidgets('the floating shadow and the outside outline are painted '
          '(${entry.key})', (tester) async {
        final elevation = entry.value.extension<ZodiannElevation>()!;
        await _pump(tester, _delete(), theme: entry.value);
        final deco =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(ZodiannDialog),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final shadows = deco.boxShadow!;
        for (final floating in elevation.floating) {
          expect(shadows, contains(floating));
        }
        final ring = shadows.where(
          (s) =>
              s.color == elevation.floatingOutline.color &&
              s.spreadRadius == elevation.floatingOutline.width &&
              s.blurRadius == 0,
        );
        expect(ring, hasLength(1), reason: 'the 1 px outline ring');
        expect(
          deco.border,
          isNull,
          reason: 'the ring is outside, not a border',
        );
      });
    }
  });

  group('semantics and asserts', () {
    testWidgets('the box names the route and the title is a header', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _delete());
      final box = tester.getSemantics(find.byType(ZodiannDialog));
      expect(box, isSemantics(label: _title, namesRoute: true));
      SemanticsNode titleNode = tester.getSemantics(find.text(_title));
      expect(titleNode, isSemantics(label: _title, isHeader: true));
      handle.dispose();
    });

    test('an empty actions list asserts', () {
      expect(
        () => ZodiannDialog(title: _title, actions: const []),
        throwsAssertionError,
      );
    });
  });
}
