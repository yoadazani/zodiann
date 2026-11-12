# ZOD-TST-013 — T-FMT-1 Date-Format Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: 2 rounds, Approve), approved and implemented 2026-11-12 (see PROGRESS.md) · **Branch:** `task/ZOD-TST-013-date-format-suite` (from `main` @ `718edf1`) · **Written:** 2026-11-12

**Goal:** Independently verify ZOD-GAN-003's cell date format (T-FMT-1). A date shows as `d.m.yy`:
- no leading zero on the day or month;
- a two-digit year;
- literal periods as separators.

The suite checks every day/month combination and proves it catches each plausible format deviation.

**Architecture:**
- **Test-only deliverable:** one suite, `packages/gann_core/test/accuracy/t_fmt_1_date_format_test.dart`, following the PROGRESS "Accuracy tests" convention. No production changes.
- **Two independent kinds of expectation:**
  1. **Literal strings** for spot checks, covering all four single/double-digit combinations, year edges and the design reference.
  2. **A structural parse-back** over the full grid. It never rebuilds the expected string the way production does. Instead, it splits the output on `.` and checks:
     - there are exactly three parts;
     - the parts are made only of digits;
     - the day and month have no leading `0`, and the year has exactly two characters;
     - the parsed numbers equal the input's day, month and `year % 100`.
- Production is imported with `show formatCellDate` only.

**Tech Stack:** Dart 3.14, `package:test` (existing dev dependency). No new dependencies.

**Spec:**
- `docs/development/testing-qa/ZOD-TST-013-author-the-date-format-test-t-fmt-1.md` (Notes dated 2026-11-12)
- `assets/zodiann-specification.md`: T-FMT-1 (line 662), L-12 (line 584), EX-1 (line 204)
- `design-reference/zodiann/MASTER.md` §8.2 (cell content `4.1.22`)
- ZOD-GAN-003 plan and `cell_format.dart` doc comment: "two digits" applies to the **year** (2005 → `05`); "no leading zero" applies to the day and month.

## Product-owner decisions already in force (2026-11-12)

1. **TST-013 owns the dedicated T-FMT-1 verification**, since GAN-003's criterion points here. Expected strings are literals, never produced by production helpers, and the suite needs a mutation proof (for example, a padded day or month must fail). Source: TST-013 Notes.
2. **Interpretation of "two digits only":** it means a two-digit year, with no leading zero on the day or month. This is settled in the approved and merged GAN-003 plan and doc comments, and it matches MASTER `yy` and Excel's `d.m.yy` (EX-1).

No new product decisions are needed.

## Global Constraints

- **Test-only.** No file under `lib/` changes. Pure Dart; the ARCH-2 guard stays green.
- **Independence:**
  - Import `package:gann_core/gann_core.dart` with `show formatCellDate`.
  - The full-grid check never formats an expected string with `'$d.$m.…'` or `padLeft`. It parses the output and compares numbers and character-level properties.
  - Calendar validity comes from a test-local `_daysInMonth`, built on a test-local `_isLeap` that uses the Gregorian 4/100/400 rule. These helpers are self-checked against literals.
- **Out of scope:**
  - `HH:MM`: covered by GAN-003's own tests, and T-FMT-1 is about the date.
  - English month-first order (L-12): ZOD-L10-010 wraps this formatter.
  - The Excel cell number format (XLS tasks).
  - Rejecting non-UTC input: covered by GAN-003's tests.

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Location | `packages/gann_core/test/accuracy/t_fmt_1_date_format_test.dart` | PROGRESS "Accuracy tests" convention |
| Full grid | Every valid (day 1–31, month 1–12) date in **2024** (leap year, 366 dates) and **2026** (common year, 365 dates). Invalid combinations are skipped using `_daysInMonth`, and the count is asserted (366 / 365), so nothing is skipped silently | The task requires parameterizing across day 1–31 × month 1–12. Feb 29 is included |
| Year range | The first day of every year from 1900 to 2100 (201 dates). The year part must have exactly 2 characters, be all digits, and parse to `year % 100` | Covers `00` (1900, 2000, 2100), `05` / `09` padding and `99` across the app's 1900–2100 range |
| Literal spot checks | Each verified against `main` @ `718edf1`; see the table below | Literal expectations per the task Notes. All four single/double combinations are present |
| Separator | Exactly two `.` characters. The output matches `^[0-9]+\.[0-9]+\.[0-9]+$` and contains no `/`, `-` or space | "The separator is a literal period" (task) |

**Literal spot checks** (input `DateTime.utc` → expected):

