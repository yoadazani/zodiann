# Zodiann

A Flutter app (iOS and Android) combining a zodiac wheel and the Gann Square of Nine, with all computation and data kept on-device.

- Product specification: [`assets/zodiann-specification.md`](assets/zodiann-specification.md)
- Development roadmap and tasks: [`docs/development/TASKS.md`](docs/development/TASKS.md)
- Current progress and architecture conventions: [`docs/PROGRESS.md`](docs/PROGRESS.md)

## License

Zodiann is licensed under the **GNU Affero General Public License, version 3 only** (`AGPL-3.0-only`). The full text is in [`LICENSE`](LICENSE).

Copyright (C) 2026 Yoad Azani

- **Covered:** the project-authored files in this repository: source code, translations, scripts, documentation, the logo, launcher and platform icons, the SVG icons and generated icon code, the design reference, the specification files and the test fixtures.
- **Not covered:** third-party components and assets, which keep their own licenses and notices: Dart and Flutter packages and SDKs, the bundled fonts (SIL Open Font License 1.1), the font copies under `design-reference/zodiann/assets/fonts/`, and any other third-party material. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) and the [inventory](docs/licensing/third-party-inventory.md). The AGPL is not applied to them. The name "Zodiann" is not addressed by this license.
- **Swiss Ephemeris:** not yet part of this repository. When it is added (ZOD-FND-003) it comes under the AGPL option of its own dual license, with its original license and copyright notices kept. This project does not use the names of its authors or of Astrodienst to promote the app.
- **Source:** the source is in this repository, at https://github.com/yoadazani/zodiann. Every build handed to anyone is made from a public Git tag of it, and the policy for where its source is and how long it stays available is in [`docs/licensing/source-availability-policy.md`](docs/licensing/source-availability-policy.md). The repository being public is not by itself taken to meet the license's source requirement.
- **For now:** the AGPL path is the current choice and may change (ZOD-REL-003 reconfirms it against the distribution channel). This is not legal advice and not a claim of legal compliance; the open questions are listed in [`docs/decisions/ZOD-FND-015-agpl-application.md`](docs/decisions/ZOD-FND-015-agpl-application.md).

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
