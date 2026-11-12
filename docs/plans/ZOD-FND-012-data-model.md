# ZOD-FND-012 — Core Data Model Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-FND-012-data-model` · **Written:** 2026-11-12

**Goal:** Implement the spec's immutable data classes for the Square of Nine and degree crossings, with strict hand-written JSON, as the shared contract between computation, storage and UI.

**Architecture:**
- **Square types** go in `packages/gann_core`: `SquareMode` / `SpiralStart` / `SpiralRotation`, `OffsetDateTime`, sealed `HighlightMatch`, `HighlightRule` plus the default rules, and `SquareConfig`.
- **`Crossing`** and **`Body` JSON** go in `packages/astro_core`. No new dependency between the two packages is needed.
- **Validation.** Every class validates its invariants in its constructor (`ArgumentError`). Every `fromJson` is strict and turns *any* invalid input into a `FormatException`, so storage and backup import (DATA-1/3) get one clear failure type.
- **JSON and equality are hand-written**, with no codegen and no new dependencies.

**Tech Stack:** Dart 3.14 (sealed classes, enhanced enums, pattern matching). No new dependencies.

**Spec:**
- `docs/development/foundations-architecture/ZOD-FND-012-define-usersettings-squareconfig-highlightrule-crossing-dart-data.md` (updated 2026-11-12)
- `assets/zodiann-specification.md`: "Data model and user settings" (code block), "Default highlight rules", DATA-1…4, SQ-8, SQ-10, SQ-11
- `design-reference/zodiann/MASTER.md` §2.2: the highlight color-token names

## Product-owner decisions (2026-11-12)

1. **`UserSettings` is deferred to ZOD-SET-007.** The first acceptance criterion was amended, and the SET-007 task file now starts by defining it.
2. **The anchor is an `OffsetDateTime`** (UTC instant + offset minutes, ISO-8601 with offset in JSON), not a bare `DateTime`. This satisfies DATA-4. ZOD-DAT-009 persists it and verifies DST and zone changes, and its task file was updated.

## Global Constraints

- Pure Dart (ARCH-2). The ARCH-2 guard must stay green. Follow `docs/PROGRESS.md` → Architecture Conventions.
- No new dependencies. `gann_core` and `astro_core` stay independent of each other.
- Field names, types and enum values exactly as the spec's code block, except `anchor`'s type (decision 2).
- Colors are **token names, never hex**. The defaults use the MASTER.md §2.2 role families `axis`, `diag` and `eighth`.
- Lists held by the model are unmodifiable copies.
- Out of scope:
  - `UserSettings` (→ SET-007).
  - Storage, drift and shared_preferences (→ FND-006, DAT-*).
  - The backup file format and its version field (→ DAT-008).
  - Spiral, highlight and date math (→ GAN-001/002/003).
  - Labels' translations (→ L10).

## Design decisions (mine, for your confirmation)

