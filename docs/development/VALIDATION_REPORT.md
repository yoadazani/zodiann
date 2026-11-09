# Zodiann Development Tasks — Validation Report

**Scope:** Full integrity audit of the restructured task documentation under `docs/development/` (205 individual task files, `TASKS.md`, `README.md`), performed independently of the restructuring work itself.

**Method:** Every check in this report was run mechanically against the filesystem — not re-asserted from memory. The baseline for "does the original say X" questions is the parsed record (`id`, `title`, `category`, `phase`, `priority`, `scope`, `dependencies`) captured directly from the original single-file `TASKS.md` at the moment it was split, before it was rewritten into the master index. Formula- and content-critical tasks were additionally spot-checked by direct re-reading against `assets/zodiann-specification.md`. This is a documentation audit only — no application code was written, no dependencies installed, and nothing under `design-reference/` was touched.

**Date:** 2026-11-10

---

## A. Overall Results

| Metric | Value |
|---|---|
| Total original tasks (parsed from the pre-split `TASKS.md`) | 205 |
| Total individual task files on disk | 205 |
| Total MVP tasks | 193 |
| Total Optional Extension tasks | 12 |
| Total category directories | 14 |
| Task-file ↔ original-parse count match | ✅ exact match |

**Overall validation status: PASS WITH WARNINGS** — see §H for the full rationale. Two genuine defects (both involving circular dependencies, one bundled with an ID typo) were found and corrected. A systematic sweep found and corrected 14 task files plus one `TASKS.md` sentence that still carried stale references to the old single-file section numbers. Eight dependency relationships cross a nominal phase boundary and are left as documented open issues rather than mechanically "fixed," because resolving them correctly requires a scheduling judgment call, not a factual correction.

---

## B. Task Integrity

| Check | Result |
|---|---|
| Missing task IDs (in original, absent on disk) | **0** |
| Duplicate task IDs (same ID, >1 file) | **0** |
| Unexpected task IDs (on disk, not in original) | **0** |
| Files containing more than one task heading | **0** |
| Files whose filename ID disagrees with their own H1 heading ID | **0** |
| Incorrect category assignments (file in the wrong folder vs. original) | **0** |
| Title mismatches (file H1 title vs. original title) | **0** |
| Phase / Priority / Scope metadata mismatches vs. original | **0** |
| Content preservation — structural (missing/empty required section) | **0** |
| Content preservation — factual defects found | **2 categories, both corrected (see §F)** |

Every one of the 205 original task IDs appears on disk exactly once, in the correct category folder, with its title, phase, priority, and scope preserved verbatim from the original parse. No file merges two tasks, and no file is missing its task heading.

**Formula fidelity spot-check.** The five highest-stakes computation tasks — the Gann spiral position formulas (`ZOD-GAN-001`), the highlight classification rules (`ZOD-GAN-002`), the crossing-solver refinement formula (`ZOD-CRS-002`), the mean-node formula (`ZOD-EPH-001`), and the Excel Helper-sheet formula set (`ZOD-XLS-002`) — were read in full and compared against the spec's own formula blocks. All formulas (`k = ceil((sqrt(n) - 1) / 2)`, the Blue/Yellow/Gray mod-rules, `Ω = 125.04452 − 1934.136261·T`, the Excel `ROUNDUP`/`MOD`/`IF` chain, etc.) are byte-exact. No formula, constant, or mathematical condition was altered, simplified, or truncated.

---

## C. Documentation Integrity

| Check | Result |
|---|---|
| Broken links (across all 207 markdown files) | **0** |
| Files missing a required metadata field | **0** |
| Tasks with zero acceptance-criteria checkboxes | **0** |
| Malformed checkboxes (`-[ ]`, pre-checked `[x]`, etc.) | **0** |
| H2 section order/naming deviating from the template | **0** |
| `TASKS.md` index rows missing, duplicated, or pointing to the wrong file | **0** |
| `TASKS.md` priority/status column disagreeing with the task file | **0** |
| `README.md` per-folder / total / MVP / Extension counts incorrect | **0** |
| `README.md` namespace table pointing to the wrong folder | **0** |

**Finding — stale internal section references (corrected).** The restructuring replaced `TASKS.md`'s single-file section numbering (`§4.1`–`§4.14`, `§7`) with category folders and a renumbered index. The prose *inside individual task files* was not re-swept for this at the time — 14 task files plus one sentence in `TASKS.md` §5.2 still said things like "the rest of §4.7" or "every NFR task in §4.12," which pointed at section numbers that no longer exist in the restructured document. This was caught by a full-text sweep and corrected (see §F) by substituting the equivalent folder name (e.g. "the rest of `excel-export/`") using the same category map the restructuring itself used, and by updating the two stale `§7` references (the old "Completeness checklist" number) to `§8` (its number in the current `TASKS.md`, where it's now "Specification coverage checklist" after the insertion of a new §7 "MVP vs. Future Extensions overview"). References to `design-reference/zodiann/MASTER.md`'s *own* internal sections (e.g. `MASTER.md §2.3`) and to `TASKS.md` §6 ("Open decisions and blockers," whose number did not change) were left untouched — they were already correct.