| Input | Expected | Why |
|---|---|---|
| 2024-01-04 | `4.1.24` | T-FMT-1 / criterion example (single day, single month) |
| 2024-11-14 | `14.11.24` | criterion example (double, double) |
| 2024-11-04 | `4.11.24` | single day, double month |
| 2024-01-14 | `14.1.24` | double day, single month (also catches swapped order: `1.14.24`) |
| 2022-01-04 | `4.1.22` | design reference, MASTER §8.2 |
| 2024-02-29 | `29.2.24` | leap day |
| 1999-12-31 | `31.12.99` | maximum day and month |
| 2000-01-01 | `1.1.00` | year `00` |
| 2005-01-05 | `5.1.05` | year padded, day and month not |
| 2009-09-09 | `9.9.09` | all single digits; only the year is padded |
| 2010-10-10 | `10.10.10` | all double digits |
| 2026-08-31 | `31.8.26` | design reference cell 139 (GAN-003) |
| 2026-10-01 | `1.10.26` | day 1, month 10 |
| 2100-03-01 | `1.3.00` | top of range |
| 1900-01-01 | `1.1.00` | bottom of range |

## File Structure

```
packages/gann_core/test/accuracy/
  t_fmt_1_date_format_test.dart    T-FMT-1: literal spot checks, full day×month grid, year range
```

## Review Focus

1. **A self-confirming expectation:** building the expected string as `'${d}.${m}.${yy}'` would copy the implementation, including its bugs. The grid therefore uses parse-back, and the spot checks use literals. (Task 1.)
2. **Swapped order (`m.d.yy`):** this is L-12's confusion risk. Every combination where the day and month are both ≤ 12 swaps invisibly, except through checks against the actual values. `14.1.24` and the parse-back (day part = day) catch it. (Task 1, mutant F5.)
3. **Year edges:** `00`, `05` / `09`, and a 4-digit or unpadded year. (Task 1, year range.)
4. **Silently skipped grid cells:** a validity filter that is too strict would test fewer dates. The 366 / 365 counts pin it. (Task 1.)
5. **A wrong separator** (`/`, `-`), caught by the regex and the literals. (Task 1, mutant F6.)
6. **Reading the wall-clock carrier through the machine's zone** (`toLocal()`): this shows the wrong date on users' devices. The grid checks both ends of the day. (Task 1, mutant F8.)

## Tasks

TDD note: production already exists, so the suite is expected to pass on its first run. The RED evidence is the mutation proof: each mutant must turn the suite red.

### Task 1: T-FMT-1 suite and mutation proof

**Files:** create `packages/gann_core/test/accuracy/t_fmt_1_date_format_test.dart`.

**Interfaces:** consumes GAN-003's `String formatCellDate(DateTime date)`. It takes a UTC-flagged carrier, so every input in this suite is `DateTime.utc(...)`.

- [ ] **Step 1: Write the suite.**
  - **Header comment:** state the independence rules (`show` list; literals plus parse-back; no expected string built the way production builds it) and the interpretation of "two digits only".
  - **Helpers:**
    - `_isLeap` and `_daysInMonth`, self-checked against literals: `_daysInMonth(2024, 2) == 29`, `(2026, 2) == 28`, `(2100, 2) == 28`, `(2000, 2) == 29`, `(2026, 4) == 30`, `(2026, 12) == 31`.
    - `_checkShape(DateTime input, String out)`, which returns a list of problems. It checks:
      - the regex `^[0-9]+\.[0-9]+\.[0-9]+$`;
      - exactly 3 parts after splitting on `.`;
      - the day and month parts don't start with `0`, and the year part has exactly 2 characters;
      - `int.parse` of the parts equals `(input.day, input.month, input.year % 100)`.
  - **Groups:**
    - `'oracle self-check'`.
    - `'literal spot checks'`: the 15 rows above, one test per row, named from the table's literal ISO date, for example `'2024-01-04 → 4.1.24'` (never derived from a `DateTime` formatter).
    - `'every day and month combination'`: one test per year (2024, 2026). Loop month 1–12 and day 1–31, skipping days greater than `_daysInMonth`.
      - Check each date twice, at `DateTime.utc(y, m, d)` and at `DateTime.utc(y, m, d, 23, 59, 59, 999)`. This catches any conversion through the machine's zone, east or west of UTC.
      - Also assert `input.day == d && input.month == m`, and compare the parsed parts against the loop variables `d`, `m` and `y % 100`, so the check doesn't depend on `DateTime` normalisation.
      - Assert that the problem list is empty, and assert the count per time of day: 366 for 2024, 365 for 2026.
    - `'two-digit year across 1900–2100'`: `DateTime.utc(y, 1, 1)` for y = 1900…2100. Assert that `_checkShape` is clean, that the year part has length 2 and equals `(y % 100)` as a number, and that 201 years were checked.
