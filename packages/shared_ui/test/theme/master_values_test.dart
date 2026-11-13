// ZOD-UI-001: every MASTER.md §2 colour token has its exact value in both
// themes. Two independent sources: MASTER's tables (typed in below) and the
// reference stylesheet the design PNGs were rendered from
// (design-reference/zodiann/_source/kit.css).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// MASTER.md §2.1–§2.3: token → (Graphite, Porcelain), as written in MASTER.
const _master = <String, (String, String)>{
  // §2.1 Surfaces, text, accent
  'bg': ('#08080A', '#F5F6F8'),
  'bg-raised': ('#0E0E11', '#EEF0F3'),
  'surface': ('#111114', '#FFFFFF'),
  'surface-2': ('#18181C', '#F4F5F7'),
  'surface-3': ('#212126', '#E9EBEF'),
  'line': ('#2A2A30', '#D9DCE1'),
  'line-soft': ('#1B1B20', '#E7E9ED'),
  'text': ('#F4F5F7', '#0B0C0E'),
  'text-2': ('#A0A4AD', '#4B5059'),
  'text-3': ('#7C808A', '#646A74'),
  'accent': ('#F4F5F7', '#0B0C0E'),
  'accent-strong': ('#FFFFFF', '#000000'),
  'accent-soft': ('rgba(255,255,255,.07)', 'rgba(11,12,14,.06)'),
  'accent-line': ('rgba(255,255,255,.24)', 'rgba(11,12,14,.26)'),
  'on-accent': ('#0A0A0B', '#FFFFFF'),
  'focus': ('#FFFFFF', '#0B0C0E'),
  'scrim': ('rgba(0,0,0,.72)', 'rgba(11,12,14,.40)'),
  'danger': ('#F2555A', '#DC3545'),
  'ok': ('#34D399', '#15803D'),
  // §2.2 Square of Nine
  'axis-fill': ('#16305A', '#DCE8FF'),
  'axis-ink': ('#D6E4FF', '#12357A'),
  'axis': ('#4F8CFF', '#2E6BE6'),
  'diag-fill': ('#3D3412', '#FBEFC2'),
  'diag-ink': ('#F3E3A3', '#5C4500'),
  'diag': ('#E2BF3E', '#A87F00'),
  'eighth-fill': ('#222226', '#ECEDF0'),
  'eighth-ink': ('#C4C6CC', '#3B4049'),
  'cell-fill': ('#0E0E11', '#FFFFFF'),
  'cell-ink': ('#8A8E97', '#646A74'),
  'cell-line': ('#1C1C21', '#E7E9ED'),
  'center': ('#F5A524', '#D97706'),
  'today': ('#2DD4BF', '#0E9F8E'),
  'sel-outer': ('#FFFFFF', '#0B0C0E'),
  'sel-inner': ('#08080A', '#FFFFFF'),
  // §2.3 Elements
  'fire': ('#F2735A', '#D9472B'),
  'earth': ('#7CC47F', '#2F8F3E'),
  'air': ('#E8D06E', '#A88600'),
  'water': ('#5AA9FF', '#1F6FD6'),
  // §2.3 Aspects
  'asp-conj': ('#F5A524', '#D97706'),
  'asp-soft': ('#2DD4BF', '#0E9F8E'),
  'asp-hard': ('#F2555A', '#DC3545'),
  // §2.3 Bodies
  'sun': ('#F5C042', '#B98500'),
  'moon': ('#D4D8E0', '#646A74'),
  'mercury': ('#8EC5E8', '#2B7DB0'),
  'venus': ('#F0A3C0', '#C2457A'),
  'mars': ('#F2555A', '#DC3545'),
  'jupiter': ('#F29E5C', '#C4621A'),
  'saturn': ('#C9B37E', '#7D6A33'),
  'uranus': ('#4FD1C5', '#0E8C82'),
  'neptune': ('#7B93FF', '#3D5AE0'),
  'pluto': ('#B48CF2', '#7A45C9'),
  'node': ('#9CA1AB', '#646A74'),
};

const _bodies = {
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
  'node',
};

/// Parses `#RRGGBB` or `rgba(r, g, b, a)`.
Color _parse(String text) {
  final s = text.replaceAll(RegExp(r'\s'), '');
  final hex = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(s);
  if (hex != null) {
    return Color(0xFF000000 | int.parse(hex.group(1)!, radix: 16));
  }
  final rgba = RegExp(r'^rgba\((\d+),(\d+),(\d+),([\d.]+)\)$').firstMatch(s);
  if (rgba != null) {
    return Color.fromRGBO(
      int.parse(rgba.group(1)!),
      int.parse(rgba.group(2)!),
      int.parse(rgba.group(3)!),
      double.parse(rgba.group(4)!),
    );
  }
  throw FormatException('not a colour', text);
}

/// Every colour token of [t], keyed by MASTER name.
Map<String, Color> _all(ZodiannTokens t) => {
  ...t.surfaces.tokens,
  ...t.square.tokens,
  ...t.zodiac.tokens,
  ...t.aspects.tokens,
  ...t.bodies.tokens,
};

/// The `--name: value;` declarations of the kit.css block that starts with
/// [header].
Map<String, String> _kitBlock(String css, String header) {
  final start = css.indexOf(header);
  expect(start, isNot(-1), reason: 'kit.css block $header');
  final end = css.indexOf('}', start);
  final block = css.substring(start + header.length, end);
  return {
    for (final m in RegExp(r'--([a-z0-9-]+)\s*:\s*([^;]+);').allMatches(block))
      m.group(1)!: m.group(2)!.trim(),
  };
}

void main() {
  final themes = {'Graphite': graphiteTokens, 'Porcelain': porcelainTokens};

  for (final (index, name) in [(0, 'Graphite'), (1, 'Porcelain')]) {
    test('every MASTER §2 token has its $name value', () {
      final actual = _all(themes[name]!);
      _master.forEach((token, values) {
        final expected = index == 0 ? values.$1 : values.$2;
        expect(actual[token], _parse(expected), reason: token);
      });
    });
  }

  test('the table covers every token in the theme', () {
    for (final t in themes.values) {
      expect(_all(t).keys.toSet(), _master.keys.toSet());
    }
  });

  test('kit.css agrees with every token value', () {
    final css = File('../../design-reference/zodiann/_source/kit.css')
        .readAsStringSync();
    final blocks = {
      graphiteTokens: (_kitBlock(css, ':root, [data-theme="dark"] {'), 0.10),
      porcelainTokens: (_kitBlock(css, '[data-theme="light"] {'), 0.09),
    };
    blocks.forEach((tokens, entry) {
      final (kit, tint) = entry;
      final actual = _all(tokens);
      for (final token in _master.keys) {
        final key = _bodies.contains(token) ? 'b-$token' : token;
        expect(kit, contains(key), reason: 'kit.css --$key');
        expect(actual[token], _parse(kit[key]!), reason: token);
      }
      expect(double.parse(kit['sign-tint']!), tint);
      expect(tokens.zodiac.signTintOpacity, tint);
    });
  });
}
