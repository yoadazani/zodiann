# Dialog references (ZOD-UI-013)

**These are generated visual references, not designer-provided assets.** `kit.css`, `kit.js` and `MASTER.md` remain authoritative; the images never override or redefine them. `test/widgets/dialog_sheet_test.dart` compares `ZodiannDialog` against them.

## What is here

`generated_<theme>_<lang>_desktop.png`: headless-Chrome renderings (1440 x 900 at 1x) of `design-reference/zodiann/_source/settings.html?lang=<lang>&theme=<theme>&dialog=delete`, the same page and query the designer's own render job uses (`_source/render/jobs.json`).

- **Themes.** `dark` and `light`. The designer's PNG (`screens/04-settings_delete-dialog_desktop_en_dark.png`) is dark English only and remains the oracle for that dialog; the generated `light` images exist because the task's acceptance criterion asks for both themes and no light delete dialog was rendered. The generated `dark_en` image exists to prove the generator reproduces the designer's image (the test compares them; of 89,010 flat, non-text pixels in the dialog area, none differs by more than 1 per channel; text edges differ from font rasterisation only).
- **Languages.** `en` and `he` (the Hebrew dialog has a two-line message, so its box is 190 high instead of 210).
- **`manifest.json`.** The Chrome version, the device, and the SHA-256 (LF-normalised) of every file the renders depend on.

## What is compared

Our dialog and every image go through one extractor (`test/support/dialog_features.dart`): the box's edges and fill, the outline ring on the left side, the rows of ink (title, message lines, buttons) and the buttons' boxes. Edges are within 1 px, text rows within 2 px, button boxes within 2 px. Flutter rounds each of the message's three lines to 20 px where Chrome gets 60.9, so our box is a pixel or two shorter and sits on a half pixel: its top and bottom edges anti-alias, so the ring is checked on the left side only, and the buttons are measured from the box bottom.

**Known limit.** With the same shadow definition (`0 24 64`, 0.55), Flutter's rasteriser darkens the 1 px ring at the box's sides far less than Chrome does (about 0 to 4 percent against 30 percent), so the ring is asserted to be the `line` colour and never darker than the reference, not equal to it. The shadow's strength on a real device is unchecked.

## Regenerating

Only when a kit file changes. From the workspace root:

```
fvm dart run tool/dialog/render_dialog_references.dart
```

- **Chrome:** `C:/Program Files/Google/Chrome/Application/chrome.exe`, unless `CHROME` names another executable.
- **Flags:** `--headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files --force-color-profile=srgb --font-render-hinting=none --force-device-scale-factor=1 --window-size=1440,900 --virtual-time-budget=5000 --screenshot=<png>`.
