# Zodiann design system (MASTER)

The visual source of truth for implementing Zodiann. Read it together with `zodiann-specification.md`: the spec decides **what** is on screen, and this file and the PNGs decide **how it looks**. When they disagree, stop and ask. Don't pick one yourself.

- High-fidelity screens: `screens/` (desktop, 1440 px wide)
- Phone and tablet layouts: `responsive/mobile/` (390 px, @2x) and `responsive/tablet/` (834 × 1194 portrait, 1194 × 834 landscape)
- Every component state: `components/components_dark.png`, `components/components_light.png`
- Original assets: `assets/` (app logo, 33 icons, fonts)
- Why things are the way they are: `DESIGN_DECISIONS.md`

File names read `<screen>_<device>_<lang>_<theme>.png`. Pixel values are logical pixels (ARCH-8).

---

## 1. Concept: a modern precision instrument

Zodiann should feel like premium analytical software, sleek, quiet and exact, not like a horoscope app, a SaaS dashboard or anything antique.

- **The two instruments are the hero.** The wheel and the square are the only richly drawn elements. Everything around them (controls, tables, panels) is quiet, flat and aligned.
- **Monochrome accent.** Interactive emphasis is crisp white on dark and near-black on light: the primary button, the active drawer item, selected segments, the selected row edge, focus rings and the wheel's pointer. There is no decorative accent colour.
- **The logo is the only brand colour.** The app icon's zodiac ring and Square of Nine mark is the brand. The interface itself stays monochrome, so the logo stands out.
- **Colour carries data only where the spec assigns a role.** Elements (WH-1), aspects (WH-6), the square's highlights (SQ-12 to SQ-15, Appendix D) and the body colours. These are clean, saturated and modern. Every other surface is cool neutral.
- **Hairlines over boxes.** Panels separate content with 1 px rules and are not stacked as identical cards. No shadows in the dark theme, except for floating layers (drawer, dialog, toast).
- **Nothing antique.** No cream or parchment, no brass, no serif display type, no textures.

## 2. Colour tokens

Components reference semantic tokens only (ARCH-7). Flutter: put them in `ColorScheme` plus one `ThemeExtension` per group (`ZodiannSurfaces`, `SquareColors`, `ZodiacColors`, `AspectColors`, `BodyColors`).

### 2.1 Surfaces, text, accent

| Token | Dark (Graphite) | Light (Porcelain) | Use |
|---|---|---|---|
| `bg` | `#08080A` | `#F5F6F8` | Page background, deep cool graphite / cool white |
| `bg-raised` | `#0E0E11` | `#EEF0F3` | Inputs, segmented track, wheel inner disc, note boxes |
| `surface` | `#111114` | `#FFFFFF` | Panels, drawer, dialogs |
| `surface-2` | `#18181C` | `#F4F5F7` | Secondary button, hover row |
| `surface-3` | `#212126` | `#E9EBEF` | Selected segment, toast |
| `line` | `#2A2A30` | `#D9DCE1` | Control borders, wheel rings |
| `line-soft` | `#1B1B20` | `#E7E9ED` | Panel borders, row dividers |
| `text` | `#F4F5F7` | `#0B0C0E` | Primary text, crisp cool white / near-black |
| `text-2` | `#A0A4AD` | `#4B5059` | Secondary text, labels |
| `text-3` | `#7C808A` | `#646A74` | Table headers, faint metadata (≥ 4.5:1 on `bg`) |
| `accent` | `#F4F5F7` | `#0B0C0E` | Primary button fill, play button, pointer, active indicators |
| `accent-strong` | `#FFFFFF` | `#000000` | Hover on accent fills |
| `accent-soft` | `rgba(255,255,255,.07)` | `rgba(11,12,14,.06)` | Active drawer item, selected row tint, selected chips |
| `accent-line` | `rgba(255,255,255,.24)` | `rgba(11,12,14,.26)` | Accent outline button, selected segment ring, wheel rim |
| `on-accent` | `#0A0A0B` | `#FFFFFF` | Text and icons on an accent fill |
| `focus` | `#FFFFFF` | `#0B0C0E` | 2 px keyboard focus ring, offset 2 |
| `scrim` | `rgba(0,0,0,.72)` | `rgba(11,12,14,.40)` | Drawer and dialog backdrop |
| `danger` | `#F2555A` | `#DC3545` | Errors, destructive actions |
| `ok` | `#34D399` | `#15803D` | Success status dot |

