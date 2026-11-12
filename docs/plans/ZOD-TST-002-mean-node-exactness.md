# ZOD-TST-002 — T-EPH-2 Mean-Node Exactness Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: Approve, 2 rounds), awaiting approval · **Branch:** `task/ZOD-TST-002-mean-node-exactness` · **Written:** 2026-11-12

**Goal:** Independently verify ZOD-EPH-001's production mean-node formula (T-EPH-2). Check it against a separately implemented reference on a shared, versioned reference date set, prove it detects coefficient changes, and confirm the spec's ~0.01° accuracy bound against the full Meeus formula over ±100 years.

**Architecture:**
- **Test-only deliverable** in `packages/astro_core/test/`.
- **The reference date set** is a versioned JSON fixture of UTC instants. ZOD-TST-001 will reuse it.
- **The T-EPH-2 suite** imports **only** `meanAscendingNodeAt` from production (`show` clause). It computes expected values with its own Julian-Day algorithm, its own coefficients and its own normalization, so a transcription bug in production can't hide.
- **The bound check** compares production with the full Meeus formula, sampled daily over ±100 years.
- **Close-out:** the production doc comments that currently say "pending verification by ZOD-TST-002" are updated to the verified result.

**Tech Stack:** Dart 3.14, `package:test` (existing dev dependency). No new dependencies.

**Spec:**
- `docs/development/testing-qa/ZOD-TST-002-author-the-mean-node-formula-exactness-test-t-eph-2.md` (updated 2026-11-12)
- `assets/zodiann-specification.md` → "Planet position" (node formula, < 0.01° claim), T-EPH-2, ACC-1 (date-set shape)

## Product-owner decisions (2026-11-12)

1. **EPH-001 and TST-002 stay separate.** TST-002 depends on EPH-001, never the reverse. Expected values never come from production helpers or constants. The mutation proof alters each production coefficient. The bound is checked against full Meeus over ±100 years. (EPH-001 / TST-002 task Notes.)
2. **TST-002 defines the shared reference date set.** ZOD-TST-001 reuses it and may add instants, but not drop or change them. TST-001 is not a dependency. (TST-002 / TST-001 task Notes.)

## Global Constraints

- **Test-only.** The only production changes are doc-comment wording in Task 3. Pure Dart; the ARCH-2 guard stays green. Follow `docs/PROGRESS.md` → Architecture Conventions.
- **Independence:** the T-EPH-2 test file imports production as `import 'package:astro_core/astro_core.dart' show meanAscendingNodeAt;`. **No** use of `meanNodeEpochLongitude`, `meanNodeDegreesPerCentury`, `meanNodeSpeedDegreesPerDay` or `normalizeDegrees`. The reference coefficients are literals in the test file.
- **Reference time scale:** both the production formula and the reference compute `T` from the UTC instant, as the contract requires. The Meeus bound compares formulas at the same `T`. Meeus defines `T` in TT, but the ΔT effect (about 4e-5°) is far below the 0.01° bound, and it's documented in the test.
- Out of scope:
  - JPL Horizons data and other bodies (→ TST-001 / EPH-002).
  - The coefficient-literal architecture guard (→ EPH-002 planning, per PROGRESS).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Fixture location and format | `packages/astro_core/test/fixtures/reference_dates.json`: `{"version": 1, "description": "...", "dates": ["<ISO-8601 UTC, …Z>", …]}`. The version lives **in the content only**. TST-001 edits this same file, adds instants and increments `version`, so every consumer keeps one path | One path for every consumer. The `version` field records add-only revisions. A test pins the v1 instants so they can't be dropped or changed |
