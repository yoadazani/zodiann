// ZOD-NAV-002: showZodiannDrawer: the route's motion (MASTER §12: 240 ms in,
// 180 ms out, easeOutCubic both ways), the scrim in step with the panel, the
// four ways to close, the swipe gesture, reduced motion, hit testing, semantics
// and the interrupted-gesture cases. The sampled fractions are literal:
// Curves.easeOutCubic is Cubic(0.215, 0.61, 0.355, 1.0), not 1 − (1 − t)³.
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';

/// What the harness counts.
class _H {
  int menu = 0;
  int body = 0;
  bool he = false;
}

List<ZodiannDrawerGroup> _groups() => [
  ZodiannDrawerGroup(
    label: 'Analysis',
    items: [
      ZodiannDrawerItem(
        icon: ZodiannIcons.wheel,
        name: 'Zodiac wheel',
        description: 'Planet positions',
        selected: true,
        onTap: () {},
      ),
      ZodiannDrawerItem(
        icon: ZodiannIcons.grid,
        name: 'Gann Square of Nine',
        description: 'Numbers',
        selected: false,
        onTap: () {},
      ),
    ],
  ),
];

void _show(BuildContext context) => showZodiannDrawer(
  context,
  builder: (ctx) => ZodiannDrawer(
    wordmark: 'Zodiann',
    groups: _groups(),
    closeLabel: 'Close menu',
    onClose: () => Navigator.of(ctx).maybePop(),
    versionLabel: 'Version 1.0.0',
    offlineLabel: 'All data stays on this device',
  ),
);

Future<void> _pump(
  WidgetTester tester,
  _H h, {
  bool dark = true,
  bool reduce = false,
  bool nested = false,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final base = dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;
  Widget home = Builder(
    builder: (context) => Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(ZodiannSize.topBar),
        child: ZodiannTopBar(
          title: 'Title',
          subtitle: 'Subtitle',
          menuLabel: 'Open menu',
          onMenuPressed: () {
            h.menu++;
            _show(context);
          },
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: ZodiannButton(
          label: 'Body button',
          variant: ZodiannButtonVariant.secondary,
          onPressed: () => h.body++,
        ),
      ),
    ),
  );
  if (nested) {
    final inner = home;
    home = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => inner),
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base,
      builder: (context, child) {
        Widget c = MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        );
        if (h.he) {
          c = Theme(
            data: withZodiannScript(Theme.of(context), ZodiannScript.hebrew),
            child: Directionality(textDirection: TextDirection.rtl, child: c),
          );
        }
        return c;
      },
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _menuButton() => find.byType(ZodiannIconButton).first;

Finder _closeButton() => find.descendant(
  of: find.byType(ZodiannDrawer),
  matching: find.byType(ZodiannIconButton),
);

/// Opens with the hamburger and runs the first frame (time zero).
Future<void> _open(WidgetTester tester) async {
  await tester.tap(_menuButton());
  await tester.pump();
}

/// How far open the panel is, 0..1 (the panel is 320 wide at 1440).
double _fraction(WidgetTester tester, bool he) {
  final rect = tester.getRect(find.byType(ZodiannDrawer));
  return he ? (1440 - rect.left) / 320 : rect.right / 320;
}

Color _scrim(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ZodiannDrawer)))
        .extension<ZodiannSurfaces>()!
        .scrim;

Color? _barrierColor(WidgetTester tester) => tester
    .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier))
    .color
    .value;

/// The scrim's alpha is the panel's open fraction × the theme's scrim alpha
/// and its RGB is the scrim's RGB (so it fades the scrim colour, not black).
void _expectScrimInStep(WidgetTester tester, bool he, {String? reason}) {
  final f = _fraction(tester, he);
  final scrim = _scrim(tester);
  final c = _barrierColor(tester)!;
  expect(c.a, closeTo(scrim.a * f, 0.01), reason: 'alpha $reason');
  if (f > 0.05) {
    expect(c.r, closeTo(scrim.r, 1e-3), reason: 'r $reason');
    expect(c.g, closeTo(scrim.g, 1e-3), reason: 'g $reason');
    expect(c.b, closeTo(scrim.b, 1e-3), reason: 'b $reason');
  }
}

