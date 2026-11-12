# ZOD-FND-001 — Melos Monorepo Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Status:** Revision 2, awaiting approval · **Branch:** `task/ZOD-FND-001-melos-workspace` · **Written:** 2026-11-12

**Goal:** Stand up the reproducible Dart/Flutter monorepo skeleton that every later Zodiann package depends on, with the computation core provably free of Flutter.

**Architecture:** One Dart **pub workspace** (single shared resolution, one committed root `pubspec.lock`) driven by **Melos 8** configured in the root `pubspec.yaml`. The SDK is pinned with **FVM** (`.fvmrc`), and Melos is pointed at the FVM SDK via `sdkPath` so every Melos command and child process uses the pinned SDK. Packages are empty skeletons. A single workspace-root test suite enforces ARCH-2 (no Flutter, no `dart:ui` in `astro_core` / `gann_core`) on every `melos run test`.

**Tech Stack:** Flutter 3.50.0 / Dart 3.14.0 (via FVM 4.3.2), Melos 8.10.1, pub workspaces, `lints` 6.1.0, `flutter_lints` 6.0.0, `test` 1.32.0.

**Spec:** `docs/development/foundations-architecture/ZOD-FND-001-set-up-the-melos-monorepo-workspace.md`; `assets/zodiann-specification.md` → "Recommended structure in Melos", ARCH-2.

## Revision 2 — changes from revision 1

| # | Review point | Change |
|---|---|---|
| 1 | Workspace-wide testing | **The rev 1 design would have failed.** Melos 8.10.1 throws `NoPackageFoundScriptException` when a script's `packageFilters` match zero packages (`commands/run.dart`). Test scripts now call `melos exec` with command-line filters, which exits 0 when the selection is empty (`commands/exec.dart`: no failures → success). This is verified from source, with no conditional fallback. |
| 2 | ARCH-2 dependency test | The `pub deps --json` format was verified on real output (see "Verified facts"). The closure rule was corrected to avoid false positives. Detection of indirect Flutter through both regular and dev paths is now a **permanent fixture-based unit test**, plus a live check. The logic lives once at the workspace root instead of being copied into two packages. |
| 3 | SDK path | Verified: the global SDK is at `C:\Program Files\flutter` (Flutter 3.27.1 / Dart 3.6.0). `C:\develop\flutter` doesn't exist and no other installs were found. Steps resolve the global `dart` from PATH instead of hardcoding a path. |
| 4 | Developer Mode | Verified as **actually required**: symlink creation fails on this machine, and FVM 4.3.2 has no junction fallback. Details and the alternative are under "Prerequisites". |
| 5 | Architecture decisions | Recorded in `docs/PROGRESS.md` → "Architecture Conventions" so later tasks follow them. |
| 6 | Dependency management | Root `pubspec.lock` is committed. All versions were checked against Flutter 3.50.0's exact pins. No conflicts besides `test` (see Version Baseline). |

## Global Constraints

- Directory layout exactly as the spec's "Recommended structure in Melos": `apps/astro_mobile`; `packages/{astro_core, ephemeris_swiss, ephemeris_astronomy, gann_core, feature_wheel, feature_square, shared_ui, shared_storage, shared_export_xlsx}`; `native/{swisseph, astronomy_c}`.
- ARCH-2: `astro_core` and `gann_core` are pure Dart: no `flutter` SDK dependency (direct or transitive, regular or dev), no `dart:ui` import.
- Every member: `resolution: workspace`, `publish_to: none`, `environment.sdk: ^3.14.0`. Flutter members also `environment.flutter: ">=3.50.0"`.
- Melos config lives under the `melos:` key of the root `pubspec.yaml`. **No `melos.yaml` file.**
- Single root `pubspec.lock`, committed. Members never have their own lock.
- Latest stable releases only (no beta/dev/rc). Exceptions must be justified in the Version Baseline.
- No dependencies beyond those listed in this plan.
- Out of scope: app bootstrap (`lib/main.dart`, Riverpod, theme, platform folders → ZOD-FND-005), `EphemerisPort` and other domain interfaces (→ ZOD-FND-002), native C code / ffigen / plugin-vs-native-assets choice (→ ZOD-FND-003), CI workflows (→ ZOD-FND-004).

