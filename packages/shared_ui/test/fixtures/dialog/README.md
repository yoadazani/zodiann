# Dialog references (ZOD-UI-013)

**These are generated visual references, not designer-provided assets.** `kit.css`, `kit.js` and `MASTER.md` remain authoritative; the images never override or redefine them. `test/widgets/dialog_sheet_test.dart` compares `ZodiannDialog` against them.

## What is here

`generated_<theme>_<lang>_desktop.png`: headless-Chrome renderings (1440 x 900 at 1x) of `design-reference/zodiann/_source/settings.html?lang=<lang>&theme=<theme>&dialog=delete`, the same page and query the designer's own render job uses (`_source/render/jobs.json`).

- **Themes.** `dark` and `light`. The designer's PNG (`screens/04-settings_delete-dialog_desktop_en_dark.png`) is dark English only and remains the oracle for that dialog; the generated `light` images exist because the task's acceptance criterion asks for both themes and no light delete dialog was rendered. The generated `dark_en` image exists to prove the generator reproduces the designer's image (the test compares their box, fill, rows of ink and button boxes; a one-off scan of the dialog area found 89,010 flat, non-text pixels and none differed by more than 1 per channel, while text edges differ from font rasterisation only; that scan is not a committed test).
- **Languages.** `en` and `he` (the Hebrew dialog has a two-line message, so its box is 190 high instead of 210).
- **`manifest.json`.** The Chrome version, the device, and the SHA-256 (LF-normalised) of every file the renders depend on.

## What is compared

Our dialog and every image go through one extractor (`test/support/dialog_features.dart`): the box's edges and fill, the outline ring on the left side, the rows of ink (title, message lines, buttons) and the buttons' boxes. Edges are within 1 px, text rows within 2 px, button boxes within 2 px. Flutter rounds each of the message's three lines to 20 px where Chrome gets 60.9, so our box is a pixel or two shorter and sits on a half pixel: its top and bottom edges anti-alias, so the ring is checked on the left side only, and the buttons are measured from the box bottom. The shadow is checked as darker just below the box than far below it, and the ring as within 3 levels of the reference.

**Shadows in tests.** `flutter_test` turns shadows off (`debugDisableShadows`), which drops every blur and leaves a hard, unblurred rectangle. The pixel tests turn them back on for their duration (`_withShadows`), so the outline ring, which the floating shadow paints over, is compared with the reference's (within 3 levels: ours is 0.55 where the kit's is 0.6, MASTER wins, UI-003). A test that compares a shadow must do the same.

## Regenerating

Only when a kit file changes. From the workspace root:

```
fvm dart run tool/dialog/render_dialog_references.dart
```

- **Chrome:** `C:/Program Files/Google/Chrome/Application/chrome.exe`, unless `CHROME` names another executable.
- **Flags:** `--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-color-profile=srgb --font-render-hinting=none --force-device-scale-factor=1 --window-size=1440,900 --virtual-time-budget=5000 --screenshot=<png>`.