| Date set (53 instants, all UTC) | Start of every 5th year 1900…2100 at 00:00 (41) · year-end boundaries `YYYY-12-31T23:59:59Z` for 1950, 1999, 2000, 2024, 2099 (5) · J2000 `2000-01-01T12:00:00Z` · the ±100-year ends `1899-12-31T12:00:00Z` (T = −1) and `2100-01-01T12:00:00Z` (T = +1) · four mid-year instants `1912-06-30T06:00:00Z`, `1969-07-20T20:17:00Z`, `2026-11-12T00:00:00Z`, `2061-07-28T18:30:00Z` | ACC-1's shape: ≥ 50 dates, 1900–2100, near year boundaries. J2000 and T = ±1 pin the epoch and the bound's ends. Retrograde windows don't apply to the node; TST-001 adds them for the physical bodies |
| Independent JD | Meeus *Astronomical Algorithms* ch. 7, the Gregorian calendar-to-JD algorithm from the date fields (`Y`, `M`, `D` + day fraction) | A different method from production's microseconds-since-epoch, so an epoch or unit slip in either one shows up as a mismatch |
| Exactness tolerance | `1e-9°` | Floating-point differences between the two `T` methods are about 1e-11°. A last-digit change to either coefficient shifts Ω by ≥ 1e-6° at \|T\| ≈ 1 (≥ 1e-5° for the epoch constant) |
| Full Meeus formula | `Ω = 125.0445479 − 1934.1362891·T + 0.0020754·T² + T³/467441 − T⁴/60616000` (Meeus eq. 47.7) | The spec's "full formula". Pre-computed maximum deviation over ±100 years, sampled daily: **0.00213°** at T = −1 |
| Bound sampling | Every day from T = −1 to T = +1 (73,051 samples), plus every fixture instant | Dense enough that the maximum can't be missed. Runs in well under a second |

## File Structure

```
packages/astro_core/test/
  fixtures/reference_dates.json           shared reference date set (version 1: 53 UTC instants), reused by TST-001
  accuracy/reference_dates_test.dart      validates the fixture's shape
  accuracy/t_eph_2_mean_node_test.dart    T-EPH-2: independent reference + Meeus bound
packages/astro_core/lib/src/ephemeris/
  mean_node.dart, ephemeris_port.dart     doc wording only (Task 3)
```

## Review Focus

1. **Self-validation:** a test that derives its expectation from production code can't catch production bugs. The `show meanAscendingNodeAt` import and literal reference coefficients make reuse a compile error. Pinned in Task 1.
2. **A fixture that silently shrinks or drifts** (a dropped or edited shared instant, fewer than 50 dates, local-time or non-canonical strings, duplicates, instants outside T = ±1) would weaken T-EPH-2 and TST-001. Pinned by the Task 1 fixture-shape tests, including the v1-subset test.
3. **Coefficient changes slipping through:** the suite must fail when either production coefficient changes by one digit in the last place. Proven by mutation in Task 1.
4. **A wrong ±100-year sweep** (wrong T range, or comparing without angular wrap near 0°/360°) could falsely pass or fail the bound. Pinned in Task 2: wrapped differences, the T = ±1 endpoints asserted, and a mutation proof.
5. **Wording drift:** once verified, the docs must state the measured result. Before verification they must not claim it. Covered by Task 3.

---

### Task 1: Reference date set + T-EPH-2 exactness against an independent reference

**Files:** create `test/fixtures/reference_dates.json`, `test/accuracy/reference_dates_test.dart`, `test/accuracy/t_eph_2_mean_node_test.dart` (all in `packages/astro_core`).

**Interfaces:** consumes `meanAscendingNodeAt(DateTime) → EclipticPosition` (EPH-001) only.

Both test files carry a header comment: "Run from `packages/astro_core` (as `melos exec` / `melos run test` do). The fixture path is relative to the package."