## Version Baseline (verified 2026-11-12)

| Item | Version | Verification | Notes |
|---|---|---|---|
| Flutter | **3.50.0** (stable, 2026-11-11) | `flutter_infra_release/releases/releases_windows.json` → `current_release.stable` | Supersedes 3.47.9 (user decision) |
| Dart | **3.14.0** | Same feed | |
| FVM | **4.3.2** | pub.dev + GitHub latest release (`prerelease=false`); SDK `>=3.6.0 <4.0.0` | Activated with the global Dart 3.6.0 |
| Melos | **8.10.1** | pub.dev latest; SDK `^3.9.0` ✓; its dependencies touch none of Flutter's exact pins | Root dev dependency **and** global CLI (global delegates to the local version) |
| `lints` | **6.1.0** | pub.dev latest; SDK `^3.8.0` ✓ | Root dev dependency |
| `flutter_lints` | **6.0.0** | pub.dev latest; SDK `^3.8.0` ✓; depends only on `lints ^6.0.0` | Flutter members' dev dependency |
| `test` | **1.32.0** (latest is 1.33.0) | See conflict below | Root and pure-Dart members' dev dependency |
| `flutter_test` | SDK | Bundled with Flutter 3.50.0 | Flutter members' dev dependency |

**Flutter 3.50.0 exact pins** (from `packages/flutter` + `packages/flutter_test` pubspecs at tag `3.50.0`): `test_api 0.7.14`, `matcher 0.12.20`, `material_color_utilities 0.13.0`. Everything else is a range.

**Compatibility conflict — `test`:** `test` 1.33.0 requires `test_api 0.7.15` exactly, which conflicts with Flutter's `test_api 0.7.14` pin in the shared workspace resolution. `test` **1.32.0** (via `test_core 0.6.20`) requires `test_api 0.7.14` and `matcher >=0.12.16 <0.12.21`, so it's the newest compatible release. Declared as `test: ^1.32.0`, so it lifts automatically once a Flutter release pins `test_api ≥ 0.7.15`. The lock records 1.32.0.

## Verified facts this plan relies on

1. **Melos script filters on an empty match.** In Melos 8.10.1 `commands/run.dart`, a script with `packageFilters` that match nothing → `throw NoPackageFoundScriptException`. Plain `melos exec` with an empty selection reports no failures, so it logs success and exits 0 (`commands/exec.dart`). `--dir-exists` and `--flutter` / `--no-flutter` are `melos exec` command-line flags (`common/utils.dart`).
2. **`sdkPath` reaches child processes.** `run.dart` sets `MELOS_SDK_PATH` and prepends the SDK to child `PATH` when `sdkPath` is configured.
3. **`useRootAsPackage: true`** is supported in Melos 8.10.1 and includes the root package in `exec`/`run` filtering.
4. **`dart pub deps --json` in a workspace** (probed on a scratch workspace with an indirect Flutter dependency via regular and dev paths):
   - Top-level keys are `root`, `packages`, `sdks`, `executables`. **`root` is the workspace root package, not the member the command ran in**, and the output is identical from any member directory.
   - Every workspace member appears in `packages` with `kind: "root"` and three lists: `directDependencies` (regular only), `devDependencies`, and `dependencies` (**the union of both**).
   - Non-member packages have `dependencies` = `directDependencies` and no `devDependencies` key.
   - **Closure rule (proven on the probe):** start at the member's node → `directDependencies ∪ devDependencies`. From every reached node, follow `directDependencies` only. Following `dependencies` would wrongly pull in other members' dev dependencies, which aren't part of the closure. The probe flagged `reg → mid → uipkg → flutter` and `dev →(dev) helper → uipkg → flutter`, passed the clean package, and passed `fp → devonly ⇢(dev-only) uipkg`.
