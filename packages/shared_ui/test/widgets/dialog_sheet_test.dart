// ZOD-UI-013 criterion 1: the dialog matches the designer's references in
// both themes.
//
// WHICH IMAGES ARE THE DESIGNER'S. Only the dark English delete dialog
// (screens/04-settings_delete-dialog_desktop_en_dark.png) and the component
// sheet's Save-square dialog (components/components_{dark,light}.png) are the
// designer's. The LIGHT and HEBREW delete dialogs are GENERATED from the kit
// with headless Chrome (tool/dialog/render_dialog_references.dart, images in
// test/fixtures/dialog/): kit.css and MASTER stay authoritative and the images
// never override them. The first test proves the tool reproduces the
// designer's dark English image.
//
// One extractor (support/dialog_features.dart) reads the box, its ring, the
// rows of ink and the button boxes from every image and from our render.
// Chrome snaps box edges to whole pixels and rounds text where Flutter does
// not: edges within 1 px, text rows within 2 px, button boxes within 2 px.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../support/dialog_features.dart';
import '../support/load_bundled_fonts.dart';
import '../support/pixels.dart';
import '../support/table_features.dart' show near;
import '../support/tag_features.dart' show decodeDesignPng;

const _boundary = Key('dialog-sheet');

const _en = (
  title: 'Delete all data?',
  message:
      'Your settings and 7 saved squares will be removed from this device. '
      'This cannot be undone. Export a backup first if you may need them.',
  cancel: 'Cancel',
  confirm: 'Delete all data',
);

// design-reference/zodiann/_source/settings.html and kit.js (lang he).
const _he = (
  title: 'למחוק את כל הנתונים?',
  message:
      'ההגדרות ו-7 ריבועים שמורים יימחקו מהמכשיר. אי אפשר לבטל את הפעולה. '
      'כדאי לייצא גיבוי קודם.',
  cancel: 'ביטול',
  confirm: 'מחיקת כל הנתונים',
);

typedef _Shot = ({Pixels image, Rect dialog});

/// Opens the delete dialog over a bare page at 1440 x 900 and captures the
/// whole screen.
Future<_Shot> _renderDelete(
  WidgetTester tester,
  ThemeData theme, {
  bool hebrew = false,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final copy = hebrew ? _he : _en;
  final s = theme.extension<ZodiannSurfaces>()!;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => RepaintBoundary(
        key: _boundary,
        child: hebrew
            ? Theme(
                data: withZodiannScript(
                  Theme.of(context),
                  ZodiannScript.hebrew,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              )
            : child,
      ),
      home: Scaffold(backgroundColor: s.bg),
    ),
  );
  showZodiannDialog<void>(
    tester.element(find.byType(Scaffold)),
    builder: (context) => ZodiannDialog(
      title: copy.title,
      message: copy.message,
      actions: [
        ZodiannButton(label: copy.cancel, onPressed: () {}),
        ZodiannButton(
          label: copy.confirm,
          variant: ZodiannButtonVariant.dangerSolid,
          onPressed: () {},
        ),
      ],
    ),
  );
  await tester.pump();
  final image = await Pixels.capture(
    tester,
    tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
  );
  return (image: image, dialog: tester.getRect(find.byType(ZodiannDialog)));
}

DialogFeatures _mine(_Shot shot) => measureDialog(
  shot.image.argb,
  probeX: shot.dialog.left.round() + 10,
  probeY: shot.dialog.top.round() + 20,
);

// Flutter rounds each of the message's three lines to 20 px where Chrome
// gets 60.9, so our box is a pixel or two shorter and, centred in the
// viewport, sits on a half pixel: its top and bottom edges anti-alias, so the
// ring is compared on the left side only (an edge on a whole pixel).
/// flutter_test turns shadows off (`debugDisableShadows`), which drops every
/// blur: a pixel test of a shadow must turn them on, and must turn them off
/// again before its body ends (the binding checks the flag before tear-down).
Future<void> _withShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