### 2.2 Square of Nine (Appendix D)

| Token | Dark | Light | Rule |
|---|---|---|---|
| `axis-fill` / `axis-ink` / `axis` | `#16305A` / `#D6E4FF` / `#4F8CFF` | `#DCE8FF` / `#12357A` / `#2E6BE6` | Blue: 0°, 90°, 180°, 270° |
| `diag-fill` / `diag-ink` / `diag` | `#3D3412` / `#F3E3A3` / `#E2BF3E` | `#FBEFC2` / `#5C4500` / `#A87F00` | Muted yellow: 45°, 135°, 225°, 315° |
| `eighth-fill` / `eighth-ink` | `#222226` / `#C4C6CC` | `#ECEDF0` / `#3B4049` | Gray: other multiples of 22.5° |
| `cell-fill` / `cell-ink` / `cell-line` | `#0E0E11` / `#8A8E97` / `#1C1C21` | `#FFFFFF` / `#646A74` / `#E7E9ED` | Unhighlighted cell, 1 px grid |
| `center` | `#F5A524` | `#D97706` | Amber border on cell 1 |
| `today` | `#2DD4BF` | `#0E9F8E` | Turquoise border on today's cell |
| `sel-outer` / `sel-inner` | `#FFFFFF` / `#08080A` | `#0B0C0E` / `#FFFFFF` | Selected cell (see DESIGN_DECISIONS D11) |

`axis` and `diag` (without `-fill`) are the saturated versions, used for legend text, mini thumbnails and the highlight-line accent bar.

### 2.3 Zodiac (WH-1, WH-6, WH-3)

| Group | Token: dark / light |
|---|---|
| Elements | `fire` `#F2735A` / `#D9472B`, `earth` `#7CC47F` / `#2F8F3E`, `air` `#E8D06E` / `#A88600`, `water` `#5AA9FF` / `#1F6FD6`. Sign sector tint = element colour at 10 % (dark) / 9 % (light) |
| Aspects | `asp-conj` `#F5A524` / `#D97706` (amber), `asp-soft` `#2DD4BF` / `#0E9F8E` (turquoise: sextile, trine), `asp-hard` `#F2555A` / `#DC3545` (red: square, opposition). The retrograde mark ℞ uses `asp-hard` |
| Bodies | sun `#F5C042`/`#B98500`, moon `#D4D8E0`/`#646A74`, mercury `#8EC5E8`/`#2B7DB0`, venus `#F0A3C0`/`#C2457A`, mars `#F2555A`/`#DC3545`, jupiter `#F29E5C`/`#C4621A`, saturn `#C9B37E`/`#7D6A33`, uranus `#4FD1C5`/`#0E8C82`, neptune `#7B93FF`/`#3D5AE0`, pluto `#B48CF2`/`#7A45C9`, node `#9CA1AB`/`#646A74` |

A body is never identified by colour alone. Its glyph is always drawn, and its name appears wherever there is room.

## 3. Typography

One crisp family: **IBM Plex Sans** for Latin and **IBM Plex Sans Hebrew** for Hebrew (it also covers Latin, so in Hebrew it is the whole UI family). The large numbers use the light weight with tight tracking for a sleek, instrument-like readout; titles use semibold.

