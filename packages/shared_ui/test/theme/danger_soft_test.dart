// ZOD-UI-005: the input's error halo colour `danger-soft`. It is defined by
// the reference stylesheet (kit.css) but not by MASTER §2.1, so it is a
// field of ZodiannSurfaces outside the MASTER-ordered `tokens` map.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'samples.dart';

/// `rgba(r, g, b, a)` from kit.css, built as the token files build it.
Color _rgba(String css) {
  final m = RegExp(
    r'rgba\(\s*(\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\s*\)',
  ).firstMatch(css)!;
  return Color.fromRGBO(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    double.parse(m.group(4)!),
  );
}

String _kitDangerSoft(String header) {
  final css = File(
    '../../design-reference/zodiann/_source/kit.css',
  ).readAsStringSync();
  final start = css.indexOf(header);
  expect(start, isNot(-1), reason: 'kit.css block $header');
  final end = css.indexOf('}', start);
  final m = RegExp(
    r'--danger-soft\s*:\s*([^;]+);',
  ).firstMatch(css.substring(start, end));
  expect(m, isNotNull, reason: '--danger-soft in $header');
  return m!.group(1)!.trim();
}

void main() {
  test('dangerSoft equals kit.css danger-soft in both themes', () {
    expect(
      graphiteTokens.surfaces.dangerSoft,
      _rgba(_kitDangerSoft(':root')),
      reason: 'Graphite',
    );
    expect(
      porcelainTokens.surfaces.dangerSoft,
      _rgba(_kitDangerSoft('[data-theme="light"]')),
      reason: 'Porcelain',
    );
    // The two values the plan names, so a kit.css edit cannot move both sides.
    expect(
      graphiteTokens.surfaces.dangerSoft,
      const Color.fromRGBO(242, 85, 90, 0.12),
    );
    expect(
      porcelainTokens.surfaces.dangerSoft,
      const Color.fromRGBO(220, 53, 69, 0.08),
    );
  });

  test("dangerSoft is not in MASTER's token map (MASTER omits it)", () {
    expect(graphiteTokens.surfaces.tokens.keys, isNot(contains('danger-soft')));
    expect(graphiteTokens.surfaces.tokens.length, 19);
  });

  test('copyWith(dangerSoft:) changes only that field', () {
    final a = sampleSurfaces(1);
    const c = Color(0xFF123456);
    final b = a.copyWith(dangerSoft: c);
    expect(b.dangerSoft, c);
    expect(b.tokens, a.tokens);
    expect(a.copyWith().dangerSoft, a.dangerSoft);
  });

  test('lerp interpolates dangerSoft', () {
    final a = sampleSurfaces(1);
    final b = sampleSurfaces(3);
    expect(
      a.lerp(b, 0.5).dangerSoft,
      Color.lerp(a.dangerSoft, b.dangerSoft, 0.5),
    );
    expect(a.lerp(b, 0).dangerSoft, a.dangerSoft);
    expect(a.lerp(b, 1).dangerSoft, b.dangerSoft);
  });
}
