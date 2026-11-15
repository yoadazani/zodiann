// ZOD-NAV-001: ZodiannTopBar (MASTER ֲ§5, NAV-1; kit.css .topbar) ג€” height,
// order and mirroring, paddings, typography, responsive actions, disabled
// controls, background, semantics, status bar, text scale and overflow.
import 'dart:ui' show ImageFilter;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _enTitle = 'Gann Square of Nine';
const _enSubtitle = 'Spiral, angles and highlights';
const _heTitle = '׳”׳’׳“׳¨׳•׳×';
const _heSubtitle =
    '׳©׳₪׳”, ׳¢׳¨׳›׳× ׳ ׳•׳©׳, ׳׳•׳¨׳‘׳™׳ ׳•׳‘׳¨׳™׳¨׳•׳× ׳׳—׳“׳';

List<ZodiannTopBarAction> _actions({bool enabled = false}) => [
  ZodiannTopBarAction(
    icon: ZodiannIcons.save,
    label: 'Save',
    onPressed: enabled ? () {} : null,
  ),
  ZodiannTopBarAction(
    icon: ZodiannIcons.download,
    label: 'Export to Excel',
    variant: ZodiannButtonVariant.primary,
    onPressed: enabled ? () {} : null,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  double width = 1440,
  bool rtl = false,
  bool dark = true,
  String title = _enTitle,
  String subtitle = _enSubtitle,
  List<ZodiannTopBarAction> actions = const [],
  VoidCallback? onMenuPressed,
  double textScale = 1,
  double topPadding = 0,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final base = dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: rtl ? withZodiannScript(base, ZodiannScript.hebrew) : base,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(top: topPadding),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ZodiannTopBar.heightFor(width)),
          child: ZodiannTopBar(
            title: title,
            subtitle: subtitle,
            menuLabel: 'Open menu',
            onMenuPressed: onMenuPressed,
            actions: actions,
          ),
        ),
      ),
    ),
  );
}

Finder get _bar => find.byType(ZodiannTopBar);
Finder get _hamburger => find.byType(ZodiannIconButton).first;
Finder _under(Type type) =>
    find.descendant(of: _bar, matching: find.byType(type));
Rect _titles(WidgetTester tester, String title) => tester.getRect(
  find.ancestor(of: find.text(title), matching: find.byType(Column)).first,
);

