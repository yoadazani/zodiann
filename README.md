# Zodiann

A Flutter app (iOS and Android) combining a zodiac wheel and the Gann Square of Nine, with all computation and data kept on-device.

- Product specification: [`assets/zodiann-specification.md`](assets/zodiann-specification.md)
- Development roadmap and tasks: [`docs/development/TASKS.md`](docs/development/TASKS.md)
- Current progress and architecture conventions: [`docs/PROGRESS.md`](docs/PROGRESS.md)

## Repository layout

A Dart [pub workspace](https://dart.dev/tools/pub/workspaces) managed with [Melos](https://melos.invertase.dev) 8. The Melos configuration lives under `melos:` in the root `pubspec.yaml`, and there is a single committed `pubspec.lock`.

```
apps/astro_mobile/      Flutter app: navigation, dependency injection
packages/astro_core/    crossings, aspects, EphemerisPort interface (pure Dart)
packages/gann_core/     spiral, angles, date mapping (pure Dart)
packages/ephemeris_*/   EphemerisPort implementations (Swiss Ephemeris, astronomy-engine)
packages/feature_*/     wheel and square screens
packages/shared_*/      UI kit, storage, Excel export
native/                 C sources built via FFI
test/architecture/      workspace-wide architecture tests (ARCH-2)
```

## Setup

The Flutter SDK is pinned in `.fvmrc` and managed with [FVM](https://fvm.app). **Never use a globally installed Flutter for this project.** Every command below runs on the pinned SDK.

1. **Windows only:** turn on Developer Mode (Settings → System → Advanced → For developers). FVM links `.fvm/flutter_sdk` with a symlink, which needs it. Alternatively, run `fvm use` once from an administrator terminal.
2. Install FVM (any Dart ≥ 3.6 works for this step):
   ```
   dart pub global activate fvm 4.3.2
   ```
   Make sure the pub cache `bin` directory is on your `PATH` (on Windows: `%LOCALAPPDATA%\Pub\Cache\bin`).
3. Install the pinned SDK and link it into the project:
   ```
   fvm install
   fvm use --force
   ```
4. Resolve dependencies and bootstrap the workspace:
   ```
   fvm flutter pub get
   fvm dart run melos bootstrap
   ```

Melos is a dev dependency of the workspace, so `fvm dart run melos …` always runs the exact Melos version recorded in `pubspec.lock`, on the pinned SDK. No global Melos install is needed.

## Everyday commands

| Command | What it does |
|---|---|
| `fvm dart run melos bootstrap` | Resolve and link all packages |
| `fvm dart run melos run lint` | `dart analyze --fatal-infos` + format check in every package |
| `fvm dart run melos run test` | Run all tests (pure-Dart with `dart test`, Flutter with `flutter test`) |
| `fvm dart run melos list --long` | List workspace packages |

`astro_core` and `gann_core` must stay pure Dart, with no Flutter dependency (even indirect) and no `dart:ui` import (spec ARCH-2). `melos run test` enforces this via `test/architecture/`.
