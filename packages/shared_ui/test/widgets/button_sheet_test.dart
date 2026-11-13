// ZOD-UI-004 criterion 1: every button cell of the design's component sheet
// (design-reference/zodiann/components/components_{dark,light}.png,
// "Buttons": 5 variants × default / hover / focus / pressed / disabled,
// plus the small row) and the delete dialog's solid danger button, rendered
// by ZodiannButton with real input and measured by the same feature
// extractor on both sides.
//
// Tolerances: width ±1 (text rendering), fill / border ±1 per channel
// (filter rounding), label ±3 per channel (antialiasing); height, top
// (pressed +1) and the focus ring exact.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/button_features.dart';
import '../support/button_harness.dart';
import '../support/load_bundled_fonts.dart';

enum _State { normal, hover, focus, pressed, disabled }

/// The drawn box's left edge per column (both sheets).
const _columnX = {
  _State.normal: 221,
  _State.hover: 455,
  _State.focus: 689,
  _State.pressed: 923,
  _State.disabled: 1157,
};

typedef _Row = ({
  ZodiannButtonVariant variant,
  String label,
  bool icon,
  int darkTop,
  int lightTop,
});

const List<_Row> _rows = [
  (
    variant: ZodiannButtonVariant.primary,
    label: 'Export to Excel',
    icon: true,
    darkTop: 1709,
    lightTop: 1692,
  ),
  (
    variant: ZodiannButtonVariant.secondary,
    label: 'Save',
    icon: true,
    darkTop: 1761,
    lightTop: 1744,
  ),
  (
    variant: ZodiannButtonVariant.accentOutline,
    label: 'Show up to today',
    icon: true,
    darkTop: 1813,
    lightTop: 1796,
  ),
  (
    variant: ZodiannButtonVariant.quiet,
    label: 'Cancel',
    icon: false,
    darkTop: 1865,
    lightTop: 1848,
  ),
  (
    variant: ZodiannButtonVariant.danger,
    label: 'Delete',
    icon: true,
    darkTop: 1917,
    lightTop: 1900,
  ),
];

typedef _Small = ({
  ZodiannButtonVariant variant,
  String label,
  bool icon,
  int x,
  int spanX,
});

const List<_Small> _small = [
  (
    variant: ZodiannButtonVariant.secondary,
    label: 'Export',
    icon: true,
    x: 614,
    spanX: 110,
  ),
  (
    variant: ZodiannButtonVariant.primary,
    label: 'Small primary',
    icon: false,
    x: 723,
    spanX: 218,
  ),
];

Future<Rgba> _decode(String path) async {
  final bytes = File('../../design-reference/zodiann/$path').readAsBytesSync();
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = Rgba(image.width, image.height, data!);
  image.dispose();
  return rgba;
}

const _boundaryKey = Key('cell');

/// Renders [button] at (8, 8) in a 260 × 60 `surface` box, drives [state]
/// with real input, and returns the box's pixels.
Future<Rgba> _render(
  WidgetTester tester,
  ThemeData theme,
  _State state,
  ZodiannButton Function(VoidCallback? onPressed) button,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 600);
  addTearDown(tester.view.reset);
  final s = theme.extension<ZodiannSurfaces>()!;
  await pumpInApp(
    tester,
    RepaintBoundary(
      key: _boundaryKey,
      child: ColoredBox(
        color: s.surface,
        child: SizedBox(
          width: 260,
          height: 60,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 8,
                child: button(state == _State.disabled ? null : () {}),
              ),
            ],
          ),
        ),
      ),
    ),
    theme: theme,
  );

  TestGesture? held;
  final center = tester.getCenter(find.byType(ZodiannButton));
  switch (state) {
    case _State.hover:
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(center);
      await tester.pumpAndSettle();
    case _State.focus:
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    case _State.pressed:
      held = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 100));
    case _State.normal:
    case _State.disabled:
      await tester.pumpAndSettle();
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundaryKey),
  );
  late Rgba rgba;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    rgba = Rgba(image.width, image.height, data!);
    final dir = Platform.environment['ZODIANN_BUTTON_DIR'];
    if (dir != null) {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final name =
          '${theme.brightness.name}_${state.name}_'
          '${button(null).label.replaceAll(' ', '_')}.png';
      File('$dir/$name').writeAsBytesSync(png!.buffer.asUint8List());
    }
    image.dispose();
  });
  await held?.up();
  return rgba;
}

