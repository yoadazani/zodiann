# Radio list reference (ZOD-UI-008)

`test/widgets/radio_sheet_test.dart` compares `ZodiannRadioList` with the
"Ephemeris source" block of the settings screens. There is no image of its own
here: the references are the designer's screens, read from
`design-reference/zodiann/screens/`.

| Screen | Theme | Language | Block (x) | Dot tops (y) |
|---|---|---|---|---|
| `04-settings_desktop_en_dark.png` | Graphite | English | 751 to 1265 | 707, 745, 784 |
| `04-settings_desktop_he_dark.png` | Graphite | Hebrew | 175 to 689 | 707, 745, 784 |
| `04-settings_desktop_he_light.png` | Porcelain | Hebrew | 175 to 689 | 707, 745, 784 |

The component sheet (`components/components_{dark,light}.png`) has **no** radio
list, although MASTER section 10 and the task file say its "Others" row shows
one. There is no English light screen, so Porcelain is proved with the Hebrew
light screen.

## What was measured (1x, English dark)

- Dot: 18 x 18 at the block's start edge. Selected: a 5 px ring in `accent`
  (`f4f5f7`) around an 8 px hole in the panel fill (`111114`). Off: a 1.5 px
  `line` ring (`29292f` at the outer pixel, `121215` at the next).
- Label: starts 30 px from the start edge (18 dot + 12 gap), 13 px of ink
  height, `text` (`f4f5f7`). Ink widths: 171, 221, 115 px.
- Badge: `text-3` (`7c808a`), 12 px, on the end edge (ink ends 1 px inside it).
- Row pitch in the mock: dot tops 707, 745, 784 (38 and 39 px). **The widget's
  rows are 44 apart** (owner decision O1, 2026-11-24: MASTER section 14's
  44 px target; the 8 px gap between targets is waived for these dense rows).
  The test therefore compares each row relative to its own dot centre and to
  the block's edges, never to an absolute vertical position.

## What is not matched, and why

- **Hebrew labels that mix scripts are 12 and 21 px wider on the screen.**
  Chrome sets the comma between the Latin and Hebrew runs with about 8 px of
  space on each side; Flutter's paragraph does not. The visual order is the
  same ("Swiss Ephemeris" at the start, then the comma, then the Hebrew). The
  label is the caller's text, so the test compares the width of the Latin-only
  labels (115 px, within 4) and the start edge, height and vertical centre of
  every label.
- The ring's outer pixels are compared loosely (24 per channel for the off
  ring) because Chrome and Flutter anti-alias a 1.5 px circle differently.
