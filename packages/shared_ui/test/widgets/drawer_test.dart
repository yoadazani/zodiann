// ZOD-NAV-002: ZodiannDrawer (MASTER §5 "Drawer", NAV-2/3; kit.css
// .drawer*, .nav-*): width, header, groups, items, the active item, footer,
// mirroring, safe areas, text scale and short screens. Geometry values are
// the kit.css values; the Wheel item's top (123.4) and height (81.1) also
// agree with the designer PNG measured in plan review.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/icons/zodiann_icon.dart' show ZodiannIconPainter;
import 'package:shared_ui/src/widgets/zodiann_pressable.dart';

import '../support/load_bundled_fonts.dart';

const _enNames = [
  'Zodiac wheel',
  'Gann Square of Nine',
  'Saved squares',
  'Settings',
  'About and sources',
];
const _enDescs = [
  'Planet positions, aspects and degree crossings',
  'Numbers, days or 4-hour blocks on the spiral',
  'Return to squares you named',
  'Language, theme, orbs, defaults',
  'Computation sources and method',
];
const _heNames = [
  'גלגל המזלות',
  'ריבוע התשע של גאן',
  'ריבועים שמורים',
  'הגדרות',
  'אודות ומקורות',
];
const _heDescs = [
  'מיקומי כוכבים, היבטים ומעברי מעלות',
  'מספרים, ימים או בלוקים של 4 שעות בספירלה',
  'חזרה לריבועים ששמרת בשם',
  'שפה, ערכת נושא, אורבים',
  'מקורות החישוב והשיטה',
];
final _icons = [
  ZodiannIcons.wheel,
  ZodiannIcons.grid,
  ZodiannIcons.folder,
  ZodiannIcons.sliders,
  ZodiannIcons.info,
];

List<ZodiannDrawerGroup> _groups({
  required bool he,
  int selected = 0,
  void Function(int)? onTap,
}) {
  final names = he ? _heNames : _enNames;
  final descs = he ? _heDescs : _enDescs;
  ZodiannDrawerItem item(int i) => ZodiannDrawerItem(
    icon: _icons[i],
    name: names[i],
    description: descs[i],
    selected: i == selected,
    onTap: () => onTap?.call(i),
  );
  return [
    ZodiannDrawerGroup(
      label: he ? 'ניתוח' : 'Analysis',
      items: [item(0), item(1)],
    ),
    ZodiannDrawerGroup(
      label: he ? 'ספרייה ואפליקציה' : 'Library and app',
      items: [item(2), item(3), item(4)],
    ),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 1440,
  double height = 900,
  bool dark = true,
  bool he = false,
  int selected = 0,
  double textScale = 1,
  FakeViewPadding padding = FakeViewPadding.zero,
  void Function(int)? onTap,
  VoidCallback? onClose,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
  final base = dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base,
      builder: (context, child) {
        Widget c = MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
        if (he) {
          c = Theme(
            data: withZodiannScript(Theme.of(context), ZodiannScript.hebrew),
            child: Directionality(textDirection: TextDirection.rtl, child: c),
          );
        }
        return c;
      },
      home: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ZodiannDrawer(
          wordmark: 'Zodiann',
          groups: _groups(he: he, selected: selected, onTap: onTap),
          closeLabel: he ? 'סגירת תפריט' : 'Close menu',
          onClose: onClose ?? () {},
          versionLabel: he ? 'גרסה 1.0.0' : 'Version 1.0.0',
          offlineLabel: he
              ? 'כל הנתונים נשארים במכשיר'
              : 'All data stays on this device',
        ),
      ),
    ),
  );
  // Settles MaterialApp's theme animation when the theme changes.
  await tester.pumpAndSettle();
}

ZodiannSurfaces _s(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ZodiannDrawer)))
        .extension<ZodiannSurfaces>()!;

Finder _pressable(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ZodiannPressable));

Rect _item(WidgetTester tester, String name) =>
    tester.getRect(_pressable(name));

Finder _closeButton() => find.byType(ZodiannIconButton);