| Topic | Decision | Reason |
|---|---|---|
| JSON + equality | Hand-written. No `json_serializable` / `freezed` / `equatable` | About 7 small types. Avoids build_runner and new dependencies (convention: no unnecessary dependencies) |
| JSON shape | camelCase keys = field names. Enums as their `name`. `DateTime` as ISO-8601 UTC (`…Z`). `OffsetDateTime` as ISO-8601 with offset. `HighlightMatch` with a discriminator `"type": "angles" \| "multipleOf"` | Readable backup files (DATA-3) and stable keys (L-9) |
| Invalid JSON | `fromJson` throws `FormatException` for missing or mistyped fields, unknown enum or `type` values, and constructor-invariant violations (`ArgumentError` re-thrown as `FormatException`) | One failure type for storage and import. Never a half-built object or a stray `TypeError` |
| Number decoding | Accept any JSON `num` for doubles (`(x as num).toDouble()`) | `jsonEncode(0.0)` writes `0.0`, but other producers (backups, hand-edited files) write `0`, which decodes as `int` |
| `Crossing` JSON | **None.** Its "not persisted" status is enforced by an architecture test | The task's "`fromJson`/`toJson` for every class" states its purpose as "used by DATA-1 storage and DATA-3 backup", and the spec marks `Crossing` "Saved? No". Giving it JSON would only invite persistence. The degree-table export (XLS-013) writes xlsx/csv, not JSON |
| `Body` JSON | `String toJson() => name` and `static Body fromJson(Object? json)` on the enum | Promised to FND-012 by FND-002. Used by SET-007's visible bodies |
| Default rule `label` | The stable key (`'axes'`, `'diagonals'`, `'eighths'`), equal to `id` | L-9: the UI translates by key. Free-text labels are only for future user rules (EXT-008) |
| `SquareConfig` defaults | `highlights` = `defaultHighlightRules`, `spiralStart` = `left`, `spiralRotation` = `cw`, `stepHours` = `4` | AC 3, SQ-8 ("2 to its left, … clockwise"), and the spec's comment `// 4 in date and time mode` |
| `SquareConfig` invariants | `size` odd and in 3…61. `anchor == null` ⇔ `mode == numbers`. `stepHours ≥ 1`. `id` and `name` non-empty. `createdAt` / `updatedAt` UTC and `updatedAt ≥ createdAt`. Highlight ids unique | Spec comments (`odd, between 3 and 61`, `null in numbers mode`). `stepHours` is editable per SET-004, so it's only required to be positive |
| `OffsetDateTime` | `OffsetDateTime(DateTime instant, int offsetMinutes)`: `instant` UTC, offset in −1080…+1080 (±18 h, the ISO limit). `parse` requires an explicit offset (`Z` or `±HH:MM`). Getter `wallClock` returns the local wall-clock fields as a UTC-flagged `DateTime` | DATA-4. GAN-003 needs the wall-clock date. Half-hour and 45-minute zones (+05:30, +05:45) must work |

## File Structure

```
packages/gann_core/lib/
  gann_core.dart                               exports the model files
  src/model/
    square_enums.dart                          SquareMode, SpiralStart, SpiralRotation (+ json helpers)
    offset_date_time.dart                      OffsetDateTime
    highlight_match.dart                       sealed HighlightMatch, AnglesMatch, MultipleOfMatch
    highlight_rule.dart                        HighlightRule + defaultHighlightRules
    square_config.dart                         SquareConfig
    json_read.dart                             internal helpers: typed field readers that throw FormatException
packages/gann_core/test/model/
  offset_date_time_test.dart  highlight_match_test.dart  highlight_rule_test.dart  square_config_test.dart
packages/astro_core/lib/src/
  ephemeris/body.dart                          + toJson / fromJson
  crossing.dart                                Crossing (no JSON)
packages/astro_core/test/
  ephemeris/body_test.dart                     + JSON tests
  crossing_test.dart
test/architecture/crossing_not_persisted_test.dart   root guard (AC 2)
```

`json_read.dart` stays internal: it isn't exported, it lives in `lib/src`, and the public classes use it.

## Review Focus

1. **Malformed or tampered JSON** (corrupted storage, a hand-edited backup): missing keys, wrong types, `null`s, unknown enum names (for example a future `"sidereal"`), and an unknown match `type` must all raise `FormatException`, never a `TypeError` and never a partially valid object. Pinned in Tasks 1–3 (`fromJson` rejection tests).
2. **Integer-valued doubles in JSON** (`0` instead of `0.0`, `22` instead of `22.0`) must decode. Pinned in Task 2.
3. **Anchor offsets** must round-trip exactly, including half- and quarter-hour zones (`+05:30`, `+05:45`), negative offsets (`-03:30`) and `Z`. A string with no offset must be rejected rather than guessed. Pinned in Task 1.
4. **`SquareConfig` invariants:** an even size, sizes 1 and 63, an anchor in numbers mode, or a missing anchor in dates mode must be rejected, and 3 and 61 accepted. Pinned in Task 3.
5. **Aliasing:** mutating a list passed to a constructor afterwards must not change the object, and lists read from the object must be unmodifiable. Pinned in Tasks 2–3.