- [ ] **Step 1: Write the fixture-shape test** (`group('reference_dates.json')`). It loads `File('test/fixtures/reference_dates.json')`, `jsonDecode`s it, and reads the dates as `(json['dates'] as List<dynamic>).cast<String>()`. Both test files do this, because `strict-casts` is enabled. It checks:
  - `'has an integer version ≥ 1'`.
  - `'contains every v1 shared instant unchanged'`: the test file holds `const _v1Instants` (the 53 strings from the decision table) and asserts `dates.toSet().containsAll(_v1Instants)`. A version bump keeps passing, but dropping or editing a v1 instant fails.
  - `'has at least 50 unique instants'`: `dates.length >= 50` and `dates.toSet().length == dates.length`.
  - `'every entry is a canonical UTC instant'`:
    - Each string matches `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.
    - Re-formatting the parsed value's fields to that pattern gives back the same string. This rejects impossible dates that `DateTime.parse` would silently normalize, such as Feb 30.
  - `'stays within the T = ±1 window'`: every instant is within [`1899-12-31T12:00:00Z`, `2100-01-01T12:00:00Z`].
  - `'is in strictly chronological order'`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=astro_core -- dart test test/accuracy/reference_dates_test.dart`. Expected: FAIL (the fixture file doesn't exist).
- [ ] **Step 3:** Create the fixture with `"version": 1` and exactly the 53 instants in the decision table, in chronological order. Add a `description` naming T-EPH-2 / ACC-1, ZOD-TST-002 as owner, and the TST-001 rule: edit this file, add-only, increment `version`.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5: Write the T-EPH-2 exactness test** (`t_eph_2_mean_node_test.dart`).
  - **File header** explains the independence rules.
  - **Imports:** `package:astro_core/astro_core.dart` `show meanAscendingNodeAt`.
  - **Private helpers in the test file:**
    - `double _julianDay(DateTime utc)`: Meeus ch. 7 from `year`/`month`/`day` + `(hour + minute/60 + second/3600 + millisecond/3.6e6)/24`.
    - `double _referenceOmega(DateTime utc)` with literals `125.04452` and `1934.136261`, and `T = (_julianDay(utc) − 2451545.0) / 36525`.
    - `double _norm360(double)`: its own normalizer.
    - `double _wrap180(double)`.
  - `group('T-EPH-2: mean node equals the spec formula')`:
    - `'reference JD helper is correct at known epochs'`: `_julianDay(2000-01-01T12Z) == 2451545.0`, `_julianDay(1899-12-31T12Z) == 2415020.0`, `_julianDay(2100-01-01T12Z) == 2488070.0`. This guards the reference itself.
    - `'matches the independent reference on every reference date'`: for each fixture instant, `_wrap180(production.longitude − _norm360(_referenceOmega(t))).abs() <= 1e-9`.
    - `'speed is the constant -1934.136261 / 36525 °/day on every reference date'`, comparing against the literal expression.
- [ ] **Step 6:** Run `fvm dart run melos exec --scope=astro_core -- dart test test/accuracy`. Expected: PASS (the production formula already exists).
- [ ] **Step 7: Mutation proof** (task AC 2). For each production coefficient in `lib/src/ephemeris/mean_node.dart`:
  1. Change `125.04452` → `125.04453`, run the Step 6 command, and expect **FAIL** in `'matches the independent reference…'`. Restore.
  2. Change `1934.136261` → `1934.136262`, run, and expect **FAIL**. Restore.

  Then confirm `git diff packages/astro_core/lib` is empty, and record the observed failures in the ledger and the PR.
- [ ] **Step 8:** Commit `test(ZOD-TST-002): add shared reference date set and T-EPH-2 exactness suite`.

### Task 2: Accuracy bound against the full Meeus formula over ±100 years

**Files:** modify `packages/astro_core/test/accuracy/t_eph_2_mean_node_test.dart`.

- [ ] **Step 1: Write the bound tests** (`group('T-EPH-2: accuracy bound vs full Meeus formula')`). Add `double _meeusOmega(double t)` (eq. 47.7, literals as in the decision table), with a comment that the comparison uses the same `T` as production and why ΔT is irrelevant at this bound.
  - `'deviates from the full formula by less than 0.01° over ±100 years (daily)'`: for `i` in −36525…36525, with `t = i / 36525` and `utc = DateTime.utc(2000, 1, 1, 12).add(Duration(days: i))`, compute `dev = _wrap180(production(utc).longitude − _norm360(_meeusOmega(t))).abs()`. Track the maximum, then assert `max < 0.01`, which is the spec bound. Also assert `max` is `closeTo(0.00213, 1e-5)`. That pins the figure written into the docs in Task 3 and proves it's a real comparison rather than production against itself.
  - `'the sweep reaches exactly T = −1 and T = +1'`: `_julianDay` of the first and last sweep instants gives `T == -1.0` and `T == 1.0`.
  - `'is within the bound on every reference date'`: the same check over the fixture.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=astro_core -- dart test test/accuracy`. Expected: PASS. The `closeTo(0.00213, 1e-5)` assertion pins the maximum.
- [ ] **Step 3: Bound mutation proof.** Change the production `1934.136261` → `1934.146261` (+0.01°/century). Run and expect **FAIL** of the daily-bound test: deviation ≈ 0.0121° at T = +1. Restore and confirm `git diff packages/astro_core/lib` is empty. Record it.
- [ ] **Step 4:** Commit `test(ZOD-TST-002): verify the 0.01° bound against the full Meeus formula`.

### Task 3: Record the verified result + close out

- [ ] **Step 1: Doc wording** (doc only; no behaviour change). Make exactly these three replacements:
  - (a) `mean_node.dart`, in `meanAscendingNodeAt`'s "Accuracy" paragraph: "This bound is pending independent verification by T-EPH-2 (ZOD-TST-002)." → "This bound is verified by T-EPH-2 (ZOD-TST-002): the maximum deviation from the full Meeus formula over ±100 years around 2000 (same `T`, sampled daily) is 0.0021°."
  - (b) `ephemeris_port.dart`, in the `meanAscendingNode` bullet: "…around 2000; this bound is pending independent verification by T-EPH-2 (ZOD-TST-002)." → "…around 2000; T-EPH-2 (ZOD-TST-002) verified a maximum deviation of 0.0021°."
  - (c) `ephemeris_port.dart`, at the end of the `meanAscendingNode` doc: "Independent verification of the formula and its accuracy bound: T-EPH-2 (ZOD-TST-002), pending." → "Independent verification of the formula and its accuracy bound: T-EPH-2 (ZOD-TST-002)."

  The "from" text spans several `///` lines in the source. Match it while ignoring line breaks and `///` prefixes. Re-wrap the new text to ≤ 80 columns in the existing `///` style, because `dart format` doesn't re-wrap comments.
- [ ] **Step 2:** Run `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: both exit 0.
- [ ] **Step 3:** Whole-branch code review (`requesting-code-review`), then resolve any important findings. Re-run Step 2 (`verification-before-completion`).
- [ ] **Step 4:**
  - Set `Status: Done` in the TST-002 task file and `TASKS.md`, and tick its acceptance criteria.
  - Commit the status and acceptance-criteria updates to the TST-002 task file and `TASKS.md`. (The TST-002 / TST-001 notes were already committed in `a975ff7`.)
  - Update `docs/PROGRESS.md`: completed task, verification, next task, the shared-fixture convention, and the Automatic Plan Review convention from PR #6.
- [ ] **Step 5:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (TST-002) | Proven by |
|---|---|
| Expected values come from a separately implemented reference; production helpers are never called for them | `show meanAscendingNodeAt` import; test-local `_julianDay` / `_referenceOmega` / `_norm360` with literal coefficients; JD helper self-check |
| Test fails if either production coefficient is altered, verified by temporarily altering each | Task 1 Step 7 mutation proof (both coefficients) |
| Passes within ~0.01° of the full Meeus formula over ±100 years | Task 2 daily sweep (max ≈ 0.00213°), endpoints at T = ±1, mutation proof that the bound can fail |

## Risks

- **TST-001 may want more instants.** It edits the same `reference_dates.json` (add-only) and increments `version`. A version bump keeps the path and passes the v1-subset test, while dropping or editing a v1 instant fails it.
- **Meeus defines T in TT.** It's documented. ΔT (about 64 s) shifts Ω by about 4e-5°, which is irrelevant at the 0.01° bound.

## Plan review

Automatic plan review (`zodiann-development` → `plan-reviewer`), two rounds.

**Round 1.** Verdict: *Approve after corrections*. It ran as a general-purpose fallback with the `plan-reviewer.md` instructions, because the agent type wasn't loaded yet in this session. The reviewer independently re-derived the 53 instants, the JD values, T = ±1, the 0.0021292° maximum, the 8.2e-12° method difference, and every mutation effect.

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | `reference_dates.v1.json` versioning conflicted with TST-001's add-only / version-bump rule, and nothing stopped shared instants being dropped or changed | **Applied:** single path `reference_dates.json` with the version in the content, plus a `'contains every v1 shared instant unchanged'` test |
| M1 | Minor | Doc replacement text in Task 3 wasn't verbatim | **Applied:** three exact replacements (a)–(c) |
| M2 | Minor | The 0.0021° figure for the docs wasn't pinned by a test | **Applied:** `closeTo(0.00213, 1e-5)` |
| M3 | Minor | Fixture shape checks looser than the design (any 1899 date; lenient `DateTime.parse`) | **Applied:** strict canonical regex with re-format equality, the T = ±1 window, chronological order |
| M4 | Minor | Bound-mutation wording imprecise | **Applied:** "≈ 0.0121° at T = +1" |
| M5 | Minor | Stale close-out step (notes already committed) | **Applied** |
| M6 | Minor | Working-directory-relative fixture path | **Applied:** header comment |

**Round 2.** Verdict: **Approve** (dedicated `plan-reviewer` agent). All round-1 findings were confirmed resolved, with no new Critical or Important issues.

| ID | Severity | Finding | Action |
|---|---|---|---|
| M1 | Minor | Task 3 "from" sentences span several `///` lines, so they need re-wrapping | **Applied:** matching and re-wrapping note added to Task 3 Step 1 |
| M2 | Minor | `strict-casts` requires an explicit cast of the decoded list | **Applied:** `(json['dates'] as List<dynamic>).cast<String>()` in Task 1 Step 1 |

**Open items / needs user decision:** none.