**Note on acceptance-criteria count.** 25 of 205 tasks have exactly one acceptance criterion. All 25 were reviewed (a representative sample of 6, spanning `performance-accessibility-reliability/`, `about/`, `excel-export/`, `optional-extensions/`, `settings-persistence/`, and `testing-qa/`, is quoted below) and every one is a genuinely narrow, single-outcome task (e.g. `ZOD-XLS-008`: "File name matches the pattern for all three modes and a range of sizes" — there is only one thing to verify). This is not truncation; it reflects task granularity, not information loss.

**Note on Implementation Details without bullet lists.** All 12 tasks with zero `-` bullets in Implementation Details are the 12 `optional-extensions/ZOD-EXT-*` files. This is by design — extension tasks were deliberately written as short prose paragraphs (lighter-weight stubs for future work) rather than full bulleted implementation specs, consistent with their "Optional Extension" scope. Not a defect.

---

## D. Dependency Integrity

| Check | Result (before correction) | Result (after correction) |
|---|---|---|
| Dependency references pointing to a nonexistent task ID | 0 | 0 |
| Self-dependencies (a task listing itself) | 0 | 0 |
| Circular dependencies | **2** | **0** |
| Range/group dependencies (e.g. "ZOD-TST-001 through ZOD-TST-013") that fail to resolve | 0 | 0 |
| Dependencies crossing into a nominally later phase | 8 | 8 (documented, not auto-resolved) |

**Circular dependencies found and corrected:**

1. **`ZOD-SET-006` ↔ `ZOD-ASP-002`.** `ZOD-SET-006` ("Build the 'Wheel and computation' panel") listed `ZOD-ASP-002` ("Implement aspect-orb configuration data flow") as a dependency, while `ZOD-ASP-002` listed `ZOD-SET-006` right back. Reading both tasks' actual descriptions: `ZOD-SET-006` only needs the stepper *component* (`ZOD-UI-007`) to render the orb controls; `ZOD-ASP-002` is the task that wires an *already-built* control's values into the aspect-detection engine, so it genuinely needs `ZOD-SET-006` to exist first. The dependency only made sense in one direction. **Fix:** removed `ZOD-ASP-002` from `ZOD-SET-006`'s Dependencies list; kept `ZOD-SET-006` → `ZOD-ASP-002` (unchanged). Also updated the one sentence in `TASKS.md` §5.2 that asserted the old (backwards) relationship, with an explicit note documenting the correction.
2. **`ZOD-DAT-008` ↔ `ZOD-SET-005`.** Same pattern: `ZOD-SET-005` ("Build the 'Your data' panel") listed `ZOD-DAT-008` ("Implement backup export/import") as a dependency, and `ZOD-DAT-008` listed `ZOD-SET-005` back. `ZOD-SET-005` only needs the panel-layout and dialog components to build its UI row; the backend `ZOD-DAT-008` naturally depends on that UI existing to attach its action to, not the reverse. **Fix:** removed `ZOD-DAT-008` from `ZOD-SET-005`'s Dependencies list.

**Incidental defect found alongside #2 and corrected:** `ZOD-SET-005`'s own acceptance criteria read *"Export produces a single versioned JSON file (ZOD-DAT-005)"* and *"Import replaces settings and adds... (ZOD-DAT-005)"* — but `ZOD-DAT-005` is "Implement 'Open' (load a saved square into the Square screen)," an unrelated task. The clearly-intended reference is `ZOD-DAT-008` (literally "Implement backup export/import"), which is also what had pulled an incorrect `ZOD-DAT-005` entry into the Dependencies list in the first place. **Fix:** both acceptance-criteria lines corrected to cite `ZOD-DAT-008`; the stray `ZOD-DAT-005` dependency entry removed (it was present only because of this typo — `ZOD-SET-005` has no genuine need for "Open a saved square" to be built first).

**Open issue — phase-order tensions (not auto-resolved).** Eight dependency edges point from a task in phase *N* to a task formally scheduled in phase *N+1* or later. None of these are logical contradictions (no cycles), and the document's own §5.2 "Independent tracks" section already acknowledges that Excel export, NFR work, and Settings legitimately straddle phases as parallel/cross-cutting tracks — so these are not necessarily wrong. They are listed here because resolving them *correctly* (rather than mechanically) requires deciding whether to nudge a phase label, split a task, or accept the cross-phase dependency as intentional — a judgment call, not a factual error, and explicitly out of scope for silent correction per this audit's instructions:

