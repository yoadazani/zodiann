// ZOD-UI-003: MASTER.md §4 spacing, radius and control sizes, and §6's
// breakpoints, are the shared_ui constants exactly. Two independent sources:
// MASTER's values (typed in below) and the reference stylesheet the design
// PNGs were rendered from (design-reference/zodiann/_source/kit.css).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

String _kitCss() =>
    File('../../design-reference/zodiann/_source/kit.css').readAsStringSync();

/// The `--name: Npx` declarations of kit.css, as numbers.
Map<String, double> _kitPx(String css) => {
  for (final m in RegExp(
    r'--([a-z0-9-]+)\s*:\s*([\d.]+)px\s*;',
  ).allMatches(css))
    m.group(1)!: double.parse(m.group(2)!),
};

/// The declarations of the first kit.css rule whose selector is [selector].
String _rule(String css, String selector) {
  final match = RegExp('(^|\\n)${RegExp.escape(selector)}\\s*\\{([^}]*)\\}')
      .firstMatch(css);
  expect(match, isNotNull, reason: 'kit.css rule $selector');
  return match!.group(2)!;
}

/// The px value of [property] inside a rule body.
double _px(String body, String property) {
  final m = RegExp('(^|[;{\\s])${RegExp.escape(property)}\\s*:\\s*([\\d.]+)px')
      .firstMatch(body);
  expect(m, isNotNull, reason: property);
  return double.parse(m!.group(2)!);
}