| Role | Size / line-height | Weight, tracking | Where |
|---|---|---|---|
| Hero wordmark | 56 / 1.0 (phone 40) | 300, −0.035 em | About hero "Zodiann" |
| Display readout | 44 / 1.0 (phone 34) | 300, −0.03 em | Under-the-pointer readout, selected cell number |
| Section title | 26 / 1.2 | 600, −0.02 em | Saved squares heading |
| Wordmark (drawer) | 20 | 600, −0.01 em | Drawer header |
| Screen title | 18 / 1.2 | 600, −0.01 em | Top bar title |
| Panel title | 16 / 1.3 | 600 | Panel heads |
| Body | 14 / 1.45 | 400 | Default text, table cells |
| Small | 13 | 400–500 | Segments, secondary text, details rows |
| Label | 12 | 500 | Field labels, table headers, subtitles |
| Micro | 11–11.5 | 400–500 | Square cells, axis labels |
| Glyphs | per context | 400 | Noto Sans Symbols, then Noto Sans Symbols 2: ♈–♓, ☉☽☿♀♂♃♄♅♆♇☊, ℞, aspect glyphs |

- **Tabular figures everywhere** (`FontFeature.tabularFigures()`), so degree, date and number columns align.
- Append U+FE0E (text presentation) to every astrological glyph so no platform renders it as an emoji.
- Both families ship with the app (offline, DATA-7). The woff2 files in `assets/fonts/` are for the mockups only, so bundle the TTF/OTF in Flutter.
- Sentence case for every label. No all-caps labels and no letter-spaced eyebrows.
- Times are always 24-hour and digits are always Western (L-13, L-14).

## 4. Spacing, radius, elevation, sizing

- **Spacing scale (4-based):** 4, 8, 12, 16, 20, 24, 32, 40, 48.
  - Desktop/tablet page gutter: 24. Phone: 16.
  - Gap between panels: 20 on desktop/tablet, 16 on phone.
  - Panel padding: 20 on desktop/tablet, 16 on phone. Panel head height: 56 (phone 52).
- **Radius:**
  - 3: square cells' outer frame, legend swatches
  - 6: tags, segment thumbs
  - 8: buttons, inputs
  - 12: panels
  - 16: dialogs
  - pill: chips
  - Hierarchy is deliberate: the bigger the container, the bigger the radius. Square cells themselves have no radius.
- **Elevation:**
  - Dark theme: surfaces get lighter instead of casting shadows.
  - Floating layers (drawer, dialog, toast) use `0 24 64 rgba(0,0,0,.55)` plus a 1 px `line` outline.
  - Light theme uses `0 24 56 rgba(21,25,31,.18)`.
- **Control heights:**
  - Buttons and inputs: 40 (small: 32). Segment thumbs: 32 inside a 3 px track.
  - Table rows: 44. Hamburger and icon buttons: 46 × 46 (NAV-1), small icon buttons 36.
  - Play button: 48 circle. Switch: 40 × 24. Orb stepper: 36 high.
- **Icons:** 20 in controls, 16 inside small buttons and fields.

## 5. Shell and navigation (NAV-1 to NAV-7)

- **Top bar:**
  - Sticky, 64 high (phone 60), `bg` at 88 % with a 10 px blur and a `line-soft` bottom rule.
  - Order from the start side: hamburger (46 × 46), then the title (18/600) over the subtitle (12, `text-2`), then screen actions at the end.
  - The bar mirrors in Hebrew.
  - Screen actions: the square shows **Save** (secondary) and **Export to Excel** (primary). On a phone these become two icon buttons (download, bookmark).
- **Drawer:**
  - Opens from the start side at `min(320, 86 %)`, on a `surface` background with a `scrim` backdrop.
  - Header: 76 high, holding the app logo (40) and the "Zodiann" wordmark (20/600, −0.01 em), with a close button at the end.
  - Items are grouped as "Analysis" (Wheel, Square) and "Library and app" (Saved, Settings, About).
  - Each item shows an icon, its name (14/500) and a description (12, `text-2`). The active item gets `accent-soft` fill, `text` icon and name at full strength, and a 3 px `accent` bar on the start edge.
  - Footer: the version and "All data stays on this device".
  - The drawer is the same at every size and is never permanent (NAV-7). See `screens/00-navigation-drawer_*`, `responsive/mobile/navigation-drawer_*`.

## 6. Breakpoints