---

### Task 1: `OffsetDateTime` and JSON helpers (gann_core, TDD)

**Files:** Create `gann_core/lib/src/model/{offset_date_time,json_read}.dart`; modify `gann_core/lib/gann_core.dart`; test `gann_core/test/model/offset_date_time_test.dart`.

**Interfaces (produced):**
- `final class OffsetDateTime { OffsetDateTime(DateTime instant, int offsetMinutes); final DateTime instant; final int offsetMinutes; DateTime get wallClock; String toIso8601String(); static OffsetDateTime parse(String input); }`
  - The constructor throws `ArgumentError` if `!instant.isUtc` or the offset is outside ±1080.
  - `parse` throws `FormatException` on anything without an explicit `Z` / `±HH:MM` offset.
  - Value equality is on `(instant, offsetMinutes)`. The same instant with a different offset is **not** equal.
  - `toIso8601String()` prints wall-clock time plus the offset, e.g. `2026-11-12T09:00:00.000+02:00`, or `Z` for offset 0.
- `json_read.dart` (internal): `T readField<T>(Map<String, Object?> json, String key)`, `double readDouble(Map json, String key)` (accepts any `num`), `E readEnum<E extends Enum>(Map json, String key, List<E> values)`, `DateTime readUtc(Map json, String key)`. All throw `FormatException` naming the key.

- [ ] **Step 1: Write the failing tests** (`group('OffsetDateTime')`)
  - `'round-trips through ISO-8601 with its offset'` for `+02:00`, `+05:30`, `+05:45`, `-03:30` and `Z`: `OffsetDateTime.parse(x.toIso8601String()) == x`.
  - `'keeps the wall-clock time of the offset'`: `parse('2026-03-27T01:00:00+02:00')` gives `instant == DateTime.utc(2026, 3, 26, 23)` and `wallClock == DateTime.utc(2026, 3, 27, 1)`.
  - `'same instant, different offset, is not equal'`.
  - `'rejects a string without an explicit offset'`: `parse('2026-11-12T09:00:00')` → `throwsFormatException`.
  - `'rejects garbage'`: `parse('tomorrow')` → `throwsFormatException`.
  - `'rejects non-UTC instants and out-of-range offsets'`: `OffsetDateTime(DateTime(2026), 0)` and `OffsetDateTime(utc, 1081)` → `throwsArgumentError`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/model/offset_date_time_test.dart`. Expected: compilation FAIL.
- [ ] **Step 3:** Implement per Interfaces. `parse` uses a strict regex for the offset suffix and delegates the date-time part to `DateTime.parse` on the UTC-normalized form.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat(ZOD-FND-012): add OffsetDateTime anchor type`.

### Task 2: `HighlightMatch`, `HighlightRule` and the default rules (gann_core, TDD)

**Files:** Create `gann_core/lib/src/model/{highlight_match,highlight_rule}.dart`; modify `gann_core.dart`; test `gann_core/test/model/{highlight_match,highlight_rule}_test.dart`.

**Interfaces (produced):**
- `sealed class HighlightMatch { Map<String, Object?> toJson(); static HighlightMatch fromJson(Object? json); }`
- `final class AnglesMatch extends HighlightMatch { AnglesMatch(List<double> degrees); final List<double> degrees; }`: the list is non-empty, each value finite and in [0, 360); it's stored as an unmodifiable copy. JSON: `{"type":"angles","degrees":[…]}`.
- `final class MultipleOfMatch extends HighlightMatch { MultipleOfMatch(double degrees); final double degrees; }`: finite and > 0. JSON: `{"type":"multipleOf","degrees":22.5}`.
- `final class HighlightRule { HighlightRule({required String id, required String label, required HighlightMatch match, required String colorToken, required int priority}); toJson(); static HighlightRule fromJson(Object? json); }`: `id`, `label` and `colorToken` are non-empty. Value equality includes the match.
- `final List<HighlightRule> defaultHighlightRules`, unmodifiable, in priority order:
  1. `HighlightRule(id: 'axes', label: 'axes', match: AnglesMatch([0, 90, 180, 270]), colorToken: 'axis', priority: 1)`
  2. `HighlightRule(id: 'diagonals', label: 'diagonals', match: AnglesMatch([45, 135, 225, 315]), colorToken: 'diag', priority: 2)`
  3. `HighlightRule(id: 'eighths', label: 'eighths', match: MultipleOfMatch(22.5), colorToken: 'eighth', priority: 3)`