void main() {
  test("the spacing scale is MASTER's 4-based scale", () {
    expect(ZodiannSpace.scale, [4, 8, 12, 16, 20, 24, 32, 40, 48]);
    expect(ZodiannSpace.s1, 4);
    expect(ZodiannSpace.s2, 8);
    expect(ZodiannSpace.s3, 12);
    expect(ZodiannSpace.s4, 16);
    expect(ZodiannSpace.s5, 20);
    expect(ZodiannSpace.s6, 24);
    expect(ZodiannSpace.s8, 32);
    expect(ZodiannSpace.s10, 40);
    expect(ZodiannSpace.s12, 48);
  });

  test("radii follow MASTER's hierarchy", () {
    expect(ZodiannRadius.xs, 3);
    expect(ZodiannRadius.sm, 6);
    expect(ZodiannRadius.md, 8);
    expect(ZodiannRadius.lg, 12);
    expect(ZodiannRadius.xl, 16);
    expect(ZodiannRadius.pill, 999);

    final semantic = <String, (BorderRadius, double)>{
      'cellFrame': (ZodiannRadius.cellFrame, 3),
      'legendSwatch': (ZodiannRadius.legendSwatch, 3),
      'tag': (ZodiannRadius.tag, 6),
      'segmentThumb': (ZodiannRadius.segmentThumb, 6),
      'control': (ZodiannRadius.control, 8),
      'panel': (ZodiannRadius.panel, 12),
      'dialog': (ZodiannRadius.dialog, 16),
      'chip': (ZodiannRadius.chip, 999),
    };
    semantic.forEach((name, value) {
      expect(value.$1, BorderRadius.circular(value.$2), reason: name);
    });

    final scale = [
      ZodiannRadius.xs,
      ZodiannRadius.sm,
      ZodiannRadius.md,
      ZodiannRadius.lg,
      ZodiannRadius.xl,
      ZodiannRadius.pill,
    ];
    for (var i = 1; i < scale.length; i++) {
      expect(scale[i], greaterThan(scale[i - 1]), reason: 'radius step $i');
    }
  });

  test("control and icon sizes are MASTER's", () {
    final sizes = <String, (double, double)>{
      'control': (ZodiannSize.control, 40),
      'controlSmall': (ZodiannSize.controlSmall, 32),
      'segmentThumb': (ZodiannSize.segmentThumb, 32),
      'segmentTrackInset': (ZodiannSize.segmentTrackInset, 3),
      'tableRow': (ZodiannSize.tableRow, 44),
      'iconButton': (ZodiannSize.iconButton, 46),
      'iconButtonSmall': (ZodiannSize.iconButtonSmall, 36),
      'playButton': (ZodiannSize.playButton, 48),
      'switchWidth': (ZodiannSize.switchWidth, 40),
      'switchHeight': (ZodiannSize.switchHeight, 24),
      'stepper': (ZodiannSize.stepper, 36),
      'panelHead': (ZodiannSize.panelHead, 56),
      'panelHeadPhone': (ZodiannSize.panelHeadPhone, 52),
      'topBar': (ZodiannSize.topBar, 64),
      'topBarPhone': (ZodiannSize.topBarPhone, 60),
      'icon': (ZodiannSize.icon, 20),
      'iconSmall': (ZodiannSize.iconSmall, 16),
      // ZOD-FND-008: MASTER §11 (never below 40), §5 (drawer header 40),
      // §9 (About hero 132).
      'logoMin': (ZodiannSize.logoMin, 40),
      'logoDrawer': (ZodiannSize.logoDrawer, 40),
      'logoAbout': (ZodiannSize.logoAbout, 132),
      // ZOD-UI-009: MASTER §10 "Tags", kit.css `.tag` (height 24, gap 6)
      // and its 1.5 px inset outline (today, center).
      'tag': (ZodiannSize.tag, 24),
      'tagGap': (ZodiannSize.tagGap, 6),
      'segmentGap': (ZodiannSize.segmentGap, 2),
      'segmentIconGap': (ZodiannSize.segmentIconGap, 6),
      'tagOutline': (ZodiannSize.tagOutline, 1.5),
      // ZOD-UI-007: kit.css `.switch::after`, `.stepper`, `.chk`.
      'switchThumb': (ZodiannSize.switchThumb, 16),
      'switchThumbInset': (ZodiannSize.switchThumbInset, 3),
      'stepperButtonWidth': (ZodiannSize.stepperButtonWidth, 34),
      'stepperInnerHeight': (ZodiannSize.stepperInnerHeight, 34),
      'stepperGlyph': (ZodiannSize.stepperGlyph, 18),
      'stepperValueMinWidth': (ZodiannSize.stepperValueMinWidth, 52),
      'bodyChipHeight': (ZodiannSize.bodyChipHeight, 34),
      'bodyChipPaddingStart': (ZodiannSize.bodyChipPaddingStart, 10),
      'bodyChipPaddingEnd': (ZodiannSize.bodyChipPaddingEnd, 12),
      'bodyChipGap': (ZodiannSize.bodyChipGap, 8),
      'bodyChipGlyph': (ZodiannSize.bodyChipGlyph, 15),
    };
    sizes.forEach((name, value) {
      expect(value.$1, value.$2, reason: name);
    });
  });

  test('drawer sizes are MASTER §5 / kit.css (ZOD-NAV-002)', () {
    expect(ZodiannSize.drawerMaxWidth, 320);
    expect(ZodiannSize.drawerWidthFactor, 0.86);
    expect(ZodiannSize.drawerHead, 76);
    expect(ZodiannSize.navIconColumn, 24);
    expect(ZodiannSize.navIconNudge, 1);
    expect(ZodiannSize.navItemGap, 2);
    expect(ZodiannSize.navActiveBar, 3);
    expect(ZodiannSize.navActiveBarInset, 10);

    final css = _kitCss();
    final drawer = _rule(css, '.drawer');
    expect(drawer, contains('min(320px, 86vw)'));
    expect(_px(_rule(css, '.drawer-head'), 'height'), ZodiannSize.drawerHead);
    expect(_px(_rule(css, '.drawer nav'), 'gap'), ZodiannSize.navItemGap);
    final item = _rule(css, '.nav-item');
    expect(item, contains('grid-template-columns: 24px 1fr'));
    expect(item, contains('gap: 2px var(--s3)'));
    expect(
      _px(_rule(css, '.nav-item svg'), 'margin-top'),
      ZodiannSize.navIconNudge,
    );
    final bar = _rule(css, '.nav-item.on::before');
    expect(_px(bar, 'width'), ZodiannSize.navActiveBar);
    expect(_px(bar, 'top'), ZodiannSize.navActiveBarInset);
    expect(_px(bar, 'bottom'), ZodiannSize.navActiveBarInset);
  });

  test('drawer motion is MASTER §12 (ZOD-NAV-002)', () {
    expect(ZodiannStates.drawerOpenDuration, const Duration(milliseconds: 240));
    expect(
      ZodiannStates.drawerCloseDuration,
      const Duration(milliseconds: 180),
    );
    // Material's drawer fling threshold.
    expect(ZodiannStates.drawerFlingVelocity, 365);
  });

  test("the field gap and halo are kit.css's 6 and 3 px (ZOD-UI-005)", () {
    expect(ZodiannSize.fieldGap, 6.0);
    expect(ZodiannSize.fieldHalo, 3.0);
  });

  test("the hairline is MASTER §4's 1 px rule (ZOD-UI-014)", () {
    expect(ZodiannSize.hairline, 1.0);
  });

  test("the minimum touch target is MASTER §14's 44", () {
    expect(ZodiannSize.minTouchTarget, 44);
  });

  test("breakpoints are MASTER §6's", () {
    expect(ZodiannBreakpoints.tablet, 700);
    expect(ZodiannBreakpoints.desktop, 1100);
    expect(ZodiannBreakpoints.contentMaxWidth, 1440);
  });

  test('kit.css agrees on spacing, radius and controls', () {
    final css = _kitCss();
    final kit = _kitPx(css);
    final expected = <String, double>{
      's1': ZodiannSpace.s1,
      's2': ZodiannSpace.s2,
      's3': ZodiannSpace.s3,
      's4': ZodiannSpace.s4,
      's5': ZodiannSpace.s5,
      's6': ZodiannSpace.s6,
      's8': ZodiannSpace.s8,
      's10': ZodiannSpace.s10,
      's12': ZodiannSpace.s12,
      'r-xs': ZodiannRadius.xs,
      'r-sm': ZodiannRadius.sm,
      'r-md': ZodiannRadius.md,
      'r-lg': ZodiannRadius.lg,
      'r-xl': ZodiannRadius.xl,
      'r-pill': ZodiannRadius.pill,
      'control-h': ZodiannSize.control,
      'control-h-sm': ZodiannSize.controlSmall,
      'tap': ZodiannSize.iconButton,
      'topbar-h': ZodiannSize.topBar,
    };
    expected.forEach((key, value) {
      expect(kit[key], value, reason: 'kit.css --$key');
    });

    final seg = _rule(css, '.seg');
    expect(_px(seg, 'padding'), ZodiannSize.segmentTrackInset, reason: '.seg');
    expect(
      _px(_rule(css, '.seg > span'), 'height'),
      ZodiannSize.segmentThumb,
      reason: '.seg > span',
    );
    expect(_px(_rule(css, '.stepper'), 'height'), ZodiannSize.stepper);
    final sw = _rule(css, '.switch');
    expect(_px(sw, 'width'), ZodiannSize.switchWidth, reason: '.switch');
    expect(_px(sw, 'height'), ZodiannSize.switchHeight, reason: '.switch');
    expect(_px(_rule(css, '.tbl td'), 'height'), ZodiannSize.tableRow);
    // ZOD-UI-007.
    final thumb = _rule(css, '.switch::after');
    expect(_px(thumb, 'width'), ZodiannSize.switchThumb, reason: 'thumb');
    expect(_px(thumb, 'height'), ZodiannSize.switchThumb, reason: 'thumb');
    expect(_px(thumb, 'top'), ZodiannSize.switchThumbInset, reason: 'thumb');
    expect(
      _px(_rule(css, '.stepper button'), 'width'),
      ZodiannSize.stepperButtonWidth,
      reason: '.stepper button',
    );
    expect(
      _px(_rule(css, '.stepper button'), 'font-size'),
      ZodiannSize.stepperGlyph,
      reason: '.stepper button',
    );
    expect(
      _px(_rule(css, '.stepper .v'), 'min-width'),
      ZodiannSize.stepperValueMinWidth,
      reason: '.stepper .v',
    );
    final chk = _rule(css, '.chk');
    expect(_px(chk, 'height'), ZodiannSize.bodyChipHeight, reason: '.chk');
    expect(_px(chk, 'gap'), ZodiannSize.bodyChipGap, reason: '.chk');
    final pad = RegExp(r'padding-inline:\s*(\d+)px\s+(\d+)px').firstMatch(chk);
    expect(pad, isNotNull, reason: '.chk padding-inline');
    expect(double.parse(pad!.group(1)!), ZodiannSize.bodyChipPaddingStart);
    expect(double.parse(pad.group(2)!), ZodiannSize.bodyChipPaddingEnd);
    expect(
      _px(_rule(css, '.chk .glyph'), 'font-size'),
      ZodiannSize.bodyChipGlyph,
      reason: '.chk .glyph',
    );
    final tag = _rule(css, '.tag');
    expect(_px(tag, 'height'), ZodiannSize.tag, reason: '.tag');
    expect(_px(tag, 'gap'), ZodiannSize.tagGap, reason: '.tag');
    expect(_px(tag, 'padding-inline'), ZodiannSpace.s2, reason: '.tag');
  });

  // ZOD-UI-010. The selected bar's 3 px is an inset shadow in the kit, which
  // cannot be parsed as a property, so it is asserted as a value.
  test("the table's header padding, compact padding and bar", () {
    final css = _kitCss();
    expect(
      _px(_rule(css, '.tbl th'), 'padding'),
      ZodiannSize.tableHeaderPadding,
      reason: '.tbl th padding-block',
    );
    final wheel = File('../../design-reference/zodiann/_source/wheel.html')
        .readAsStringSync();
    expect(
      wheel,
      contains(
        '.pos-panel .tbl th { padding-inline: '
        '${ZodiannSize.tableCompactPadding.toInt()}px; }',
      ),
      reason: 'wheel.html compact padding-inline',
    );
    expect(ZodiannSize.tableHeaderPadding, 10);
    expect(ZodiannSize.tableCompactPadding, 10);
    expect(ZodiannSize.tableSelectedBar, 3);
    expect(css, contains('inset 3px 0 0 var(--accent)'), reason: 'bar width');
  });

  // ZOD-UI-013: the dialog's width, padding and gaps (kit.css `.dialog`).
  test("the dialog's width, padding and gaps are the kit's", () {
    final css = _kitCss();
    final kit = _kitPx(css);
    final dialog = _rule(css, '.dialog');
    expect(_px(dialog, 'width'), ZodiannSize.dialogWidth, reason: '.dialog');
    expect(ZodiannSize.dialogWidth, 420);
    expect(dialog, contains('padding: var(--s6)'));
    expect(kit['s6'], ZodiannSpace.s6);
    expect(dialog, contains('border-radius: var(--r-xl)'));
    expect(kit['r-xl'], ZodiannRadius.xl);
    expect(_rule(css, '.dialog h3'), contains('margin-bottom: var(--s2)'));
    final actions = _rule(css, '.dialog .actions');
    expect(actions, contains('gap: var(--s2)'));
    expect(actions, contains('margin-top: var(--s6)'));
    expect(actions, contains('justify-content: flex-end'));
    expect(kit['s2'], ZodiannSpace.s2);
  });
}