| Name | Width | Layout rule |
|---|---|---|
| Phone | < 700 | One column, 16 gutter, controls go full width, segmented controls stretch evenly |
| Tablet | 700–1099 | The hero instrument spans the full width with its readout or details beside or above it; secondary panels sit two up |
| Desktop / tablet landscape | ≥ 1100 | Instrument plus side column; content max width 1440 (secondary screens 1080–1180, centred) |

A phone is a different composition, not a scaled-down desktop. The wheel switches to its compact drawing, the crossing table becomes a two-line list, the square's details move above the square, and the square scrolls sideways inside its panel.

## 7. Zodiac wheel screen

Reference: `screens/01-zodiac-wheel_*`, `responsive/*/zodiac-wheel_*`.

### 7.1 Layout

- **Desktop:** grid `1fr | 470`. The wheel panel spans two rows on the start side. **Time** and **Positions** stack on the end side. **Degree crossings** takes the full width below.
- **Tablet:** the wheel panel goes full width, with a 250 px readout column beside the wheel. Time goes full width, then Positions and Degree crossings sit side by side, with the crossings shown as a list.
- **Phone:** everything stacks in this order: wheel, readout and aspect legend, Time, Positions, Degree crossings.

### 7.2 The wheel drawing

Proportions are given as a fraction of the outer radius R, so the wheel scales.

| Ring | Desktop | Compact (phone and tablet) |
|---|---|---|
| Outer halo, `line` at 50 % | 1.02 R | same |
| Sign band, element tint at 11 %, `accent-line` rim, 30° separators in `line` | 0.987 R to 0.833 R | 0.987 R to 0.80 R |
| Degree ticks, inward from the band | 1° → 5 px, 5° → 9 px, 10° → 14 px (`text-2`) | same |
| Degree numbers (10, 20 within the sign) | 22 px inside the band, 9.5 px | 14 px |
| Body glyph discs | 0.64 R, disc r 14, glyph 17 px | 0.60 R, disc r 21, glyph 27 px |
| Body degree labels | 0.547 R, 11.5/600, ℞ in `asp-hard` | 0.467 R, 19 px |
| Inner disc (`bg-raised`), aspect chords and true-position dots | 0.453 R, dots r 3.2 | 0.373 R, dots r 4.5 |

- **Sign glyphs** sit centred in the band and are coloured by element (21 px, compact 30).
- **Connector:** a 1 px line in the body's colour, at 75 % opacity, runs from the body's **true** degree on the scale to its **displayed** disc (WH-3, WH-4).
- **Display spread:** bodies closer than 11° are pushed apart on desktop, and closer than 16° in the compact wheel, because a phone needs more room.
- **Aspect chords:** 1.3 px at 90 % opacity, drawn between the true positions on the inner disc. The node is excluded.
- **Pointer:** a fixed `accent` triangle (18 × 18) above the rim, plus a 1.5 px `accent` line across the sign band at 12 o'clock. The wheel rotates under the pointer, which never moves (WH-7).
- **Orientation:**
  - Longitude increases counterclockwise.
  - The drawing is LTR and **never mirrors** in Hebrew (L-6). In Flutter, wrap the painter in `Directionality(textDirection: TextDirection.ltr)`, and for any text drawn on the canvas.
- **Focus (WH-10):** a dashed `focus` ring outside the rim when the wheel holds keyboard focus.

### 7.3 Around the wheel

- **Drag mode** (WH-9): a segmented control in the wheel panel head, "Rotate wheel" / "Change date", with a one-line hint at the end that changes with the mode.
- **Readout** (WH-7):
  - Label "Under the pointer", then the position in display type (44/300): `17°03′`, the sign glyph in its element colour, and the sign name at 26 in `text-2`.
  - Below it, "Within 3° of the pointer" with one pill chip per body: glyph, name and position.
  - An aspect legend sits beside the readout on desktop and below it on a phone.
- **Time panel** (WH-11):
  - A date-and-time field with the **Now** button in accent outline.
  - The step as a full segmented control: Hour / Day / Week / 30 days.
  - Transport: back (46 boxed), play (48 `accent` disc, which becomes an `accent` ring with a pause glyph while playing), forward.
  - The device time zone is shown at the end of the transport row.
