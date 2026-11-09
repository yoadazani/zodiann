# Design decisions

Each entry records what was decided, why, and whether it needs your approval. Entries marked **Needs approval** interpret or stretch the specification. Everything else follows from the spec or the brief.

## Identity

**D1. Direction: modern precision instrument.** Zodiann aims for sleek, premium analytical software: deep cool graphite, crisp white type and clean data colours, with the wheel and the square as the only richly drawn elements. At your request this replaces an earlier "observatory instrument" direction (brass gold, parchment text, a serif display face), which read as antique and vintage. The design-system tool's neon sci-fi HUD style is still rejected, because the brief rules out glow.

**D2. Monochrome accent; the logo carries the brand colour.** Interactive emphasis uses the text colour at full strength: white on dark and near-black on light. That covers the primary button, the play button, the active drawer item, selected segments, the selected row edge, focus rings and the wheel's pointer. A monochrome accent is the most contemporary, least decorative choice. It never competes with the analytical colours, and it matches the spec's white selection border on the square. The pink, violet and cyan app logo is the only brand colour on screen, so it stays recognisable.

**D3. Deep cool-neutral backgrounds.** Dark ("Graphite") is `#08080A` with `#111114` panels: cool, but close to neutral, so the base doesn't turn blue (an earlier request). Text is crisp cool white `#F4F5F7` with cool grey secondaries, and there is no cream. Light ("Porcelain") is cool white `#F5F6F8` with white panels and near-black text. Blue appears only where the spec gives it a meaning (axis highlights, water signs, some bodies).

**D4. Typography: one crisp sans family, IBM Plex Sans and IBM Plex Sans Hebrew.** The earlier serif display face was removed as old-fashioned. Big readouts use Plex Light (300) with tight tracking, a sleek instrument look; titles use Semibold (600). Plex has matching Latin and Hebrew families with true tabular figures, is open-source, and ships offline.

**D5. Hairline panels instead of a card grid.** Panels have one border weight and a radius that grows with the container. There are no shadows on the dark theme. The two instruments carry the visual weight.

**D5a. The app icon is the logo.** The logo is a five-by-five Square of Nine grid whose lit cells trace a Z (the top row, the diagonal through a centre cell holding a small dial, and the bottom row) inside a ring of the twelve zodiac glyphs, all in one pink, violet and cyan gradient (`assets/zodiann-logo.svg`). It replaces the earlier purple and cyan hexagonal mark. It is used in the drawer, on the About screen and in the component sheet, without its tile: as is on dark, and on light with its gradient deepened slightly and its empty cells tinted dark instead of white so the grid still reads on white.

## Zodiac wheel

**D6. A compact wheel for phones and tablets.** Scaled down from desktop, the glyphs would render at about 9 px on a phone. The compact drawing keeps the geometry but narrows the sign band, enlarges the glyphs (27 px in a 644 unit drawing, about 15 px on a 390 px phone), and widens the display spread from 11° to 16°. WH-4 only says bodies are pushed apart "in the display only". **Needs approval:** WH-4 says 11°, and the phone uses 16° for legibility. The true position stays on the scale and the inner circle either way.

**D7. Aspect legend beside the wheel.** WH-6 defines three aspect colours, and the legend makes the chords readable without opening About. It is small and secondary.

**D8. The row under the pointer is selected in the positions table.** This ties the table to the pointer readout and to WH-13 (tapping a row rotates the wheel there).

**D9. Crossings become a list on phone and tablet.** Five columns don't fit a phone (NFR-C2: tables must not break the width), so each crossing becomes a two-line row: date and time, then "Body → Sign", with the sign glyph, degree and ℞ at the end.

## Gann Square of Nine

**D10. Highlights carry a mark as well as a colour (NFR-X4).** Axis cells carry a small **+**, diagonal cells a small **×**, and eighths a lighter neutral fill. The marks echo the meaning: + is the cross of the axes, × the diagonals. The same marks appear in the tags and the legend.

**D11. Selection border in the light theme. Needs approval.** SQ-16 says the selected cell gets a **white** border. On the light theme's white cells, a white border is invisible. The design keeps the white line and adds a 2 px ink outline outside it, so the dark theme is exactly white and the light theme is white plus ink. If you want the selection to stay strictly white in light theme, it will need a different background behind the square.

**D12. Border stacking order.** From the outside in: selected, today, center. This keeps every combination readable, and the center-is-today case is a double turquoise border as SQ-7 requires.

**D13. Compass labels around the square.** "90° N", "180° E", "270° S" and "0° W" sit outside the four edges. They put Appendix C's directions and the legend's "how the angle is measured" right on the square, and they also show that the square doesn't mirror in Hebrew.

**D14. Details above the square on tablet portrait.** SQ-16 defines only "wide screen: beside" and "phone: above". An 834 px tablet can't fit a 13×13 square plus a 360 px panel side by side, so portrait tablets use the phone rule in a wider strip, and landscape tablets use the desktop rule. **Needs approval** as an interpretation of "wide screen".

**D15. The anchor field and "Show up to today" are hidden in numbers mode.** SQ-5 ties the anchor to "a date, or a date and time", and numbers mode always has 1 in the center (SQ-2). This doesn't decide the open Excel question about a numeric anchor (EX section), which stays open.

**D16. Rotating outer rings and planets on the square are not drawn.** Both are listed as planned extensions, and the rings are explicitly "an interpretation that needs approval", so the mockups don't invent their look. The square's axis-label band is the natural place for a future ring scale.

## Shell, settings, content

**D17. Drawer groups: "Analysis" and "Library and app".** The two instruments are separated from the supporting screens. Item names and descriptions follow NAV-3, and the drawer is never permanent (NAV-7).

**D18. Aspect orbs are editable in Settings. Needs approval.** The planning constraints say orbs "are configurable in settings", while open decision D-1 proposes "no editing" by default. The mockup shows steppers to make the control's design visible. If D-1 is accepted as written, show the same rows read-only.

**D19. Sidereal and Topocentric appear as visible choices.** Sidereal is shown disabled and labelled "(planned)" (out of scope for v1). Topocentric is an "option, off by default" in the spec's computation table. **Needs approval:** remove the Sidereal option entirely if planned features shouldn't be visible.

**D20. Hebrew names follow each language's tradition** (L-9 open decision, as the plan assumes), for example טלה, נוגה, כוכב חמה, and ראש הדרקון for the lunar node.

**D21. Sample data.** The wheel uses one plausible sample moment, 9 Nov 2026 12:00 local, with retrograde Mercury and Venus, a new Moon beside the Sun, and Mars conjunct Jupiter. Aspects, sign and degree splits and the display spread are computed from those positions with the spec's real rules. The positions and crossing rows are **illustrative**, not ephemeris output. Every square value, angle, ring, offset and highlight is computed exactly from the spec's spiral formulas: the 9×9 square shows 16 blue, 16 yellow and 16 gray cells, 49 sits 3 left and 3 down on the 315° diagonal, and 139 sits on the 90° axis.

**D22. No invented specifics.** Where the spec leaves a value open (the supported date range, Delta T precision), the copy says what the spec says ("the coverage of the packaged data files") instead of inventing a number.

## Process

The mockups were rendered from a disposable HTML kit (`_source/`) using headless Chrome. The kit encodes the spec's spiral, angle and aspect rules so the pictures are truthful, but it is **not** application code and must not be ported. Implement the look from the PNGs and MASTER.md in Flutter (CustomPainter for the wheel and the square, ARCH-5).
