// ZOD-UI-009 criterion 1: every tag of the design's component sheet
// (design-reference/zodiann/components/components_{dark,light}.png,
// "Highlight and state tags"), rendered by ZodiannTag and measured by the
// same feature extractor on both sides.
//
// Chrome snaps each tag box to whole pixels in the sheet; the harness
// renders each tag at an integer origin. Tolerances (as UI-004): width ±1,
// fill ±1 per channel, label and outline pixels ±3 per channel; height and
// top exact. The layout width (checked against Chrome's fractional widths
// within ±0.5) tells snapping apart from a real defect.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/load_bundled_fonts.dart';
import '../support/tag_features.dart';
import '../support/tag_harness.dart';

typedef _Tag = ({
  String name,
  ZodiannTagVariant variant,
  String label,
  int row,
  int left,
  int spanRight,
  double chromeWidth,
});

// Sheet lefts and spanRights (known right edge + 3) are the snapped pixel
// runs measured on both sheets; chromeWidth is Chrome's layout width of the
// source (kit.css at the sheet's layout).
const List<_Tag> _tags = [
  (
    name: 'axis',
    variant: ZodiannTagVariant.axis,
    label: 'Axis',
    row: 1,
    left: 65,
    spanRight: 121,
    chromeWidth: 53.70,
  ),
  (
    name: 'diagonal',
    variant: ZodiannTagVariant.diagonal,
    label: 'Diagonal',
    row: 1,
    left: 127,
    spanRight: 207,
    chromeWidth: 78.61,
  ),
  (
    name: 'eighth',
    variant: ZodiannTagVariant.eighth,
    label: 'Eighth',
    row: 1,
    left: 213,
    spanRight: 267,
    chromeWidth: 51.64,
  ),
  (
    name: 'noHighlight',
    variant: ZodiannTagVariant.noHighlight,
    label: 'No highlight',
    row: 1,
    left: 273,
    spanRight: 358,
    chromeWidth: 83.09,
  ),
  (
    name: 'center',
    variant: ZodiannTagVariant.center,
    label: 'Center',
    row: 1,
    left: 364,
    spanRight: 419,
    chromeWidth: 53.31,
  ),
  (
    name: 'today',
    variant: ZodiannTagVariant.today,
    label: 'Today',
    row: 1,
    left: 425,
    spanRight: 476,
    chromeWidth: 49.05,
  ),
  (
    name: 'neutral',
    variant: ZodiannTagVariant.neutral,
    label: 'Dates',
    row: 2,
    left: 65,
    spanRight: 115,
    chromeWidth: 47.67,
  ),
  (
    name: 'accent',
    variant: ZodiannTagVariant.accent,
    label: 'Mean node',
    row: 2,
    left: 121,
    spanRight: 199,
    chromeWidth: 76.81,
  ),
];

const _outlined = {ZodiannTagVariant.center, ZodiannTagVariant.today};

typedef _Sheet = ({
  String file,
  ThemeData theme,
  int row1Top,
  int row2Top,
  Map<String, int> fills,
  Map<String, List<int>> outline,
});

final Map<String, _Sheet> _sheets = {
  'dark': (
    file: 'components/components_dark.png',
    theme: ZodiannTheme.graphite,
    row1Top: 3528,
    row2Top: 3560,
    fills: {
      'axis': 0xFF16305A,
      'diagonal': 0xFF3D3412,
      'eighth': 0xFF222226,
      'noHighlight': 0xFF18181C,
      'neutral': 0xFF18181C,
      'accent': 0xFF222225,
    },
    // Full outline colour, then a 50 % pixel (center, today).
    outline: {
      'center': [0xFFF5A524, 0xFF825A1C],
      'today': [0xFF2DD4BF, 0xFF1E7269],
    },
  ),
  'light': (
    file: 'components/components_light.png',
    theme: ZodiannTheme.porcelain,
    row1Top: 3510,
    row2Top: 3542,
    fills: {
      'axis': 0xFFDCE8FF,
      'diagonal': 0xFFFBEFC2,
      'eighth': 0xFFECEDF0,
      'noHighlight': 0xFFF4F5F7,
      'neutral': 0xFFF4F5F7,
      'accent': 0xFFF1F1F1,
    },
    outline: {
      'center': [0xFFD97706, 0xFFEBBA82],
      'today': [0xFF0E9F8E, 0xFF86CEC6],
    },
  ),
};

void _channels(int actual, int expected, int tolerance, String reason) {
  for (final shift in [16, 8, 0]) {
    final a = (actual >> shift) & 0xFF;
    final e = (expected >> shift) & 0xFF;
    expect(
      (a - e).abs(),
      lessThanOrEqualTo(tolerance),
      reason:
          '$reason: ${hex(actual)} vs ${hex(expected)} '
          '(channel ${shift ~/ 8})',
    );
  }
}

int? _outlineColour(ThemeData theme, ZodiannTagVariant v) {
  final sq = theme.extension<SquareColors>()!;
  return switch (v) {
    ZodiannTagVariant.center => sq.center.toARGB32(),
    ZodiannTagVariant.today => sq.today.toARGB32(),
    _ => null,
  };
}