void _channels(int actual, int expected, int tolerance, String reason) {
  for (final shift in [16, 8, 0]) {
    final a = (actual >> shift) & 0xFF;
    final e = (expected >> shift) & 0xFF;
    expect(
      (a - e).abs(),
      lessThanOrEqualTo(tolerance),
      reason:
          '$reason: ${actual.toRadixString(16)} vs '
          '${expected.toRadixString(16)}',
    );
  }
}

void _compare(
  ButtonFeatures flutter,
  int flutterOriginY,
  ButtonFeatures png,
  int pngOriginY,
  String why, {
  bool edges = true,
}) {
  if (png.inkStart != null) {
    expect(
      (flutter.inkStart! - png.inkStart!).abs(),
      lessThanOrEqualTo(1),
      reason: '$why inkStart (flutter $flutter, png $png)',
    );
  } else {
    expect(
      (flutter.width! - png.width!).abs(),
      lessThanOrEqualTo(1),
      reason: '$why width (flutter $flutter, png $png)',
    );
    expect(flutter.height, png.height, reason: '$why height');
    expect(
      flutter.top! - flutterOriginY,
      png.top! - pngOriginY,
      reason: '$why top',
    );
    if (png.fill != null) _channels(flutter.fill!, png.fill!, 1, '$why fill');
    if (edges && png.border != null) {
      _channels(flutter.border!, png.border!, 1, '$why border');
    }
    expect(flutter.ring, png.ring, reason: '$why ring');
  }
  _channels(flutter.label, png.label, 3, '$why label');
}