5. **Global SDK location.** `where.exe flutter` / `where.exe dart` → `C:\Program Files\flutter\bin`. `flutter --version --machine` → `flutterRoot: C:\Program Files\flutter`, 3.27.1 / Dart 3.6.0. `C:\develop\flutter` doesn't exist and `FLUTTER_ROOT` is unset.
6. **Symlinks on this machine.** The session isn't elevated, has no `SeCreateSymbolicLinkPrivilege`, and Developer Mode's registry value is unset. `mklink /D` fails, and Dart's `Link.createSync` fails with errno 1314. Junctions (`mklink /J`) do succeed. FVM 4.3.2 creates `.fvm/flutter_sdk` with Dart's `Link` and **has no junction fallback**: on errno 1314 it aborts with "Requires administrator privileges… turn on developer mode". Its `privilegedAccess: false` option only skips the link, which would leave Melos's `sdkPath` dangling. FVM's Melos auto-config only targets `melos.yaml`, so it ignores a `pubspec.yaml`-based config.

## Prerequisites (user action, verified as required)

Creating `.fvm/flutter_sdk` needs symlink permission, which this account doesn't have (Verified fact 6). Pick **one** of these, once:

- **A (recommended):** turn on Developer Mode (Settings → System → For developers → Developer Mode). This is Microsoft's and FVM's documented route, it's permanent, and it works for every future `fvm use` / SDK upgrade.
- **B:** run `fvm use 3.50.0 --force` once from an **administrator** terminal in the repo root. The link it creates is usable without elevation afterwards, but every future SDK change needs admin again.

Task 1, Step 1 checks the permission first and stops if neither has been done. I won't hand-craft junctions behind FVM's back: `fvm doctor` and `fvm use` would fight them.

The global Flutter at `C:\Program Files\flutter` (3.27.1) stays untouched. Upgrading it needs admin and is unnecessary, because every project command goes through FVM or Melos.

## File Structure

```
.fvmrc                                   {"flutter": "3.50.0", "updateVscodeSettings": false,
                                          "updateGitIgnore": false, "updateMelosSettings": false}
pubspec.yaml                             workspace root package: members, melos config/scripts, dev deps
pubspec.lock                             committed: the single lock for the whole workspace
analysis_options.yaml                    shared analyzer config (pure-Dart baseline)
README.md                                developer setup: prerequisites → FVM → Melos → bootstrap/lint/test
test/architecture/
  dependency_closure.dart                pure functions: closure + forbidden-package search over pub-deps JSON
  dependency_closure_test.dart           fixture unit tests (regular-indirect, dev-indirect, clean, dev-of-dep, errors)
  pure_dart_test.dart                    live ARCH-2 check of astro_core and gann_core (deps + source imports)
  fixtures/pub_deps_workspace.json       recorded scratch-workspace output (Verified fact 4)
apps/astro_mobile/
  pubspec.yaml                           Flutter app member (no lib/, no platforms: FND-005)
  analysis_options.yaml                  include: [../../analysis_options.yaml, package:flutter_lints/flutter.yaml]
packages/<dart_pkg>/                     astro_core, gann_core, ephemeris_swiss, ephemeris_astronomy
  pubspec.yaml
  lib/<name>.dart                        library doc comment only (`library;`)
packages/<flutter_pkg>/                  feature_wheel, feature_square, shared_ui, shared_storage, shared_export_xlsx
  pubspec.yaml
  analysis_options.yaml                  as astro_mobile
  lib/<name>.dart                        library doc comment only
native/swisseph/README.md                placeholder: owned by ZOD-FND-003
native/astronomy_c/README.md             placeholder: owned by ZOD-EPH-004
```

