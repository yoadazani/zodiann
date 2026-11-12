// ZOD-UI-001: sanity check of MASTER's stated minimum ("text-3 ≥ 4.5:1 on
// bg") and the primary text roles against WCAG AA (NFR-X5). The full audit
// of every text/background pairing is ZOD-NFR-009.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {'Graphite': graphiteTokens, 'Porcelain': porcelainTokens};

  test('text on bg/surface/bg-raised meets WCAG AA (4.5:1) in both themes', () {
    themes.forEach((name, t) {
      final s = t.surfaces;
      for (final (fg, fgName) in [
        (s.text, 'text'),
        (s.text2, 'text-2'),
        (s.text3, 'text-3'),
      ]) {
        for (final (bg, bgName) in [
          (s.bg, 'bg'),
          (s.surface, 'surface'),
          (s.bgRaised, 'bg-raised'),
        ]) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name $fgName on $bgName',
          );
        }
      }
    });
  });

  test('on-accent on accent meets WCAG AA in both themes', () {
    themes.forEach((name, t) {
      expect(
        _contrast(t.surfaces.onAccent, t.surfaces.accent),
        greaterThanOrEqualTo(4.5),
        reason: name,
      );
    });
  });
}