TextStyle _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  // Real glyph widths: the description wraps as in the reference.
  setUpAll(loadBundledFonts);

  group('width', () {
    for (final (screen, expected) in [
      (1440.0, 320.0),
      (390.0, 320.0),
      (372.1, 320.0),
      (372.09, 319.9974),
      (360.0, 309.6),
      (320.0, 275.2),
    ]) {
      testWidgets('min(320, 86 %) at $screen', (tester) async {
        await _pump(tester, width: screen);
        expect(ZodiannDrawer.widthFor(screen), closeTo(expected, 1e-4));
        expect(
          tester.getSize(find.byType(ZodiannDrawer)).width,
          closeTo(expected, 1e-4),
        );
      });
    }
  });

  group('header', () {
    testWidgets('LTR: logo, wordmark and close button', (tester) async {
      await _pump(tester);
      final logo = tester.getRect(find.byType(ZodiannLogo));
      expect(logo.size, const Size(40, 40));
      expect(logo.left, 20);
      expect(logo.top, closeTo(17.5, 1e-6));
      final word = tester.getRect(find.text('Zodiann'));
      expect(word.left, 72);
      final style = _style(tester, 'Zodiann');
      expect(
        style,
        ZodiannTheme.graphite.extension<ZodiannTextStyles>()!.drawerWordmark,
      );
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w600);
      final close = tester.getRect(_closeButton());
      expect(close.size, const Size(46, 46));
      // The content box is width - 1 (the 1 px inner border); 12 from it.
      expect(close.right, 320 - 1 - 12);
      final labelled = tester.widget<ZodiannIconButton>(_closeButton());
      expect(labelled.semanticLabel, 'Close menu');
    });

    testWidgets('RTL mirrors it exactly', (tester) async {
      await _pump(tester, he: true);
      final logo = tester.getRect(find.byType(ZodiannLogo));
      expect(logo.right, 1440 - 20);
      expect(tester.getRect(find.text('Zodiann')).right, 1440 - 72);
      final close = tester.getRect(_closeButton());
      // Panel [1120, 1440]; the 1 px border is on the end (left) edge.
      expect(close.left, 1120 + 1 + 12);
      expect(
        tester.widget<ZodiannIconButton>(_closeButton()).semanticLabel,
        'סגירת תפריט',
      );
    });

    testWidgets('the logo variant follows the app theme, not the OS', (
      tester,
    ) async {
      String asset() {
        final image = tester.widget<Image>(
          find.descendant(
            of: find.byType(ZodiannLogo),
            matching: find.byType(Image),
          ),
        );
        final provider = image.image;
        final inner = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        return (inner as AssetImage).assetName;
      }

      // The OS is light while the app theme is dark, then the other way.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await _pump(tester, dark: true);
      expect(asset(), endsWith('zodiann-logo-on-dark.png'));
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _pump(tester, dark: false);
      expect(asset(), endsWith('zodiann-logo-on-light.png'));
    });
  });

  group('list', () {
    testWidgets('groups, items and the 2 px gap between every child', (
      tester,
    ) async {
      await _pump(tester);
      // 76 header + 12 nav padding + 8 (first label's top padding).
      final analysis = tester.getRect(find.text('Analysis'));
      expect(analysis.top, 96);
      expect(analysis.left, 12 + 12);
      final label = _style(tester, 'Analysis');
      final s = _s(tester);
      expect(label.fontSize, 12);
      expect(label.fontWeight, FontWeight.w400);
      expect(label.color, s.text3);

      // label (17.4) + 8 below + the 2 px gap, then the first item.
      final wheel = _item(tester, _enNames[0]);
      expect(wheel.left, 12);
      expect(wheel.width, 320 - 1 - 24);
      // 123.4 is the CSS arithmetic; Flutter rounds the label's 17.4 line to
      // 17, so the item sits at 123.0 (the reference comparison in
      // drawer_reference_test judges the pixels).
      expect(wheel.top, closeTo(123.4, 0.5));
      // Two lines of description at 320: CSS gives 24 + 20.3 + 2 + 2 × 17.4 =
      // 81.1; Flutter rounds each line to whole pixels (20 and 17), so 80.
      // Ledger ruling: layout follows kit.css, text heights may differ by
      // up to about 1 px per item.
      expect(wheel.height, closeTo(81.1, 1.5));

      final square = _item(tester, _enNames[1]);
      expect(square.top, closeTo(wheel.bottom + 2, 1e-6));

      // The second group's label: 2 gap + 16 above it.
      final library = tester.getRect(find.text('Library and app'));
      expect(library.top, closeTo(square.bottom + 2 + 16, 1e-6));
      final saved = _item(tester, _enNames[2]);
      expect(saved.top, closeTo(library.bottom + 8 + 2, 1e-6));
    });

    testWidgets('an item: icon column, name and description', (tester) async {
      await _pump(tester);
      final s = _s(tester);
      final wheel = _item(tester, _enNames[0]);
      final icon = tester.getRect(
        find.descendant(
          of: _pressable(_enNames[0]),
          matching: find.byType(ZodiannIcon),
        ),
      );
      expect(icon.size, const Size(20, 20));
      // Padding 12 from the item's start, and 1 px down.
      expect(icon.left, wheel.left + 12);
      expect(icon.top, closeTo(wheel.top + 12 + 1, 1e-6));
      final name = tester.getRect(find.text(_enNames[0]));
      expect(name.left, wheel.left + 12 + 24 + 12);
      expect(name.top, closeTo(wheel.top + 12, 1e-6));
      final desc = tester.getRect(find.text(_enDescs[0]));
      expect(desc.top, closeTo(name.bottom + 2, 1e-6));
      expect(desc.left, name.left);

      final inactive = _style(tester, _enNames[1]);
      expect(inactive.fontSize, 14);
      expect(inactive.fontWeight, FontWeight.w500);
      expect(inactive.color, s.text);
      final description = _style(tester, _enDescs[1]);
      expect(description.fontSize, 12);
      expect(description.fontWeight, FontWeight.w400);
      expect(description.color, s.text2);
    });

    testWidgets('the item box radius is 8', (tester) async {
      await _pump(tester);
      final s = _s(tester);
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: _pressable(_enNames[0]),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>();
      final fill = boxes.firstWhere((d) => d.color == s.accentSoft);
      expect(fill.borderRadius, ZodiannRadius.control);
    });
  });

  group('the active item', () {
    testWidgets('fill, 3 px bar on the start edge, accent-strong ink', (
      tester,
    ) async {
      await _pump(tester);
      final s = _s(tester);
      final wheel = _item(tester, _enNames[0]);
      // accent-soft fill on the active item only.
      bool hasFill(String name) => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: _pressable(name),
              matching: find.byType(DecoratedBox),
            ),
          )
          .any((b) => (b.decoration as BoxDecoration).color == s.accentSoft);
      expect(hasFill(_enNames[0]), isTrue);
      expect(hasFill(_enNames[1]), isFalse);

      final bar = find.descendant(
        of: _pressable(_enNames[0]),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).color == s.accent,
        ),
      );
      expect(bar, findsOneWidget);
      final rect = tester.getRect(bar);
      expect(rect.width, 3);
      expect(rect.left, wheel.left);
      expect(rect.top, closeTo(wheel.top + 10, 1e-6));
      expect(rect.bottom, closeTo(wheel.bottom - 10, 1e-6));
      expect(
        (tester.widget<DecoratedBox>(bar).decoration as BoxDecoration)
            .borderRadius,
        BorderRadius.circular(ZodiannRadius.xs),
      );
      // No bar on an inactive item.
      expect(
        find.descendant(
          of: _pressable(_enNames[1]),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                (w.decoration as BoxDecoration).color == s.accent,
          ),
        ),
        findsNothing,
      );
      // Name and icon in accent-strong (decision D1); inactive icon text-2.
      expect(_style(tester, _enNames[0]).color, s.accentStrong);
      Color iconColor(String name) {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: _pressable(name),
            matching: find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is ZodiannIconPainter,
            ),
          ),
        );
        return (paint.painter! as ZodiannIconPainter).color;
      }

      expect(iconColor(_enNames[0]), s.accentStrong);
      expect(iconColor(_enNames[1]), s.text2);
    });

    testWidgets('RTL: the bar and the icon column sit on the right', (
      tester,
    ) async {
      await _pump(tester, he: true);
      final s = _s(tester);
      final wheel = _item(tester, _heNames[0]);
      final bar = tester.getRect(
        find.descendant(
          of: _pressable(_heNames[0]),
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                (w.decoration as BoxDecoration).color == s.accent,
          ),
        ),
      );
      expect(bar.right, wheel.right);
      final icon = tester.getRect(
        find.descendant(
          of: _pressable(_heNames[0]),
          matching: find.byType(ZodiannIcon),
        ),
      );
      expect(icon.right, wheel.right - 12);
    });

    testWidgets('semantics: selected on the active item only', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(
        tester.getSemantics(_pressable(_enNames[0])),
        isSemantics(
          label: _enNames[0],
          hint: _enDescs[0],
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      for (var i = 1; i < 5; i++) {
        final node = tester.getSemantics(_pressable(_enNames[i]));
        expect(node, isSemantics(label: _enNames[i], hint: _enDescs[i]));
        expect(node, isNot(isSemantics(hasSelectedState: true)));
      }
      handle.dispose();
    });
  });

  group('footer', () {
    testWidgets('pinned to the bottom, 16 / 20 padding, text-3', (
      tester,
    ) async {
      await _pump(tester);
      final s = _s(tester);
      final version = tester.getRect(find.text('Version 1.0.0'));
      final offline = tester.getRect(
        find.text('All data stays on this device'),
      );
      expect(version.left, 20);
      expect(offline.bottom, closeTo(900 - 16, 1e-6));
      expect(offline.top, closeTo(version.bottom + 2, 1e-6));
      final style = _style(tester, 'Version 1.0.0');
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, s.text3);
    });
  });

  group('the panel', () {
    testWidgets('surface, inner-edge line and floating elevation', (
      tester,
    ) async {
      await _pump(tester);
      final s = _s(tester);
      final e = Theme.of(tester.element(find.byType(ZodiannDrawer)))
          .extension<ZodiannElevation>()!;
      final decorations = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(ZodiannDrawer),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>();
      final panel = decorations.firstWhere((d) => d.color == s.surface);
      final border = panel.border! as BorderDirectional;
      expect(border.end.color, s.line);
      expect(border.end.width, 1);
      // The outline ring first (under the shadow, as the reference), then
      // the floating shadow.
      expect(panel.boxShadow!.length, e.floating.length + 1);
      expect(panel.boxShadow!.first.color, e.floatingOutline.color);
      expect(panel.boxShadow!.first.spreadRadius, e.floatingOutline.width);
      expect(panel.boxShadow!.skip(1).toList(), e.floating);
    });

    testWidgets('the header rule and the footer rule are line-soft', (
      tester,
    ) async {
      await _pump(tester);
      final s = _s(tester);
      bool ruleAbove(Finder of, {required bool bottom}) => tester
          .widgetList<DecoratedBox>(
            find.ancestor(of: of, matching: find.byType(DecoratedBox)),
          )
          .map((b) => b.decoration)
          .whereType<BoxDecoration>()
          .any((d) {
            final b = d.border;
            if (b is! Border) return false;
            final side = bottom ? b.bottom : b.top;
            return side.color == s.lineSoft && side.width == 1;
          });
      expect(ruleAbove(find.byType(ZodiannLogo), bottom: true), isTrue);
      expect(ruleAbove(find.text('Version 1.0.0'), bottom: false), isTrue);
    });
  });

  group('behaviour', () {
    testWidgets('an item tap and the close button call back once', (
      tester,
    ) async {
      final taps = <int>[];
      var closed = 0;
      await _pump(tester, onTap: taps.add, onClose: () => closed++);
      await tester.tap(find.text(_enNames[3]));
      expect(taps, [3]);
      await tester.tap(_closeButton());
      expect(closed, 1);
    });

    testWidgets('items have a 44 px target and activate from the keyboard', (
      tester,
    ) async {
      final taps = <int>[];
      await _pump(tester, onTap: taps.add);
      expect(_item(tester, _enNames[2]).height, greaterThanOrEqualTo(44));
      // Tab order: the close button, then the items.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, [0]);
    });

    testWidgets('focus rings fit inside the list at both ends', (tester) async {
      await _pump(tester);
      final list = tester.getRect(find.byType(Scrollable));
      final first = _item(tester, _enNames[0]).inflate(4);
      expect(list.left <= first.left && first.right <= list.right, isTrue);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      final last = _item(tester, _enNames[4]).inflate(4);
      expect(list.top <= last.top && last.bottom <= list.bottom, isTrue);
    });
  });

  group('review focus', () {
    testWidgets('320 wide, text scale 2.0, Hebrew: no overflow, scrolls', (
      tester,
    ) async {
      await _pump(tester, width: 320, height: 600, he: true, textScale: 2);
      expect(tester.takeException(), isNull);
      // The header's text is clamped at 1.5x; the list scales freely.
      final word = tester.element(find.text('Zodiann'));
      expect(MediaQuery.textScalerOf(word).scale(10), closeTo(15, 1e-9));
      final name = tester.element(find.text(_heNames[0]));
      expect(MediaQuery.textScalerOf(name).scale(10), closeTo(20, 1e-9));
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('360 high: no overflow, footer at the bottom, list scrolls', (
      tester,
    ) async {
      await _pump(tester, width: 390, height: 360);
      expect(tester.takeException(), isNull);
      final offline = tester.getRect(
        find.text('All data stays on this device'),
      );
      expect(offline.bottom, closeTo(360 - 16, 1e-6));
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('safe areas: background covers the insets, content stays in', (
      tester,
    ) async {
      await _pump(
        tester,
        padding: const FakeViewPadding(top: 24, bottom: 34, left: 20),
      );
      expect(tester.getRect(find.byType(ZodiannDrawer)).top, 0);
      expect(tester.getRect(find.byType(ZodiannDrawer)).height, 900);
      // Start inset 20 joins the 20 header padding; 24 on top; 34 below.
      expect(tester.getRect(find.byType(ZodiannLogo)).left, 40);
      expect(tester.getRect(find.text('Analysis')).top, 24 + 76 + 12 + 8);
      expect(
        tester.getRect(find.text('All data stays on this device')).bottom,
        closeTo(900 - 34 - 16, 1e-6),
      );
    });

    testWidgets('RTL start inset is the right side', (tester) async {
      await _pump(tester, he: true, padding: const FakeViewPadding(right: 20));
      expect(tester.getRect(find.byType(ZodiannLogo)).right, 1440 - 20 - 20);
    });
  });
}
