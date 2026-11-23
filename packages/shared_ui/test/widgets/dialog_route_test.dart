// ZOD-UI-013 Task 3: showZodiannDialog. The route opens centred over the
// scrim, closes with null on Escape, a scrim tap and the back button (never
// taking the destructive action), traps focus, restores the focus it
// interrupted, stacks, scrolls, rises above the keyboard and names itself.
import 'dart:ui' show SemanticsAction;

import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';

const _title = 'Delete all data?';

/// The screen under test: an Open button, a button behind the dialog, and
/// counters the dialog's buttons write to.
class _Probe {
  final open = FocusNode(debugLabel: 'open');
  final behind = FocusNode(debugLabel: 'behind');
  // A control outside the navigator, under the extra FocusScope: where Tab
  // would land if it escaped the dialog's scope.
  final outside = FocusNode(debugLabel: 'outside');
  final cancel = FocusNode(debugLabel: 'cancel');
  final delete = FocusNode(debugLabel: 'delete');
  int behindTaps = 0;
  int cancelTaps = 0;
  int deleteCalls = 0;
  bool completed = false;
  bool? result;
  int opens = 0;

  Future<bool?> show(
    BuildContext context, {
    bool barrierDismissible = true,
    Widget? content,
    bool nestable = false,
  }) {
    opens++;
    final future = showZodiannDialog<bool>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => ZodiannDialog(
        title: _title,
        message: 'This cannot be undone.',
        content: content,
        actions: [
          ZodiannButton(
            label: 'Cancel',
            focusNode: cancel,
            onPressed: () {
              cancelTaps++;
              Navigator.of(ctx).pop(false);
            },
          ),
          if (nestable)
            ZodiannButton(
              label: 'Again',
              onPressed: () => showZodiannDialog<void>(
                ctx,
                builder: (inner) => ZodiannDialog(
                  title: 'Second dialog',
                  actions: [
                    ZodiannButton(
                      label: 'Close second',
                      onPressed: () => Navigator.of(inner).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ZodiannButton(
            label: 'Delete',
            focusNode: delete,
            variant: ZodiannButtonVariant.dangerSolid,
            onPressed: () {
              deleteCalls++;
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );
    future.then((v) {
      completed = true;
      result = v;
    });
    return future;
  }

  void dispose() {
    open.dispose();
    behind.dispose();
    outside.dispose();
    cancel.dispose();
    delete.dispose();
  }
}

Future<void> _pumpApp(
  WidgetTester tester,
  _Probe p, {
  ThemeData? theme,
  bool extraScope = false,
  bool barrierDismissible = true,
  Widget? content,
  bool nestable = false,
  Size size = const Size(800, 600),
  Widget Function(Widget)? screen,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final body = Builder(
    builder: (context) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ZodiannButton(
          label: 'Open',
          focusNode: p.open,
          onPressed: () => p.show(
            context,
            barrierDismissible: barrierDismissible,
            content: content,
            nestable: nestable,
          ),
        ),
        ZodiannButton(
          label: 'Behind',
          focusNode: p.behind,
          onPressed: () => p.behindTaps++,
        ),
      ],
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? ZodiannTheme.graphite,
      builder: extraScope
          ? (c, child) => FocusScope(
              child: Column(
                children: [
                  Focus(
                    focusNode: p.outside,
                    child: const SizedBox(width: 10, height: 10),
                  ),
                  Expanded(child: child!),
                ],
              ),
            )
          : null,
      home: Scaffold(body: screen == null ? body : screen(body)),
    ),
  );
}

/// Opens by the keyboard: Tab to the Open button, then Enter.
Future<void> _openByKeyboard(WidgetTester tester, _Probe p) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  expect(p.open.hasPrimaryFocus, isTrue, reason: 'Tab reaches Open first');
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

Future<void> _openByTap(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pump();
}

Rect _dialog(WidgetTester t) => t.getRect(find.byType(ZodiannDialog).first);

void main() {
  setUpAll(loadBundledFonts);

  group('opening', () {
    for (final entry in {
      'Graphite': ZodiannTheme.graphite,
      'Porcelain': ZodiannTheme.porcelain,
    }.entries) {
      testWidgets('opens centred over the scrim (${entry.key})', (
        tester,
      ) async {
        final p = _Probe();
        addTearDown(p.dispose);
        await _pumpApp(tester, p, theme: entry.value);
        await _openByTap(tester);
        expect(find.byType(ZodiannDialog), findsOneWidget);
        final box = _dialog(tester);
        expect(box.center.dx, closeTo(400, 0.5));
        expect(box.center.dy, closeTo(300, 0.5));
        final scrim = entry.value.extension<ZodiannSurfaces>()!.scrim;
        final barriers = tester.widgetList<ModalBarrier>(
          find.byType(ModalBarrier),
        );
        expect(barriers.map((b) => b.color), contains(scrim));
      });
    }

    testWidgets('a result button closes it and the future completes with its '
        'value', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.completed, isTrue);
      expect(p.result, isTrue);
      expect(p.deleteCalls, 1);
    });

    testWidgets('appears and disappears without animation', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await tester.tap(find.text('Open'));
      await tester.pump();
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(ZodiannDialog),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1.0);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
    });
  });

  group('dismissal never takes the action', () {
    testWidgets('Escape completes with null', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      // Nothing is focused inside the dialog: Escape right after opening.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.completed, isTrue);
      expect(p.result, isNull);
      expect(p.deleteCalls + p.cancelTaps, 0);
    });

    testWidgets('the back button completes with null', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.result, isNull);
      expect(p.deleteCalls + p.cancelTaps, 0);
    });

    testWidgets('a tap in the empty area beside, above and below the box '
        'dismisses it', (tester) async {
      for (var i = 0; i < 4; i++) {
        final p = _Probe();
        addTearDown(p.dispose);
        await _pumpApp(tester, p);
        await _openByTap(tester);
        final r = _dialog(tester);
        final point = [
          Offset(r.left - 30, r.center.dy),
          Offset(r.right + 30, r.center.dy),
          Offset(r.center.dx, r.top - 30),
          Offset(r.center.dx, r.bottom + 30),
        ][i];
        await tester.tapAt(point);
        await tester.pump();
        expect(find.byType(ZodiannDialog), findsNothing, reason: 'point $i');
        expect(p.result, isNull, reason: 'point $i');
        expect(p.deleteCalls + p.cancelTaps, 0, reason: 'point $i');
      }
    });

    testWidgets('a tap on a control behind the scrim does not activate it', (
      tester,
    ) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      await tester.tap(find.text('Behind'), warnIfMissed: false);
      await tester.pump();
      expect(p.behindTaps, 0);
    });

    testWidgets('barrierDismissible false ignores Escape and a scrim tap; '
        'buttons still close it', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p, barrierDismissible: false);
      await _openByTap(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsOneWidget);
      final r = _dialog(tester);
      await tester.tapAt(Offset(r.left - 30, r.center.dy));
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.result, isFalse);
    });

    testWidgets('Escape while a ZodiannTextField in the dialog has focus '
        'dismisses it', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(
        tester,
        p,
        content: ZodiannTextField(label: 'Name', autofocus: true),
      );
      await _openByTap(tester);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.result, isNull);
    });
  });

  group('focus', () {
    testWidgets('returns to a keyboard-opened trigger after every way of '
        'closing', (tester) async {
      for (final close in ['cancel', 'escape', 'scrim', 'back', 'delete']) {
        final p = _Probe();
        addTearDown(p.dispose);
        await _pumpApp(tester, p);
        await _openByKeyboard(tester, p);
        expect(find.byType(ZodiannDialog), findsOneWidget);
        switch (close) {
          case 'cancel':
            await tester.tap(find.text('Cancel'));
          case 'delete':
            await tester.tap(find.text('Delete'));
          case 'escape':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          case 'back':
            await tester.binding.handlePopRoute();
          case 'scrim':
            await tester.tapAt(Offset(_dialog(tester).left - 30, 300));
        }
        await tester.pump();
        expect(find.byType(ZodiannDialog), findsNothing, reason: close);
        expect(p.open.hasPrimaryFocus, isTrue, reason: 'after $close');
      }
    });

    testWidgets('returns to the trigger also when it scrolled out of view', (
      tester,
    ) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(
        tester,
        p,
        size: const Size(800, 400),
        screen: (body) => SingleChildScrollView(
          child: Column(children: [body, const SizedBox(height: 1200)]),
        ),
      );
      await _openByKeyboard(tester, p);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(ZodiannDialog), findsNothing);
      expect(p.open.hasPrimaryFocus, isTrue);
    });

    testWidgets('a pointer-opened trigger holds no focus: nothing is left in '
        'the dead dialog scope', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(p.cancel.hasFocus || p.delete.hasFocus, isFalse);
      // Keyboard use still works afterwards.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(p.open.hasPrimaryFocus || p.behind.hasPrimaryFocus, isTrue);
    });

    for (final extra in [false, true]) {
      testWidgets('Tab and Shift+Tab stay inside the dialog'
          '${extra ? ' (inside an extra FocusScope)' : ''}', (tester) async {
        final p = _Probe();
        addTearDown(p.dispose);
        await _pumpApp(tester, p, extraScope: extra);
        await _openByTap(tester);
        final inside = [p.cancel, p.delete];
        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          expect(
            p.open.hasFocus || p.behind.hasFocus || p.outside.hasFocus,
            isFalse,
            reason: 'tab $i',
          );
          expect(
            inside.any((n) => n.hasPrimaryFocus),
            isTrue,
            reason: 'tab $i',
          );
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          expect(
            p.open.hasFocus || p.behind.hasFocus || p.outside.hasFocus,
            isFalse,
            reason: 'back $i',
          );
          expect(
            inside.any((n) => n.hasPrimaryFocus),
            isTrue,
            reason: 'back $i',
          );
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      });
    }
  });

  group('stacking, layout and semantics', () {
    testWidgets('a second dialog stacks, and closing it returns to the first', (
      tester,
    ) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p, nestable: true);
      await _openByTap(tester);
      await tester.tap(find.text('Again'));
      await tester.pump();
      expect(find.text('Second dialog'), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Second dialog'), findsNothing);
      expect(find.text(_title), findsOneWidget);
      expect(p.completed, isFalse, reason: 'the first is still open');
      // The first is still focus-trapped.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(p.open.hasFocus || p.behind.hasFocus, isFalse);
      }
    });

    testWidgets('rises above the keyboard', (tester) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p, content: ZodiannTextField(label: 'Name'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await _openByTap(tester);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_dialog(tester).bottom, lessThanOrEqualTo(600 - 300 + 0.5));
    });

    testWidgets('scrolls instead of overflowing in a short viewport', (
      tester,
    ) async {
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(
        tester,
        p,
        size: const Size(800, 260),
        content: const SizedBox(height: 300),
      );
      await _openByTap(tester);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Delete'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(Overlay),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(p.result, isTrue);
    });

    testWidgets('the route scopes and names itself, the scrim adds no node and '
        'the screen behind is blocked', (tester) async {
      final handle = tester.ensureSemantics();
      final p = _Probe();
      addTearDown(p.dispose);
      await _pumpApp(tester, p);
      await _openByTap(tester);
      await tester.pump();
      final nodes = <SemanticsNode>[];
      void walk(SemanticsNode n) {
        nodes.add(n);
        n.visitChildren((c) {
          walk(c);
          return true;
        });
      }

      // The root owner has no semantics in flutter_test; this accessor does.
      // ignore: deprecated_member_use
      walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      final scopes = nodes.where(
        (n) => n.getSemanticsData().flagsCollection.scopesRoute,
      );
      expect(scopes, isNotEmpty);
      final named = nodes.where(
        (n) =>
            n.getSemanticsData().flagsCollection.namesRoute &&
            n.label == _title,
      );
      expect(named, isNotEmpty);
      expect(
        nodes.any(
          (n) => n.getSemanticsData().hasAction(SemanticsAction.dismiss),
        ),
        isFalse,
        reason: 'the scrim must not add a dismiss node',
      );
      expect(
        nodes.any((n) => n.label == 'Open'),
        isFalse,
        reason: 'the screen behind the dialog is blocked from assistive tech',
      );
      handle.dispose();
    });
  });
}
