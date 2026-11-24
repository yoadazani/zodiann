# Switch, orb stepper and body chip: sheet measurements (ZOD-UI-007)

`test/widgets/others_sheet_test.dart` compares `ZodiannSwitch`, `ZodiannOrbStepper`
and `ZodiannBodyChip` with the "Others" rows of
`design-reference/zodiann/components/components_{dark,light}.png` (1x, the kit's
1440 px viewport) and the Hebrew stepper with
`screens/04-settings_desktop_he_dark.png`. There are no generated images here;
this file records what was measured once, by `test/support/others_features.dart`
on the PNGs. The light sheet is 18 px higher than the dark one.

| Control | Dark sheet position | Measured |
|---|---|---|
| Orb stepper | (730, 2465) | 122 x 36; border `line`, fill `bg-raised`; `-` ink x 13..23 (centre 18), value ink 50..72, `+` ink 99..109 (relative to the box) |
| Switch on | (876, 2471) | 40 x 24; border and fill `accent`; thumb x 20..36, y 4..20, `on-accent` |
| Switch off | (928, 2471) | 40 x 24; border `line`, fill `surface-3`; thumb x 4..20, y 4..20, `text-3` |
| Chips (34 high, y 2544) | Sun 730 w 67, Moon 805 w 73, Mercury 886 w 88, Venus 982 w 75, Mean node 1065 w 109 | on: `accent-soft` fill, `accent-line` border; off: no fill, `line` border |

Known renderer differences, compared within tolerance rather than hidden: Chrome
paints text with LCD sub-pixel fringes (each ink channel is compared at its own
extreme), and Flutter draws the symbol-font glyph about 2 to 3 px higher than
Chrome inside a chip (glyph boxes are compared within 3 px).
