# Zodiann — Development Task Index

This is the **master index** for the Zodiann development task breakdown. It replaces the single-file version of this document: every task's full detail (description, implementation notes, design reference, acceptance criteria, dependencies, spec references) now lives in its own file under a category folder, linked from the tables below. See [`README.md`](README.md) for how the directory is organized and how to work with it day to day.

This document converts `assets/zodiann-specification.md` (the spec) into an exhaustive, implementation-ready set of development tasks. **It is a planning artifact only — nothing described in it has been implemented.**

Every UI-related task names the exact file(s) in `design-reference/zodiann/` to follow. The design reference is the visual source of truth; where the spec's prose and the design reference appear to differ, the task calls it out explicitly as a conflict rather than resolving it silently. Where the design reference has no answer, the task says so as a design gap.

## 1. Project overview

Zodiann is a Flutter app (iOS + Android, phone and tablet) with no server, combining two instruments:

- **The zodiac wheel** — tropical geocentric positions of ten bodies and the mean lunar node, rotation, time travel, and a degree-crossing search.
- **The Gann Square of Nine** — a spiral of numbers, dates, or 4-hour blocks, with angle-based highlights, cell detail, and a self-recalculating Excel export.

All computation runs on-device (Swiss Ephemeris via FFI, with an astronomy-engine backup), all data stays on-device (`shared_preferences` + SQLite/drift), and the interface ships in Hebrew (RTL) and English (LTR) from the first version. The visual design is **already fully specified** in `design-reference/zodiann/` (`MASTER.md`, `DESIGN_DECISIONS.md`, five desktop screens, mobile/tablet responsive captures, and a component sheet in dark and light) — implementation must follow it, not reinvent it.

**Who this is for:** an AI coding agent or developer picking up one task at a time. Each task is scoped to be implementable and testable independently, with explicit dependencies so the order of work is unambiguous.

## 2. Development phases

Phases follow the spec's roadmap exactly (`Roadmap and development phases`). No screen starts before the core passes its accuracy tests; no polish work starts before both screens exist.

```
Phase 1 Foundations ─► Phase 2 Zodiac wheel ─► Phase 3 Gann square ─► Phase 4 Polish, launch ─► Phase 5 Expansion (optional)

  ◇ Gate 1 — after Phase 1: core passes every accuracy test (ACC-1..5, T-EPH-*, T-CRS-*, T-GAN-*)
  ◇ Gate 2 — after Phase 3: user approves spiral direction, highlight colors, and date handling
  ◇ Gate 3 — after Phase 4: decide whether Phase 5 (server/accounts/sync) is needed at all
```

| Phase | Deliverable | Exit criterion |
|---|---|---|
| 1. Foundations | Melos workspace, pure computation core, FFI bindings, accuracy tests | All core unit tests pass (`testing-qa/`) |
| 2. Zodiac wheel | Wheel screen, drag/playback, change-date mode, crossing table | Wheel performance + accessibility requirements measured and passed |
| 3. Gann square | Three modes, highlights, cell details, Excel export | User approved spiral direction, colors, dates (Gate 2) |
| 4. Polish, launch | Accessibility, compatibility, performance, storage, settings | All NFRs measured |
| 5. Expansion (optional) | Server, accounts, device sync | Explicit go/no-go decision + privacy policy if "go" |

---

## 3. Task categories

| Folder | Area | Tasks |
|---|---|---|
| [`foundations-architecture/`](foundations-architecture/) | Foundations & Architecture | 14 |
| [`computation-engine/`](computation-engine/) | Computation Engine | 14 |
| [`shared-ui-design-system/`](shared-ui-design-system/) | Shared UI & Design System | 15 |
| [`navigation/`](navigation/) | Navigation & App Shell | 5 |
| [`zodiac-wheel/`](zodiac-wheel/) | Zodiac Wheel | 25 |
| [`gann-square/`](gann-square/) | Gann Square of Nine | 20 |
| [`excel-export/`](excel-export/) | Excel Export | 17 |
| [`settings-persistence/`](settings-persistence/) | Settings & Persistence | 20 |
| [`localization/`](localization/) | Localization | 15 |
| [`about/`](about/) | About & Sources | 7 |
| [`testing-qa/`](testing-qa/) | Testing & QA | 17 |
| [`performance-accessibility-reliability/`](performance-accessibility-reliability/) | Performance, Accessibility & Reliability | 17 |
| [`release-preparation/`](release-preparation/) | Release Preparation | 7 |
| [`optional-extensions/`](optional-extensions/) | Optional Extensions | 12 |
| | **Total** | **205** |