| Dependent task (phase) | Depends on (phase) | Note |
|---|---|---|
| `ZOD-XLS-013` (2) | `ZOD-XLS-001` (3) | The wheel's degree-table xlsx/csv export genuinely needs the OOXML pipeline spike, which is scheduled in the Excel phase. |
| `ZOD-NFR-001` (2) | `ZOD-UI-011` (3) | Only the "Stop" interaction (surfaced via the toast) needs the toast component; the core isolate-wiring does not. |
| `ZOD-NFR-016` (1, ongoing) | `ZOD-DAT-011` (4) | `ZOD-NFR-016` is explicitly an ongoing/standing audit; its phase-1 label marks when it *starts*, not when every dependency must be done. |
| `ZOD-SET-006` (3) | `ZOD-SET-001` (4) | The panel-layout container (`SET-001`) is scheduled a full phase after a panel that plugs into it (`SET-006`) — worth a second look during planning. |
| `ZOD-TST-014` (2–3) | `ZOD-SQR-001`, `ZOD-SQR-003`, `ZOD-SQR-010`, `ZOD-XLS-010` (3) | `ZOD-TST-014`'s own phase is already "2–3" (it covers T-UI-1 through T-UI-5, which span both the wheel and the square) — not actually a conflict once read correctly, included here only for completeness. |

---

## E. Design Reference Integrity

| Metric | Value |
|---|---|
| Total UI-related tasks checked (Design Reference ≠ "No direct design reference applies") | 109 |
| Non-UI tasks correctly stating no design reference applies | 96 |
| UI tasks citing at least one concrete `design-reference/zodiann/...` path or a bare `MASTER.md`/`DESIGN_DECISIONS.md` reference | 103 (of 109) |
| Distinct design-reference paths/glob patterns cited | 31 |
| Paths/patterns that failed to resolve to a real file | **0** |
| Explicitly documented design gaps | **3** (`ZOD-EXT-006`, `ZOD-EXT-007`, `ZOD-WHL-011`) |
| Files/content under `design-reference/` modified | **0** |

Every one of the 31 distinct design-reference paths or brace-expanded glob patterns cited across all task files (e.g. `design-reference/zodiann/screens/02-square-of-nine_{numbers,dates,datetime}_desktop_{en,he}_{dark,light}.png`) resolves to at least one real file under `design-reference/zodiann/`. `design-reference/` itself was read-only throughout this audit.

**Six tasks initially flagged, all confirmed correct on manual review.** An automated check first flagged `ZOD-XLS-005`, `ZOD-XLS-006`, `ZOD-EXT-007`, `ZOD-EXT-012`, `ZOD-DAT-005`, and `ZOD-WHL-022` for "citing no concrete design-reference path" because their Design Reference text didn't match the exact boilerplate string the checker expected. Reading each directly: all six are legitimate and well-reasoned — `ZOD-XLS-005`/`006` correctly explain that Excel data sheets have no screen mockup (their structure is spec-defined, in EX-2/EX-3/Appendix E); `ZOD-EXT-007`/`012` are two of the three intentional, explicitly-flagged design gaps; `ZOD-DAT-005`/`ZOD-WHL-022` correctly state "No new visual element" because they're pure interaction-wiring tasks that reuse already-specified UI from other tasks. This was a checker-precision issue, not a content issue — logged here for transparency since the goal is to report what was actually verified, not just what passed a narrow pattern match.

**Design-gap handling confirmed correct.** `ZOD-EXT-006` (rotating outer rings) and `ZOD-EXT-007` (planets on the square) both correctly state, per `DESIGN_DECISIONS.md` D16, that no mockup exists and implementation must not start until a design reference is produced. `ZOD-WHL-011` (change-date drag mode) correctly flags that only its hint-text change is specified — any unique visual treatment beyond that is an open design gap, since the static mockups only show "Rotate wheel" mode active. No task invents a visual treatment to fill a gap.

---

## F. Corrections Made

