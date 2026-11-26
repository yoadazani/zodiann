# Third-party notices

> **Not legal advice. No compliance or clearance claim.** This file lists third-party components that Zodiann uses or contains, the license each states for itself, and where the full license text is. It is derived from [`docs/licensing/third-party-inventory.md`](docs/licensing/third-party-inventory.md) (read on 2026-11-20), which records the method, the exact files read and what remains `Unverified`.

**These components are not relicensed.** Zodiann's own license (`AGPL-3.0-only`, see [`LICENSE`](LICENSE)) is **not** applied to any component below. Each keeps its own license and notices, and the notices must be kept with copies as each license requires.

## Where the full license texts are

- **Dart and Flutter packages:** the `LICENSE` file in each package's own distribution (pub cache copy of the version in `pubspec.lock`, or the package's source repository). The repository does not vendor them.
- **Flutter SDK and Dart SDK:** `LICENSE` at the root of each SDK (Flutter 3.50.0 pinned by `.fvmrc`; Dart 3.14.0).
- **Bundled fonts:** `packages/shared_ui/assets/fonts/<family>/OFL.txt` (shipped as assets).
- **Flutter engine third-party components:** the aggregate license file in the Flutter SDK (`bin/cache/pkg/sky_engine/license`); individual components are `Unverified` here.

## Notice conditions as read (per license, from the texts)

- **MIT:** the copyright notice and permission notice must be included in all copies or substantial portions.
- **BSD-3-Clause (including the Google variant wording found in Dart and Flutter packages) and BSD-2-Clause:** redistributions of source must retain the copyright notice, conditions and disclaimer; redistributions in binary form must reproduce them in the documentation or other materials provided; the BSD-3-Clause variants also forbid using the named entity's or contributors' names to endorse or promote derived products.
- **Apache-2.0:** a copy of the license must be given to recipients, copyright, patent, trademark and attribution notices retained, and modified files marked.
- **SIL OFL 1.1 (fonts):** the copyright notice and the license must accompany each copy; fonts must not be sold on their own; the Reserved Font Names ("Plex" for IBM Plex) must not be used for modified versions; and the Font Software must be distributed entirely under the OFL and not under any other license (condition 5, as read in the shipped `OFL.txt`; it applies to the font software, and how it interacts with an AGPL application is an open legal question).