void main() {
  setUpAll(loadBundledFonts);

  final sheets = {
    'dark': (
      file: 'components/components_dark.png',
      size: (1440, 5586),
      theme: ZodiannTheme.graphite,
      smallTop: 1989,
    ),
    'light': (
      file: 'components/components_light.png',
      size: (1440, 5569),
      theme: ZodiannTheme.porcelain,
      smallTop: 1972,
    ),
  };
  final pngs = <String, Rgba>{};
  late Rgba dialog;
  setUpAll(() async {
    for (final MapEntry(:key, :value) in sheets.entries) {
      pngs[key] = await _decode(value.file);
    }
    dialog = await _decode(
      'screens/04-settings_delete-dialog_desktop_en_dark.png',
    );
  });

  for (final MapEntry(key: sheetName, value: sheet) in sheets.entries) {
    final s = sheet.theme.extension<ZodiannSurfaces>()!;
    final board = s.surface.toARGB32();
    final focus = s.focus.toARGB32();

    test('$sheetName sheet is the expected size', () {
      expect((pngs[sheetName]!.width, pngs[sheetName]!.height), sheet.size);
    });

    test('$sheetName sheet default column has the measured literals', () {
      final png = pngs[sheetName]!;
      final dark = sheetName == 'dark';
      final expected = <ZodiannButtonVariant, (int, int, int)>{
        // (width, fill, border)
        ZodiannButtonVariant.primary: dark
            ? (156, 0xFFF4F5F7, 0xFFF4F5F7)
            : (156, 0xFF0B0C0E, 0xFF0B0C0E),
        ZodiannButtonVariant.secondary: dark
            ? (89, 0xFF18181C, 0xFF2A2A30)
            : (89, 0xFFF4F5F7, 0xFFD9DCE1),
        ZodiannButtonVariant.accentOutline: dark
            ? (169, board, 0xFF4A4A4C)
            : (169, board, 0xFFC0C0C1),
        ZodiannButtonVariant.danger: dark
            ? (100, board, 0xFF762F34)
            : (100, board, 0xFFEFA4AB),
      };
      for (final row in _rows) {
        final f = measureButton(
          png,
          originX: _columnX[_State.normal]! - 8,
          originY: dark ? row.darkTop : row.lightTop,
          drawnHeight: 40,
          spanX: 218,
          board: board,
          focus: focus,
          padding: 16,
          icon: row.icon,
          boxless: row.variant == ZodiannButtonVariant.quiet,
        );
        if (row.variant == ZodiannButtonVariant.quiet) {
          expect(f.inkStart, 8 + 17, reason: 'quiet ink start');
          continue;
        }
        final (width, fill, border) = expected[row.variant]!;
        expect(
          (f.width, f.fill, f.border, f.height),
          (width, fill, border, 40),
          reason: '${row.variant}: $f',
        );
      }
    });

    for (final row in _rows) {
      for (final state in _State.values) {
        testWidgets('$sheetName ${row.variant.name} ${state.name}', (
          tester,
        ) async {
          final boxless =
              row.variant == ZodiannButtonVariant.quiet &&
              state != _State.focus;
          final pngOriginY = sheetName == 'dark' ? row.darkTop : row.lightTop;
          final png = measureButton(
            pngs[sheetName]!,
            originX: _columnX[state]! - 8,
            originY: pngOriginY,
            drawnHeight: 40,
            spanX: 218,
            board: board,
            focus: focus,
            padding: 16,
            icon: row.icon,
            boxless: boxless,
          );
          final render = await _render(
            tester,
            sheet.theme,
            state,
            (onPressed) => ZodiannButton(
              label: row.label,
              variant: row.variant,
              onPressed: onPressed,
              icon: row.icon ? const SizedBox.square(dimension: 16) : null,
            ),
          );
          final flutter = measureButton(
            render,
            originX: 0,
            originY: 10,
            drawnHeight: 40,
            spanX: 250,
            board: board,
            focus: focus,
            padding: 16,
            icon: row.icon,
            boxless: boxless,
          );
          _compare(flutter, 10, png, pngOriginY, '${row.variant} $state');
        });
      }
    }

    for (final cell in _small) {
      testWidgets('$sheetName small ${cell.label}', (tester) async {
        final png = measureButton(
          pngs[sheetName]!,
          originX: cell.x - 8,
          originY: sheet.smallTop,
          drawnHeight: 32,
          spanX: cell.spanX,
          board: board,
          focus: focus,
          padding: 12,
          icon: cell.icon,
        );
        final render = await _render(
          tester,
          sheet.theme,
          _State.normal,
          (onPressed) => ZodiannButton(
            label: cell.label,
            variant: cell.variant,
            size: ZodiannButtonSize.small,
            onPressed: onPressed,
            icon: cell.icon ? const SizedBox.square(dimension: 16) : null,
          ),
        );
        final flutter = measureButton(
          render,
          originX: 0,
          originY: 14,
          drawnHeight: 32,
          spanX: 250,
          board: board,
          focus: focus,
          padding: 12,
          icon: cell.icon,
        );
        _compare(flutter, 14, png, sheet.smallTop, 'small ${cell.label}');
      });
    }
  }

  testWidgets('dialog solid danger "Delete all data"', (tester) async {
    final s = ZodiannTheme.graphite.extension<ZodiannSurfaces>()!;
    final board = s.surface.toARGB32();
    final focus = s.focus.toARGB32();
    final png = measureButton(
      dialog,
      originX: 773,
      originY: 491,
      drawnHeight: 40,
      spanX: 150,
      board: board,
      focus: focus,
      padding: 16,
    );
    expect(png.fill, 0xFFF2555A);
    final render = await _render(
      tester,
      ZodiannTheme.graphite,
      _State.normal,
      (onPressed) => ZodiannButton(
        label: 'Delete all data',
        variant: ZodiannButtonVariant.dangerSolid,
        onPressed: onPressed,
      ),
    );
    final flutter = measureButton(
      render,
      originX: 0,
      originY: 10,
      drawnHeight: 40,
      spanX: 250,
      board: board,
      focus: focus,
      padding: 16,
    );
    // The PNG box sits at a fractional x: no border / left comparison.
    _compare(flutter, 10, png, 491, 'dangerSolid', edges: false);
  });
}
