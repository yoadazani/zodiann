# ZOD-NAV-001 — Sticky top bar design (short)

**Status:** decided by the product owner, 2026-11-15. The plan is `docs/plans/ZOD-NAV-001-sticky-top-bar.md`.

## Intent

Every screen sits under one bar (MASTER §5, NAV-1):
- 64 px high (60 on a phone), translucent `bg` at 88 % with a 10 px blur and a `line-soft` bottom rule;
- a 46 × 46 hamburger at the start, then the screen title (18/600) over the subtitle (12, `text-2`), then the screen's actions at the end;
- it mirrors in Hebrew.

On the Square screen the actions are **Save** (secondary) and **Export to Excel** (primary). They collapse to two icon buttons (bookmark, download) on a phone.

## Approaches

1. **Chosen:** a route-independent `ZodiannTopBar` in `shared_ui`. The app's shell maps routes to titles and actions.
2. Rejected: a bar built in the app layer, which isn't reusable and can't be tested against the tokens in `shared_ui`.
3. Rejected: a bar in `shared_ui` that knows routes, which would force the route-contract decision now.

## Decisions (product owner)

- **Architecture:**
  - `ZodiannTopBar` lives in `shared_ui` and is independent of the router.
  - The app shell owns the route-to-title, subtitle and actions mapping.
  - All five routes are wrapped in one shared shell now, so NAV-002 and NAV-003 can add the drawer without restructuring navigation.
- **Icon button:** a reusable `ZodiannIconButton` in `shared_ui`, 46 × 46.
  - It follows UI-004's hover, press, focus and disabled behaviour exactly, and draws a `ZodiannIcon` (FND-009).
  - It is designed for reuse by the drawer close button and the wheel steppers.
- **Copy:** every screen title, subtitle, accessibility label and action label, in en and he, taken from `kit.js`. No new copy is invented.
- **Subtitle weight:** 400, matching kit.css and the rendered mockups. The discrepancy with MASTER §3's 500 is documented; MASTER is not edited.
- **Unimplemented actions (Option B):**
  - The hamburger, Save and Export are visible in their places but **disabled** (UI-004's disabled state) until their owning tasks wire them: hamburger → NAV-002, Save → the saved-squares task, Export → the Excel task.
  - The responsive layout stays, including the phone Square screen's two icon buttons.
- **Out of scope:** the drawer, saving and Excel export.

## Left to the plan

File layout, how the state machinery is shared with `ZodiannButton`, the token additions, the shell mechanics (go_router `ShellRoute`, content scrolling under the bar), the tests, and the design cross-checks.
