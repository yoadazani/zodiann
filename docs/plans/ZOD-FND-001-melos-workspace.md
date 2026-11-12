# ZOD-FND-001 — Melos Monorepo Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Awaiting approval · **Branch:** `task/ZOD-FND-001-melos-workspace` · **Written:** 2026-11-12

**Goal:** Stand up the reproducible Dart/Flutter monorepo skeleton that every later Zodiann package depends on, with the computation core provably free of Flutter.

**Architecture:** One Dart **pub workspace** (single shared resolution, one root `pubspec.lock`) driven by **Melos 8** configured in the root `pubspec.yaml`. The SDK is pinned with **FVM** (`.fvmrc`), and Melos is pointed at the FVM SDK via `sdkPath` so every Melos command and script uses the pinned SDK, never the machine's global Flutter. Packages are empty skeletons; a test inside each core package enforces ARCH-2 (no Flutter, no `dart:ui`) on every `melos run test`.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (via FVM 4.3.2), Melos 8.10.1, pub workspaces, `lints` 6.1.0, `flutter_lints` 6.0.0, `test` 1.32.0.

**Spec:** `docs/development/foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md`; `assets/zodiann-specification.md` → "Recommended structure in Melos", ARCH-2.

## Global Constraints

- Directory layout exactly as the spec's "Recommended structure in Melos": `apps/astro_mobile`; `packages/{astro_core, ephemeris_swiss, ephemeris_astronomy, gann_core, feature_wheel, feature_square, shared_ui, shared_storage, shared_export_xlsx}`; `native/{swisseph, astronomy_c}`.
- ARCH-2: `astro_core` and `gann_core` are pure Dart: no `flutter` SDK dependency (direct or transitive), no `dart:ui` import.
- Every package: `resolution: workspace`, `publish_to: none`, `environment.sdk: ^3.14.0`. Flutter packages also `environment.flutter: ">=3.50.0"`.
- Melos config lives under the `melos:` key of the root `pubspec.yaml`. **No `melos.yaml` file.**
- Latest stable releases only (no beta/dev/rc). Exceptions must be justified (see Version Baseline).
- No dependencies beyond the ones listed in this plan.
- Out of scope: app bootstrap (`lib/main.dart`, Riverpod, theme, platform folders → ZOD-FND-005), `EphemerisPort` and other domain interfaces (→ ZOD-FND-002), native C code / ffigen / plugin-vs-native-assets choice (→ ZOD-FND-003), CI workflows (→ ZOD-FND-004).

## Version Baseline (verified 2026-11-12)

| Item | Version | Source / verification | Notes |
|---|---|---|---|
| Flutter | **3.50.0** (stable, released 2026-11-11) | `flutter_infra_release/releases/releases_windows.json` → `current_release.stable` | Supersedes 3.47.9 (approved by user) |
| Dart | **3.14.0** | Same feed, `dart_sdk_version` | |
| FVM | **4.3.2** | pub.dev + GitHub latest release (`prerelease=false`); SDK `>=3.6.0 <4.0.0` | Installed with the existing global Dart 3.6.0 |
| Melos | **8.10.1** | pub.dev latest; SDK `^3.9.0` ✓ | Root dev dependency **and** global CLI (global delegates to the local version) |
| `lints` | **6.1.0** | pub.dev latest; SDK `^3.8.0` ✓ | Root dev dependency |
| `flutter_lints` | **6.0.0** | pub.dev latest; SDK `^3.8.0` ✓; depends only on `lints ^6.0.0` | Flutter packages' dev dependency |
| `test` | **1.32.0** (not latest 1.33.0) | See conflict below | Pure-Dart packages' dev dependency |
| `flutter_test` | SDK | Bundled with Flutter 3.50.0 | Flutter packages' dev dependency |

**Compatibility conflict — `test`:** latest `test` 1.33.0 pins `test_api 0.7.15`, but Flutter 3.50.0's `flutter_test` pins `test_api 0.7.14` (and `matcher 0.12.20`). A pub workspace resolves all members together, so `test` 1.33.0 and `flutter_test` cannot coexist. `test` **1.32.0** is the newest release pinning `test_api 0.7.14` and allowing `matcher <0.12.21`, so it's the latest version compatible with the selected SDK. Declare `test: ^1.32.0` so the next Flutter release can lift it automatically; the lock file records 1.32.0.

**Pub workspaces:** need Dart ≥ 3.6. Dart 3.14.0 ✓. Melos ≥ 7 is built on them ✓.

## Prerequisites (user action)

