# ZOD-GAN-003 — Gann Date/Number Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Reviewed (plan-reviewer: 2 rounds; round-2 corrections applied and independently verified); approved and implemented 2026-11-12 (see PROGRESS.md) · **Branch:** `task/ZOD-GAN-003-date-number-mapping` · **Written:** 2026-11-12

**Goal:** Map a Square of Nine cell's spiral position `n` to the value it displays in each mode (number, calendar date, or date and time in fixed hour steps), find "today's" cell, and format dates as `d.m.yy` and times as `HH:MM`. The mapping follows the spec's "Dates" rules and the product owner's time-zone decision.

**Architecture:**
- Pure functions in `packages/gann_core/lib/src/dates/`:
  - Dates mode uses calendar arithmetic on the anchor's own calendar date, so DST and travel never shift it.
  - Date-and-time mode steps in absolute time and converts to the device's local wall clock through an **injected `LocalTimeZone`**.
  - "Now" is a parameter, not a clock read.
- Everything is deterministic and unit-testable regardless of the machine's zone or clock.

**Tech Stack:** Dart 3.14 (`DateTime`, which uses the device's zone database for `toLocal`). No new dependencies.

**Spec:**
- `docs/development/computation-engine/ZOD-GAN-003-implement-gann-date-number-mapping-per-mode.md` (amended 2026-11-12)
- `assets/zodiann-specification.md`: "Dates" (full section), SQ-2 … SQ-7, T-GAN-4, T-FMT-1, NFR-A3, DATA-4, R-4, and the line 74 planning constraint
- `design-reference/zodiann/MASTER.md` §8.2 ("Content" row) and `screens/02-square-of-nine_{dates,datetime}_*.png`

## Product-owner decisions (2026-11-12)

1. **Cycle resolution** (same as EPH-001 / GAN-001 / GAN-002). "T-GAN-4 passes" and "T-FMT-1 passes" were amended to "covered by GAN-003's own unit tests; dedicated T-GAN-4 / T-FMT-1 tracked by ZOD-TST-012 / ZOD-TST-013". The test tasks' notes carry the independence and mutation-proof rules.
2. **Time zone (resolves the spec's open question; NFR-A3's "one rule"):**
   - Date-and-time cells step in **absolute time** and are shown in the **device's current local time zone**. Across DST the displayed hour visibly jumps by one hour, documented and not "corrected".
   - **Today's cell** uses the device zone and the current moment.
   - **Dates mode** uses the anchor's own calendar date plus whole days.
   - The anchor's saved offset (DATA-4) preserves the exact anchor instant.

3. **`stepHours` has no upper cap** (from plan review round 1): GAN-003 requires only `≥ 1`, with overflow guarded. SET-004 decides the UI range later.
4. **Anchor field in date-and-time mode** (from plan review round 1; built in ZOD-SQR-002, no GAN-003 code): the field shows the anchor in the **device's zone**, so it always matches the center cell. Recorded in ZOD-SQR-002's notes.

## Global Constraints

- Pure Dart in `gann_core` (ARCH-2), no new dependencies. Follow `docs/PROGRESS.md` → Architecture Conventions (data model, spiral, highlights).
- **The rules**, exactly:
  - Numbers mode: `value(n) = n`.
  - Dates mode: `date(n) = anchor date + (n − 1)` calendar days, built as a local date (year, month, day + n − 1).
  - Date-and-time mode: `moment(n) = anchor instant + stepHours·(n − 1)` hours in absolute time. `stepHours` comes from `SquareConfig` (default 4; SET-004 makes it editable).
  - Today's cell, dates mode: calendar days from the anchor date to today's local date, + 1.
  - Today's cell, date-and-time mode: ⌊(now − anchor instant) / stepHours⌋ + 1.
- **`n` is the spiral position** (1 = center), matching the GAN-002 convention.
- **Formats:**
  - Date: `d.m.yy`, with no leading zero on day or month and a 2-digit year (`4.1.22`, `31.12.99`, `5.1.05`).
  - Time: `HH:MM`, 24-hour, zero-padded (`04:00`).
- Out of scope:
  - The anchor field, buttons, "Show up to today" and the size expansion (→ SQR-002/004).
  - The today border and tag (→ SQR-008/009).
  - Persisting the anchor (→ DAT-009).
  - The Excel export's time handling (spec line 256: "the file has no time zone" → XLS-*).
  - Localized weekday/month names (→ L10).
  - **Month-first order for English (L-12) and the app-wide date-format utility → ZOD-L10-010**, which wraps or extends `formatCellDate`. GAN-003's formatter is the day-first `d.m.yy` form required by SQ-3 / T-FMT-1 and used in Hebrew.
  - **The numbers-mode anchor** (EX-8/9, TASKS §6.2 numeric-anchor item) → ZOD-XLS-003. In the app, numbers mode has no anchor (D15, SQR-002), so `cellNumber(n) = n`.

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| Time-zone abstraction | `abstract interface class LocalTimeZone { int offsetMinutesAt(DateTime utc); }`. Implementations: `DeviceTimeZone` (const; offset of `DateTime.fromMicrosecondsSinceEpoch(utc.microsecondsSinceEpoch).timeZoneOffset`) and `FixedOffsetTimeZone(int offsetMinutes)`, which requires the offset within ±1080 (`OffsetDateTime.maxOffsetMinutes`), otherwise `ArgumentError` | The device zone is the decided rule. Injecting it makes DST behaviour testable with a fake zone. `FixedOffsetTimeZone` serves tests and future consumers |
| Calendar date carrier | A date is returned as a **UTC-flagged `DateTime` at 00:00** holding the calendar fields (`DateTime.utc(y, m, d)`), documented as date-only: "never call `toLocal()` on it; the fields are the calendar date". `formatCellDate` / `formatCellTime` **require `isUtc`** (`ArgumentError` otherwise) and read only the fields | No new type. `DateTime.utc` normalises month and leap-year overflow (Feb 29) without any zone involvement |
| Wall clock | `DateTime localWallClock(DateTime utcInstant, LocalTimeZone zone)` returns a UTC-flagged `DateTime` holding the local fields (instant + offset), like `OffsetDateTime.wallClock`. An out-of-range `add` → `ArgumentError` | One convention for "local fields" across `gann_core` |
| `stepHours` | **Required** named parameter `{required int stepHours}` (no default). Callers pass `config.stepHours`. **No upper cap** (product-owner decision 2026-11-12): only `≥ 1`, and the overflow guard rejects impossible values. SET-004 decides the UI's allowed range | A default of 4 would silently ignore a square's edited step (SET-004 / T-EX-3) |
| Overflow guard | `cellDate`: `n − 1 > 100000000` → `ArgumentError` (DateTime's whole range is ±100,000,000 days), then catch any remaining `ArgumentError`. `cellMoment` and `hoursAfterAnchor`: `n − 1 > 2400000000 ~/ stepHours` → `ArgumentError`, checked **before** multiplying, then catch `ArgumentError` / `RangeError`, and **reject a result earlier than the anchor** (int64 wrap for anchors near `DateTime`'s limits; the parser accepts 6-digit years). `nowCellInDateTimeMode` divides by hours before `stepHours`, so it never forms an overflowing product | `DateTime.utc(…, d + huge)` and `Duration(hours: huge)` wrap silently to wrong dates rather than throwing (verified in review) |
| "Now" | Passed in as `DateTime nowUtc` | Pure and deterministic; the UI supplies `DateTime.now().toUtc()` |
| Before the anchor | The today-cell functions return `null` when today or now is before the anchor | SQ-6 shows a message instead. `null` lets the UI do that, with no exception |
| Range | `n ≥ 1`, otherwise `ArgumentError`. A result outside `DateTime`'s range → `ArgumentError`. `stepHours ≥ 1`. All `DateTime` inputs must be UTC (`ArgumentError` otherwise) | Same validation conventions as FND-012 / GAN-001 |

### API (`packages/gann_core/lib/src/dates/`)

- `local_time_zone.dart`: `LocalTimeZone`, `DeviceTimeZone`, `FixedOffsetTimeZone`.
- `cell_values.dart`:
  - `int cellNumber(int n)` (numbers mode; = n)
  - `DateTime cellDate(OffsetDateTime anchor, int n)` (dates mode; date-only)
  - `DateTime cellMoment(OffsetDateTime anchor, int n, {required int stepHours})` (UTC instant)
  - `DateTime localWallClock(DateTime utcInstant, LocalTimeZone zone)`
  - `int? todayCellInDatesMode(OffsetDateTime anchor, DateTime nowUtc, LocalTimeZone zone)`
  - `int? nowCellInDateTimeMode(OffsetDateTime anchor, DateTime nowUtc, {required int stepHours})`
  - `int daysAfterAnchor(int n)` (= n − 1) and `int hoursAfterAnchor(int n, {required int stepHours})` (= stepHours·(n − 1), absolute hours, same overflow guard). This is the **SQ-18 "N days/hours after the anchor" distance** that ZOD-SQR-013 must match exactly (design: cell 52 → 204 hours, cell 139 → 138 days).
- `cell_format.dart`: `String formatCellDate(DateTime date)` (`d.m.yy`), `String formatCellTime(DateTime wallClock)` (`HH:MM`).

## Reference values

**Design reference** (`02-square-of-nine_datetime_desktop_he_dark.png`). Anchor `1.11.2026 00:00`; Israel in November is +02:00, with no DST in the window:

| n | moment (UTC) | local display |
|---|---|---|
| 1 | 2026-10-31T22:00Z | `1.11.26` / `00:00` |
| 2 | +4 h | `1.11.26` / `04:00` |
| 52 | +204 h | `9.11.26` / `12:00` (design: "204 hours after the anchor") |
| 169 | +672 h | `29.11.26` / `00:00` (bottom-left of 13×13) |

**DST** uses a fake zone mirroring Israel 2026: +02:00 until `2026-03-27T00:00Z`, +03:00 until `2026-10-24T23:00Z`, then +02:00.

- **Spring** (anchor `2026-03-26T20:00+02:00`): local times 20:00, 00:00, **05:00** (not 04:00: the documented jump), 09:00.
- **Autumn** (anchor `2026-10-24T20:00+03:00`): local times 20:00, 00:00, **03:00** (not 04:00), 07:00.

**Leap year:**
- Anchor `2024-02-27`: dates `27.2.24`, `28.2.24`, `29.2.24`, `1.3.24`.
- Anchor `2026-02-27`: n = 3 → `1.3.26`.

**Today's cell:**
- **Dates mode, DST fake zone, anchor `2026-03-25T00:00+02:00`.** `nowUtc = 2026-03-27T21:30Z` is local 00:30 on 28.3 → cell **4**. Taking the UTC date would give 3, so the zone matters.
- **Dates mode across Feb 29**, `FixedOffsetTimeZone(120)`:
  - anchor `2024-02-27T00:00+02:00`, `nowUtc = 2024-03-01T10:00Z` → **4** (leap year);
  - anchor `2026-02-27T00:00+02:00`, `nowUtc = 2026-03-01T10:00Z` → **3**.
- **Dates mode, design reference** (`02-square-of-nine_dates_desktop_en_dark.png`): anchor `2026-04-15T00:00+03:00`, `nowUtc = 2026-11-09T10:00Z`, `FixedOffsetTimeZone(120)` → **209** ("Today — Cell 209"). Also `cellDate(that anchor, 139)` → `31.8.26` ("138 days after the anchor").
- **Date-and-time mode, design anchor:**
  - now = anchor + 204 h → **52**;
  - now = anchor + 207 h 59 m → 52;
  - now = anchor + 208 h → 53;
  - now = anchor → 1;
  - now = anchor − 1 min, − 30 s or − 1 µs → `null`.
- **Travel** (anchor offset ≠ device zone):
  - Anchor `2026-11-01T00:00+02:00` shown in `FixedOffsetTimeZone(0)`: cell 1 = `31.10.26 22:00`, cell 2 = `1.11.26 02:00`.
  - Dates mode keeps the anchor's own date. Anchor `2026-03-25T00:30+03:00` in `FixedOffsetTimeZone(0)`:
    - cell 1 = 25.3;
    - today at `2026-03-25T12:00Z` → 1;
    - today at `2026-03-24T23:00Z` (local 24.3) → `null`.

## Review Focus

1. **DST:** dates mode must never shift a date. Date-and-time mode must show the documented one-hour jump in both directions, never a silently corrected time. Pinned by the spring and autumn DST tests.
2. **Leap years and month ends:** Feb 29 present in 2024 and absent in 2026, for both the dates and the today cell; month and year rollovers (31.12 → 1.1). Pinned by the leap-year tests.
3. **Today near local midnight and when travelling:**
   - The dates-mode today cell uses the **local** date, not the UTC date.
   - The anchor's date is always its own calendar date, never re-derived through the device zone.
   - The today cell always displays today's local date.

   Pinned by the 00:30, travel and invariant tests.
4. **Before the anchor and block boundaries:** `null` for anything before the anchor, including sub-minute gaps, which truncating to minutes would mishandle. Exact block boundaries (207 h 59 m vs 208 h), and `stepHours` honoured. Pinned in the today-cell tests.
5. **No silent overflow:** huge `n` or `stepHours` throw `ArgumentError` rather than wrapping to a wrong date. Pinned by the overflow test.
6. **Format edges:** single- and double-digit days and months, years 2000–2009 (`05`), and midnight `00:00`. Pinned by the format tests.

---

### Task 1: `LocalTimeZone` + date mapping + today's cell + distances (TDD)

**Files:** create `packages/gann_core/lib/src/dates/{local_time_zone,cell_values}.dart`; modify `packages/gann_core/lib/gann_core.dart`; test `packages/gann_core/test/dates/cell_values_test.dart`.

**Interfaces:** consumes `OffsetDateTime` (FND-012); produces the API above, minus formatting.

- [ ] **Step 1: Write the failing tests.** The file defines a test-only `_DstZone implements LocalTimeZone` with the Israel-2026-like transitions above.
  - `group('LocalTimeZone')`:
    - `'FixedOffsetTimeZone returns its offset; rejects offsets beyond ±1080'`;
    - `'DeviceTimeZone matches DateTime.toLocal for sample instants'` (self-consistent on any machine);
    - `'rejects non-UTC input'`: `FixedOffsetTimeZone(120).offsetMinutesAt(DateTime(2026))`, `const DeviceTimeZone().offsetMinutesAt(DateTime(2026))` and `localWallClock(DateTime(2026), FixedOffsetTimeZone(0))` → `throwsArgumentError`.
  - `group('numbers mode')`:
    - `'cellNumber(n) == n, rejects n < 1'`.
  - `group('dates mode')`:
    - `'the anchor cell is the anchor date'`;
    - `'design reference: cell 139 is 31.8.26'`;
    - `'consecutive calendar days, across a month and a year end'`: anchor `2026-12-30T00:00+02:00` → 30.12, 31.12, 1.1.2027;
    - `'leap year includes Feb 29; a common year does not'`;
    - `'is unaffected by DST'`: anchor `2026-03-25T00:00+02:00`, n = 1…5 → 25.3 … 29.3 with no gap or duplicate;
    - `'uses the anchor’s own calendar date, not UTC'`: anchor `2026-03-25T00:30+03:00` (UTC date 24.3) → cell 1 is 25.3;
    - `'rejects n < 1'`.
  - `group('date-and-time mode')`:
    - `'design reference: 1.11.2026 00:00 anchor'`: cells 1, 2, 52 and 169 using `FixedOffsetTimeZone(120)`;
    - `'spring DST: the displayed hour jumps forward by one'`;
    - `'autumn DST: the displayed hour jumps back by one'`;
    - `'travel: date-and-time cells show the anchor instant in the device zone'`: `FixedOffsetTimeZone(0)` → `31.10.26 22:00`, `1.11.26 02:00`;
    - `'honours stepHours'`: `stepHours: 6`, n = 2 → +6 h;
    - `'rejects stepHours < 1 and n < 1'`.
  - `group('distance from the anchor (SQ-18)')`:
    - `daysAfterAnchor(139) == 138`;
    - `hoursAfterAnchor(52, stepHours: 4) == 204`;
    - n = 1 → 0;
    - n < 1 and `hoursAfterAnchor(2, stepHours: 0)` rejected.
  - `group('overflow')`:
    - `'rejects results beyond DateTime's range (no silent overflow)'`: throws for `cellDate(anchor, 3000000000)`, `cellDate(anchor, 200000002)`, `cellMoment(anchor, 1000000001, stepHours: 4)`, `cellMoment(anchor, 1 << 31, stepHours: 1 << 30)` and `hoursAfterAnchor(1 << 31, stepHours: 1 << 30)`. Also, with the far anchor `OffsetDateTime.parse('+275000-01-01T00:00Z')`: `cellDate(farAnchor, 50000001)` and `cellMoment(farAnchor, 600000001, stepHours: 4)` throw `ArgumentError` (wrap detected).
  - `group('today’s cell')`:
    - `'dates mode uses the local date (00:30 local, UTC date one day earlier)'` → 4;
    - `'dates mode across Feb 29: leap year 4, common year 3'`;
    - `'dates mode design reference: cell 209'`;
    - `'dates mode: the anchor day is cell 1; before the anchor is null'`;
    - `'travel: dates mode and its today cell keep the anchor's own date'` (1, then `null`);
    - `'the dates-mode today cell displays today's local date'`: anchor `2026-03-25T00:00+02:00`, under `_DstZone`. For `nowUtc` = 2026-03-27T21:30Z, 2026-03-27T20:30Z and 2026-10-24T22:30Z, the expected today cells are **4, 3 and 215**. In each case `cellDate(anchor, todayCell)` equals the local date of `localWallClock(nowUtc, zone)`;
    - `'date-and-time mode: whole blocks elapsed + 1'`: 52, 52, 53, and `now == anchor` → 1;
    - `'date-and-time mode: before the anchor is null'`: −1 min, −30 s and −1 µs;
    - `'date-and-time mode honours stepHours'`: `stepHours: 6`, now = anchor + 12 h → 3;
    - `'date-and-time mode: huge stepHours does not overflow'`: design anchor, now = anchor + 204 h, `stepHours: 5124095576` → 1, and `stepHours: 1 << 62` → 1;
    - `'rejects non-UTC now and stepHours: 0'` (for `nowCellInDateTimeMode`).
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/dates`. Expected: compilation FAIL (undefined symbols).
- [ ] **Step 3: Implement.**
  - `cellDate`: `n − 1 > 100000000` → `ArgumentError`. Otherwise `final w = anchor.wallClock; DateTime.utc(w.year, w.month, w.day + n − 1)`, with a caught `ArgumentError` → `ArgumentError.value(n, 'n', 'date out of range')`.
  - `cellMoment` / `hoursAfterAnchor`: `n − 1 > 2400000000 ~/ stepHours` → `ArgumentError`, checked before multiplying. Then `anchor.instant.add(Duration(hours: stepHours * (n − 1)))`, catching `ArgumentError` (`RangeError` is a subclass).
  - Today's cell, dates mode: the local today is the date fields of `localWallClock(nowUtc, zone)`. The anchor date is **always** `anchor.wallClock`'s date, never derived through `zone`. Take the `inDays` difference between the two UTC-midnight dates, + 1; `null` if negative.
  - Today's cell, date-and-time mode: `null` if `nowUtc.isBefore(anchor.instant)`. Otherwise `nowUtc.difference(anchor.instant).inMicroseconds ~/ Duration.microsecondsPerHour ~/ stepHours + 1`.
    - **Divide by hours first, then by `stepHours`.** This equals ⌊Δ / (stepHours · 1 h)⌋ for positive integers and never forms the product `stepHours * microsecondsPerHour`, which overflows int64 for very large uncapped steps. (Verified: the product form gives −6702 for `stepHours` 5124095576 and a division-by-zero error for 2^62; hour-first gives 1.)
  - **Wrap check** (anchors near `DateTime`'s limits; the strict parser accepts 6-digit years):
    - In `cellDate`, if the result is before `DateTime.utc(w.year, w.month, w.day)`, throw `ArgumentError.value(n, 'n', 'date out of range')`.
    - In `cellMoment`, if `result.isBefore(anchor.instant)`, throw the same.
    - With the absolute caps, any int64 wrap lands before every anchor that can wrap. Verified: anchor `+275000-01-01` wraps to −172659 / −35764 and is detected.
  - **Doc comments** state the decided time-zone rule (device zone, absolute steps, visible DST jump; dates mode calendar-only), the SQ-18 distance meaning, and cite NFR-A3 and the GAN-003 notes.
- [ ] **Step 4:** Same command, then `fvm dart run melos run lint` and `fvm dart run melos run test`. Expected: all PASS / exit 0.
- [ ] **Step 5: Mutation proof.** Each change below must FAIL the suite; then restore:
  - (a) date-and-time mode uses wall-clock addition instead of absolute (`anchor.wallClock + hours`): the DST tests fail;
  - (b) dates mode uses `anchor.instant` (UTC date) instead of `anchor.wallClock`: the anchor-date test fails;
  - (c) today's cell (dates mode) uses the UTC date instead of the local one: the 00:30 test fails;
  - (d) the today-cell formula drops the `+ 1`;
  - (e) hard-code 4 in `nowCellInDateTimeMode`: the stepHours test fails;
  - (f) the dates-mode today cell derives the anchor date via `zone`: the travel test fails.

  Record the results in the commit message.
- [ ] **Step 6:** Commit `feat(ZOD-GAN-003): map cells to dates and moments; today's cell; device-zone rule`.

### Task 2: Cell formatting `d.m.yy` / `HH:MM` (TDD)

**Files:** create `packages/gann_core/lib/src/dates/cell_format.dart`; modify `gann_core.dart`; test `packages/gann_core/test/dates/cell_format_test.dart`.

- [ ] **Step 1: Write the failing tests.**
  - `formatCellDate` (literal expectations):
    - `DateTime.utc(2022, 1, 4)` → `4.1.22`;
    - `(2024, 1, 4)` → `4.1.24`;
    - `(1999, 12, 31)` → `31.12.99`;
    - `(2005, 1, 5)` → `5.1.05`;
    - `(2000, 1, 1)` → `1.1.00`;
    - `(2026, 11, 1)` → `1.11.26`;
    - `(2026, 10, 9)` → `9.10.26`.
  - `formatCellTime`: 00:00 → `00:00`; 04:00 → `04:00`; 12:05 → `12:05`; 23:59 → `23:59`.
  - `'formats the design reference cells'`: cells 2, 52 and 169 combine to `1.11.26 / 04:00`, `9.11.26 / 12:00`, `29.11.26 / 00:00`.
  - `'rejects non-UTC-flagged carriers'`: `formatCellDate(DateTime(2026))` and `formatCellTime(DateTime(2026))` → `throwsArgumentError`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/dates`. Expected: `cell_format_test.dart` fails to load (`formatCellDate` / `formatCellTime` undefined), `cell_values_test.dart` passes, and the exit code is non-zero.
- [ ] **Step 3: Implement.**
  - The date is `'${d.day}.${d.month}.${(d.year % 100).toString().padLeft(2, '0')}'`. The time pads hours and minutes to 2 digits. Both require `isUtc`.
  - The doc comments cite SQ-3 / SQ-4 / T-FMT-1 and MASTER.md §8.2.
  - They state that "two digits" applies to the **year** (2005 → `05`) and "no leading zero" to day and month, matching `yy` in MASTER §8.2/§13 and Excel's `d.m.yy` (EX-1).
  - They note that **English month-first order (L-12) is ZOD-L10-010**, which wraps this formatter.
- [ ] **Step 4:** Same command, then lint and the full test run. Expected: all PASS / exit 0.
- [ ] **Step 5: Mutation proof.** Each of these must FAIL: padding the day, padding the month, a 4-digit year, and an unpadded year (`5.1.5`). Restore afterwards and record the results.
- [ ] **Step 6:** Commit `feat(ZOD-GAN-003): format cell dates d.m.yy and times HH:MM`.

### Task 3: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch code review (`requesting-code-review`), then resolve any important findings. Re-run lint and test.
- [ ] **Step 2:**
  - Set `Status: Done` in the task file and `TASKS.md`, and tick the acceptance criteria. (The GAN-003, TST-012 and TST-013 notes are committed in the planning commits.)
  - Update `docs/PROGRESS.md`: the decided time-zone rule as a convention (NFR-A3), the decision rows, verification, and the next task.
  - **Propagate the time-zone decision:**
    - In `TASKS.md`, mark the §6.2 DST item and the §5.4 "ZOD-WHL-011, ZOD-GAN-003 | DST-hour-jump planning constraint" row as resolved (2026-11-12, see the GAN-003 notes). Also update the R-4 row in §6.4, which still points to "§6.2's DST open item", to reference the 2026-11-12 decision.
    - Add a 2026-11-12 note to ZOD-DAT-005 and ZOD-DAT-009: per the GAN-003 time-zone decision, "identical / same anchor moment" means the same instant and offset. In date-and-time mode, the cells re-display in the device's current zone after travel; dates mode is unchanged.
    - Add a note to ZOD-SET-002: its read-only time-zone row is NFR-A3's "shown to the user" part of the decided rule.
  - Update GAN-003's implementation-details line 20 to `stepHours·(n−1)` and "decided 2026-11-12 (see Notes)".
- [ ] **Step 3:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as amended 2026-11-12) | Proven by |
|---|---|
| Implemented and covered by own unit tests: anchor cell = anchor date; today's cell correct across a DST boundary and in a leap year; T-GAN-4 → TST-012 | Task 1: anchor-date tests, dates-mode DST test, today's cell at 00:30 local in the DST zone, **the leap-year today-cell test (4 vs 3)**, the design's today cell 209, the travel tests, block boundaries |
| Own unit tests: `d.m.yy`, no leading zero, single- and double-digit day/month; T-FMT-1 → TST-013 | Task 2 literal format tests plus mutation proof |
| A 4-hour date-and-time square crossing DST shows the documented one-hour jump, not a corrected time | Task 1 spring and autumn DST tests (05:00 and 03:00 where 04:00 would be "corrected"), mutation (a) |

## Risks

- **Real-device DST behaviour depends on the OS zone database** used by `DateTime.toLocal`. `DeviceTimeZone` is a thin wrapper, its self-consistency is tested here, and real-device checks belong to NFR/QA.
- **The Excel export has no time zone** (spec line 256). It may show a different hour than the app on DST days. That's documented in the spec and owned by the XLS tasks.

## Plan review

Automatic plan review (`zodiann-development` → `plan-reviewer`), two rounds. Both rounds independently re-derived:
- every reference value: design cells 1, 2, 52 and 169; dates-mode cell 139 and today cell 209; spring and autumn DST; leap-year sequences and today cells; block boundaries; travel;
- the overflow behaviour of `DateTime` and `Duration` on Dart 3.14.

**Round 1.** Verdict: *Needs user decision*.

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | No test for "today's cell … in a leap year" | **Applied:** leap-year today test (4 vs 3) and design today cell 209 / cell 139 |
| I2 | Important | Large `n` / `stepHours` wrapped silently to wrong dates | **Applied:** guards checked before multiplying, plus an overflow test |
| I3 | Important | Truncating to minutes returned cell 1 for `anchor − 30 s` | **Applied:** `isBefore` plus microseconds; −1 min / −30 s / −1 µs / equal tests; mutant (e) |
| I4 | Important | Travel (anchor offset ≠ device zone) not pinned | **Applied:** travel tests, "today cell shows today's local date" invariant, mutant (f) |
| I5 | Important | SQR-013 needs GAN-003's "N days/hours after the anchor" distance | **Applied:** `daysAfterAnchor` / `hoursAfterAnchor` (SQ-18) |
| I6 | Important | L-12 English month-first order: owner unstated | **Applied:** owned by L10-010 (Out of scope + doc comment) |
| I7 | Important | Time-zone decision not propagated to TASKS.md / DAT-005 / DAT-009 / SET-002 | **Applied:** in Task 3 close-out |
| M1–M8 | Minor | Explicit anchors; required `stepHours`; Task 2 RED expectation; unpadded-year mutant; "05" rationale; `isUtc` carrier; offset/overflow validation; numbers-mode anchor → XLS-003 | **Applied** |
| U1 | Needs user decision | `stepHours` upper cap | **Product owner:** no cap now (≥ 1, overflow guarded; SET-004 decides the UI range) |
| U2 | Needs user decision | Which zone the anchor field shows in date-and-time mode | **Product owner:** device zone (recorded in ZOD-SQR-002 Notes) |

**Round 2.** Verdict: *Approve after corrections*. All round-1 findings were confirmed resolved.

| ID | Severity | Finding | Action |
|---|---|---|---|
| I1 | Important | With uncapped `stepHours` (U1), the today-cell product `stepHours × µs/h` overflows (a negative cell, or division by zero) | **Applied:** divide by hours, then by `stepHours`; huge-`stepHours` test. **Independently verified by the orchestrator** (old form −6702 / `IntegerDivisionByZeroException`, new form 1) |
| I2 | Important | Absolute guards miss anchors near `DateTime`'s limits (6-digit years wrap silently) | **Applied:** reject a result earlier than the anchor; far-anchor tests. **Independently verified by the orchestrator** (`+275000` anchor wraps to −172659 / −35764, detected) |
| M1–M4 | Minor | Invariant test anchor and expected cells (4, 3, 215); which functions the non-UTC test covers; `stepHours: 0` rejection for every function; R-4 row in TASKS.md | **Applied** |

Round-2 Important corrections were applied exactly as the reviewer specified, and their effect was verified by the orchestrator in a scratch run. The workflow allows at most two review rounds, so they weren't sent for a third.

**Open items / needs user decision:** none.