void main() {
  setUpAll(loadBundledFonts);

  final pngs = <String, Rgba>{};
  setUpAll(() async {
    for (final MapEntry(key: name, value: sheet) in _sheets.entries) {
      pngs[name] = await decodeDesignPng(sheet.file);
    }
  });

  TagFeatures onSheet(String sheetName, _Tag t) {
    final sheet = _sheets[sheetName]!;
    final s = sheet.theme.extension<ZodiannSurfaces>()!;
    return measureTag(
      pngs[sheetName]!,
      left: t.left,
      top: t.row == 1 ? sheet.row1Top : sheet.row2Top,
      spanRight: t.spanRight,
      backdrop: s.surface.toARGB32(),
      outline: _outlineColour(sheet.theme, t.variant),
    );
  }

  for (final sheetName in _sheets.keys) {
    final sheet = _sheets[sheetName]!;

    test("$sheetName: extractor reads the sheet's known geometry", () {
      const widths = {
        'axis': 54,
        'diagonal': 78,
        'eighth': 52,
        'noHighlight': 83,
        'center': 53,
        'today': 49,
        'neutral': 48,
        'accent': 76,
      };
      for (final t in _tags) {
        final f = onSheet(sheetName, t);
        final top = t.row == 1 ? sheet.row1Top : sheet.row2Top;
        expect(f.left, t.left, reason: t.name);
        expect(f.top, top, reason: t.name);
        expect(f.height, 24, reason: t.name);
        expect(f.width, widths[t.name], reason: t.name);
        final fill = sheet.fills[t.name];
        if (fill != null) {
          expect(hex(f.fill), hex(fill), reason: '${t.name} fill');
        }
        final outline = sheet.outline[t.name];
        if (outline != null) {
          final p = f.outlinePixels!;
          expect(hex(p[0]), hex(outline[0]), reason: '${t.name} full');
          expect(hex(p[1]), hex(outline[1]), reason: '${t.name} half');
          expect(hex(p[2]), hex(outline[0]), reason: '${t.name} top full');
          expect(hex(p[3]), hex(outline[1]), reason: '${t.name} top half');
        }
        expect(f.cornerOuter, isTrue, reason: '${t.name} radius 6 outer');
        expect(f.cornerInner, isTrue, reason: '${t.name} radius 6 inner');
      }
    });

    for (final t in _tags) {
      testWidgets('$sheetName: ZodiannTag matches the sheet: ${t.name}', (
        tester,
      ) async {
        final s = sheet.theme.extension<ZodiannSurfaces>()!;
        final design = onSheet(sheetName, t);
        final render = await renderTag(tester, sheet.theme, t.variant, t.label);
        final flutter = measureTag(
          render.image,
          left: tagCellOrigin,
          top: tagCellOrigin,
          spanRight: tagCellOrigin + 100,
          backdrop: s.surface.toARGB32(),
          outline: _outlineColour(sheet.theme, t.variant),
        );

        expect(flutter.left, tagCellOrigin, reason: 'left');
        expect(flutter.top, tagCellOrigin, reason: 'top');
        expect(flutter.height, design.height, reason: 'height');
        expect(
          flutter.width,
          inInclusiveRange(design.width - 1, design.width + 1),
          reason:
              'width ${flutter.width} vs ${design.width} '
              '(layout ${render.layoutWidth}, Chrome ${t.chromeWidth})',
        );
        _channels(flutter.fill, design.fill, 1, 'fill');
        _channels(flutter.label, design.label, 3, 'label');
        expect(flutter.cornerOuter, design.cornerOuter, reason: 'cornerOuter');
        expect(flutter.cornerInner, design.cornerInner, reason: 'cornerInner');
        if (_outlined.contains(t.variant)) {
          for (var i = 0; i < 4; i++) {
            _channels(
              flutter.outlinePixels![i],
              design.outlinePixels![i],
              3,
              'outline pixel $i',
            );
          }
        }
      });

      testWidgets('$sheetName: layout width matches Chrome: ${t.name}', (
        tester,
      ) async {
        final render = await renderTag(tester, sheet.theme, t.variant, t.label);
        expect(render.layoutWidth, closeTo(t.chromeWidth, 0.5));
      });
    }

    testWidgets('$sheetName: accent fill', (tester) async {
      final accent = _tags.last;
      final s = sheet.theme.extension<ZodiannSurfaces>()!;
      final design = onSheet(sheetName, accent);
      // A float Color.alphaBlend gives 0xFF222224 / 0xFFF0F0F1: never the
      // expected value.
      expect(
        hex(design.fill),
        hex(sheetName == 'dark' ? 0xFF222225 : 0xFFF1F1F1),
      );
      final render = await renderTag(
        tester,
        sheet.theme,
        accent.variant,
        accent.label,
      );
      final f = measureTag(
        render.image,
        left: tagCellOrigin,
        top: tagCellOrigin,
        spanRight: tagCellOrigin + 100,
        backdrop: s.surface.toARGB32(),
      );
      _channels(f.fill, design.fill, 1, 'accent fill');
    });
  }
}