**Package kind decisions:**
- **Pure Dart:** `astro_core`, `gann_core` (ARCH-2), and `ephemeris_swiss` / `ephemeris_astronomy`. FFI needs only `dart:ffi`; plugin vs. native assets is ZOD-FND-003's decision.
- **Flutter:** `feature_wheel`, `feature_square`, `shared_ui` (widgets), `shared_storage` (`shared_preferences` is a plugin), `shared_export_xlsx` (system share sheet is a plugin), `apps/astro_mobile`.
- **Workspace root** (`zodiann_workspace`): pure Dart, `useRootAsPackage: true`, owns the cross-package architecture tests. It's not part of the shipped app.

## Review Focus

1. **Global SDK used by mistake** (`dart pub get` with the global Dart 3.6.0): it must fail loudly on `^3.14.0`. Pinned in Task 2, Step 6.
2. **Melos child processes not using the pinned SDK.** Pinned in Task 2, Step 5.
3. **Flutter reaching the core indirectly**, through a regular or a dev dependency path. Pinned permanently by fixture tests in Task 3, and live in `pure_dart_test.dart`.
4. **False positive from another member's dev-only Flutter dependency.** It must *not* fail the core. Pinned in Task 3's fixture tests.
5. **No Flutter tests exist yet.** `melos run test` must still exit 0. Pinned in Task 4, Step 3.

---

### Task 1: Pin the SDK with FVM

**Files:**
- Create: `.fvmrc`

**Interfaces:**
- Produces: `.fvm/flutter_sdk` (gitignored link to Flutter 3.50.0), used by Melos `sdkPath` in Task 2.

- [ ] **Step 1: Check the prerequisite**

Check the `AllowDevelopmentWithoutDevLicense` registry value. If Developer Mode is on, continue. If it's off and the user chose option B, ask them to run Step 3's `fvm use` from an admin terminal and wait. If neither, stop and report.

- [ ] **Step 2: Install FVM 4.3.2**

Run: `dart pub global activate fvm 4.3.2` (global Dart 3.6.0 from PATH)
Expected: `Activated fvm 4.3.2`. Put `%LOCALAPPDATA%\Pub\Cache\bin` on the session PATH.

- [ ] **Step 3: Install and select Flutter 3.50.0**

Run: `fvm install 3.50.0`, then `fvm use 3.50.0 --force` from the repo root. Then set `.fvmrc` to the exact content in File Structure (the three `update*: false` flags).
Expected: `.fvm/flutter_sdk` exists. If you get errno 1314 / "Requires administrator privileges", the prerequisite isn't met: stop.

- [ ] **Step 4: Verify the pinned SDK**

Run: `fvm flutter --version --machine`
Expected: `frameworkVersion: 3.50.0`, `channel: stable`, `dartSdkVersion: 3.14.0`.

- [ ] **Step 5: Commit**

```bash
git add .fvmrc
git commit -m "build(ZOD-FND-001): pin Flutter 3.50.0 with FVM"
```

### Task 2: Workspace root, Melos and package skeletons

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `pubspec.lock` (generated), every member `pubspec.yaml` / `lib/<name>.dart` / `analysis_options.yaml` in File Structure, `native/*/README.md`

**Interfaces:**
- Consumes: `.fvm/flutter_sdk` (Task 1).
- Produces: member package names equal to their directory names. Later tasks import `package:<name>/<name>.dart`.

- [ ] **Step 1: Root `pubspec.yaml`**

`name: zodiann_workspace`, `publish_to: none`, `environment.sdk: ^3.14.0`, `workspace:` listing all 10 members, `dev_dependencies: {melos: ^8.10.1, lints: ^6.1.0, test: ^1.32.0}`, and:

```yaml
melos:
  sdkPath: .fvm/flutter_sdk
  useRootAsPackage: true
  ide:
    intellij:
      enabled: false
  scripts:
    analyze:
      run: melos exec -- dart analyze --fatal-infos .
    format:check:
      run: melos exec -- dart format --output=none --set-exit-if-changed .
    lint:
      steps: [analyze, format:check]
    test:dart:
      run: melos exec --dir-exists=test --no-flutter -- dart test
    test:flutter:
      run: melos exec --dir-exists=test --flutter -- flutter test
    test:
      steps: [test:dart, test:flutter]
```

Never use script-level `packageFilters` here (Verified fact 1). A `melos exec` selection that comes up empty is a valid no-op.

- [ ] **Step 2: Shared analyzer config**

Root `analysis_options.yaml`: `include: package:lints/recommended.yaml`; `analyzer.language: {strict-casts: true, strict-inference: true, strict-raw-types: true}`. Flutter members: `include: [../../analysis_options.yaml, package:flutter_lints/flutter.yaml]` (multi-include, Dart ≥ 3.8). Pure-Dart members have no file and inherit the root's.

- [ ] **Step 3: Member skeletons**

Each member pubspec: `name`, a one-line `description` taken from the spec's structure table, `publish_to: none`, `resolution: workspace`, `environment.sdk: ^3.14.0`.
- Pure Dart: `dev_dependencies: {test: ^1.32.0}`. Nothing else.
- Flutter: `environment.flutter: ">=3.50.0"`, `dependencies: {flutter: {sdk: flutter}}`, `dev_dependencies: {flutter_test: {sdk: flutter}, flutter_lints: ^6.0.0}`. Declaring `flutter_test` now makes the `test`/`test_api` resolution face Flutter's pins at bootstrap.
- `astro_mobile`: as Flutter, but no `lib/`.
- `lib/<name>.dart`: one library doc comment stating the package's role, then `library;`.
- `native/*/README.md`: one paragraph saying what goes there and which task owns it.

- [ ] **Step 4: Install Melos and bootstrap**

Run: `fvm dart pub global activate melos 8.10.1`, then `melos bootstrap`.
Expected: success, listing 11 packages (root + 10 members). `pubspec.lock` contains `melos 8.10.1`, `lints 6.1.0`, `flutter_lints 6.0.0`, `test 1.32.0`, `test_api 0.7.14`, `matcher 0.12.20`. If version solving fails, stop and report the solver output. Don't pick older versions without approval.

- [ ] **Step 5: Verify Melos child processes use the pinned SDK**

Run: `melos exec --scope=astro_core -- dart --version`
Expected: `Dart SDK version: 3.14.0`.

- [ ] **Step 6: Verify the global SDK is rejected**

Run from repo root: `"$(where.exe dart | head -1)" pub get`, which resolves the global `dart` from PATH (currently `C:\Program Files\flutter\bin\dart`).
Expected: non-zero exit, with a message that the current Dart SDK 3.6.0 doesn't satisfy `^3.14.0`. Then run `melos bootstrap` to restore the pinned state, and check that `git diff pubspec.lock` is empty.

- [ ] **Step 7: Lint passes on the skeleton**