- [ ] **Step 1: Write the failing tests**
  - Match: JSON round-trip for both kinds; `'decodes integer-valued degrees'` (`{"type":"angles","degrees":[0,90]}` and `{"type":"multipleOf","degrees":22}`); rejects an unknown `type`, a missing `degrees`, an empty angle list, 360, a negative value, NaN, and a multipleOf of 0 (ArgumentError from the constructor, FormatException from `fromJson`); `'copies and freezes its list'` (mutating the source list leaves `degrees` unchanged, and `degrees.add` throws `UnsupportedError`).
  - Rule: JSON round-trip; rejects empty `id`/`label`/`colorToken`; a non-int `priority` in JSON → `FormatException`; value equality.
  - Defaults: `'are Axes, Diagonals, Eighths in priority order 1, 2, 3 with the spec angles and token colors'`, asserting every field above; `'colors are token names, not hex'` (no `colorToken` starts with `#`); the list is unmodifiable.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/model`. Expected: compilation FAIL for the new types.
- [ ] **Step 3:** Implement per Interfaces, using `json_read.dart`. `fromJson` wraps constructor `ArgumentError`s as `FormatException`.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat(ZOD-FND-012): add highlight rules and the default rule set`.

### Task 3: Square enums and `SquareConfig` (gann_core, TDD)

**Files:** Create `gann_core/lib/src/model/{square_enums,square_config}.dart`; modify `gann_core.dart`; test `gann_core/test/model/square_config_test.dart`.

**Interfaces (produced):**
- `enum SquareMode { numbers, dates, datetime }`, `enum SpiralStart { left, right, up, down }`, `enum SpiralRotation { cw, ccw }`. JSON uses `name`.
- `final class SquareConfig`:
  - `SquareConfig({required String id, required String name, required SquareMode mode, OffsetDateTime? anchor, int stepHours = 4, required int size, SpiralStart spiralStart = SpiralStart.left, SpiralRotation spiralRotation = SpiralRotation.cw, List<HighlightRule>? highlights, required DateTime createdAt, required DateTime updatedAt})`. A `null` `highlights` means `defaultHighlightRules`.
  - The invariants are as in the decision table.
  - `toJson()` and `static SquareConfig fromJson(Object? json)`. Value equality covers every field.

