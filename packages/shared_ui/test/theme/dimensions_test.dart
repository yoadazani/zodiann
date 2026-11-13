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
      'icon': (ZodiannSize.icon, 20),
      'iconSmall': (ZodiannSize.iconSmall, 16),
    };
    sizes.forEach((name, value) {
      expect(value.$1, value.$2, reason: name);
    });
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
  });
}