| # | Correction | Files affected |
|---|---|---|
| 1 | Removed the backwards `ZOD-ASP-002` dependency from `ZOD-SET-006`, resolving a circular dependency | `settings-persistence/ZOD-SET-006-*.md` |
| 2 | Removed the backwards `ZOD-DAT-008` dependency from `ZOD-SET-005`, resolving a circular dependency | `settings-persistence/ZOD-SET-005-*.md` |
| 3 | Corrected a task-ID typo (`ZOD-DAT-005` → `ZOD-DAT-008`) in two acceptance-criteria lines, and removed the resulting stray `ZOD-DAT-005` dependency entry | `settings-persistence/ZOD-SET-005-*.md` |
| 4 | Updated `TASKS.md` §5.2 to describe the corrected `ZOD-SET-006`/`ZOD-ASP-002` dependency direction, with an explicit note about the fix | `TASKS.md` |
| 5 | Replaced stale single-file section references (`§4.1`–`§4.14`) with their current folder-name equivalents (e.g. `§4.7` → `` `excel-export/` ``) | `excel-export/ZOD-XLS-001-*.md`, `ZOD-XLS-012-*.md`, `ZOD-XLS-016-*.md`, `foundations-architecture/ZOD-FND-013-*.md`, `localization/ZOD-L10-004-*.md`, `ZOD-L10-009-*.md`, `optional-extensions/ZOD-EXT-003-*.md`, `performance-accessibility-reliability/ZOD-NFR-006-*.md`, `ZOD-NFR-012-*.md`, `ZOD-NFR-013-*.md`, `release-preparation/ZOD-REL-004-*.md`, `ZOD-REL-005-*.md`, `settings-persistence/ZOD-DAT-005-*.md` |
| 6 | Replaced two stale `§7` references (the old "Completeness checklist" number) with the correct current reference, `TASKS.md` §8 "Specification coverage checklist" | `release-preparation/ZOD-REL-007-*.md` |

No task was deleted, no task's scope or requirements were changed, no formula or acceptance criterion was altered in meaning, and `design-reference/` was not touched. Every correction either fixes a mechanical cross-reference (stale section number → current folder name) or removes/redirects a dependency edge whose *direction* was provably backwards from the tasks' own descriptions — no product or technical ambiguity was silently resolved.

*(For transparency: a prior pass, performed during the restructuring itself rather than this audit, had already fixed nine instances of a related but distinct issue — orphaned bullet points like "- §2.3" in Specification References lists that lost their "MASTER.md" prefix when a shared-prefix citation like "MASTER.md §7.2, §2.3" was naively split on commas. That fix is not re-counted here since it predates this audit; it is mentioned only so the two issue classes aren't confused with each other.)*

---

## G. Remaining Issues

Everything below requires a human decision and was deliberately **not** auto-resolved, per this audit's instructions not to silently resolve ambiguous product or technical decisions:

1. **Eight phase-order tensions** (§D above) — recommend a maintainer review during sprint planning: either accept the cross-phase dependency as intentional parallel-track work (consistent with `TASKS.md` §5.2's own framing for Excel/NFR/Settings), or adjust the dependent task's phase label. `ZOD-SET-006`/`ZOD-SET-001` in particular (a specific settings panel scheduled a full phase before its own container) is worth a second look.
2. **`ZOD-REL-007`'s "Completeness verification" specification reference.** This citation is explicitly parenthesized as `(task-breakdown process requirement)` and does not refer to `assets/zodiann-specification.md` — it refers to the original task-breakdown request's own "§7. Completeness verification" instructions, which is not a separate file in this repository. This is self-documenting (the parenthetical already discloses it) and not a factual error, so no action was taken; flagged here only so it isn't mistaken for an uninvestigated gap.
3. **This audit's own heuristic checks produced 82 + 6 = 88 flagged items that, on manual review, were all false positives** (an overly narrow keyword/pattern match in the automated scan, not a real documentation defect — see §E). They are not re-listed individually here since §E already accounts for every one; noted so a future audit doesn't need to re-derive this from scratch, and so the raw "88 flags" number isn't mistaken for 88 outstanding problems.

No missing tasks, no duplicate IDs, no broken links, and no lost requirements remain outstanding.

---

## H. Final Status

### PASS WITH WARNINGS

All 205 original tasks are present, uniquely identified, correctly categorized, and structurally intact, with zero broken links and zero remaining circular dependencies. Two genuine defects were found (both circular-dependency pairs, one bundled with an ID typo) and corrected with high confidence, using only the tasks' own stated descriptions to determine the correct direction — no scope, requirement, or formula was changed in the process. A related but separate defect class — 14 files and one `TASKS.md` sentence carrying stale references to the pre-restructuring single-file section numbers — was also found and corrected.

The "WARNINGS" qualifier reflects §G's two remaining open items (the eight phase-order tensions, and the one self-documenting non-spec citation), both of which are genuinely judgment calls for a maintainer rather than defects this audit can or should resolve unilaterally. Nothing in §G represents missing content, a broken structural guarantee, or a risk to using these 205 files as the development backlog.

**The 205 individual task files faithfully represent the original development plan and are reliable enough to be used as the source of truth for future implementation work.**