- [ ] **Step 1: Write the failing tests**
  - `'a new SquareConfig gets the three default highlight rules in priority order'` (AC 3).
  - `'defaults to spiral left + clockwise and a 4-hour step'` (SQ-8).
  - `'round-trips through JSON without data loss'` for each mode. The dates mode uses an anchor at `+05:30`, the datetime mode one at `-03:30`, and one config has custom highlights. Assert `fromJson(jsonDecode(jsonEncode(c.toJson()))) == c`, and that `anchor.offsetMinutes` survives (AC 1).
  - Size: accepts 3 and 61; rejects 1, 63, an even 10, and 0.
  - Anchor vs mode: rejects numbers mode with an anchor, and dates or datetime mode without one.
  - Rejects `stepHours: 0`, an empty `id` or `name`, non-UTC `createdAt`, `updatedAt` before `createdAt`, and duplicate highlight ids.
  - `fromJson` rejects an unknown `mode` (`"sidereal"`), a missing `size`, a string `size`, and an anchor without an offset, all with `FormatException`.
  - `'copies and freezes its highlights list'`.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=gann_core -- dart test test/model`. Expected: compilation FAIL for the new types.
- [ ] **Step 3:** Implement per Interfaces.
- [ ] **Step 4:** Same command. Expected: PASS.
- [ ] **Step 5:** Commit `feat(ZOD-FND-012): add square enums and SquareConfig`.

### Task 4: `Body` JSON, `Crossing`, and the not-persisted guard (astro_core + root, TDD)

**Files:**
- Modify `astro_core/lib/src/ephemeris/body.dart` and `astro_core/lib/astro_core.dart`.
- Create `astro_core/lib/src/crossing.dart`.
- Tests: `astro_core/test/ephemeris/body_test.dart`, `astro_core/test/crossing_test.dart`, `test/architecture/crossing_not_persisted_test.dart`.

**Interfaces (produced):**
- On `Body`: `String toJson() => name;` and `static Body fromJson(Object? json)`, which throws `FormatException` for a non-string or unknown name.
- `final class Crossing { Crossing({required DateTime timeUtc, required Body body, required int degree, required bool retrograde}); }`
  - It throws `ArgumentError` if `!timeUtc.isUtc` or `degree` is outside 0…359.
  - Value equality and `toString`. **No `toJson`/`fromJson`**: the doc comment states it's derived and never persisted (DATA-2).
- Root guard: no `.dart` file under `packages/shared_storage/lib` or `apps/astro_mobile/lib` (the storage layers) refers to the identifier `Crossing`. It uses the `\bCrossing\b` regex and skips directories that don't exist yet.

- [ ] **Step 1: Write the failing tests**
  - Body: `'round-trips every value through JSON'`; `'rejects unknown names and non-strings'` (`'chiron'`, `3`, `null` → `FormatException`).
  - Crossing: accepts degrees 0 and 359; rejects 360, −1 and non-UTC; has value equality.
  - Guard: `'storage layers never reference Crossing'` (passes on the current empty storage package). Then prove it bites: temporarily add a file to `packages/shared_storage/lib/` mentioning `Crossing`, expect FAIL, delete the file, expect PASS.
- [ ] **Step 2:** Run `fvm dart run melos exec --scope=astro_core -- dart test`. Expected: compilation FAIL (`Crossing`, `Body.toJson` undefined).
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run the same command, then `fvm dart run melos run test` and `fvm dart run melos run lint`. Expected: all exit 0.
- [ ] **Step 5:** Commit `feat(ZOD-FND-012): add Crossing, Body JSON and the not-persisted guard`.

### Task 5: Close out (zodiann-development workflow)

- [ ] **Step 1:** Whole-branch review (`requesting-code-review`), then resolve any important findings.
- [ ] **Step 2:** Re-run lint and test (`verification-before-completion`).
- [ ] **Step 3:**
  - Set `Status: Done` in the task file and `TASKS.md`, and tick the acceptance criteria.
  - Commit the task-file updates on this branch (FND-012, SET-007, DAT-009).
  - Update `docs/PROGRESS.md`: decisions, conventions (JSON / `FormatException` / `OffsetDateTime`), verification, next task.
- [ ] **Step 4:** Commit, push, open a PR, then record the PR link.

## Acceptance Criteria → Evidence

| AC (as updated 2026-11-12) | Proven by |
|---|---|
| `SquareConfig`, `HighlightRule` (+ `HighlightMatch`) and `Crossing` compile; persisted types round-trip through JSON without data loss, including the anchor's offset | Task 3 round-trip tests per mode with `+05:30` / `-03:30` anchors; Task 2 match and rule round-trips; Task 1 offset round-trips |
| `Crossing` has no storage/persistence code path | No JSON on `Crossing` (Task 4); root guard over the storage layers, proven to fail on an injected reference |
| A new `SquareConfig` defaults to the three default rules in priority order | Task 3 AC test + Task 2 defaults test |

## Risks

- **Spec drift on `stepHours`.** The comment says "4 in date and time mode", but SET-004 makes it editable. Modelled as positive with a default of 4. Revisit if GAN-003 needs it fixed.
- **Guard reach.** The guard scans known storage layers only. When a new persistence package appears, add it to the guard's list (noted in conventions).