See [`README.md`](README.md#what-each-folder-contains) for a one-paragraph description of what each folder covers.

---

## 4. Task index

### Foundations & Architecture (`foundations-architecture/`)

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-FND-001 | [Set up the Melos monorepo workspace](foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md) | Critical | Done |
| ZOD-FND-002 | [Define the `EphemerisPort` interface contract](foundations-architecture/ZOD-FND-002-define-the-ephemerisport-interface-contract.md) | Critical | Done |
| ZOD-FND-003 | [Spike: Swiss Ephemeris FFI binding on Android and iOS](foundations-architecture/ZOD-FND-003-spike-swiss-ephemeris-ffi-binding-on-android-and-ios.md) | Critical | Not Started |
| ZOD-FND-004 | [Set up the CI pipeline](foundations-architecture/ZOD-FND-004-set-up-the-ci-pipeline.md) | High | Not Started |
| ZOD-FND-005 | [Flutter app shell bootstrap (`apps/astro_mobile`)](foundations-architecture/ZOD-FND-005-flutter-app-shell-bootstrap-apps-astro-mobile.md) | Critical | Not Started |
| ZOD-FND-006 | [Local storage infrastructure: `shared_preferences` + SQLite (drift) schema v1](foundations-architecture/ZOD-FND-006-local-storage-infrastructure-shared-preferences-sqlite-drift-schema-v1.md) | High | Not Started |
| ZOD-FND-007 | [Bundle offline fonts and verify no network dependency](foundations-architecture/ZOD-FND-007-bundle-offline-fonts-and-verify-no-network-dependency.md) | Medium | Not Started |
| ZOD-FND-008 | [Package and integrate the app icon / logo asset set](foundations-architecture/ZOD-FND-008-package-and-integrate-the-app-icon-logo-asset-set.md) | Medium | Not Started |
| ZOD-FND-009 | [Integrate the 33-icon set as SVG assets](foundations-architecture/ZOD-FND-009-integrate-the-33-icon-set-as-svg-assets.md) | Medium | Not Started |
| ZOD-FND-010 | [Research and document the Swiss Ephemeris license decision](foundations-architecture/ZOD-FND-010-research-and-document-the-swiss-ephemeris-license-decision.md) | Critical | Not Started |
| ZOD-FND-011 | [Decide and document the ephemeris data-file coverage range](foundations-architecture/ZOD-FND-011-decide-and-document-the-ephemeris-data-file-coverage-range.md) | High | Not Started |
| ZOD-FND-012 | [Define `UserSettings`, `SquareConfig`, `HighlightRule`, `Crossing` Dart data classes](foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md) | Critical | Done |
| ZOD-FND-013 | [Establish the design-token theme skeleton (dark + light `ColorScheme`)](foundations-architecture/ZOD-FND-013-establish-the-design-token-theme-skeleton-dark-light-colorscheme.md) | Critical | Not Started |
| ZOD-FND-014 | [Set up `go_router` navigation scaffold](foundations-architecture/ZOD-FND-014-set-up-go-router-navigation-scaffold.md) | High | Not Started |

### Computation Engine (`computation-engine/`)

All tasks in this section live in `packages/astro_core` and `packages/gann_core` (pure Dart, ARCH-2). None has a design reference — these are headless calculation tasks whose correctness is verified entirely by the tests in `testing-qa/`.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-EPH-001 | [Implement the mean ascending lunar node formula](computation-engine/ZOD-EPH-001-implement-the-mean-ascending-lunar-node-formula.md) | Critical | Not Started |
| ZOD-EPH-002 | [Implement the Swiss Ephemeris `EphemerisPort` adapter (data-file mode)](computation-engine/ZOD-EPH-002-implement-the-swiss-ephemeris-ephemerisport-adapter-data-file-mode.md) | Critical | Not Started |
| ZOD-EPH-003 | [Implement the Swiss Ephemeris built-in (Moshier) fallback mode](computation-engine/ZOD-EPH-003-implement-the-swiss-ephemeris-built-in-moshier-fallback-mode.md) | Medium | Not Started |
| ZOD-EPH-004 | [Spike + implement the astronomy-engine `EphemerisPort` adapter (backup/oracle)](computation-engine/ZOD-EPH-004-spike-implement-the-astronomy-engine-ephemerisport-adapter-backup.md) | High | Not Started |
| ZOD-EPH-005 | [Implement retrograde detection and position formatting](computation-engine/ZOD-EPH-005-implement-retrograde-detection-and-position-formatting.md) | High | Not Started |
| ZOD-CRS-001 | [Implement segment splitting at stationary points](computation-engine/ZOD-CRS-001-implement-segment-splitting-at-stationary-points.md) | Critical | Not Started |
| ZOD-CRS-002 | [Implement the per-segment crossing solver (bisection/Brent + Newton refinement)](computation-engine/ZOD-CRS-002-implement-the-per-segment-crossing-solver-bisection-brent-newton.md) | Critical | Not Started |
| ZOD-CRS-003 | [Implement the retrograde mark on crossing results](computation-engine/ZOD-CRS-003-implement-the-retrograde-mark-on-crossing-results.md) | Medium | Not Started |
| ZOD-CRS-004 | [Implement the degree-crossing query API (range, body filter, product limits)](computation-engine/ZOD-CRS-004-implement-the-degree-crossing-query-api-range-body-filter-product.md) | High | Not Started |
| ZOD-ASP-001 | [Implement aspect detection between body pairs](computation-engine/ZOD-ASP-001-implement-aspect-detection-between-body-pairs.md) | High | Not Started |
| ZOD-ASP-002 | [Implement aspect-orb configuration data flow](computation-engine/ZOD-ASP-002-implement-aspect-orb-configuration-data-flow.md) | Medium | Not Started |
| ZOD-GAN-001 | [Implement the Gann spiral position formulas (k, j, i, θ)](computation-engine/ZOD-GAN-001-implement-the-gann-spiral-position-formulas-k-j-i.md) | Critical | Not Started |
| ZOD-GAN-002 | [Implement Gann highlight classification (blue/yellow/gray)](computation-engine/ZOD-GAN-002-implement-gann-highlight-classification-blue-yellow-gray.md) | Critical | Not Started |
| ZOD-GAN-003 | [Implement Gann date/number mapping per mode](computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md) | Critical | Not Started |

### Shared UI & Design System (`shared-ui-design-system/`)

Every task in this section implements a component that is **already fully designed**. The job is pixel-faithful Flutter implementation, not visual design. Reference `design-reference/zodiann/components/components_dark.png` and `components_light.png` for every component state side by side.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-UI-001 | [Implement the color token values (dark + light)](shared-ui-design-system/ZOD-UI-001-implement-the-color-token-values-dark-light.md) | Critical | Not Started |
| ZOD-UI-002 | [Implement the typography scale](shared-ui-design-system/ZOD-UI-002-implement-the-typography-scale.md) | High | Not Started |
| ZOD-UI-003 | [Implement spacing, radius, elevation, and sizing tokens](shared-ui-design-system/ZOD-UI-003-implement-spacing-radius-elevation-and-sizing-tokens.md) | Medium | Not Started |
| ZOD-UI-004 | [Implement the button components (primary, secondary, accent-outline, quiet, danger) and their states](shared-ui-design-system/ZOD-UI-004-implement-the-button-components-primary-secondary-accent-outline-quiet.md) | High | Not Started |
| ZOD-UI-005 | [Implement the input/field component](shared-ui-design-system/ZOD-UI-005-implement-the-input-field-component.md) | High | Not Started |
| ZOD-UI-006 | [Implement the segmented control component](shared-ui-design-system/ZOD-UI-006-implement-the-segmented-control-component.md) | High | Not Started |
| ZOD-UI-007 | [Implement switch, stepper, and body-chip components](shared-ui-design-system/ZOD-UI-007-implement-switch-stepper-and-body-chip-components.md) | Medium | Not Started |
| ZOD-UI-008 | [Implement the radio-list component (ephemeris source selector)](shared-ui-design-system/ZOD-UI-008-implement-the-radio-list-component-ephemeris-source-selector.md) | Low | Not Started |
| ZOD-UI-009 | [Implement the tag component (highlight tags, mode tags, Today/Center outline tags)](shared-ui-design-system/ZOD-UI-009-implement-the-tag-component-highlight-tags-mode-tags-today-center.md) | Medium | Not Started |
| ZOD-UI-010 | [Implement the table component (header, rows, hover, selected)](shared-ui-design-system/ZOD-UI-010-implement-the-table-component-header-rows-hover-selected.md) | High | Not Started |
| ZOD-UI-011 | [Implement the toast/feedback component (export status, progress with Stop)](shared-ui-design-system/ZOD-UI-011-implement-the-toast-feedback-component-export-status-progress-with.md) | High | Not Started |
| ZOD-UI-012 | [Implement the banner component (neutral + danger)](shared-ui-design-system/ZOD-UI-012-implement-the-banner-component-neutral-danger.md) | Medium | Not Started |
| ZOD-UI-013 | [Implement the dialog component](shared-ui-design-system/ZOD-UI-013-implement-the-dialog-component.md) | Medium | Not Started |
| ZOD-UI-014 | [Implement the hairline panel component](shared-ui-design-system/ZOD-UI-014-implement-the-hairline-panel-component.md) | High | Not Started |
| ZOD-UI-015 | [Build the automated light/dark, EN/HE visual regression harness](shared-ui-design-system/ZOD-UI-015-build-the-automated-light-dark-en-he-visual-regression-harness.md) | Medium | Not Started |

### Navigation & App Shell (`navigation/`)

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-NAV-001 | [Implement the sticky top bar](navigation/ZOD-NAV-001-implement-the-sticky-top-bar.md) | Critical | Not Started |
| ZOD-NAV-002 | [Implement the side navigation drawer](navigation/ZOD-NAV-002-implement-the-side-navigation-drawer.md) | Critical | Not Started |
| ZOD-NAV-003 | [Wire drawer navigation to `go_router` routes](navigation/ZOD-NAV-003-wire-drawer-navigation-to-go-router-routes.md) | Critical | Not Started |
| ZOD-NAV-004 | [Implement drawer/top-bar accessibility behavior](navigation/ZOD-NAV-004-implement-drawer-top-bar-accessibility-behavior.md) | High | Not Started |
| ZOD-NAV-005 | [Implement responsive drawer behavior across breakpoints](navigation/ZOD-NAV-005-implement-responsive-drawer-behavior-across-breakpoints.md) | Medium | Not Started |

### Zodiac Wheel (`zodiac-wheel/`)

Every drawing task in this section renders onto a single `CustomPainter` (ARCH-5), proportioned as a fraction of the outer radius `R` so it scales across breakpoints. Primary design reference for the whole section: `design-reference/zodiann/screens/01-zodiac-wheel_desktop_{en,he}_{dark,light}.png`, `design-reference/zodiann/responsive/mobile/zodiac-wheel_mobile_{en,he}_{dark,light}.png`, `design-reference/zodiann/responsive/tablet/zodiac-wheel_{tablet,tablet-landscape}_{en,he}_{dark,light}.png`, and `design-reference/zodiann/MASTER.md` §7 "Zodiac wheel screen" (the full ring/radius table).

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-WHL-001 | [Build the wheel canvas and proportion system](zodiac-wheel/ZOD-WHL-001-build-the-wheel-canvas-and-proportion-system.md) | Critical | Not Started |
| ZOD-WHL-002 | [Render the zodiac sign ring](zodiac-wheel/ZOD-WHL-002-render-the-zodiac-sign-ring.md) | Critical | Not Started |
| ZOD-WHL-003 | [Render the degree scale](zodiac-wheel/ZOD-WHL-003-render-the-degree-scale.md) | High | Not Started |
| ZOD-WHL-004 | [Render body markers (glyph, degree label, connector, true-position dot)](zodiac-wheel/ZOD-WHL-004-render-body-markers-glyph-degree-label-connector-true-position-dot.md) | Critical | Not Started |
| ZOD-WHL-005 | [Implement the body display-spread (collision avoidance) algorithm](zodiac-wheel/ZOD-WHL-005-implement-the-body-display-spread-collision-avoidance-algorithm.md) | High | Not Started |
| ZOD-WHL-006 | [Render the retrograde indicator (℞)](zodiac-wheel/ZOD-WHL-006-render-the-retrograde-indicator.md) | Medium | Not Started |
| ZOD-WHL-007 | [Render aspect chords on the inner disc](zodiac-wheel/ZOD-WHL-007-render-aspect-chords-on-the-inner-disc.md) | High | Not Started |
| ZOD-WHL-008 | [Build the aspect legend](zodiac-wheel/ZOD-WHL-008-build-the-aspect-legend.md) | Low | Not Started |
| ZOD-WHL-009 | [Implement the fixed pointer and "under the pointer" readout](zodiac-wheel/ZOD-WHL-009-implement-the-fixed-pointer-and-under-the-pointer-readout.md) | Critical | Not Started |
| ZOD-WHL-010 | [Implement wheel rotation via drag (rotate-wheel mode)](zodiac-wheel/ZOD-WHL-010-implement-wheel-rotation-via-drag-rotate-wheel-mode.md) | Critical | Not Started |
| ZOD-WHL-011 | [Implement change-date drag mode](zodiac-wheel/ZOD-WHL-011-implement-change-date-drag-mode.md) | High | Not Started |
| ZOD-WHL-012 | [Implement external-keyboard controls for the wheel](zodiac-wheel/ZOD-WHL-012-implement-external-keyboard-controls-for-the-wheel.md) | Medium | Not Started |
| ZOD-WHL-013 | [Implement screen-reader accessibility actions for the wheel](zodiac-wheel/ZOD-WHL-013-implement-screen-reader-accessibility-actions-for-the-wheel.md) | Medium | Not Started |
| ZOD-WHL-014 | [Build the Time panel: date/time field and Now button](zodiac-wheel/ZOD-WHL-014-build-the-time-panel-date-time-field-and-now-button.md) | Critical | Not Started |
| ZOD-WHL-015 | [Build the Time panel: step-size segmented control](zodiac-wheel/ZOD-WHL-015-build-the-time-panel-step-size-segmented-control.md) | High | Not Started |
| ZOD-WHL-016 | [Build the Time panel: back/forward step buttons](zodiac-wheel/ZOD-WHL-016-build-the-time-panel-back-forward-step-buttons.md) | High | Not Started |
| ZOD-WHL-017 | [Build automatic playback (play/pause)](zodiac-wheel/ZOD-WHL-017-build-automatic-playback-play-pause.md) | High | Not Started |
| ZOD-WHL-018 | [Build the positions table](zodiac-wheel/ZOD-WHL-018-build-the-positions-table.md) | Critical | Not Started |
| ZOD-WHL-019 | [Implement tap-row-to-snap wheel animation](zodiac-wheel/ZOD-WHL-019-implement-tap-row-to-snap-wheel-animation.md) | Medium | Not Started |
| ZOD-WHL-020 | [Build the degree-crossings filter row](zodiac-wheel/ZOD-WHL-020-build-the-degree-crossings-filter-row.md) | High | Not Started |
| ZOD-WHL-021 | [Build the degree-crossings results table/list and Moon-exclusion rule](zodiac-wheel/ZOD-WHL-021-build-the-degree-crossings-results-table-list-and-moon-exclusion-rule.md) | Critical | Not Started |
| ZOD-WHL-022 | [Implement tap-crossing-row-to-navigate interaction](zodiac-wheel/ZOD-WHL-022-implement-tap-crossing-row-to-navigate-interaction.md) | Medium | Not Started |
| ZOD-WHL-023 | [Implement initial wheel state on screen open](zodiac-wheel/ZOD-WHL-023-implement-initial-wheel-state-on-screen-open.md) | Medium | Not Started |
| ZOD-WHL-024 | [Build the compact (phone/tablet) wheel drawing variant](zodiac-wheel/ZOD-WHL-024-build-the-compact-phone-tablet-wheel-drawing-variant.md) | High | Not Started |
| ZOD-WHL-025 | [Implement responsive wheel-screen layout (desktop/tablet/phone)](zodiac-wheel/ZOD-WHL-025-implement-responsive-wheel-screen-layout-desktop-tablet-phone.md) | High | Not Started |

### Gann Square of Nine (`gann-square/`)

Primary design reference for this whole section: `design-reference/zodiann/screens/02-square-of-nine_{numbers,dates,datetime}_desktop_{en,he}_{dark,light}.png`, `design-reference/zodiann/responsive/mobile/square-of-nine_*`, `design-reference/zodiann/responsive/tablet/square-of-nine_*`, and `design-reference/zodiann/MASTER.md` §8 "Gann Square of Nine screen".

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-SQR-001 | [Build the mode switcher with state preservation](gann-square/ZOD-SQR-001-build-the-mode-switcher-with-state-preservation.md) | Critical | Not Started |
| ZOD-SQR-002 | [Build the anchor field and "Anchor to today/now" shortcut](gann-square/ZOD-SQR-002-build-the-anchor-field-and-anchor-to-today-now-shortcut.md) | Critical | Not Started |
| ZOD-SQR-003 | [Build the square-size selector (presets + custom)](gann-square/ZOD-SQR-003-build-the-square-size-selector-presets-custom.md) | Critical | Not Started |
| ZOD-SQR-004 | [Implement "Show up to today" / "Show up to now"](gann-square/ZOD-SQR-004-implement-show-up-to-today-show-up-to-now.md) | High | Not Started |
| ZOD-SQR-005 | [Build the square canvas (single-canvas cell grid)](gann-square/ZOD-SQR-005-build-the-square-canvas-single-canvas-cell-grid.md) | Critical | Not Started |
| ZOD-SQR-006 | [Render highlight fills (blue/yellow/gray) on the square canvas](gann-square/ZOD-SQR-006-render-highlight-fills-blue-yellow-gray-on-the-square-canvas.md) | Critical | Not Started |
| ZOD-SQR-007 | [Render non-color highlight marks (+ and ×)](gann-square/ZOD-SQR-007-render-non-color-highlight-marks-and.md) | High | Not Started |
| ZOD-SQR-008 | [Implement cell border stacking (selected, today, center)](gann-square/ZOD-SQR-008-implement-cell-border-stacking-selected-today-center.md) | High | Not Started |
| ZOD-SQR-009 | [Implement the "today" cell computation and live update](gann-square/ZOD-SQR-009-implement-the-today-cell-computation-and-live-update.md) | High | Not Started |
| ZOD-SQR-010 | [Implement cell tap-to-select and details-panel wiring](gann-square/ZOD-SQR-010-implement-cell-tap-to-select-and-details-panel-wiring.md) | Critical | Not Started |
| ZOD-SQR-011 | [Implement keyboard cell-selection navigation](gann-square/ZOD-SQR-011-implement-keyboard-cell-selection-navigation.md) | Medium | Not Started |
| ZOD-SQR-012 | [Build cell details: core fields](gann-square/ZOD-SQR-012-build-cell-details-core-fields.md) | Critical | Not Started |
| ZOD-SQR-013 | [Build cell details: date-mode fields](gann-square/ZOD-SQR-013-build-cell-details-date-mode-fields.md) | High | Not Started |
| ZOD-SQR-014 | [Implement responsive cell-size rules](gann-square/ZOD-SQR-014-implement-responsive-cell-size-rules.md) | High | Not Started |
| ZOD-SQR-015 | [Implement the square's own horizontal-scroll container](gann-square/ZOD-SQR-015-implement-the-squares-own-horizontal-scroll-container.md) | High | Not Started |
| ZOD-SQR-016 | [Enforce LTR-always rendering of the square](gann-square/ZOD-SQR-016-enforce-ltr-always-rendering-of-the-square.md) | Critical | Not Started |
| ZOD-SQR-017 | [Build the compass axis labels around the square](gann-square/ZOD-SQR-017-build-the-compass-axis-labels-around-the-square.md) | Medium | Not Started |
| ZOD-SQR-018 | [Build the square's legend](gann-square/ZOD-SQR-018-build-the-squares-legend.md) | Low | Not Started |
| ZOD-SQR-019 | [Build the controls-panel layout and summary row](gann-square/ZOD-SQR-019-build-the-controls-panel-layout-and-summary-row.md) | High | Not Started |
| ZOD-SQR-020 | [Implement responsive square-screen layout (desktop/tablet-portrait/tablet-landscape/phone)](gann-square/ZOD-SQR-020-implement-responsive-square-screen-layout-desktop-tablet-portrait.md) | High | Not Started |

### Excel Export (`excel-export/`)

The export package (`packages/shared_export_xlsx`) builds the OOXML file directly (archive/ZIP + XML), per R-8 — the `excel` Dart package is too limited for live formulas, conditional formatting, and defined names. A spike (ZOD-XLS-001) must verify this approach opens cleanly in Excel, LibreOffice, and Google Sheets before the rest of the section is built.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-XLS-001 | [Spike: OOXML (xlsx) generation via raw archive + XML](excel-export/ZOD-XLS-001-spike-ooxml-xlsx-generation-via-raw-archive-xml.md) | Critical | Not Started |
| ZOD-XLS-002 | [Implement the Gann spiral "Helper" sheet (hidden)](excel-export/ZOD-XLS-002-implement-the-gann-spiral-helper-sheet-hidden.md) | Critical | Not Started |
| ZOD-XLS-003 | [Implement the "Square" sheet with the live Anchor input cell](excel-export/ZOD-XLS-003-implement-the-square-sheet-with-the-live-anchor-input-cell.md) | Critical | Not Started |
| ZOD-XLS-004 | [Implement conditional formatting for highlights, center, and today](excel-export/ZOD-XLS-004-implement-conditional-formatting-for-highlights-center-and-today.md) | Critical | Not Started |
| ZOD-XLS-005 | [Implement the "Cell list" sheet](excel-export/ZOD-XLS-005-implement-the-cell-list-sheet.md) | High | Not Started |
| ZOD-XLS-006 | [Implement the "Details" sheet](excel-export/ZOD-XLS-006-implement-the-details-sheet.md) | Medium | Not Started |
| ZOD-XLS-007 | [Implement cached values + recalculate-on-open flag](excel-export/ZOD-XLS-007-implement-cached-values-recalculate-on-open-flag.md) | High | Not Started |
| ZOD-XLS-008 | [Implement the export file-naming convention](excel-export/ZOD-XLS-008-implement-the-export-file-naming-convention.md) | Low | Not Started |
| ZOD-XLS-009 | [Meet the export performance budget (≤3s at 61×61, non-blocking)](excel-export/ZOD-XLS-009-meet-the-export-performance-budget-3s-at-61-61-non-blocking.md) | High | Not Started |
| ZOD-XLS-010 | [Build the export status UI (disabled button + toast states)](excel-export/ZOD-XLS-010-build-the-export-status-ui-disabled-button-toast-states.md) | High | Not Started |
| ZOD-XLS-011 | [Implement share-sheet integration (temp storage + system share)](excel-export/ZOD-XLS-011-implement-share-sheet-integration-temp-storage-system-share.md) | High | Not Started |
| ZOD-XLS-012 | [Enforce Excel formula-compatibility constraints](excel-export/ZOD-XLS-012-enforce-excel-formula-compatibility-constraints.md) | Medium | Not Started |
| ZOD-XLS-013 | [Implement degree-crossing table export (xlsx/csv)](excel-export/ZOD-XLS-013-implement-degree-crossing-table-export-xlsx-csv.md) | Medium | Not Started |
| ZOD-XLS-014 | [Implement Square of Nine "Cell list" CSV export](excel-export/ZOD-XLS-014-implement-square-of-nine-cell-list-csv-export.md) | Low | Not Started |
| ZOD-XLS-015 | [Implement PNG/PDF screen export (wheel and square)](excel-export/ZOD-XLS-015-implement-png-pdf-screen-export-wheel-and-square.md) | Medium | Not Started |
| ZOD-XLS-016 | [Localize the Excel export (sheet names, headers, notes, direction)](excel-export/ZOD-XLS-016-localize-the-excel-export-sheet-names-headers-notes-direction.md) | Medium | Not Started |
| ZOD-XLS-017 | [Document the Excel export's known limits](excel-export/ZOD-XLS-017-document-the-excel-exports-known-limits.md) | Low | Not Started |

### Settings & Persistence (`settings-persistence/`)

Primary design reference: `design-reference/zodiann/screens/04-settings_{desktop,tablet}_{en,he}_{dark,light}.png`, `04-settings_delete-dialog_desktop_en_dark.png`, `design-reference/zodiann/screens/03-saved-squares_*`, `design-reference/zodiann/MASTER.md` §9.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-SET-001 | [Build the Settings screen panel layout](settings-persistence/ZOD-SET-001-build-the-settings-screen-panel-layout.md) | High | Not Started |
| ZOD-SET-002 | [Build the Language and region panel](settings-persistence/ZOD-SET-002-build-the-language-and-region-panel.md) | Critical | Not Started |
| ZOD-SET-003 | [Build the Appearance panel](settings-persistence/ZOD-SET-003-build-the-appearance-panel.md) | High | Not Started |
| ZOD-SET-004 | [Build the Square defaults panel](settings-persistence/ZOD-SET-004-build-the-square-defaults-panel.md) | Medium | Not Started |
| ZOD-SET-005 | [Build the "Your data" panel (export/import backup, delete all data)](settings-persistence/ZOD-SET-005-build-the-your-data-panel-export-import-backup-delete-all-data.md) | High | Not Started |
| ZOD-SET-006 | [Build the "Wheel and computation" panel](settings-persistence/ZOD-SET-006-build-the-wheel-and-computation-panel.md) | Critical | Not Started |
| ZOD-SET-007 | [Implement `UserSettings` persistence wiring](settings-persistence/ZOD-SET-007-implement-usersettings-persistence-wiring.md) | Critical | Not Started |
| ZOD-SET-008 | [Implement reliability behavior for invalid settings input](settings-persistence/ZOD-SET-008-implement-reliability-behavior-for-invalid-settings-input.md) | Medium | Not Started |
| ZOD-DAT-001 | [Build the Saved squares list screen](settings-persistence/ZOD-DAT-001-build-the-saved-squares-list-screen.md) | High | Not Started |
| ZOD-DAT-002 | [Implement "Save current square" flow](settings-persistence/ZOD-DAT-002-implement-save-current-square-flow.md) | High | Not Started |
| ZOD-DAT-003 | [Implement inline rename](settings-persistence/ZOD-DAT-003-implement-inline-rename.md) | Medium | Not Started |
| ZOD-DAT-004 | [Implement delete (with confirmation)](settings-persistence/ZOD-DAT-004-implement-delete-with-confirmation.md) | Medium | Not Started |
| ZOD-DAT-005 | [Implement "Open" (load a saved square into the Square screen)](settings-persistence/ZOD-DAT-005-implement-open-load-a-saved-square-into-the-square-screen.md) | High | Not Started |
| ZOD-DAT-006 | [Implement the 100-saved-squares cap and live counter](settings-persistence/ZOD-DAT-006-implement-the-100-saved-squares-cap-and-live-counter.md) | Low | Not Started |
| ZOD-DAT-007 | [Implement last-screen-state persistence (resume on relaunch)](settings-persistence/ZOD-DAT-007-implement-last-screen-state-persistence-resume-on-relaunch.md) | Medium | Not Started |
| ZOD-DAT-008 | [Implement backup export/import (single JSON file)](settings-persistence/ZOD-DAT-008-implement-backup-export-import-single-json-file.md) | Medium | Not Started |
| ZOD-DAT-009 | [Persist anchor dates with time-zone offset](settings-persistence/ZOD-DAT-009-persist-anchor-dates-with-time-zone-offset.md) | Medium | Not Started |
| ZOD-DAT-010 | [Implement "Delete all data" with confirmation](settings-persistence/ZOD-DAT-010-implement-delete-all-data-with-confirmation.md) | Medium | Not Started |
| ZOD-DAT-011 | [Verify no network/analytics/third-party data paths exist](settings-persistence/ZOD-DAT-011-verify-no-network-analytics-third-party-data-paths-exist.md) | High | Not Started |
| ZOD-DAT-012 | [Implement the drift schema migration framework](settings-persistence/ZOD-DAT-012-implement-the-drift-schema-migration-framework.md) | Medium | Not Started |

### Localization (`localization/`)

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-L10-001 | [Set up ARB files and `gen-l10n`](localization/ZOD-L10-001-set-up-arb-files-and-gen-l10n.md) | Critical | Not Started |
| ZOD-L10-002 | [Implement first-launch language detection](localization/ZOD-L10-002-implement-first-launch-language-detection.md) | High | Not Started |
| ZOD-L10-003 | [Implement the in-app language override](localization/ZOD-L10-003-implement-the-in-app-language-override.md) | High | Not Started |
| ZOD-L10-004 | [Audit and enforce logical (directional) layout properties app-wide](localization/ZOD-L10-004-audit-and-enforce-logical-directional-layout-properties-app-wide.md) | Critical | Not Started |
| ZOD-L10-005 | [Verify never-mirrored exceptions stay unmirrored](localization/ZOD-L10-005-verify-never-mirrored-exceptions-stay-unmirrored.md) | High | Not Started |
| ZOD-L10-006 | [Implement bidi isolation for Latin runs inside Hebrew text](localization/ZOD-L10-006-implement-bidi-isolation-for-latin-runs-inside-hebrew-text.md) | High | Not Started |
| ZOD-L10-007 | [Implement stable, language-independent entity keys](localization/ZOD-L10-007-implement-stable-language-independent-entity-keys.md) | Critical | Not Started |
| ZOD-L10-008 | [Implement ICU plural rules for countable UI text](localization/ZOD-L10-008-implement-icu-plural-rules-for-countable-ui-text.md) | Medium | Not Started |
| ZOD-L10-009 | [Audit for fixed-width labels (flexible-width layout)](localization/ZOD-L10-009-audit-for-fixed-width-labels-flexible-width-layout.md) | Medium | Not Started |
| ZOD-L10-010 | [Implement the English date-order setting and Hebrew's fixed format](localization/ZOD-L10-010-implement-the-english-date-order-setting-and-hebrews-fixed-format.md) | Medium | Not Started |
| ZOD-L10-011 | [Verify month/weekday localization and 24-hour time everywhere](localization/ZOD-L10-011-verify-month-weekday-localization-and-24-hour-time-everywhere.md) | Low | Not Started |
| ZOD-L10-012 | [Enforce Western digits everywhere](localization/ZOD-L10-012-enforce-western-digits-everywhere.md) | Low | Not Started |
| ZOD-L10-013 | [Resolve and document the symbol-translation open decision](localization/ZOD-L10-013-resolve-and-document-the-symbol-translation-open-decision.md) | Medium | Not Started |
| ZOD-L10-014 | [Implement the missing-translation-key CI test](localization/ZOD-L10-014-implement-the-missing-translation-key-ci-test.md) | High | Not Started |
| ZOD-L10-015 | [Build the EN/HE × phone/tablet screenshot comparison suite](localization/ZOD-L10-015-build-the-en-he-phone-tablet-screenshot-comparison-suite.md) | Medium | Not Started |

### About & Sources (`about/`)

Design reference for this whole section: `design-reference/zodiann/screens/05-about-sources_desktop_{en,he}_{dark,light}.png`, `design-reference/zodiann/responsive/mobile/about-sources_mobile_{en,he}_{light,dark}.png`, `design-reference/zodiann/MASTER.md` §9 "About and sources".

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-ABT-001 | [Build the About screen hero](about/ZOD-ABT-001-build-the-about-screen-hero.md) | Medium | Not Started |
| ZOD-ABT-002 | [Build the Computation sources table](about/ZOD-ABT-002-build-the-computation-sources-table.md) | Medium | Not Started |
| ZOD-ABT-003 | [Build the Method settings table](about/ZOD-ABT-003-build-the-method-settings-table.md) | Medium | Not Started |
| ZOD-ABT-004 | [Build the Gann method explanation block](about/ZOD-ABT-004-build-the-gann-method-explanation-block.md) | Low | Not Started |
| ZOD-ABT-005 | [Build the "Not advice" notice](about/ZOD-ABT-005-build-the-not-advice-notice.md) | High | Not Started |
| ZOD-ABT-006 | [Build the Privacy statement block](about/ZOD-ABT-006-build-the-privacy-statement-block.md) | Medium | Not Started |
| ZOD-ABT-007 | [Build the Open-source licenses list](about/ZOD-ABT-007-build-the-open-source-licenses-list.md) | Low | Not Started |

### Testing & QA (`testing-qa/`)

The spec's principle is explicit: **every formula requires an automated test that fails if the formula changes.** Most of these tests already appear as acceptance criteria on their owning implementation task (cross-referenced below); this section's tasks are the dedicated deliverables — reference datasets, fixture files, and standalone test suites — that those acceptance criteria depend on, plus the tests that don't belong to any single feature task.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-TST-001 | [Build the JPL Horizons reference dataset (T-EPH-1 / ACC-1)](testing-qa/ZOD-TST-001-build-the-jpl-horizons-reference-dataset-t-eph-1-acc-1.md) | Critical | Not Started |
| ZOD-TST-002 | [Author the mean-node formula exactness test (T-EPH-2)](testing-qa/ZOD-TST-002-author-the-mean-node-formula-exactness-test-t-eph-2.md) | Critical | Not Started |
| ZOD-TST-003 | [Author the retrograde-marking regression test (T-EPH-3)](testing-qa/ZOD-TST-003-author-the-retrograde-marking-regression-test-t-eph-3.md) | High | Not Started |
| ZOD-TST-004 | [Author the double-precession regression test (T-EPH-1 guard / ACC-5)](testing-qa/ZOD-TST-004-author-the-double-precession-regression-test-t-eph-1-guard-acc-5.md) | Critical | Not Started |
| ZOD-TST-005 | [Author the astronomy-engine backup comparison suite (ACC-2)](testing-qa/ZOD-TST-005-author-the-astronomy-engine-backup-comparison-suite-acc-2.md) | High | Not Started |
| ZOD-TST-006 | [Author the Astrolog cross-check (ACC-3)](testing-qa/ZOD-TST-006-author-the-astrolog-cross-check-acc-3.md) | Medium | Not Started |
| ZOD-TST-007 | [Author the dense-scan crossing-completeness oracle (T-CRS-2 / ACC-4)](testing-qa/ZOD-TST-007-author-the-dense-scan-crossing-completeness-oracle-t-crs-2-acc-4.md) | Critical | Not Started |
| ZOD-TST-008 | [Author the crossing-solver accuracy and boundary tests (T-CRS-1, T-CRS-3)](testing-qa/ZOD-TST-008-author-the-crossing-solver-accuracy-and-boundary-tests-t-crs-1-t-crs-3.md) | Critical | Not Started |
| ZOD-TST-009 | [Author the aspect boundary-value test suite (T-ASP-1)](testing-qa/ZOD-TST-009-author-the-aspect-boundary-value-test-suite-t-asp-1.md) | High | Not Started |
| ZOD-TST-010 | [Author the Gann spiral/direction test suite (T-GAN-1, T-GAN-3)](testing-qa/ZOD-TST-010-author-the-gann-spiral-direction-test-suite-t-gan-1-t-gan-3.md) | Critical | Not Started |
| ZOD-TST-011 | [Author the ring highlight-count test (T-GAN-2)](testing-qa/ZOD-TST-011-author-the-ring-highlight-count-test-t-gan-2.md) | Critical | Not Started |
| ZOD-TST-012 | [Author the Gann date-mapping test suite (T-GAN-4)](testing-qa/ZOD-TST-012-author-the-gann-date-mapping-test-suite-t-gan-4.md) | Critical | Not Started |
| ZOD-TST-013 | [Author the date-format test (T-FMT-1)](testing-qa/ZOD-TST-013-author-the-date-format-test-t-fmt-1.md) | Medium | Not Started |
| ZOD-TST-014 | [Author the component/interface test suite (T-UI-1 through T-UI-5)](testing-qa/ZOD-TST-014-author-the-component-interface-test-suite-t-ui-1-through-t-ui-5.md) | High | Not Started |
| ZOD-TST-015 | [Author the Excel export test suite (T-EX-1 through T-EX-6)](testing-qa/ZOD-TST-015-author-the-excel-export-test-suite-t-ex-1-through-t-ex-6.md) | Critical | Not Started |
| ZOD-TST-016 | [Conduct manual acceptance testing with the user](testing-qa/ZOD-TST-016-conduct-manual-acceptance-testing-with-the-user.md) | High | Not Started |
| ZOD-TST-017 | [Wire all unit/accuracy/spiral tests as release-blocking in CI](testing-qa/ZOD-TST-017-wire-all-unit-accuracy-spiral-tests-as-release-blocking-in-ci.md) | Critical | Not Started |

### Performance, Accessibility & Reliability (`performance-accessibility-reliability/`)

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-NFR-001 | [Move crossing-table computation to a background isolate](performance-accessibility-reliability/ZOD-NFR-001-move-crossing-table-computation-to-a-background-isolate.md) | Critical | Not Started |
| ZOD-NFR-002 | [Measure and tune wheel drag frame rate](performance-accessibility-reliability/ZOD-NFR-002-measure-and-tune-wheel-drag-frame-rate.md) | High | Not Started |
| ZOD-NFR-003 | [Measure square refresh latency on date/mode change](performance-accessibility-reliability/ZOD-NFR-003-measure-square-refresh-latency-on-date-mode-change.md) | High | Not Started |
| ZOD-NFR-004 | [Validate the 2-second-per-year crossing-table budget](performance-accessibility-reliability/ZOD-NFR-004-validate-the-2-second-per-year-crossing-table-budget.md) | High | Not Started |
| ZOD-NFR-005 | [Validate 61×61 square rendering performance (NFR-P4)](performance-accessibility-reliability/ZOD-NFR-005-validate-61-61-square-rendering-performance-nfr-p4.md) | High | Not Started |
| ZOD-NFR-006 | [Audit full screen-reader navigation (VoiceOver/TalkBack)](performance-accessibility-reliability/ZOD-NFR-006-audit-full-screen-reader-navigation-voiceover-talkback.md) | High | Not Started |
| ZOD-NFR-007 | [Verify drawer dialog-equivalent focus behavior (NFR-X3)](performance-accessibility-reliability/ZOD-NFR-007-verify-drawer-dialog-equivalent-focus-behavior-nfr-x3.md) | Medium | Not Started |
| ZOD-NFR-008 | [Audit color-independence of all meaningful marks (NFR-X4)](performance-accessibility-reliability/ZOD-NFR-008-audit-color-independence-of-all-meaningful-marks-nfr-x4.md) | High | Not Started |
| ZOD-NFR-009 | [Audit WCAG AA text contrast in both themes (NFR-X5)](performance-accessibility-reliability/ZOD-NFR-009-audit-wcag-aa-text-contrast-in-both-themes-nfr-x5.md) | High | Not Started |
| ZOD-NFR-010 | [Audit reduced-motion compliance across every animation (NFR-X6)](performance-accessibility-reliability/ZOD-NFR-010-audit-reduced-motion-compliance-across-every-animation-nfr-x6.md) | Medium | Not Started |
| ZOD-NFR-011 | [Define and document the supported iOS/Android version range](performance-accessibility-reliability/ZOD-NFR-011-define-and-document-the-supported-ios-android-version-range.md) | Medium | Not Started |
| ZOD-NFR-012 | [Conduct full responsive QA sweep (portrait/landscape, phone/tablet)](performance-accessibility-reliability/ZOD-NFR-012-conduct-full-responsive-qa-sweep-portrait-landscape-phone-tablet.md) | High | Not Started |
| ZOD-NFR-013 | [Verify external mouse/keyboard support app-wide](performance-accessibility-reliability/ZOD-NFR-013-verify-external-mouse-keyboard-support-app-wide.md) | Medium | Not Started |
| ZOD-NFR-014 | [Build the storage-unavailable failure banner](performance-accessibility-reliability/ZOD-NFR-014-build-the-storage-unavailable-failure-banner.md) | Medium | Not Started |
| ZOD-NFR-015 | [Audit invalid-input handling app-wide](performance-accessibility-reliability/ZOD-NFR-015-audit-invalid-input-handling-app-wide.md) | High | Not Started |
| ZOD-NFR-016 | [Pin all dependency versions and audit for runtime network/script loading](performance-accessibility-reliability/ZOD-NFR-016-pin-all-dependency-versions-and-audit-for-runtime-network-script.md) | High | Not Started |
| ZOD-NFR-017 | [Implement the ΔT-forecast and out-of-range warning banners](performance-accessibility-reliability/ZOD-NFR-017-implement-the-t-forecast-and-out-of-range-warning-banners.md) | Medium | Not Started |

### Release Preparation (`release-preparation/`)

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-REL-001 | [Package the launcher icon and store metadata assets](release-preparation/ZOD-REL-001-package-the-launcher-icon-and-store-metadata-assets.md) | Medium | Not Started |
| ZOD-REL-002 | [Finalize and verify the native build pipeline (CMake/Xcode/native assets)](release-preparation/ZOD-REL-002-finalize-and-verify-the-native-build-pipeline-cmake-xcode-native.md) | Critical | Not Started |
| ZOD-REL-003 | [Finalize store-distribution and Swiss Ephemeris licensing path](release-preparation/ZOD-REL-003-finalize-store-distribution-and-swiss-ephemeris-licensing-path.md) | Critical | Not Started |
| ZOD-REL-004 | [Run the full non-functional-requirements measurement pass](release-preparation/ZOD-REL-004-run-the-full-non-functional-requirements-measurement-pass.md) | Critical | Not Started |
| ZOD-REL-005 | [Execute Gate 2 sign-off (Square of Nine approval)](release-preparation/ZOD-REL-005-execute-gate-2-sign-off-square-of-nine-approval.md) | Critical | Not Started |
| ZOD-REL-006 | [Execute Gate 3 decision (server/accounts/sync go/no-go)](release-preparation/ZOD-REL-006-execute-gate-3-decision-server-accounts-sync-go-no-go.md) | Medium | Not Started |
| ZOD-REL-007 | [Final specification-coverage verification pass](release-preparation/ZOD-REL-007-final-specification-coverage-verification-pass.md) | High | Not Started |

### Optional Extensions (`optional-extensions/`)

These are **out of MVP scope**. Each is listed in the spec's "Planned extensions" sections or "Out of scope for the first version," and none should be started before Phase 4 is complete, per the roadmap's "no screen is started before the core is tested" ordering principle applied analogously to extensions following the shipped core.

| ID | Task | Priority | Status |
|---|---|---|---|
| ZOD-EXT-001 | [User-defined aspect orbs with an active-aspects list](optional-extensions/ZOD-EXT-001-user-defined-aspect-orbs-with-an-active-aspects-list.md) | Low | Not Started |
| ZOD-EXT-002 | [True lunar node as a selectable option](optional-extensions/ZOD-EXT-002-true-lunar-node-as-a-selectable-option.md) | Low | Not Started |
| ZOD-EXT-003 | [Additional bodies (Chiron, Lilith)](optional-extensions/ZOD-EXT-003-additional-bodies-chiron-lilith.md) | Low | Not Started |
| ZOD-EXT-004 | [Sidereal zodiac with ayanamsa choice](optional-extensions/ZOD-EXT-004-sidereal-zodiac-with-ayanamsa-choice.md) | Low | Not Started |
| ZOD-EXT-005 | [Ascendant and houses (birth place/time input)](optional-extensions/ZOD-EXT-005-ascendant-and-houses-birth-place-time-input.md) | Low | Not Started |
| ZOD-EXT-006 | [Rotating outer rings on the Square of Nine](optional-extensions/ZOD-EXT-006-rotating-outer-rings-on-the-square-of-nine.md) | Low | Not Started |
| ZOD-EXT-007 | [Show planet positions on the Square of Nine](optional-extensions/ZOD-EXT-007-show-planet-positions-on-the-square-of-nine.md) | Low | Not Started |
| ZOD-EXT-008 | [User-defined highlight angles and colors](optional-extensions/ZOD-EXT-008-user-defined-highlight-angles-and-colors.md) | Low | Not Started |
| ZOD-EXT-009 | [Jump to a cell by entering a number or date](optional-extensions/ZOD-EXT-009-jump-to-a-cell-by-entering-a-number-or-date.md) | Low | Not Started |
| ZOD-EXT-010 | [Configurable spiral start point and direction](optional-extensions/ZOD-EXT-010-configurable-spiral-start-point-and-direction.md) | Low | Not Started |
| ZOD-EXT-011 | [ICS calendar export for degree crossings](optional-extensions/ZOD-EXT-011-ics-calendar-export-for-degree-crossings.md) | Low | Not Started |
| ZOD-EXT-012 | [Server, accounts, and cross-device sync (Phase 5 expansion)](optional-extensions/ZOD-EXT-012-server-accounts-and-cross-device-sync-phase-5-expansion.md) | Low | Not Started |

---

# 5. Dependencies and task order

## 5.1 Critical path (must happen first, strictly sequential)

```
ZOD-FND-001 (Melos workspace)
  → ZOD-FND-002 (EphemerisPort interface) ─┬→ ZOD-FND-003 (Swiss Ephemeris FFI spike) → ZOD-EPH-002 (primary adapter)
                                            └→ ZOD-EPH-001 (mean node formula)
  → ZOD-FND-012 (data model) ──────────────────────────────────────────────────┐
  → ZOD-FND-013 → ZOD-UI-001 (color tokens) ────────────────────────────────────┤
  → ZOD-GAN-001 (spiral math) → ZOD-GAN-002 (highlights) → ZOD-GAN-003 (date mapping)
                                                                                 ▼
                                                         Gate 1: ZOD-TST-001..013, ZOD-TST-017
                                                                 (core accuracy tests pass)
                                                                                 ▼
                                              Phase 2 (wheel) and Phase 3 (square) can both start
```

Nothing in Phase 2 or Phase 3 should start before Gate 1 passes — this mirrors the roadmap's explicit "no screen is started before the core is tested" rule. In practice this means: all of `foundations-architecture/` (Foundations) and `computation-engine/` (Computation engine), plus the dedicated test tasks in `testing-qa/` that cover them (ZOD-TST-001 through ZOD-TST-013, ZOD-TST-017), form the Phase-1 critical path.

## 5.2 Independent tracks once Gate 1 passes

These four tracks have no dependency on each other and can run **in parallel** by different developers/agents once their own prerequisites (below) are met:

| Track | Starts after | Key internal order |
|---|---|---|
| **Wheel** (`zodiac-wheel/`) | ZOD-WHL-001 needs ZOD-UI-001/ZOD-FND-005; crossing-table features need ZOD-CRS-004 | Canvas (001) → rings/markers (002–009) → interaction (010–013) → time controls (014–017) → tables (018–023) → responsive (024–025) |
| **Square** (`gann-square/`) | ZOD-SQR-001 needs ZOD-UI-006/ZOD-GAN-003 | Mode/anchor/size controls (001–004) → canvas/highlights (005–009) → selection/details (010–013) → responsive/legend (014–020) |
| **Shared UI** (`shared-ui-design-system/`) | ZOD-UI-001 needs ZOD-FND-013 | Tokens (001–003) before any component (004–014); harness (015) last |
| **Localization infra** (`localization/`, early tasks) | ZOD-L10-001/007 need ZOD-FND-005/012 | Infra (001, 007) can start in Phase 1 alongside Foundations; the audit/enforcement tasks (004–015) run in Phase 4 once every screen exists |

Excel export (`excel-export/`) depends on the Square screen existing conceptually (its data model, not its UI) and should start once ZOD-GAN-001/002/003 and ZOD-FND-012 are stable — it can run in parallel with the Square *screen's* UI work, converging at Gate 2.

Settings and persistence (`settings-persistence/`) depend on nearly everything upstream (wheel settings, square defaults, export triggers) and are correctly sequenced into Phase 3–4 — don't start ZOD-SET-006 before ZOD-EPH-002/003/004 and ZOD-ASP-001 exist, since it's the control surface for all of them. Note the direction here: ZOD-SET-006 builds the orb-stepper *control*, and ZOD-ASP-002 (which wires that control's value into the aspect-detection engine) correctly depends on ZOD-SET-006 existing first, not the other way around — an earlier draft of this document had that backwards, creating a circular dependency between ZOD-SET-006 and ZOD-ASP-002; it has been corrected in both task files.

## 5.3 Tasks that require technical investigation before estimation

- **ZOD-FND-003** (Swiss Ephemeris FFI spike) — R-7's named risk; blocks ZOD-EPH-002 and therefore nearly everything.
- **ZOD-EPH-004** (astronomy-engine FFI spike) — same category of risk, lower severity since it's a backup.
- **ZOD-XLS-001** (OOXML generation spike) — R-8's named risk; blocks all of `excel-export/`.
- **ZOD-FND-011** (data-file coverage range) — affects app size and every date-range limit in the UI; should resolve early in Phase 1.

## 5.4 Tasks blocked by an unresolved product decision

| Task | Blocked by | See §6 |
|---|---|---|
| ZOD-ASP-002 | D-1 (orb editability) | §6.1 |
| ZOD-SQR-008 (partially) | D11 (light-theme selection border) | §6.2 |
| ZOD-SQR-020 (partially) | D14 (tablet-portrait "wide screen" interpretation) | §6.2 |
| ZOD-XLS-003 | The EX open decision (numeric-anchor interpretation) | §6.2 |
| ZOD-WHL-011, ZOD-GAN-003 | The DST-hour-jump planning constraint | §6.2 |
| ZOD-SET-006 (Sidereal row) | D19 (whether to show disabled planned options at all) | §6.2 |
| ZOD-EXT-005 | D-2 (location/privacy for houses) | §6.1 |
| ZOD-EXT-004 | D-5 (tropical-only default) | §6.1 |
| ZOD-EXT-006, ZOD-EXT-007 | No design reference exists (D16) | §6.2 |
| ZOD-EXT-012 | Gate 3 go/no-go | §6.3 |

No circular dependencies exist in this document: the computation core (`computation-engine/`) depends only on foundations (`foundations-architecture/`); every screen (`navigation/` through `about/`) depends only on the core, shared UI, and foundations; testing (`testing-qa/`) depends on the thing it tests; NFR/release (`performance-accessibility-reliability/` through `release-preparation/`) depend only on already-built screens; extensions (`optional-extensions/`) depend only on MVP tasks.

---

# 6. Open decisions and blockers

## 6.1 Spec-level open decisions (require explicit product-owner sign-off)

| ID | Question | Spec's proposed default | Blocks |
|---|---|---|---|
| D-1 | Are aspect orbs user-editable, or fixed? | Fixed table, no editing | ZOD-ASP-002, ZOD-EXT-001 |
| D-2 | Is a geographic location required for houses, and does that conflict with the device-only privacy model? | Not required in v1 | ZOD-EXT-005 |
| D-3 | Mean vs. true node as default; add Chiron/Lilith? | Mean node only | ZOD-EXT-002, ZOD-EXT-003 |
| D-4 | Is "clockwise, left of center" the permanently fixed spiral, or should direction be user-selectable? | Fixed, but the setting field exists in the data model | ZOD-EXT-010 |
| D-5 | Add a sidereal zodiac? | Tropical only | ZOD-EXT-004 |

## 6.2 Design-reference "needs approval" items (`DESIGN_DECISIONS.md`)

These are places the design reference made a judgment call that stretches or interprets the spec — each is called out in its owning task above, collected here for one-place review:

| ID | Item | Owning task |
|---|---|---|
| D6 | Compact-wheel display-spread threshold is 16°, not WH-4's literal 11° | ZOD-WHL-005, ZOD-WHL-024 |
| D11 | Light-theme selected-cell border adds an ink outline outside the spec's literal "white border" | ZOD-SQR-008 |
| D14 | Tablet-portrait square details use the phone ("above") rule, as an interpretation of SQ-16's undefined "wide screen" | ZOD-SQR-020 |
| D15 | Numbers mode hides the anchor field entirely (doesn't resolve the separate open numeric-anchor Excel question) | ZOD-SQR-002 |
| D18 | Settings mocks aspect orbs as editable, which may conflict with D-1's "no editing" default | ZOD-SET-006, ZOD-ASP-002 |
| D19 | Sidereal/Topocentric shown as visible (disabled/planned) options rather than hidden entirely | ZOD-SET-006, ZOD-EXT-004 |
| D16 | Rotating rings and on-square planet positions are deliberately **not** designed yet | ZOD-EXT-006, ZOD-EXT-007 |

Two more spec-level open items, not from `DESIGN_DECISIONS.md`, also need resolution:

- **The Excel numeric-anchor interpretation** ("Export with live formulas" → "One open decision for approval"): does changing a numbers-mode anchor keep highlights fixed to position (the document's working assumption, EX-11) or recompute them from the new value's square root? Blocks ZOD-XLS-003's exact formula semantics.
- **The DST 4-hour-step behavior** (planning constraints: "a decision is needed on whether this is the desired behavior"): the spec's working assumption (absolute-time stepping, so the displayed local hour jumps across a DST change) is implemented as the default throughout `computation-engine/`/`gann-square/`/`excel-export/`, but is explicitly flagged as needing confirmation, not a settled requirement.

## 6.3 Gate-level blockers

- **Gate 1** (ZOD-TST-017): all core accuracy tests must pass before Phase 2/3 feature work begins.
- **Gate 2** (ZOD-REL-005): explicit user approval of spiral direction, highlight colors, and date handling, bundling the §6.2 square-related approvals into one checkpoint.
- **Gate 3** (ZOD-REL-006): go/no-go on Phase 5 (server/accounts/sync), gating all of `optional-extensions/`'s ZOD-EXT-012.

## 6.4 Non-decision risks to actively monitor (from the spec's risk table)

These don't block a specific task the way the decisions above do, but each has a named mitigation task and should stay visible to whoever is sequencing work:

| ID | Risk | Mitigated by |
|---|---|---|
| R-1 | Missed degree crossing near a retrograde station | ZOD-CRS-001, ZOD-TST-007 |
| R-2 | Silent accuracy loss outside the ephemeris's covered date range | ZOD-FND-011, ZOD-NFR-017 |
| R-3 | Formula regressions when splitting code into packages | ZOD-TST-001 through ZOD-TST-013 (tests as source of truth, written before/alongside the split) |
| R-4 | DST causes a skipped/duplicated cell in date-and-time mode | ZOD-TST-012, §6.2's DST open item |
| R-5 | A result mistaken for financial/astrological advice | ZOD-ABT-005, ZOD-XLS-006/017 |
| R-6 | Swiss Ephemeris licensing blocks store distribution | ZOD-FND-010, ZOD-REL-003 |
| R-7 | FFI build complexity on iOS/Android | ZOD-FND-003, ZOD-REL-002 |
| R-8 | No proven Dart library for formula-bearing Excel export | ZOD-XLS-001 |

---

## 7. MVP vs. Future Extensions overview

193 of 205 tasks are **MVP** scope (required for the first shipping version, phases 1–4). 12 are **Optional Extension** scope — every one of them lives in [`optional-extensions/`](optional-extensions/) and none should be started before Phase 4 is complete and Gate 3 (§6.3) has been decided, per the roadmap.

| Folder | MVP tasks | Optional Extension tasks |
|---|---|---|
| [`foundations-architecture/`](foundations-architecture/) | 14 | 0 |
| [`computation-engine/`](computation-engine/) | 14 | 0 |
| [`shared-ui-design-system/`](shared-ui-design-system/) | 15 | 0 |
| [`navigation/`](navigation/) | 5 | 0 |
| [`zodiac-wheel/`](zodiac-wheel/) | 25 | 0 |
| [`gann-square/`](gann-square/) | 20 | 0 |
| [`excel-export/`](excel-export/) | 17 | 0 |
| [`settings-persistence/`](settings-persistence/) | 20 | 0 |
| [`localization/`](localization/) | 15 | 0 |
| [`about/`](about/) | 7 | 0 |
| [`testing-qa/`](testing-qa/) | 17 | 0 |
| [`performance-accessibility-reliability/`](performance-accessibility-reliability/) | 17 | 0 |
| [`release-preparation/`](release-preparation/) | 7 | 0 |
| [`optional-extensions/`](optional-extensions/) | 0 | 12 |
| **Total** | **193** | **12** |

No MVP folder contains an Optional Extension task and vice versa — the separation is structural (by folder), not just a per-task label.

---

# 8. Specification coverage checklist

Confirms every category of actionable requirement in the spec is converted into at least one task. Check marks indicate coverage exists in this document; they do not indicate the work itself is done (all of it is planned; none of it has been implemented yet — see "Project overview" above and the spec's own "Development status and scope" section).

**Use cases (UC1–UC10):**
- [x] UC1–UC3 (wheel positions, crossings, historical dates) → `zodiac-wheel/` ZOD-WHL-002 through 023
- [x] UC4–UC8 (square modes, cell details, export, rotating rings) → `gann-square/` ZOD-SQR-*, `excel-export/` ZOD-XLS-*, rotating rings correctly deferred to `optional-extensions/` ZOD-EXT-006
- [x] UC9 (planets on the square) → correctly deferred to `optional-extensions/` ZOD-EXT-007 (no design reference exists yet)
- [x] UC10 (save squares/settings) → `settings-persistence/` ZOD-DAT-001 through 010

**Navigation (NAV-1–NAV-7):** [x] all seven → `navigation/` ZOD-NAV-001 through 005

**Wheel (WH-1–WH-20):** [x] all twenty → `zodiac-wheel/` ZOD-WHL-001 through 023 (structure 001–009, interaction 010–013, time/playback 014–017, tables 018–023)

**Square (SQ-1–SQ-22):** [x] all twenty-two → `gann-square/` ZOD-SQR-001 through 020 (modes/anchor 001–004, layout/highlights 005–009, details 010–013, display 014–020)

**Excel export (EX-1–EX-16) and the live-formula override section:** [x] all sixteen, plus the live-formula rules EX-8–EX-15 and the formula table → `excel-export/` ZOD-XLS-001 through 012; other formats → ZOD-XLS-013 through 015; localization → ZOD-XLS-016; limits → ZOD-XLS-017

**Calculation rules:**
- [x] Planet position, retrograde, position format → `computation-engine/` ZOD-EPH-001, 002, 005
- [x] Degree crossings (solver, refinement, boundary) → `computation-engine/` ZOD-CRS-001 through 004
- [x] Aspects (table, rule, orbs) → `computation-engine/` ZOD-ASP-001, 002
- [x] Gann spiral (position, highlights) → `computation-engine/` ZOD-GAN-001, 002
- [x] Dates (three modes, today's cell, format) → `computation-engine/` ZOD-GAN-003

**Astronomical accuracy (CRS-A1–CRS-A5, ACC-1–ACC-5, data-source/settings tables, decisions table):** [x] CRS-A* → ZOD-CRS-001/002; ACC-1–5 → `testing-qa/` ZOD-TST-001, 004, 005, 006, 007; data sources/fixed settings → ZOD-EPH-002/003/004, ZOD-ABT-002/003; FFI/license decisions → ZOD-FND-003/010, ZOD-REL-002/003

**Data model and storage (DATA-1–DATA-10):** [x] all ten → `foundations-architecture/` ZOD-FND-006, 012; `settings-persistence/` ZOD-DAT-001 through 012; ZOD-NFR-014

**Architecture (ARCH-1–ARCH-8):** [x] all eight → ZOD-FND-001 (workspace/ARCH-2), ZOD-NFR-001 (ARCH-1), ZOD-FND-005 (ARCH-3), ZOD-EPH adapters (ARCH-4), ZOD-WHL-001/ZOD-SQR-005 (ARCH-5), ZOD-FND-003/ZOD-REL-002 (ARCH-6), ZOD-FND-013/ZOD-UI-001 (ARCH-7), noted throughout as "logical pixels" (ARCH-8)

**Localization (L-1–L-19):** [x] all nineteen → `localization/` ZOD-L10-001 through 015, plus ZOD-XLS-016 for export-specific L-15/16/17

**Non-functional requirements (NFR-P1–P4, A1–A3, X1–X6, C1–C3, R1–R3):** [x] all twenty → `performance-accessibility-reliability/` ZOD-NFR-001 through 017 (A1 also directly guarded by ZOD-TST-004)

**Testing (T-EPH-1–3, T-CRS-1–3, T-ASP-1, T-GAN-1–4, T-FMT-1, T-UI-1–5, T-EX-1–6):** [x] all twenty-two named tests → `testing-qa/` ZOD-TST-001 through 015, each cross-referenced to its owning implementation task's acceptance criteria

**Risks (R-1–R-8) and open decisions (D-1–D-5):** [x] all tracked → §6 (this document), each linked to its mitigating/blocked task

**Roadmap phases and gates:** [x] all five phases assigned per-task via the **Development phase** field; all three gates have dedicated tasks (ZOD-TST-017 for Gate 1, ZOD-REL-005 for Gate 2, ZOD-REL-006 for Gate 3)

**Appendices (A–F):** [x] A (Terms) informs vocabulary throughout; B (Ring table) → ZOD-TST-011; C (Highlighted angles) → ZOD-SQR-017, ZOD-TST-010; D (Color roles) → ZOD-UI-001; E (Building the Excel file) → `excel-export/` throughout; F (Sources) → ZOD-ABT-002, ZOD-ABT-007

**Design reference coverage:** every UI task in `shared-ui-design-system/` through `about/` cites a specific file or file set under `design-reference/zodiann/`; every explicit design gap (rotating rings, on-square planets, saved-squares mobile capture, change-date-mode hint styling) is called out by name in its task rather than silently invented. No task in `shared-ui-design-system/` through `about/` introduces a new visual design, component, or color not already present in `design-reference/zodiann/MASTER.md`, `DESIGN_DECISIONS.md`, or the screenshots.

**Optional extensions kept separate from MVP:** [x] all items from "Planned extensions to the wheel," "Planned extensions to the square," and the ics export row live exclusively in `optional-extensions/` (`Scope: Optional Extension`), none are mixed into the MVP task list in `foundations-architecture/` through `release-preparation/`.