void main() {
  test('heightFor: 699.9 is phone, 700 is regular', () {
    expect(ZodiannTopBar.heightFor(699.9), ZodiannSize.topBarPhone);
    expect(ZodiannTopBar.heightFor(700), ZodiannSize.topBar);
    expect(ZodiannTopBar.heightFor(390), 60);
    expect(ZodiannTopBar.heightFor(1440), 64);
  });

  testWidgets('height 64 regular, 60 phone; 699.9 is phone, 700 is regular', (
    tester,
  ) async {
    for (final (width, height) in [
      (1440.0, 64.0),
      (700.0, 64.0),
      (699.9, 60.0),
      (390.0, 60.0),
    ]) {
      await _pump(tester, width: width);
      expect(tester.getSize(_bar).height, height, reason: '$width');
    }
  });

  testWidgets(
    'hamburger is 46 ֳ— 46 at the start: LTR left 12 (phone 4), RTL right 12 '
    '(phone 4)',
    (tester) async {
      for (final (width, inset) in [(1440.0, 12.0), (390.0, 4.0)]) {
        await _pump(tester, width: width);
        var r = tester.getRect(_hamburger);
        expect(r.size, const Size.square(46), reason: '$width');
        expect(r.left, inset, reason: '$width LTR');
        final barHeight = ZodiannTopBar.heightFor(width);
        expect(r.top, (barHeight - 1 - 46) / 2, reason: '$width centred');
        await _pump(tester, width: width, rtl: true);
        r = tester.getRect(_hamburger);
        expect(width - r.right, inset, reason: '$width RTL');
      }
    },
  );

  testWidgets(
    'order from the start: hamburger, titles (start at 70 / 62), actions at '
    'the end',
    (tester) async {
      for (final (width, titlesStart) in [(1440.0, 70.0), (390.0, 62.0)]) {
        await _pump(tester, width: width, actions: _actions());
        final titles = _titles(tester, _enTitle);
        expect(titles.left, titlesStart, reason: '$width LTR');
        expect(tester.getTopLeft(find.text(_enTitle)).dx, titlesStart);
        final firstAction = tester.getRect(
          width >= 700
              ? find.byType(ZodiannButton).first
              : find.byType(ZodiannIconButton).at(1),
        );
        expect(firstAction.left, greaterThan(titles.right), reason: '$width');

        await _pump(tester, width: width, rtl: true, actions: _actions());
        final rtlTitles = _titles(tester, _enTitle);
        expect(width - rtlTitles.right, titlesStart, reason: '$width RTL');
        final rtlFirst = tester.getRect(
          width >= 700
              ? find.byType(ZodiannButton).first
              : find.byType(ZodiannIconButton).at(1),
        );
        expect(rtlFirst.right, lessThan(rtlTitles.left), reason: '$width');
      }
    },
  );

  testWidgets('end padding: 24 regular; phone 16 without actions, 8 with', (
    tester,
  ) async {
    await _pump(tester, actions: _actions());
    expect(1440 - tester.getRect(find.byType(ZodiannButton).last).right, 24);
    await _pump(tester, width: 390, actions: _actions());
    expect(390 - tester.getRect(find.byType(ZodiannIconButton).last).right, 8);
    await _pump(tester, width: 390);
    expect(390 - _titles(tester, _enTitle).right, 16);
    await _pump(tester);
    expect(1440 - _titles(tester, _enTitle).right, 24);
  });

  testWidgets(
    'gaps: 12 hamburger ג†’ titles, 12 titles ג†’ actions, 8 between',
    (tester) async {
      await _pump(tester, actions: _actions());
      final titles = _titles(tester, _enTitle);
      expect(titles.left - tester.getRect(_hamburger).right, 12);
      final save = tester.getRect(find.byType(ZodiannButton).first);
      final export = tester.getRect(find.byType(ZodiannButton).last);
      expect(save.left - titles.right, 12);
      // The buttons' 44-high touch targets equal their drawn width, so the
      // drawn boxes are 8 apart (kit.css .end gap s2).
      expect(export.left - save.right, 8);
    },
  );

  testWidgets('title is screenTitle 18/600; subtitle is 12/400 text2', (
    tester,
  ) async {
    await _pump(tester);
    final theme = ZodiannTheme.graphite;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final s = theme.extension<ZodiannSurfaces>()!;
    final title = tester.widget<Text>(find.text(_enTitle));
    expect(title.style, styles.screenTitle);
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    final subtitle = tester.widget<Text>(find.text(_enSubtitle));
    expect(subtitle.style?.fontSize, 12);
    expect(subtitle.style?.fontWeight, FontWeight.w400);
    expect(subtitle.style?.color, s.text2);
    expect(subtitle.style?.height, styles.label.height);
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
  });

  testWidgets(
    'regular actions are ZodiannButtons with icon + label + variant; phone '
    'actions are ZodiannIconButtons labelled with the action label, same order',
    (tester) async {
      await _pump(tester, actions: _actions());
      final buttons = tester
          .widgetList<ZodiannButton>(find.byType(ZodiannButton))
          .toList();
      expect([for (final b in buttons) b.label], ['Save', 'Export to Excel']);
      expect(
        [for (final b in buttons) b.variant],
        [ZodiannButtonVariant.secondary, ZodiannButtonVariant.primary],
      );
      expect(
        [for (final b in buttons) (b.icon! as ZodiannIcon).icon],
        [ZodiannIcons.save, ZodiannIcons.download],
      );
      expect(find.byType(ZodiannIconButton), findsOneWidget);

      await _pump(tester, width: 390, actions: _actions());
      expect(find.byType(ZodiannButton), findsNothing);
      final icons = tester
          .widgetList<ZodiannIconButton>(find.byType(ZodiannIconButton))
          .toList();
      expect(icons, hasLength(3));
      expect(
        [for (final b in icons.skip(1)) b.semanticLabel],
        ['Save', 'Export to Excel'],
      );
      expect(
        [for (final b in icons.skip(1)) (b.icon as ZodiannIcon).icon],
        [ZodiannIcons.save, ZodiannIcons.download],
      );
      expect([
        for (final b in icons.skip(1)) b.variant,
      ], everyElement(ZodiannIconButtonVariant.plain));
    },
  );

  testWidgets(
    'null callbacks render disabled: hamburger and actions enabled: false, '
    '42 % opacity',
    (tester) async {
      for (final width in [1440.0, 390.0]) {
        await _pump(tester, width: width, actions: _actions());
        final opacities = tester
            .widgetList<Opacity>(_under(Opacity))
            .map((o) => o.opacity)
            .toList();
        expect(opacities, hasLength(3), reason: '$width');
        expect(
          opacities,
          everyElement(ZodiannStates.disabledOpacity),
          reason: '$width',
        );
      }
      await _pump(
        tester,
        actions: _actions(enabled: true),
        onMenuPressed: () {},
      );
      expect(
        tester.widgetList<Opacity>(_under(Opacity)).map((o) => o.opacity),
        everyElement(1.0),
      );
    },
  );

  for (final dark in [true, false]) {
    final name = dark ? 'graphite' : 'porcelain';
    testWidgets(
      '$name background: bg at 0.88 behind a ֿƒ 10 blur, 1 px lineSoft '
      'bottom rule',
      (tester) async {
        await _pump(tester, dark: dark);
        final s = (dark ? ZodiannTheme.graphite : ZodiannTheme.porcelain)
            .extension<ZodiannSurfaces>()!;
        expect(
          tester.widget<BackdropFilter>(_under(BackdropFilter)).filter,
          ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        );
        final decoration =
            tester.widget<DecoratedBox>(_under(DecoratedBox).first).decoration
                as BoxDecoration;
        expect(decoration.color, s.bg.withValues(alpha: 0.88));
        expect(
          decoration.border,
          Border(bottom: BorderSide(color: s.lineSoft)),
        );
        expect(_under(ClipRect), findsWidgets);
      },
    );

    testWidgets('$name: status-bar icons contrast with the bar', (
      tester,
    ) async {
      await _pump(tester, dark: dark);
      final style = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find
                .descendant(
                  of: _bar,
                  matching: find.byWidgetPredicate(
                    (w) => w is AnnotatedRegion<SystemUiOverlayStyle>,
                  ),
                )
                .first,
          )
          .value;
      expect(
        style.statusBarIconBrightness,
        dark ? Brightness.light : Brightness.dark,
      );
      expect(style.statusBarColor?.a ?? 0, 0);
    });
  }

  testWidgets('title is a header; hamburger is labelled menuLabel', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(
      tester.getSemantics(find.text(_enTitle)),
      isSemantics(label: _enTitle, isHeader: true),
    );
    expect(
      tester.getSemantics(_hamburger),
      isSemantics(label: 'Open menu', isButton: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets(
    'status-bar inset: content below padding.top; background covers it',
    (tester) async {
      await _pump(tester, topPadding: 24);
      expect(tester.getSize(_bar).height, 24 + 64);
      expect(tester.getTopLeft(_bar).dy, 0);
      expect(tester.getRect(_hamburger).top, 24 + (63 - 46) / 2);
      expect(tester.getSize(_under(DecoratedBox).first).height, 24 + 64);
    },
  );

  testWidgets('textScaler 2.0: height unchanged, no overflow', (tester) async {
    for (final (width, rtl, title, subtitle) in [
      (700.0, false, _enTitle, _enSubtitle),
      (
        700.0,
        true,
        '׳¨׳™׳‘׳•׳¢ ׳”׳×׳©׳¢ ׳©׳ ׳’׳׳',
        '׳¡׳₪׳™׳¨׳׳”, ׳–׳•׳•׳™׳•׳× ׳•׳”׳“׳’׳©׳•׳×',
      ),
      (320.0, true, _heTitle, _heSubtitle),
    ]) {
      await _pump(
        tester,
        width: width,
        rtl: rtl,
        title: title,
        subtitle: subtitle,
        actions: _actions(),
        textScale: 2,
      );
      expect(tester.takeException(), isNull, reason: '$width $rtl');
      expect(
        tester.getSize(_bar).height,
        ZodiannTopBar.heightFor(width),
        reason: '$width $rtl',
      );
    }
  });

  testWidgets('narrow phone ellipsizes, no overflow', (tester) async {
    await _pump(
      tester,
      width: 320,
      rtl: true,
      title: _heTitle,
      subtitle: _heSubtitle,
      actions: _actions(),
    );
    expect(tester.takeException(), isNull);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(_heSubtitle),
    );
    expect(paragraph.didExceedMaxLines, isTrue);
    final titles = _titles(tester, _heTitle);
    final firstAction = tester.getRect(find.byType(ZodiannIconButton).at(1));
    expect(titles.left - firstAction.right, greaterThanOrEqualTo(12));
  });

  testWidgets(
    'only logical layout: no mirroring transform, positions mirror exactly',
    (tester) async {
      Map<String, Rect> rects() => {
        'hamburger': tester.getRect(_hamburger),
        'titles': _titles(tester, _enTitle),
        'save': tester.getRect(find.byType(ZodiannButton).first),
        'export': tester.getRect(find.byType(ZodiannButton).last),
      };
      for (final rtl in [false, true]) {
        await _pump(tester, rtl: rtl, actions: _actions());
        for (final t in tester.widgetList<Transform>(_under(Transform))) {
          expect(t.transform.getTranslation().x, 0);
          expect(t.transform.entry(0, 0), greaterThan(0));
        }
      }
      await _pump(tester, actions: _actions());
      final ltr = rects();
      await _pump(tester, rtl: true, actions: _actions());
      final rtl = rects();
      for (final key in ltr.keys) {
        expect(
          rtl[key]!.left,
          closeTo(1440 - ltr[key]!.right, 0.01),
          reason: key,
        );
        expect(rtl[key]!.width, closeTo(ltr[key]!.width, 0.01), reason: key);
      }
    },
  );

  testWidgets('the clip keeps the keyboard focus ring', (tester) async {
    await _pump(
      tester,
      width: 390,
      actions: _actions(enabled: true),
      onMenuPressed: () {},
    );
    final bar = tester.getRect(_bar);
    for (final button in [_hamburger, find.byType(ZodiannIconButton).last]) {
      // The ring sits 4 px outside the 46 ֳ— 46 box (2 gap + 2 width).
      final ring = tester.getRect(button).inflate(4);
      expect(bar.contains(ring.topLeft), isTrue);
      expect(ring.right, lessThanOrEqualTo(bar.right));
      expect(ring.bottom, lessThanOrEqualTo(bar.bottom - 1));
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