- **Positions table** (WH-15):
  - Columns: Body (glyph and name), Sign (glyph and name), Position `14°32′` (500), Motion (Direct in `text-2` / `℞ Retrograde` / `℞ Mean`).
  - The row under the pointer is selected.
  - On a phone the Motion column and the sign names are dropped, and ℞ moves next to the position.
- **Degree crossings** (WH-16, WH-17):
  - Head: title, counter ("43 crossings") and an Export button (small).
  - Filters in one row on desktop (Body 1.3fr, From, To, Sign, Degree .7fr), and in two columns on tablet and phone.
  - Table: Local date and time (date, two spaces, then the time in `text-3`), Body, Sign, Degree, Motion.
  - Phone and tablet use a two-line list: body glyph | date and time over "Body → Sign" | sign glyph, degree, ℞.
  - The list fades out at the bottom edge of its scroll area.

## 8. Gann Square of Nine screen

Reference: `screens/02-square-of-nine_*`, `responsive/*/square-of-nine_*`.

### 8.1 Layout

- **Controls panel:**
  - One wrapping row: Mode (segmented) | Anchor field with "Anchor to today" or "Anchor to now" (date modes only) | Size (segmented 9×9, 13×13, 17×17, 21×21, Custom) | Cells input (disabled unless Custom) | **Show up to today** (accent outline, date modes only).
  - Below a rule: the actual count, "289 cells, 17 × 17" (SQ-10), followed by the Today tag and the today cell number.
- **Desktop:** grid `1fr | 360`. The square panel is on the start side and the details panel floats sticky beside it (SQ-16).
- **Tablet portrait:** the details become a full-width strip **above** the square (number column 240, then a 4-column detail grid).
- **Phone:** the details go above the square in a single column. The square scrolls horizontally inside its panel, with a "Swipe the square sideways" hint (SQ-20). The page never scrolls sideways.

### 8.2 The square

- **Single canvas in the app (ARCH-5).** The mockup draws it with cells, but the look is what counts:
  - 1 px `cell-line` gaps and a 1 px `line` outer border.
  - Cell content is centred, 11.5 px.
- **Highlights:** fill from the role table (§2.2), weight 500 for highlighted cells.
- **Non-colour marks (NFR-X4):** a 9 px glyph in the cell's top-end corner at 70 % opacity. **+** marks an axis and **×** marks a diagonal. An eighth is marked by its lighter neutral fill.
- **Borders**, inset and stacking from the outside in:
  - Selected: 2 px `sel-outer` + 2 px `sel-inner`.
  - Selected and today: 2 px `sel-outer` + 2 px `today`.
  - Today: 2 px `today`.
  - Center: 2 px `center`.
  - Center that is also today: double turquoise, 2 px + 2 px gap + 2 px (SQ-7).
- **Cell sizes** (SQ-20):

  | Mode | Desktop | Tablet | Phone | Allowed range |
  |---|---|---|---|---|
  | Numbers | 50 | 52 | 38 | 30–56 |
  | Dates | 52 | 52 | 44 | 40–64 |
  | Date and time | 58 | 58 | 50 | 46–72 |

  Use the largest size in range that fits the available width. If even the minimum doesn't fit, scroll.
- **Content:**
  - Numbers: `1,771`.
  - Dates: `4.1.22`.
  - Date and time: the date over `HH:MM` at 86 % size and 78 % opacity.
- **Axis labels** sit in a 24 px band outside the square: "90° N" top, "270° S" bottom, "0° W" start (rotated), "180° E" end (rotated). The degree is in `axis`, the letter in `text-3`.
- **Direction:** the square is **always LTR** (SQ-21). Wrap it in `Directionality(ltr)`, and in Hebrew the scroll view starts at the left edge.
- **Legend** (SQ-22), below a rule:
  - Six swatches: Axes +, Diagonals ×, Eighths, Center, Today, Selected, each with its angle list.
  - One line explaining how the angle is measured.

### 8.3 Cell details (SQ-17, SQ-18)

- **Head:**
  - The label "Cell", then the number in display type (44).
  - Tags: the highlight tag with its mark (Axis +, Diagonal ×, Eighth, No highlight, Center), and **Today** in turquoise outline when it applies.