Run: `melos run lint`
Expected: exit 0.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml apps packages native
git commit -m "build(ZOD-FND-001): add pub workspace, Melos 8 config and package skeletons"
```

### Task 3: ARCH-2 purity guard (TDD)

**Files:**
- Create: `test/architecture/dependency_closure.dart`
- Test: `test/architecture/dependency_closure_test.dart`, `test/architecture/pure_dart_test.dart`
- Create: `test/architecture/fixtures/pub_deps_workspace.json`

**Interfaces:**
- Produces (in `dependency_closure.dart`, used only by the tests in this directory):
  - `const Set<String> flutterSdkPackages = {'flutter', 'flutter_test', 'sky_engine'};`
  - `Map<String, List<String>> findForbiddenDependencies(Map<String, Object?> pubDepsJson, String package, {Set<String> forbidden = flutterSdkPackages})` returns each forbidden package that's reachable, mapped to one dependency path (`[package, …, forbiddenName]`). Empty means clean. It throws `ArgumentError` if `package` isn't in `pubDepsJson['packages']`.
  - `List<String> findForbiddenImports(Directory libDir)` lists `.dart` files under `libDir` (recursive) with a line matching `^\s*(import|export)\s+['"](dart:ui|package:flutter/)`.

- [ ] **Step 1: Write the fixture**

`fixtures/pub_deps_workspace.json`: a trimmed copy of the real scratch-workspace output from Verified fact 4. It has root `ws` and members `core_reg` (direct → `mid` → `uipkg` → `flutter` → `sky_engine`), `core_dev` (dev → `helper` → `uipkg`), `core_clean` (none), `core_fp` (direct → `devonly`, whose **dev** dependency is `uipkg`), and `ws`. Keep the real field shapes: members have `kind: "root"` with `dependencies` / `directDependencies` / `devDependencies`, and non-members have no `devDependencies`.

- [ ] **Step 2: Write the failing fixture tests**

In `dependency_closure_test.dart`, `group('findForbiddenDependencies')`:
- `'detects Flutter reached indirectly through a regular dependency'`: `core_reg` → keys `{'flutter', 'sky_engine'}`, `result['flutter'] == ['core_reg', 'mid', 'uipkg', 'flutter']`.
- `'detects Flutter reached indirectly through a dev dependency'`: `core_dev` → `result['flutter'] == ['core_dev', 'helper', 'uipkg', 'flutter']`.
- `'passes a package with no Flutter in its closure'`: `core_clean` → `isEmpty`.
- `'ignores dev dependencies of dependencies'`: `core_fp` → `isEmpty`.
- `'starts from the named member, not the workspace root'`: `ws` → `isEmpty`, while `core_reg` in the same JSON is non-empty.
- `'throws for a package missing from the output'`: `'nope'` → `throwsArgumentError`.

`group('findForbiddenImports')` uses a temp dir: a file with `import 'package:flutter/widgets.dart';` is reported; files with `import 'dart:ui';` and `export 'dart:ui';` are reported; a file with `import 'dart:math';` and a comment mentioning `package:flutter/` mid-line isn't.

- [ ] **Step 3: Run the tests and verify they fail**

Run: `melos exec --scope=zodiann_workspace -- dart test test/architecture/dependency_closure_test.dart`
Expected: compilation FAIL (functions not defined).

- [ ] **Step 4: Implement `dependency_closure.dart`**

Breadth-first search using the closure rule from Verified fact 4: the start node contributes `directDependencies ∪ devDependencies`, every later node contributes `directDependencies` only, and nodes are visited once. Store the first path that reaches each forbidden name. Use only `dart:convert`/`dart:io`, with no new dependencies.

- [ ] **Step 5: Run the tests and verify they pass**

Same command. Expected: all PASS.

- [ ] **Step 6: Write the live ARCH-2 test**

`pure_dart_test.dart`: compute `pubDeps = jsonDecode(Process.runSync(Platform.resolvedExecutable, ['pub', 'deps', '--json']).stdout)` once, from the workspace root (`Platform.resolvedExecutable` is the pinned Dart VM running the test). Then for each `package` in `['astro_core', 'gann_core']`, `group('ARCH-2: $package is pure Dart')`:
- `'has no Flutter SDK package in its dependency closure'`: `expect(findForbiddenDependencies(pubDeps, package), isEmpty, reason: <paths>)`.
- `'lib/ imports neither dart:ui nor package:flutter'`: `expect(findForbiddenImports(Directory('packages/$package/lib')), isEmpty)`.
Also assert that `Process.runSync`'s `exitCode == 0`, so a broken `pub deps` can't pass silently.

- [ ] **Step 7: Prove the live test bites, once, against the real workspace**

Temporarily add `shared_ui:` to `astro_core`'s **dev_dependencies** and run `melos bootstrap` and `melos exec --scope=zodiann_workspace -- dart test test/architecture/pure_dart_test.dart`.
Expected: FAIL naming `astro_core → shared_ui → flutter`. Revert, run `melos bootstrap`, rerun, expect PASS, and check that `git diff packages/` is empty. The fixture tests are the permanent proof; this step confirms the real `pub deps` output on Dart 3.14.0 matches the fixture's shape.

- [ ] **Step 8: Commit**

```bash
git add test
git commit -m "test(ZOD-FND-001): enforce ARCH-2 pure-Dart core packages"
```

### Task 4: Setup docs and acceptance verification

**Files:**
- Create: `README.md` (root)

- [ ] **Step 1: Write the root `README.md`**

Short developer setup:
- Prerequisite: Developer Mode on Windows, or the admin alternative.
- Commands: `dart pub global activate fvm 4.3.2`, `fvm install`, `fvm dart pub global activate melos 8.10.1`, `melos bootstrap`, `melos run lint`, `melos run test`.
- Note that the global Flutter is never used, and link `docs/development/TASKS.md`.

- [ ] **Step 2: AC — bootstrap links all packages**

Run: `melos list --long`, then `melos bootstrap`.
Expected: 11 packages listed (root + 10 members), and bootstrap succeeds.

- [ ] **Step 3: AC — `melos run test` across the workspace**

Run: `melos run test`
Expected: exit 0. `test:dart` runs the root architecture suite. `test:flutter` selects zero packages and succeeds (Verified fact 1). Also run `melos run test:flutter` on its own and confirm exit 0.

- [ ] **Step 4: AC — core packages have no Flutter dependency (`pub deps`)**

Run: `melos exec --scope=astro_core,gann_core -- dart pub deps --style=compact`
Expected: neither output contains `flutter` or `sky_engine`. Record it in PROGRESS.md.

- [ ] **Step 5: Full lint**

Run: `melos run lint`. Expected: exit 0.

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs(ZOD-FND-001): document workspace setup"
```

### Task 5: Close out (zodiann-development workflow)

- [ ] **Step 1:** Run the code review (`requesting-code-review`) on the branch diff and resolve any important findings.
- [ ] **Step 2:** Re-run Task 4, Steps 2–5 (`verification-before-completion`) and record the exact results.
- [ ] **Step 3:** Set `Status: Done` in the ZOD-FND-001 task file and its `TASKS.md` row, and tick its acceptance criteria. Update `docs/PROGRESS.md` (completed task, verification evidence, next task).
- [ ] **Step 4:** Commit `docs(ZOD-FND-001): mark task complete`, push `task/ZOD-FND-001-melos-workspace`, open a PR into `main`, then record the PR link in PROGRESS.md and commit and push that follow-up.

## Acceptance Criteria → Evidence

| AC (task file) | Proven by |
|---|---|
| `melos bootstrap` succeeds and links all packages | Task 2, Step 4; Task 4, Step 2 |
| `astro_core` / `gann_core` have no Flutter/`dart:ui` dependency (verified by `pub deps`) | Task 3 (automated: transitive, regular + dev); Task 4, Step 4 (`pub deps` output) |
| CI (ZOD-FND-004) can run `melos run test` across the workspace | Task 4, Step 3 |

## Risks

- **Symlink prerequisite** (Developer Mode or one admin `fvm use`) blocks Task 1 until done.
- **`test` held at 1.32.0** by Flutter 3.50.0's `test_api` pin. It lifts automatically.
- **`pub deps --json` shape was probed on Dart 3.6.0.** Task 3, Step 7 re-confirms it on 3.14.0. If the shape differs, stop and report rather than loosen the test.
- **Flutter 3.50.0 is one day old.** Report any regression that affects the skeleton before considering 3.47.9.
- **`.qodo/`** is untracked and not ignored. It won't be staged; adding it to `.gitignore` is outside this task.