- **Windows Developer Mode must be enabled** (Settings → System → For developers → Developer Mode). FVM creates the `.fvm/flutter_sdk` symlink, and Windows only lets non-admin users create symlinks with Developer Mode on. It currently looks disabled (`AllowDevelopmentWithoutDevLicense` isn't set). If it stays off, Task 1 stops and reports the error. It won't work around it.
- The global Flutter at `C:\Program Files\flutter` (3.27.1) is left untouched. Upgrading it needs admin rights and is unnecessary, because every project command goes through FVM or Melos.

## File Structure

```
.fvmrc                                   pinned SDK: {"flutter": "3.50.0"}
pubspec.yaml                             workspace root: members, melos config/scripts, root dev deps
pubspec.lock                             committed — single lock for the whole workspace
analysis_options.yaml                    shared analyzer config (pure-Dart baseline)
README.md                                developer setup: FVM → Melos → bootstrap/lint/test
apps/astro_mobile/
  pubspec.yaml                           Flutter app member (no lib/, no platforms — FND-005)
  analysis_options.yaml                  shared config + flutter_lints
packages/<dart_pkg>/                     astro_core, gann_core, ephemeris_swiss, ephemeris_astronomy
  pubspec.yaml
  lib/<name>.dart                        library doc comment only (`library;`)
packages/<flutter_pkg>/                  feature_wheel, feature_square, shared_ui, shared_storage, shared_export_xlsx
  pubspec.yaml
  analysis_options.yaml                  shared config + flutter_lints
  lib/<name>.dart                        library doc comment only
packages/astro_core/test/architecture/pure_dart_test.dart   ARCH-2 guard
packages/gann_core/test/architecture/pure_dart_test.dart    ARCH-2 guard
native/swisseph/README.md                placeholder: owned by ZOD-FND-003
native/astronomy_c/README.md             placeholder: owned by ZOD-EPH-004
```

**Package kind decisions:**
- **Pure Dart:** `astro_core`, `gann_core` (ARCH-2), and `ephemeris_swiss` / `ephemeris_astronomy`. FFI needs only `dart:ffi`; whether they become Flutter plugins or use native assets is ZOD-FND-003's decision, and the skeleton doesn't preempt it.
- **Flutter:** `feature_wheel`, `feature_square`, `shared_ui` (widgets), `shared_storage` (`shared_preferences` is a Flutter plugin), `shared_export_xlsx` (system share sheet is a Flutter plugin), `apps/astro_mobile`.

## Review Focus

1. **Global SDK used by mistake** (`dart pub get` with the global Dart 3.6.0 / Flutter 3.27.1): it must fail loudly on the `^3.14.0` SDK constraint rather than resolve silently. Pinned in Task 2, Step 6.
2. **Melos scripts not using the pinned SDK.** `melos exec` must run Dart 3.14.0, not whatever is first on PATH. Pinned in Task 2, Step 5.
3. **Flutter sneaking into the core transitively**, for example `astro_core` depending on a package that depends on Flutter. The purity test must catch transitive deps, not just direct ones. Pinned in Task 3 (negative test).
4. **`test` vs `flutter_test` resolution conflict.** It must surface at bootstrap, not later. That's why every Flutter skeleton declares `flutter_test` now. Pinned in Task 2, Step 4.
5. **No tests in Flutter packages yet.** `melos run test` must still exit 0 when a filter matches zero packages. Pinned in Task 4, Step 3.

---

### Task 1: Pin the SDK with FVM

**Files:**
- Create: `.fvmrc`

**Interfaces:**
- Produces: `.fvm/flutter_sdk` (gitignored symlink to Flutter 3.50.0), used by Melos `sdkPath` in Task 2.

- [ ] **Step 1: Install FVM 4.3.2**

Run: `dart pub global activate fvm 4.3.2`
Expected: `Activated fvm 4.3.2`. Ensure `%LOCALAPPDATA%\Pub\Cache\bin` is on PATH for the session.

- [ ] **Step 2: Install and select Flutter 3.50.0 for the project**

Run: `fvm install 3.50.0` then `fvm use 3.50.0 --force` from the repo root. Decline or skip VS Code settings changes; `.gitignore` already contains `.fvm/`.
Expected: `.fvmrc` = `{"flutter": "3.50.0"}`; `.fvm/flutter_sdk` exists. A symlink error means Developer Mode is off: stop and report.

- [ ] **Step 3: Verify the pinned SDK**

Run: `fvm flutter --version`
Expected: `Flutter 3.50.0 • channel stable` and `Dart 3.14.0`.

- [ ] **Step 4: Commit**

```bash
git add .fvmrc
git commit -m "build(ZOD-FND-001): pin Flutter 3.50.0 with FVM"
```

### Task 2: Workspace root, Melos and package skeletons

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `pubspec.lock` (generated), every `pubspec.yaml` / `lib/<name>.dart` / `analysis_options.yaml` in the File Structure, `native/*/README.md`

**Interfaces:**
- Consumes: `.fvm/flutter_sdk` (Task 1).
- Produces: workspace member names exactly as the directory names (`astro_core`, `gann_core`, …, `astro_mobile`). Later tasks import `package:<name>/<name>.dart`.

- [ ] **Step 1: Root `pubspec.yaml`**

`name: zodiann_workspace`, `publish_to: none`, `environment.sdk: ^3.14.0`, `workspace:` listing all 10 members (`apps/astro_mobile` + 9 `packages/*`), `dev_dependencies: {melos: ^8.10.1, lints: ^6.1.0}`, and:

```yaml
melos:
  sdkPath: .fvm/flutter_sdk
  ide:
    intellij:
      enabled: false        # don't generate .idea run configs
  scripts:
    analyze:
      exec: dart analyze --fatal-infos .
    format:check:
      exec: dart format --output=none --set-exit-if-changed .
    lint:
      steps: [analyze, format:check]
    test:dart:
      exec: dart test
      packageFilters: { flutter: false, dirExists: test }
    test:flutter:
      exec: flutter test
      packageFilters: { flutter: true, dirExists: test }
    test:
      steps: [test:dart, test:flutter]
```

- [ ] **Step 2: Shared `analysis_options.yaml`**

Root: `include: package:lints/recommended.yaml`; `analyzer.language: {strict-casts: true, strict-inference: true, strict-raw-types: true}`. Flutter members' own `analysis_options.yaml`: `include: [../../analysis_options.yaml, package:flutter_lints/flutter.yaml]` (multi-include supported since Dart 3.8). Pure-Dart members have no file and inherit the root's.

- [ ] **Step 3: Member skeletons**

Each member pubspec: `name`, one-line `description` (from the spec's structure table), `publish_to: none`, `resolution: workspace`, `environment.sdk: ^3.14.0`.
- Pure Dart: `dev_dependencies: {test: ^1.32.0}`. No other dependencies.
- Flutter: add `environment.flutter: ">=3.50.0"`, `dependencies: {flutter: {sdk: flutter}}`, `dev_dependencies: {flutter_test: {sdk: flutter}, flutter_lints: ^6.0.0}`.
- `astro_mobile`: same as Flutter, but no `lib/` (FND-005 runs `flutter create` into it).
- `lib/<name>.dart`: a single library doc comment naming the package's role, then `library;`. No code, no exports.
- `native/swisseph/README.md` and `native/astronomy_c/README.md`: one paragraph saying what goes there and which task owns it.

- [ ] **Step 4: Install Melos and bootstrap**

Run: `fvm dart pub global activate melos 8.10.1`, then `melos bootstrap`.
Expected: success, with all 10 members listed. `pubspec.lock` contains `test` 1.32.0, `test_api` 0.7.14, `melos` 8.10.1, `lints` 6.1.0, `flutter_lints` 6.0.0. A version-solving failure here means a conflict: stop and report it with the solver output.

- [ ] **Step 5: Verify Melos uses the pinned SDK**

Run: `melos exec --scope=astro_core -- dart --version`
Expected: `Dart SDK version: 3.14.0`. If it prints 3.6.0, `sdkPath` isn't applied to scripts: stop and report before choosing a workaround.

- [ ] **Step 6: Verify the global SDK is rejected**

Run (global Dart, from repo root): `"C:/Program Files/flutter/bin/dart" pub get`
Expected: non-zero exit, with a message that the current Dart SDK (3.6.0) doesn't satisfy `^3.14.0`. Then rerun `melos bootstrap` to restore the pinned state.

- [ ] **Step 7: Lint passes on the skeleton**

Run: `melos run lint`
Expected: exit 0, no analyzer issues, no formatting changes.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml apps packages native
git commit -m "build(ZOD-FND-001): add pub workspace, Melos 8 config and package skeletons"
```

### Task 3: ARCH-2 purity guard for the core packages (TDD)

**Files:**
- Test: `packages/astro_core/test/architecture/pure_dart_test.dart`
- Test: `packages/gann_core/test/architecture/pure_dart_test.dart` (same content, package name differs)

**Interfaces:**
- Consumes: the package's own `lib/` and `dart pub deps --json` output.
- Produces: nothing imported elsewhere. ZOD-FND-004 (CI) runs it via `melos run test`.

- [ ] **Step 1: Write the test**

Two tests in `group('ARCH-2: <package> is pure Dart')`:
- `'lib/ imports neither dart:ui nor package:flutter'`: recursively read every `.dart` file under `lib/`, and `expect` no line matching `^\s*(import|export)\s+['"](dart:ui|package:flutter/)`. On failure, list the offending files.
- `'dependency closure contains no Flutter SDK package'`: run `Process.runSync(Platform.resolvedExecutable, ['pub', 'deps', '--json'])` in the package directory. Compute the transitive closure starting from this package's own node (follow `dependencies` and `devDependencies` of the root package, then `dependencies` of each reached package). `expect` it contains none of `flutter`, `flutter_test`, `sky_engine`. On failure, print the closure.

`Platform.resolvedExecutable` is the Dart VM running the test, so it's always the pinned SDK under Melos.

- [ ] **Step 2: Prove the source check fails (RED)**

Temporarily create `packages/astro_core/lib/src/_violation.dart` containing `import 'package:flutter/widgets.dart';`.
Run: `melos exec --scope=astro_core -- dart test test/architecture`
Expected: FAIL on the import test, naming `_violation.dart`. Delete the file.

- [ ] **Step 3: Prove the transitive check fails (RED)**

Temporarily add `shared_ui:` (a workspace member that depends on Flutter) to `astro_core`'s `dependencies`, then run `melos bootstrap` and the same test command.
Expected: FAIL on the closure test, with `flutter`/`sky_engine` listed. Revert the pubspec and rerun `melos bootstrap`.

- [ ] **Step 4: Verify GREEN**

Run: `melos run test:dart`
Expected: both packages' tests pass (4 tests), and `git status` shows no leftover violation changes.

- [ ] **Step 5: Commit**

```bash
git add packages/astro_core/test packages/gann_core/test
git commit -m "test(ZOD-FND-001): enforce ARCH-2 pure-Dart core packages"
```

### Task 4: Workspace-wide scripts, setup docs, acceptance verification

**Files:**
- Create: `README.md` (root)

- [ ] **Step 1: Write the root `README.md`**

Short developer setup: prerequisites (Developer Mode on Windows), `dart pub global activate fvm 4.3.2`, `fvm install`, `fvm dart pub global activate melos 8.10.1`, `melos bootstrap`, `melos run lint`, `melos run test`. Explain that the global Flutter isn't used, and link `docs/development/TASKS.md`. No product description beyond one line.

- [ ] **Step 2: AC — bootstrap links all packages**

Run: `melos list --long`
Expected: all 10 members with paths. Then run `melos bootstrap` and expect success.

- [ ] **Step 3: AC — `melos run test` across the workspace**

Run: `melos run test`
Expected: exit 0. `test:dart` runs 4 tests in `astro_core` and `gann_core`. `test:flutter` matches zero packages (no Flutter tests yet) and must **not** fail. If Melos exits non-zero on an empty filter match, stop and report. Candidate fix to propose: keep `test:flutter` defined but leave it out of `test` until the first Flutter test exists (ZOD-FND-005).

- [ ] **Step 4: AC — core packages have no Flutter dependency (`pub deps`)**

Run: `melos exec --scope=astro_core,gann_core -- dart pub deps --style=compact`
Expected: neither output contains `flutter` or `sky_engine`. Record the output in PROGRESS.md.

- [ ] **Step 5: Full lint**

Run: `melos run lint`
Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs(ZOD-FND-001): document workspace setup"
```

### Task 5: Close out (zodiann-development workflow)

- [ ] **Step 1:** Run the code review (`requesting-code-review`) on the branch diff and resolve any important findings.
- [ ] **Step 2:** Re-run Task 4, Steps 2–5 (`verification-before-completion`) and record the exact results.
- [ ] **Step 3:** Set `Status: Done` in the ZOD-FND-001 task file and its `TASKS.md` row, and tick its acceptance criteria. Update `docs/PROGRESS.md` (completed task, verification evidence, decisions, next task).
- [ ] **Step 4:** Commit with `docs(ZOD-FND-001): mark task complete`, push `task/ZOD-FND-001-melos-workspace`, open a PR into `main`, record the PR link in PROGRESS.md, and commit and push that follow-up.

## Acceptance Criteria → Evidence

| AC (task file) | Proven by |
|---|---|
| `melos bootstrap` succeeds and links all packages | Task 2, Step 4; Task 4, Step 2 |
| `astro_core` / `gann_core` have no Flutter/`dart:ui` dependency (verified by `pub deps`) | Task 3 (automated, transitive); Task 4, Step 4 (`pub deps` output) |
| CI (ZOD-FND-004) can run `melos run test` across the workspace | Task 4, Step 3 |

## Risks and Open Points

- **Developer Mode** is a user prerequisite (see above). Without it, Task 1 is blocked.
- **`sdkPath` applied to scripts** (Task 2, Step 5) and **empty filter match** (Task 4, Step 3) are behaviours verified at implementation time. Each has a stop-and-report rule, so no silent workaround.
- **`test` held at 1.32.0** because of the Flutter SDK pin. It lifts automatically when a Flutter release pins `test_api ≥ 0.7.15`.
- **Flutter 3.50.0 is one day old.** If a regression affects the skeleton (unlikely at this scope), report it before considering 3.47.9.
- **`.qodo/`** is untracked and not ignored. It won't be staged; adding it to `.gitignore` is outside this task.