Whether a built app actually carries these notices (for example through Flutter's license registry) is `Unverified` until a build exists (ZOD-ABT-007, ZOD-REL-002).

## Swiss Ephemeris

**Vendored by ZOD-FND-003 on 2026-11-20, unmodified:** tag `v2.10.3bfinal` of https://github.com/aloistr/swisseph (commit `f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0`), under `native/swisseph/upstream/` with its original `LICENSE`, `LICENSE.TXT`, `agpl-3.0.txt` and `readme.md`, plus the data files `sepl_18.se1` and `semo_18.se1` in `packages/ephemeris_swiss/assets/ephe/`. Its original license and copyright files and notices are kept unchanged and are checked on every test run. The generated Dart bindings `packages/ephemeris_swiss/lib/src/ffi/swisseph_bindings.g.dart` are derived from its `swephexp.h`. Only the Android build is verified so far; no build containing it has been given to anyone. The vendor's notice (read 2026-11-20) offers the "GNU Affero General Public License (AGPL)" or a Swiss Ephemeris Professional License, requires its copyright and notice to be preserved on all copies, forbids using the authors' or Astrodienst's names to promote software that uses it, and names no AGPL version (an open question for Astrodienst). The data files' license is also an open question. The About-screen text is ZOD-ABT-007's.

## astronomy-engine

**Vendored by ZOD-EPH-004 on 2026-11-21, unmodified:** tag `v2.1.19` of https://github.com/cosinekitty/astronomy (commit `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef`), the three files `astronomy.c`, `astronomy.h` and `LICENSE` under `native/astronomy_c/upstream/`. License: **MIT**, "Copyright (c) 2019-2023 Don Cross" (the file's own text; the full text is `native/astronomy_c/upstream/LICENSE` and ships with the source). The MIT condition as read from that text: the copyright notice and permission notice must be included in all copies or substantial portions of the software. Origin, version and how "unchanged" is proved: [`native/astronomy_c/VENDORED.md`](native/astronomy_c/VENDORED.md). This is a statement of what the file says, not a compatibility or compliance claim. Whether a built app carries the notice is `Unverified` until a build that contains the library exists (ZOD-ABT-007, ZOD-REL-002).

## `Unverified` components

Not read, so no license is stated here: the Flutter engine's individual third-party components, the Android build libraries and tooling (Android Gradle Plugin, Kotlin, Gradle, AndroidX), the Android SDK, the iOS system frameworks, six SDK packages that have no license file of their own (`flutter_driver`, `flutter_localizations`, `flutter_test`, `flutter_web_plugins`, `fuchsia_remote_debug_protocol`, `integration_test`), `sky_engine` (an aggregate), and developer tools (FVM, Chrome, Python).

## Components by license (the license named is what each package's own `LICENSE` file states)

`runtime` = in the app's declared runtime dependency graph; `tool` = development, test or tooling only.

### BSD-3-Clause (text as in the SPDX list apart from bullet markers and the named entity; includes Flutter SDK packages)

- `_fe_analyzer_shared` 111.0.0 (tool) — Copyright 2019, the Dart project authors.
- `analyzer` 14.7.0 (tool) — Copyright 2013, the Dart project authors.
- `args` 2.7.0 (runtime) — Copyright 2013, the Dart project authors.
- `async` 2.13.1 (runtime) — Copyright 2015, the Dart project authors.
- `boolean_selector` 2.1.2 (runtime) — Copyright 2016, the Dart project authors.
- `characters` 1.4.1 (runtime) — Copyright 2019, the Dart project authors.
- `charcode` 1.4.0 (tool) — Copyright 2014, the Dart project authors. All rights reserved.
- `checked_yaml` 2.0.4 (tool) — Copyright 2019, the Dart project authors. All rights reserved.
- `cli_config` 0.2.0 (tool) — Copyright 2023, the Dart project authors.
- `cli_util` 0.6.0 (tool) — Copyright 2015, the Dart project authors.
- `collection` 1.19.1 (runtime) — Copyright 2015, the Dart project authors.
- `convert` 3.1.2 (runtime) — Copyright 2015, the Dart project authors.
- `coverage` 1.16.0 (tool) — Copyright 2014, the Dart project authors.
- `crypto` 3.0.8 (runtime) — Copyright 2015, the Dart project authors.
- `cupertino_ui` 1.1.6 (runtime) — Copyright 2013 The Flutter Authors
- `ffi` 2.2.0 (runtime) — Copyright 2019, the Dart project authors.
- `file` 7.0.1 (runtime) — Copyright 2017, the Dart project authors. All rights reserved.
- `fixnum` 1.1.1 (runtime) — Copyright 2014, the Dart project authors.
- `flutter_lints` 6.0.0 (tool) — Copyright 2013 The Flutter Authors. All rights reserved.
- `flutter` 0.0.0 (runtime) — Copyright 2014 The Flutter Authors
- `frontend_server_client` 4.2.0 (tool) — Copyright 2012, the Dart project authors.
- `glob` 2.2.0 (runtime) — Copyright 2014, the Dart project authors.
- `go_router` 18.1.4 (runtime) — Copyright 2013 The Flutter Authors
- `graphs` 2.3.2 (tool) — Copyright 2017, the Dart project authors.
- `http_multi_server` 3.2.3 (tool) — Copyright 2014, the Dart project authors.
- `http_parser` 4.1.2 (tool) — Copyright 2014, the Dart project authors.
- `http` 1.6.0 (tool) — Copyright 2014, the Dart project authors.
- `intl` 0.20.3 (runtime) — Copyright 2013, the Dart project authors.
- `io` 1.1.0 (tool) — Copyright 2017, the Dart project authors.
- `jni` 1.2.1 (runtime) — Copyright 2022, the Dart project authors.
- `jni_flutter` 1.1.0 (runtime) — Copyright 2026, the Dart project authors.
- `jni_util` 1.0.0 (runtime) — Copyright 2026, the Dart project authors.
- `json_annotation` 4.12.0 (tool) — Copyright 2017, the Dart project authors. All rights reserved.
- `leak_tracker_flutter_testing` 3.0.10 (runtime) — Copyright 2022, the Dart project authors.
- `leak_tracker_testing` 3.0.2 (runtime) — Copyright 2022, the Dart project authors.
- `leak_tracker` 11.0.2 (runtime) — Copyright 2022, the Dart project authors.
- `lints` 6.1.0 (tool) — Copyright 2021, the Dart project authors.
- `listen` 1.0.1 (runtime) — Copyright 2013 The Flutter Authors
- `logging` 1.3.0 (runtime) — Copyright 2013, the Dart project authors.
- `matcher` 0.12.20 (runtime) — Copyright 2014, the Dart project authors.
- `material_ui` 1.11.0 (runtime) — Copyright 2013 The Flutter Authors
- `meta` 1.19.0 (runtime) — Copyright 2016, the Dart project authors.
- `mime` 2.1.0 (tool) — Copyright 2015, the Dart project authors.
- `objective_c` 9.6.4 (runtime) — Copyright 2024, the Dart project authors.
- `package_config` 3.0.0 (runtime) — Copyright 2019, the Dart project authors.
- `path` 1.9.1 (runtime) — Copyright 2014, the Dart project authors.
- `path_provider` 2.1.6 (runtime) — Copyright 2013 The Flutter Authors
- `path_provider_android` 2.3.1 (runtime) — Copyright 2013 The Flutter Authors
- `path_provider_foundation` 2.6.0 (runtime) — Copyright 2013 The Flutter Authors
- `path_provider_linux` 2.2.2 (runtime) — Copyright 2013 The Flutter Authors
- `path_provider_platform_interface` 2.1.3 (runtime) — Copyright 2013 The Flutter Authors
- `path_provider_windows` 2.3.0 (runtime) — Copyright 2013 The Flutter Authors. All rights reserved.
- `platform` 3.1.6 (runtime) — Copyright 2017, the Dart project authors. All rights reserved.
- `plugin_platform_interface` 2.1.8 (runtime) — Copyright 2013 The Flutter Authors. All rights reserved.
- `pool` 1.5.3 (tool) — Copyright 2014, the Dart project authors.
- `process` 5.0.6 (runtime) — Copyright 2013, the Dart project authors.
- `pub_semver` 2.2.1 (runtime) — Copyright 2014, the Dart project authors.
- `pubspec_parse` 1.7.0 (tool) — Copyright 2018, the Dart project authors.
- `shelf_packages_handler` 3.0.2 (tool) — Copyright 2016, the Dart project authors.
- `shelf_static` 1.2.0 (tool) — Copyright 2015, the Dart project authors.
- `shelf_web_socket` 3.0.0 (tool) — Copyright 2014, the Dart project authors.
- `shelf` 1.4.3 (tool) — Copyright 2014, the Dart project authors.
- `source_map_stack_trace` 2.1.2 (tool) — Copyright 2015, the Dart project authors.
- `source_maps` 0.10.14 (tool) — Copyright 2014, the Dart project authors.
- `source_span` 1.10.2 (runtime) — Copyright 2014, the Dart project authors.
- `stack_trace` 1.12.2 (runtime) — Copyright 2014, the Dart project authors.
- `stream_channel` 2.1.4 (runtime) — Copyright 2015, the Dart project authors.
- `string_scanner` 1.4.1 (runtime) — Copyright 2014, the Dart project authors.
- `sync_http` 0.3.1 (tool) — Copyright 2017, the Dart project authors.
- `term_glyph` 1.2.2 (runtime) — Copyright 2017, the Dart project authors.
- `test_api` 0.7.14 (runtime) — Copyright 2018, the Dart project authors.
- `test_core` 0.6.20 (tool) — Copyright 2018, the Dart project authors.
- `test` 1.32.0 (tool) — Copyright 2014, the Dart project authors.
- `typed_data` 1.4.0 (runtime) — Copyright 2015, the Dart project authors.
- `vector_math` 2.4.4 (runtime) — Copyright 2013 The Flutter Authors
- `vm_service` 15.4.0 (runtime) — Copyright 2015, the Dart project authors.
- `watcher` 1.2.1 (tool) — Copyright 2014, the Dart project authors.
- `web_socket_channel` 3.0.3 (tool) — Copyright 2016, the Dart project authors.
- `web_socket` 1.0.1 (tool) — Copyright 2024, the Dart project authors.
- `web` 1.1.2 (runtime) — Copyright 2023, the Dart project authors.
- `webkit_inspection_protocol` 1.2.1 (tool) — Copyright 2013, Google Inc.
- `xdg_directories` 1.1.0 (runtime) — Copyright 2013 The Flutter Authors. All rights reserved.
- `yaml_edit` 2.2.4 (tool) — Copyright 2020, the Dart project authors.

### MIT

- `archive` 4.7.1 (tool) — Copyright (c) 2013-2021 Brendan Duncan.
- `cli_launcher` 0.3.4+1 (tool) — Copyright 2022 Gabriel Terwesten
- `flutter_riverpod` 3.5.0 (runtime) — Copyright (c) 2020 Remi Rousselet
- `image` 4.13.1 (tool) — Copyright (c) 2013-2022 Brendan Duncan.
- `petitparser` 7.1.0 (tool) — Copyright (c) 2006-2026 Lukas Renggli.
- `posix` 6.5.4 (tool) — Copyright (c) 2020 Brett Sutton
- `prompts` 2.0.0 (tool) — Copyright (c) 2018 Tobe O
- `pub_updater` 0.6.0 (tool) — Copyright (c) 2021 Very Good Ventures
- `riverpod` 3.5.0 (runtime) — Copyright (c) 2020 Remi Rousselet
- `state_notifier` 1.0.0 (runtime) — Copyright (c) 2020 Remi Rousselet
- `uuid` 4.6.0 (runtime) — Copyright (c) 2021 Yulian Kuncheff
- `xml` 7.1.0 (tool) — Copyright (c) 2006-2026 Lukas Renggli.
- `yaml` 3.1.4 (runtime) — Copyright (c) 2014, the Dart project authors; Copyright (c) 2006, Kirill Simonov.

### Apache-2.0

- `ansi_styles` 0.3.2+1 (tool) — Copyright 2020 Invertase Limited
- `clock` 1.1.3 (runtime) — none in file
- `conventional_commit` 0.6.1+1 (tool) — Copyright 2020 Invertase Limited
- `fake_async` 1.3.3 (runtime) — none in file
- `material_color_utilities` 0.13.0 (runtime) — Copyright 2021 Google LLC
- `melos` 8.10.1 (tool) — Copyright 2020 Invertase Limited
- `webdriver` 3.2.0 (tool) — Copyright 2013 Google LLC

### BSD-2-Clause

- `mustache_template` 2.0.6 (tool) — Copyright (c) 2013, Greg Lowe

### Two texts in one license file (MIT and a BSD-3-Clause-style text)

- `node_preamble` 2.0.2 (tool) — Copyright (c) 2015 Michael Bullington (MIT) and Copyright 2012, the Dart project authors (BSD-3-Clause-style); the file does not say which part each text covers, so both are recorded.


### SIL Open Font License 1.1 (bundled fonts, assets)

- IBM Plex Sans (4 files) and IBM Plex Sans Hebrew (4 files) — Copyright © 2017 IBM Corp., Reserved Font Name "Plex"; `packages/shared_ui/assets/fonts/ibm-plex-sans/OFL.txt`, `.../ibm-plex-sans-hebrew/OFL.txt`
- Noto Sans Symbols (1 file) and Noto Sans Symbols 2 (1 file) — Copyright 2022 The Noto Project Authors (https://github.com/notofonts/symbols); `.../noto-sans-symbols/OFL.txt`, `.../noto-sans-symbols-2/OFL.txt`
- Noto Sans (1 file) — Copyright 2022 The Noto Project Authors (https://github.com/notofonts/latin-greek-cyrillic); `.../noto-sans/OFL.txt`
- Reference copies of the same families (woff2) under `design-reference/zodiann/assets/fonts/` have no license text beside them (inventory Finding F1).

### Flutter and Dart SDKs

- Flutter SDK 3.50.0 and the `flutter` package — Copyright 2014 The Flutter Authors (BSD-3-Clause, as read).
- Dart SDK 3.14.0 — Copyright 2012, the Dart project authors (BSD-3-Clause, as read).