void _expectSimilar(
  DialogFeatures got,
  DialogFeatures want,
  String label, {
  bool absoluteLeft = true,
}) {
  expect(got.width, want.width, reason: '$label width');
  expect(
    (got.height - want.height).abs(),
    lessThanOrEqualTo(2),
    reason: '$label height ${got.height} vs ${want.height}',
  );
  if (absoluteLeft) expect(got.left, want.left, reason: '$label left');
  expect(near(got.fill, want.fill), isTrue, reason: '$label fill');
  // The ring is the `line` colour with the floating shadow painted over it, as
  // in the kit (it darkens the ring by about 30 % at the sides). Our shadow is
  // 0.55 where the kit's is 0.6 (MASTER wins, UI-003), so the ring may differ
  // by a level or two.
  expect(
    near(got.ringSide, want.ringSide, 3),
    isTrue,
    reason:
        '$label side ring ${got.ringSide.toRadixString(16)} vs reference '
        '${want.ringSide.toRadixString(16)}',
  );
  // Rows of ink: the title and the message lines relative to the box top, the
  // buttons relative to the box bottom (the message is a pixel shorter here,
  // which would otherwise shift everything below it).
  expect(
    got.ink.length,
    want.ink.length,
    reason: '$label ink groups ${got.ink} vs ${want.ink}',
  );
  for (var i = 0; i < want.ink.length; i++) {
    final last = i == want.ink.length - 1;
    int off(DialogFeatures f, int row) => last ? f.bottom - row : row - f.top;
    expect(
      (off(got, got.ink[i].$1) - off(want, want.ink[i].$1)).abs(),
      lessThanOrEqualTo(last ? 1 : 2),
      reason: '$label ink $i start ${got.ink[i]} vs ${want.ink[i]}',
    );
    expect(
      (off(got, got.ink[i].$2) - off(want, want.ink[i].$2)).abs(),
      lessThanOrEqualTo(last ? 1 : 2),
      reason: '$label ink $i end ${got.ink[i]} vs ${want.ink[i]}',
    );
  }
  expect(
    got.buttons.length,
    want.buttons.length,
    reason: '$label buttons ${got.buttons} vs ${want.buttons}',
  );
  for (var i = 0; i < want.buttons.length; i++) {
    expect(
      ((got.buttons[i].$1 - got.left) - (want.buttons[i].$1 - want.left)).abs(),
      lessThanOrEqualTo(2),
      reason: '$label button $i start ${got.buttons[i]} vs ${want.buttons[i]}',
    );
    expect(
      (got.buttons[i].$2 - want.buttons[i].$2).abs(),
      lessThanOrEqualTo(2),
      reason: '$label button $i length ${got.buttons[i]} vs ${want.buttons[i]}',
    );
  }
}

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('the generator reproduces the designer\'s dark English dialog', (
    tester,
  ) async {
    final designer = (await tester.runAsync(
      () => decodeDesignPng(
        'screens/04-settings_delete-dialog_desktop_en_dark.png',
      ),
    ))!;
    final generated = (await tester.runAsync(
      () => decodeFile('test/fixtures/dialog/generated_dark_en_desktop.png'),
    ))!;
    final a = measureDialog(designer.argb, probeX: 520, probeY: 365);
    final b = measureDialog(generated.at, probeX: 520, probeY: 365);
    expect(
      (b.left, b.right, b.top, b.bottom),
      (a.left, a.right, a.top, a.bottom),
    );
    expect(b.fill, a.fill);
    expect(b.ink, a.ink);
    expect(b.buttons, a.buttons);
    // The 420 x 210 box, centred in the 1440 x 900 viewport.
    expect((a.width, a.height), (420, 210));
  });

  final references = {
    'dark English (designer)': (ZodiannTheme.graphite, false, 'designer', 365),
    'dark English (generated)': (
      ZodiannTheme.graphite,
      false,
      'test/fixtures/dialog/generated_dark_en_desktop.png',
      365,
    ),
    'light English (generated)': (
      ZodiannTheme.porcelain,
      false,
      'test/fixtures/dialog/generated_light_en_desktop.png',
      365,
    ),
    'dark Hebrew (generated)': (
      ZodiannTheme.graphite,
      true,
      'test/fixtures/dialog/generated_dark_he_desktop.png',
      375,
    ),
    'light Hebrew (generated)': (
      ZodiannTheme.porcelain,
      true,
      'test/fixtures/dialog/generated_light_he_desktop.png',
      375,
    ),
  };

  for (final entry in references.entries) {
    testWidgets(
      'the delete dialog matches ${entry.key}',
      (tester) => _withShadows(() async {
        final (theme, hebrew, path, probeY) = entry.value;
        final ref = path == 'designer'
            ? (await tester.runAsync(
                () => decodeDesignPng(
                  'screens/04-settings_delete-dialog_desktop_en_dark.png',
                ),
              ))!.argb
            : (await tester.runAsync(() => decodeFile(path)))!.at;
        final want = measureDialog(ref, probeX: 520, probeY: probeY);
        final shot = await _renderDelete(tester, theme, hebrew: hebrew);
        final got = _mine(shot);
        // Centred in the viewport, as the reference is.
        expect(shot.dialog.center.dx, closeTo(720, 0.5));
        expect(shot.dialog.center.dy, closeTo(450, 0.5));
        _expectSimilar(got, want, entry.key);
        // The scrim over the page: a bare page here, the settings page there,
        // compared on the empty left margin.
        expect(
          near(shot.image.argb(50, 300), ref(50, 300), 1),
          isTrue,
          reason:
              'scrim over the page ${shot.image.argb(50, 300).toRadixString(16)} '
              'vs ${ref(50, 300).toRadixString(16)}',
        );
        // The shadow: darker just below the box than far below it.
        final below = shot.image.argb(720, got.bottom + 8) & 0xff;
        final far = shot.image.argb(720, got.bottom + 120) & 0xff;
        expect(below, lessThanOrEqualTo(far));
      }),
    );
  }

  // The sheet's Save-square dialog: a message with a 16 margin, a Name field
  // in its focused state, a quiet Cancel and a primary Save. It is rendered
  // there with `width: auto` in a three-column board: 423 wide, not 420.
  for (final entry in {
    'dark': (ZodiannTheme.graphite, 'components_dark.png', 5190),
    'light': (ZodiannTheme.porcelain, 'components_light.png', 5173),
  }.entries) {
    testWidgets(
      'the Save-square dialog matches the component sheet '
      '(${entry.key})',
      (tester) => _withShadows(() async {
        final (theme, sheetFile, sheetTop) = entry.value;
        final s = theme.extension<ZodiannSurfaces>()!;
        final sheet = (await tester.runAsync(
          () => decodeDesignPng('components/$sheetFile'),
        ))!;
        // The sheet's box: fill from x 65, the row 20 below its top edge.
        final want = measureDialog(
          sheet.argb,
          probeX: 75,
          probeY: sheetTop + 20,
        );
        tester.view.physicalSize = const Size(900, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            debugShowCheckedModeBanner: false,
            home: RepaintBoundary(
              key: _boundary,
              child: Scaffold(
                backgroundColor: s.bg,
                body: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(100, 100, 0, 0),
                    child: SizedBox(
                      width: 423,
                      child: ZodiannDialog(
                        title: 'Save square',
                        message: 'Saves the mode, anchor, size and highlights.',
                        content: ZodiannTextField(
                          label: 'Name',
                          focusNode: node,
                          controller: TextEditingController(
                            text: 'Spring equinox 2026',
                          ),
                        ),
                        actions: [
                          ZodiannButton(
                            label: 'Cancel',
                            variant: ZodiannButtonVariant.quiet,
                            onPressed: () {},
                          ),
                          ZodiannButton(
                            label: 'Save',
                            variant: ZodiannButtonVariant.primary,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        node.requestFocus();
        await tester.pump();
        final image = await Pixels.capture(
          tester,
          tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary)),
        );
        final rect = tester.getRect(find.byType(ZodiannDialog));
        final got = measureDialog(
          image.argb,
          probeX: rect.left.round() + 10,
          probeY: rect.top.round() + 20,
        );
        _expectSimilar(
          got,
          want,
          'Save square (${entry.key})',
          absoluteLeft: false,
        );
      }),
    );
  }

  test('the manifest hashes still match the kit files', () {
    final manifest = jsonDecode(
      File('test/fixtures/dialog/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final hashes = (manifest['sha256'] as Map<String, dynamic>)
        .cast<String, String>();
    expect(hashes, isNotEmpty);
    hashes.forEach((path, hash) {
      final text = File('../../$path')
          .readAsStringSync()
          .replaceAll('\r\n', '\n');
      expect(
        sha256.convert(utf8.encode(text)).toString(),
        hash,
        reason:
            '$path changed: regenerate the references '
            '(fvm dart run tool/dialog/render_dialog_references.dart)',
      );
    });
  });
}