- [ ] **Step 2: Run the suite.**
  - Run `fvm dart run melos exec --scope=gann_core -- dart test test/accuracy`.
  - Expected: all tests pass (T-GAN-4's 28 tests plus the new ones).
  - If a test fails, re-derive the value by hand from the format rule.
    - If the test is wrong, fix it and record a ruling.
    - If production is wrong, stop and report it to the user as a GAN-003 defect. Never edit `lib/`, and never change an expectation to match production.
- [ ] **Step 3: Run the gates:** `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: exit 0.
- [ ] **Step 4: Mutation proof.**
  - Before mutating, copy `packages/gann_core/lib/src/dates/cell_format.dart` to the session scratch directory.
  - Apply each mutant, then run the Step 2 command.
  - Confirm **test failures, not compile errors**.
  - Copy the file back, then confirm that `git diff --exit-code -- packages/gann_core/lib` exits 0.
  - Record the failing-test counts.

  | # | Mutant in `formatCellDate` | Must fail |
  |---|---|---|
  | F1 | padded day: `date.day.toString().padLeft(2, '0')` | `4.1.24` and other single-day literals; grid |
  | F2 | padded month | `4.1.24`, `14.1.24`; grid |
  | F3 | 4-digit year: `date.year` instead of `yy` | every literal; grid; year range |
  | F4 | unpadded year: drop `.padLeft(2, '0')` on `yy` | `1.1.00` (1900, 2000), `1.3.00`, `5.1.05`, `9.9.09`; year range (21 years). The grid does not catch it (2024 / 2026), as expected |
  | F5 | swapped order: `'${date.month}.${date.day}.$yy'` | `14.1.24`, `4.11.24`; grid parse-back |
  | F6 | separator `/` | every literal; regex |
  | F7 | year from the wrong digits: `(date.year ~/ 100).toString().padLeft(2, '0')` (century) | every literal; grid; year range (all but 1919 and 2020) |
  | F8 | reads the date through the machine zone: `final d = date.toLocal();`, then formats `d` | grid at 23:59:59.999 (machine east of UTC) or at 00:00 (west of UTC). Equivalent only on a UTC machine; record the machine offset with the result |

  Expected failing tests (one test per literal, two grid tests, one year-range test): F1 −12, F2 −13, F3 −18, F4 −6, F5 −13, F6 −18, F7 −18, F8 −2 (on this +02:00 machine).

- [ ] **Step 5: Commit** `test(ZOD-TST-013): T-FMT-1 date-format suite; mutation proof F1–F8`, with the mutant results in the body.

### Task 2: Close out (zodiann-development workflow)

- [ ] **Step 1: Code review.** Run a whole-branch review (`requesting-code-review`, a fresh reviewer on the most capable model). Re-grade the findings, then fix the important ones test-first.
- [ ] **Step 2: Documentation.**
  - In the TST-013 task file, set `Status: Done` and tick the criterion.
  - Set the `TASKS.md` row to Done.
  - Update `docs/PROGRESS.md`: completed row, verification table, and Current / Next task.
- [ ] **Step 3: Publish.** Commit, push and open a PR, then record the PR link (`docs(ZOD-TST-013): record PR link`).

## Acceptance Criteria → Evidence

| Criterion | Evidence |
|---|---|
| Both single-digit and double-digit day/month combinations are tested (e.g., `4.1.24` and `14.11.24`) | All four combination literals (`4.1.24`, `14.11.24`, `4.11.24`, `14.1.24`); the full 2024 / 2026 grid with counts; mutants F1, F2, F5 |
| (T-FMT-1) day.month.year, two-digit year, no leading zero; any deviation is caught | Literals including `1.1.00`, `5.1.05`, `9.9.09`; the year range 1900–2100; separator regex; mutants F3, F4, F6, F7, F8 |

## Risks

- **Parse-back shares `int.parse` and `split` with nothing in production.** It is independent by construction, and the literals pin it.
- **Scope creep into L-12 (month-first):** excluded explicitly. ZOD-L10-010 owns it.

## Plan review

**Round 1: Approve after corrections.** The reviewer re-ran F1–F7 against the plan's oracle in a scratch script, and each one was caught.
- **I1 (Important), applied.** Every input was at 00:00 UTC, so a formatter that reads the date through the machine's zone (`toLocal()`) passed on a +02:00 machine. Fix: the grid now checks each date at 00:00 and at 23:59:59.999 UTC, mutant F8 is added, and Review Focus gains item 6.
- **Minors M1–M6, applied:**
  - accurate wording for the F7 and F4 rows;
  - one grid test per year, plus the expected failing counts;
  - the grid compares against the loop variables (independent of `DateTime` normalisation);
  - test names come from the literal ISO dates;
  - the year-range count is asserted.

**Round 2: Approve.** The reviewer re-derived all eight expected mutant counts exactly, including F8 −2 on this +02:00 machine. It confirmed that the 23:59:59.999 check is correct on production for any machine zone, and that F8 is caught on any machine that isn't on UTC. No open items and no user decisions.

