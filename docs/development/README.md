# Zodiann Development Tasks — Directory Guide

This directory holds the complete, implementation-ready task breakdown for the Zodiann app, split into one Markdown file per task. **This is a planning/documentation structure only — nothing described here has been implemented.**

- [`TASKS.md`](TASKS.md) is the **master index**: project overview, phases, category list, the full task table (linked), execution order, and open decisions/blockers.
- **Every task's full detail — description, implementation notes, design reference, acceptance criteria, dependencies, spec references — lives in its own file.** `TASKS.md` links to each one rather than repeating it. If `TASKS.md` and a task file ever appear to disagree on a detail, the task file is authoritative.
- The spec these tasks were derived from is `assets/zodiann-specification.md`.
- The visual design source of truth is `design-reference/zodiann/` — **never modified by this restructuring**, and every UI-related task file still points to the exact file(s) in it to follow.

## Directory structure

```text
docs/development/
├── README.md                              ← you are here
├── TASKS.md                               ← master index
├── foundations-architecture/              ← 14 tasks
├── computation-engine/                    ← 14 tasks
├── shared-ui-design-system/               ← 15 tasks
├── navigation/                            ← 5 tasks
├── zodiac-wheel/                          ← 25 tasks
├── gann-square/                           ← 20 tasks
├── excel-export/                          ← 17 tasks
├── settings-persistence/                  ← 20 tasks
├── localization/                          ← 15 tasks
├── about/                                 ← 7 tasks
├── testing-qa/                            ← 17 tasks
├── performance-accessibility-reliability/ ← 17 tasks
├── release-preparation/                   ← 7 tasks
└── optional-extensions/                   ← 12 tasks  (Scope: Optional Extension — all other folders are MVP)
```

Each folder groups tasks by development area, matching §4 of the original single-file `TASKS.md` one-for-one. MVP tasks (193) and the Optional Extension tasks (12, all in `optional-extensions/`) are never mixed in the same folder.

## What each folder contains

### `foundations-architecture/`

Workspace setup, the computation-core/EphemerisPort contract, FFI spikes, CI, theming scaffold, data model, routing scaffold. No design reference (tooling/architecture) except the logo/icon/font packaging tasks.

### `computation-engine/`

The pure-Dart (`packages/astro_core`, `packages/gann_core`) math: planet position, retrograde, degree-crossing solver, aspects, and the Gann spiral/date formulas. No UI, no design reference — correctness is verified entirely by `testing-qa/`.

### `shared-ui-design-system/`

Every reusable Flutter component (buttons, inputs, segmented control, tables, toasts, dialogs...) and the color/type/spacing token system. Each is already fully designed in `design-reference/zodiann/components/`.

### `navigation/`

The top bar, the side drawer, routing, and screen-switch behavior (scroll-to-top, stop playback).

### `zodiac-wheel/`

Everything on the Zodiac Wheel screen: the wheel drawing, drag/keyboard interaction, time controls and playback, the positions table, and the degree-crossing table.

### `gann-square/`

Everything on the Gann Square of Nine screen: mode/anchor/size controls, the spiral canvas and highlights, cell selection and details, legend, and responsive layout.

### `excel-export/`

The self-recalculating xlsx export (live formulas, conditional formatting, defined names) plus the secondary CSV/PNG/PDF/degree-table export formats.

### `settings-persistence/`

The Settings screen, the Saved squares screen, and all on-device storage (shared_preferences, SQLite/drift, backup export/import, delete-all-data).

### `localization/`

Hebrew (RTL) and English (LTR) support: ARB infrastructure, language switching, logical-layout auditing, bidi isolation, date/number formatting, and the never-mirrored exceptions (wheel, square).

### `about/`

The About and Sources screen: hero, computation-sources table, method settings, the Gann formula block, the not-advice notice, privacy statement, and license list.

### `testing-qa/`

Dedicated test-suite deliverables for every named spec test (T-EPH-*, T-CRS-*, T-ASP-1, T-GAN-*, T-FMT-1, T-UI-*, T-EX-*, ACC-*) plus the manual acceptance-testing task and CI gate wiring.

### `performance-accessibility-reliability/`

Cross-cutting NFR verification: frame-rate/latency budgets, isolate-based background computation, screen-reader/keyboard/contrast/reduced-motion audits, responsive QA, and reliability (storage failure, invalid input, no-network).

### `release-preparation/`

Store packaging, the native build pipeline, licensing/distribution decisions, the Gate 2/Gate 3 sign-off tasks, and the final specification-coverage verification pass.

### `optional-extensions/`

Everything explicitly out of MVP scope: editable orbs, true node, extra bodies, sidereal zodiac, houses, rotating rings, on-square planets, user-defined highlights, jump-to-cell, configurable spiral direction, ICS export, and the Phase 5 server/accounts/sync expansion.

## How to find a task by ID

Every task ID is namespaced by category (e.g. `ZOD-WHL-010` is always in `zodiac-wheel/`), and every filename starts with its exact ID:

| Namespace | Folder | Area |
|---|---|---|
| `ZOD-FND-###` | [`foundations-architecture/`](foundations-architecture/) | Project foundations and architecture |
| `ZOD-EPH-###` | [`computation-engine/`](computation-engine/) | Ephemeris / planet-position computation |
| `ZOD-CRS-###` | [`computation-engine/`](computation-engine/) | Degree-crossing solver |
| `ZOD-ASP-###` | [`computation-engine/`](computation-engine/) | Aspect detection |
| `ZOD-GAN-###` | [`computation-engine/`](computation-engine/) | Gann spiral math (pure core) |
| `ZOD-UI-###` | [`shared-ui-design-system/`](shared-ui-design-system/) | Shared UI components and design system |
| `ZOD-NAV-###` | [`navigation/`](navigation/) | Navigation and app shell |
| `ZOD-WHL-###` | [`zodiac-wheel/`](zodiac-wheel/) | Zodiac wheel screen |
| `ZOD-SQR-###` | [`gann-square/`](gann-square/) | Gann Square of Nine screen |
| `ZOD-XLS-###` | [`excel-export/`](excel-export/) | Excel (and other format) export |
| `ZOD-SET-###` | [`settings-persistence/`](settings-persistence/) | Settings |
| `ZOD-DAT-###` | [`settings-persistence/`](settings-persistence/) | Local persistence (saved squares, backup) |
| `ZOD-L10-###` | [`localization/`](localization/) | Hebrew/English localization |
| `ZOD-ABT-###` | [`about/`](about/) | About and sources screen |
| `ZOD-TST-###` | [`testing-qa/`](testing-qa/) | Dedicated test-suite tasks (named spec tests) |
| `ZOD-NFR-###` | [`performance-accessibility-reliability/`](performance-accessibility-reliability/) | Cross-cutting performance/accessibility/reliability |
| `ZOD-REL-###` | [`release-preparation/`](release-preparation/) | Release preparation |
| `ZOD-EXT-###` | [`optional-extensions/`](optional-extensions/) | Optional future extensions |

The fastest way to find a specific task:

1. **Know the ID?** Its namespace prefix tells you the folder (table above); the file is `<folder>/<ID>-<slug>.md`.
2. **Know the title or topic?** Use `TASKS.md`'s task index tables (§4) — every row links straight to the file.
3. **Searching the repo?** Every task file's `# <ID> - <Title>` heading is unique and grep-able.

## How to read the dependency and spec-reference fields

- **Dependencies** lists prerequisite tasks that should be done first. Most entries are direct links (`[ZOD-XXX-###](...)`) with the dependency's title inlined so you don't have to open it to know what it is. A few entries are written as a range (`ZOD-NFR-001 through ZOD-NFR-017`) or a phrase (`Every task in this document`) when a task genuinely depends on an entire group — these are intentionally not expanded into dozens of links, exactly as in the original `TASKS.md`.
- **Specification references** lists the exact requirement IDs (or quoted section titles) from `assets/zodiann-specification.md` that the task implements — use these to go back to the spec's own wording if a task's intent is unclear.
- **Notes** is auto-populated only when a task touches an open product/design decision, references a `DESIGN_DECISIONS.md` "needs approval" item, or an explicit design gap — cross-reference `TASKS.md` §6 "Open decisions and blockers" before starting that task.

## How to update task status

Each task file's **Metadata** block has a `Status` field. When you start, pause, or finish a task:

1. Edit that task's own file — set `Status` to one of: `Not Started`, `In Progress`, `Blocked`, `Done`. (If `Blocked`, add a one-line reason, e.g. referencing an open decision in `TASKS.md` §6.)
2. Update the matching row in `TASKS.md`'s task index table (§4) to the same status, so the master index stays accurate without anyone having to open every file to check progress.
3. **The individual task file is always the source of truth for the task's details** (description, acceptance criteria, dependencies). `TASKS.md` only mirrors ID / title / priority / status for at-a-glance scanning and linking — if you need to change scope, acceptance criteria, or dependencies, edit the task file, not `TASKS.md`.

All 205 tasks currently start at `Not Started` — none of this plan has been implemented yet.

## Design reference — unchanged, still the source of truth

`design-reference/zodiann/` was **not modified** by this reorganization. Every UI-related task file still contains an explicit **Design Reference** field naming the exact screen(s)/component(s) to follow under `design-reference/zodiann/`, per the project's standing rule:

- Do not invent a new visual design.
- Do not introduce a different design language.
- Do not redesign existing screens or replace existing components with arbitrary alternatives.
- Where the design reference doesn't cover something, the task says so explicitly as a **design gap** rather than inventing a solution (see e.g. `optional-extensions/ZOD-EXT-006-...` and `ZOD-EXT-007-...`, which block on "no design reference exists yet").

Non-UI tasks (most of `foundations-architecture/`, all of `computation-engine/`, most of `testing-qa/`) explicitly state "No direct design reference applies" rather than leaving the field blank.