- **Date block** (date modes): the full weekday date (with the time in hour mode) on `bg-raised`, and below it "138 days after the anchor" or "204 hours after the anchor".
- **Rows** (13 px, label in `text-2`, value in 500 at the end):
  - Squared `139² = 19,321`
  - Square root `√139 = 11.7898`
  - Ring `6 (48 cells)`
  - Angle `90°`
  - Direction `Axis, north`
  - Offset from center `6 up`
  - Multiple of 45° / of 22.5°: Yes or No
- **Highlight line:** a `bg-raised` box with a 3 px accent bar on the start side in the highlight's colour, for example "Blue: on the 90° axis, north of the center".

## 9. Saved squares, Settings, About

- **Saved squares** (`screens/03-*`):
  - Head: section title (26/600), a counter ("7 of 100 saved") and the primary "Save current square".
  - One panel with a row per square: a mini thumbnail (52 px, the real highlight pattern), the name (16/500), and meta (mode tag, size, anchor).
  - Then Updated, then Open plus rename and delete icon buttons.
  - Inline rename turns the name into a focused input with a primary Save.
  - On a phone, the actions collapse into an overflow (⋮) button.
  - The empty state is in the component sheet.
- **Settings** (`screens/04-*`):
  - Two columns on desktop, one on tablet and phone.
  - Panels: Language and region, Appearance, Square defaults, Your data (start column); Wheel and computation (end column).
  - Each row has a label and hint at the start and the control at the end. Long controls (body chips, orb steppers, ephemeris radios) stack below the label.
  - **Delete all data** is red and opens a confirmation dialog (`04-settings_delete-dialog_*`, DATA-10).
- **About and sources** (`screens/05-*`):
  - Hero: the app logo at 132 px, "Zodiann" at 56/300, the version and build, and a one-sentence purpose.
  - Then the sources table, method settings, the Gann method (the formula set left to right), the Not advice notice (R-5), Privacy, and licenses.

## 10. Components and states

See `components/components_{dark,light}.png`.

- **Buttons:**
  - Primary: `accent` fill (white on dark, near-black on light), `on-accent` text, 600.
  - Secondary: `surface-2` with a `line` border (the default).
  - Accent outline: time and anchor shortcuts (Now, Show up to today, Anchor to …).
  - Quiet: Cancel.
  - Danger: outline, or solid inside a confirmation dialog.
  - States: hover lightens one step (+12 %), focus shows a 2 px `focus` ring offset 2, pressed moves 1 px down and darkens 6 %, disabled is 42 % opacity.
  - Rule: at most one primary per region.
- **Inputs:**
  - Label above at 12/500 `text-2`, field 40 high on `bg-raised` with a `line` border, leading icon in `text-3`.
  - Focus: `accent` border plus a 3 px `accent-soft` halo.
  - Error: `danger` border plus a halo, with the message under the field saying how to fix the value.
  - Disabled: 45 % opacity.
- **Segmented control:**
  - A `bg-raised` track with a 3 px inset.
  - The selected thumb is `surface-3` with an inset 1 px `accent-line` ring, and its icon is full-strength `text`.
  - A planned option (Sidereal) shows at 40 % opacity.
- **Others:** switch, orb stepper (− value +), body chips (on = `accent-soft` plus `accent-line`), radio list for the ephemeris source.
- **Tags:** 24 high, 6 radius, 12/600. There are highlight tags, outline tags for Today and Center, a neutral tag for modes and an accent tag.
- **Tables:**
  - Header 12/500 `text-3`, in sentence case.
  - Rows 44 with a `line-soft` divider.
  - Hover is `surface-2`. Selected is `accent-soft` with a 3 px `accent` edge on the start side.
- **Feedback:**
  - Toast for export status (EX-6): preparing with a progress bar, saved with a Share action, canceled, or error with a cause and a remedy.
  - Progress toast for long crossing computations, with Stop (NFR-P3).
  - Neutral banners (`accent-soft` fill, `accent-line` border) for SQ-6 messages and the ΔT and range warnings (R-2).
  - Red banner for unavailable storage (NFR-R1).