NavigatorState _root(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

/// The labels a screen reader can reach (the simulated traversal).
Set<String> _labels(WidgetTester tester) => {
  for (final node in tester.semantics.simulatedAccessibilityTraversal())
    if (node.label.isNotEmpty) node.label,
};

/// A drag with timestamps; [toStart] gives the dx toward the start edge.
class _Drag {
  _Drag(this.tester, this.he, this.gesture);
  final WidgetTester tester;
  final bool he;
  final TestGesture gesture;
  int _t = 0;

  static Future<_Drag> start(WidgetTester tester, bool he, Offset at) async =>
      _Drag(tester, he, await tester.startGesture(at));

  /// Moves [dx] toward the start edge (negative: toward the open side).
  Future<void> toward(double dx, {int ms = 100}) async {
    _t += ms;
    await gesture.moveBy(
      Offset(he ? dx : -dx, 0),
      timeStamp: Duration(milliseconds: _t),
    );
    await tester.pump();
  }

  Future<void> up({int ms = 100}) async {
    _t += ms;
    await gesture.up(timeStamp: Duration(milliseconds: _t));
  }
}

void main() {
  setUpAll(loadBundledFonts);

  group('motion', () {
    testWidgets('opens in 240 ms along easeOutCubic', (tester) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      expect(_fraction(tester, false), closeTo(0, 0.01));
      for (final (ms, expected) in [(60, 0.600), (60, 0.875), (60, 0.976)]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(
          _fraction(tester, false),
          closeTo(expected, 0.01),
          reason: '$ms',
        );
      }
      await tester.pump(const Duration(milliseconds: 60));
      expect(_fraction(tester, false), closeTo(1.0, 1e-6));
    });

    testWidgets('closes in 180 ms and eases out (the curve is flipped)', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(_closeButton());
      await tester.pump();
      for (final (ms, expected) in [(45, 0.400), (45, 0.125), (45, 0.024)]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(
          _fraction(tester, false),
          closeTo(expected, 0.01),
          reason: '$ms',
        );
      }
      // 180 ms: fully closed (the entry itself is removed a frame later).
      await tester.pump(const Duration(milliseconds: 45));
      if (find.byType(ZodiannDrawer).evaluate().isNotEmpty) {
        expect(_fraction(tester, false), closeTo(0, 1e-6));
      }
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
    });

    for (final dark in [true, false]) {
      testWidgets('the scrim fades in step with the panel '
          '(${dark ? 'graphite' : 'porcelain'})', (tester) async {
        final h = _H();
        await _pump(tester, h, dark: dark);
        await _open(tester);
        for (var i = 1; i <= 4; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          _expectScrimInStep(tester, false, reason: 'open $i');
        }
        await tester.pumpAndSettle();
        _expectScrimInStep(tester, false, reason: 'open');
        await tester.tap(_closeButton());
        await tester.pump();
        for (var i = 1; i <= 3; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          _expectScrimInStep(tester, false, reason: 'close $i');
        }
      });
    }

    testWidgets('reduced motion: open and close are immediate', (tester) async {
      final h = _H();
      await _pump(tester, h, reduce: true);
      await _open(tester);
      expect(_fraction(tester, false), closeTo(1.0, 1e-6));
      await tester.tap(_closeButton());
      await tester.pump();
      await tester.pump();
      expect(find.byType(ZodiannDrawer), findsNothing);
    });
  });

  for (final he in [false, true]) {
    final lang = he ? 'RTL' : 'LTR';
    // A point outside the panel, and one on it.
    final outside = Offset(he ? 400 : 1000, 450);
    final onPanel = Offset(he ? 1340 : 100, 450);

    group('the four closes ($lang)', () {
      testWidgets('a backdrop tap closes', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.tapAt(outside);
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('the close button closes', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.tap(_closeButton());
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('a swipe toward the start edge closes', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(ZodiannDrawer),
          Offset(he ? 300 : -300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('the Android back button closes', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('a tap on the panel does not close it', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.tapAt(onPanel);
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
      });

      testWidgets('a swipe toward the open side does nothing', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(ZodiannDrawer),
          Offset(he ? -300 : 300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
        expect(_fraction(tester, he), closeTo(1.0, 1e-6));
      });
    });

    group('the swipe gesture ($lang)', () {
      testWidgets('follows the finger 1:1 and keeps the scrim in step', (
        tester,
      ) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        final f1 = _fraction(tester, he);
        _expectScrimInStep(tester, he, reason: 'drag 1');
        await drag.toward(40);
        final f2 = _fraction(tester, he);
        _expectScrimInStep(tester, he, reason: 'drag 2');
        // After the drag has started, 40 px of finger is 40 px of panel
        // (linear: not drawn through the curve).
        expect(f1 - f2, closeTo(40 / 320, 1e-6));
        await drag.up();
        await tester.pumpAndSettle();
      });

      testWidgets('never moves past fully open', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        await drag.toward(-300);
        expect(_fraction(tester, he), closeTo(1.0, 1e-6));
        await drag.up();
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
      });

      testWidgets('a slow release below halfway closes, without a jump', (
        tester,
      ) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        while (_fraction(tester, he) > 0.3) {
          await drag.toward(10);
        }
        final before = tester.getRect(find.byType(ZodiannDrawer));
        await drag.up();
        await tester.pump();
        final after = tester.getRect(find.byType(ZodiannDrawer));
        expect((after.left - before.left).abs(), lessThan(1.0));
        await tester.pump(const Duration(milliseconds: 20));
        _expectScrimInStep(tester, he, reason: 'settle');
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('a slow release above halfway settles open', (tester) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        while (_fraction(tester, he) > 0.7) {
          await drag.toward(10);
        }
        await drag.up();
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
        expect(_fraction(tester, he), closeTo(1.0, 1e-6));
      });

      testWidgets('a fling decides by its direction first', (tester) async {
        // 30 % open, then a fast flick toward the open side: settles open.
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        var drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        while (_fraction(tester, he) > 0.3) {
          await drag.toward(10);
        }
        for (var i = 0; i < 4; i++) {
          await drag.toward(-20, ms: 10);
        }
        await drag.up(ms: 10);
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
        expect(_fraction(tester, he), closeTo(1.0, 1e-6));

        // 70 % open, then a fast flick toward the start: closes.
        drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        while (_fraction(tester, he) > 0.7) {
          await drag.toward(10);
        }
        for (var i = 0; i < 4; i++) {
          await drag.toward(20, ms: 10);
        }
        await drag.up(ms: 10);
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
      });

      testWidgets('dragging to the closed edge and releasing leaves no route', (
        tester,
      ) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, onPanel);
        await drag.toward(kTouchSlop + 12);
        await drag.toward(600);
        expect(_fraction(tester, he), closeTo(0, 1e-6));
        await drag.up();
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(_root(tester).canPop(), isFalse);
      });

      testWidgets('a drag that starts on the scrim also moves the panel', (
        tester,
      ) async {
        final h = _H()..he = he;
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        final drag = await _Drag.start(tester, he, outside);
        await drag.toward(kTouchSlop + 12);
        await drag.toward(100);
        expect(_fraction(tester, he), lessThan(0.75));
        await drag.up();
        await tester.pumpAndSettle();
      });
    });
  }

  group('the top bar and hit testing', () {
    testWidgets(
      'the top bar is behind the scrim; the panel covers the burger',
      (tester) async {
        final h = _H();
        await _pump(tester, h);
        await _open(tester);
        await tester.pumpAndSettle();
        expect(h.menu, 1);
        // The hamburger's position is on the panel (the panel stays open and
        // the bar's button gets no tap).
        await tester.tapAt(const Offset(35, 32));
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsOneWidget);
        expect(h.menu, 1);
        // The title area is outside the panel: it hits the scrim and closes.
        await tester.tapAt(const Offset(800, 32));
        await tester.pumpAndSettle();
        expect(find.byType(ZodiannDrawer), findsNothing);
        expect(h.menu, 1);
      },
    );

    testWidgets('the screen behind gets no taps while open', (tester) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Body button'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.body, 0);
      expect(find.byType(ZodiannDrawer), findsNothing);
    });

    testWidgets('the route is on the root navigator', (tester) async {
      final h = _H();
      await _pump(tester, h, nested: true);
      final navs = find.byType(Navigator);
      expect(navs, findsNWidgets(2));
      await _open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      expect(_root(tester).canPop(), isTrue);
      expect(tester.state<NavigatorState>(navs.last).canPop(), isFalse);
    });
  });

  group('semantics', () {
    testWidgets('the panel is the only accessible content', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _H();
      await _pump(tester, h);
      expect(_labels(tester), contains('Open menu'));
      await _open(tester);
      await tester.pumpAndSettle();
      final labels = _labels(tester);
      expect(labels, containsAll(['Close menu', 'Zodiac wheel']));
      // The screen behind is blocked; the scrim adds no node of its own.
      expect(labels, isNot(contains('Open menu')));
      expect(labels, isNot(contains('Body button')));
      handle.dispose();
    });

    testWidgets('the scrim still closes on a tap without semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1000, 450));
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      handle.dispose();
    });
  });

  group('review focus', () {
    testWidgets('two calls from the same context leave one route', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      final context = tester.element(find.byType(Scaffold));
      _show(context);
      _show(context);
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      _root(tester).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_root(tester).canPop(), isFalse);
    });

    testWidgets('a call during the close animation ends with one drawer', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(_closeButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      _show(tester.element(find.byType(Scaffold)));
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      _root(tester).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_root(tester).canPop(), isFalse);
    });

    testWidgets('a locale and theme change while open update the drawer', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pumpAndSettle();
      final graphite = _scrim(tester);
      _expectScrimInStep(tester, false, reason: 'before');

      // Hebrew and porcelain: the same app, re-pumped; the route stays.
      h.he = true;
      await _pump(tester, h, dark: false);
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      expect(tester.getRect(find.byType(ZodiannDrawer)).right, 1440);
      final porcelain = _scrim(tester);
      expect(porcelain, isNot(graphite));
      expect(_barrierColor(tester), porcelain);
      // The swipe direction followed: a leftward swipe does nothing, a
      // rightward one closes.
      await tester.fling(
        find.byType(ZodiannDrawer),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsOneWidget);
      await tester.fling(
        find.byType(ZodiannDrawer),
        const Offset(300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
    });

    testWidgets('back during the opening animation reaches closed', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ZodiannDrawer), findsNothing);
      expect(_root(tester).canPop(), isFalse);
    });

    testWidgets('a fling while opening ends in a consistent state', (
      tester,
    ) async {
      final h = _H();
      await _pump(tester, h);
      await _open(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.fling(
        find.byType(ZodiannDrawer),
        const Offset(-200, 0),
        1500,
      );
      await tester.pumpAndSettle();
      final open = find.byType(ZodiannDrawer).evaluate().isNotEmpty;
      expect(_root(tester).canPop(), open);
      if (open) expect(_fraction(tester, false), closeTo(1.0, 1e-6));
    });
  });
}