- **Dialog:** 420 wide, radius 16, title 20/600, with the actions at the end.

## 11. Iconography and assets

- **Icons:**
  - Drawn for Zodiann: 24 grid, 1.6 px round stroke, no fills except play, pause and small dots. They live in `assets/icons/*.svg`.
  - In Flutter use them as SVG (flutter_svg) or convert them to an icon font.
  - `chevL` / `chevR` mean back and forward and **swap in Hebrew**. `wheel`, `grid`, `rotate`, `datewheel`, `target` and `anchor` never mirror.
- **Logo:** the app icon (`assets/zodiann-logo.svg`): a five-by-five Square of Nine grid whose lit cells trace a Z (the top row, the diagonal through a centre cell holding a small dial, and the bottom row) inside a ring of the twelve zodiac glyphs, all in one pink, violet and cyan gradient, on a near-black rounded tile (corner radius 22 %).
  - Where it appears: the launcher icon, the drawer header (40 px), the About hero (132 px), exported files.
  - In-app copies (vector, with PNG renders at 1024 px beside them):
    - Dark theme: `assets/zodiann-logo-on-dark.svg`. The source with its tile removed, so the mark sits directly on any dark surface.
    - Light theme: `assets/zodiann-logo-on-light.svg`. No tile, the gradient deepened (× 0.78: `#be598e`, `#826cc3`, `#1ba5ba`) for contrast on white, and the empty grid cells filled black at 6 % instead of white at 6 %.
    - `assets/zodiann-logo.svg` (the mark on its tile) is the source for both and is the launcher icon. In Flutter use the SVGs with flutter_svg, or the PNGs.
  - Size: don't show it below 40 px. Its hairlines blur at small sizes in a raster image.
  - Ship it in the app as a vector or high-resolution asset so it stays crisp on high-density screens.
- **No illustrations.** The instruments are the imagery.

## 12. Motion

- Wheel snap to a body (WH-13): 450 ms, `easeInOutCubic`, taking the shortest arc.
- Drawer: opens in 240 ms (`easeOutCubic`) and closes in 180 ms. The scrim fades in step.
- Selection and segment changes: 120 ms crossfade. Hover: 150 ms.
- Playback (WH-11): one step every 110 ms, with no easing between steps.
- **Reduced motion** (NFR-X6, WH-13): every animation above becomes an instant change, and playback still steps.
- No decorative or ambient motion, no glow pulses, no entrance animations.

## 13. Hebrew and English

- The whole shell mirrors: the drawer and hamburger, panel order (the wheel goes to the right in Hebrew), table column order, text alignment, and the selected-row edge. Use only `EdgeInsetsDirectional` and `AlignmentDirectional`.
- **Never mirrored** (L-6): the wheel drawing, the square (including its scroll origin and axis labels), the Gann formula block, and numbers.
- **Isolation** (L-7):
  - Wrap every Latin run inside Hebrew text (Swiss Ephemeris, Asia/Jerusalem (UTC+2), JSON) in a direction isolate (`⁨ … ⁩` FSI/PDI in Flutter, or `Directionality` per span).
  - Dates and times stay LTR as **one** unit (`22.11.26  07:36`).
  - Don't force LTR on a string that contains Hebrew words. The mockups show what goes wrong when you do.
- Arrows that express reading order flip: `→` in English, `←` in Hebrew ("שמש ← קשת").
- Date formats: Hebrew uses `d.m.yyyy` in fields and `d.m.yy` in cells. English follows the d/m/y or m/d/y setting (L-12).
- Hebrew compass phrases in the details panel take the adjective form ("צפונית למרכז").

## 14. Accessibility floor

- Text meets WCAG AA in both themes: `text-3` on `bg` is at least 4.5:1.
- Touch targets are at least 44 (hamburger 46), with at least 8 between targets.
- Highlights always carry a mark (+ ×) in addition to their colour, and bodies always carry a glyph.
- Keyboard focus is always visible.
- Selection never relies on colour alone: borders and the accent edge back it up.
