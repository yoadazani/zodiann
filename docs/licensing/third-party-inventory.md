# Third-party inventory and project-owned asset groups

> **Not legal advice. No compliance or clearance claim.** This file records what was read and when. A license listed here is the license text found in the named file, not a legal opinion that it is compatible with anything. Anything not read is marked `Unverified`. Produced by ZOD-FND-015 on **2026-11-20**.

The project's own license is **AGPL-3.0-only** for the project-authored groups (a)–(e) and (g) below (owner decisions D1 and D2, 2026-11-20; see [`docs/decisions/ZOD-FND-015-agpl-application.md`](../decisions/ZOD-FND-015-agpl-application.md)). It is **not** applied to anything in sections 2–5 or 7: those keep their own licenses and notices.

## 1. Method and legend

- **Packages (section 2):** the set is every entry of the root `pubspec.lock` (119 on 2026-11-20 after ZOD-FND-003 added 19: 111 `hosted`, 8 `sdk`, 0 `path`; kinds: 7 `direct dev`, 112 `transitive`, no `direct main` because the root is a pub workspace; `yaml`'s kind was corrected from `transitive` to `direct dev`, it became a root dev dependency in ZOD-FND-004). The 19 rows added by ZOD-FND-003 were read with the same method on 2026-11-20; the word comparison was calibrated on rows already classified (the existing `variant V1` rows score 16 differing words and the existing exact Apache-2.0 row scores 51 under the script used that day, so 16 and 51 are recorded as `variant V1` and `exact`). For each hosted package the `LICENSE` file of the **locked version** in the pub cache (`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\<name>-<version>\`) was read; `pub get` was not run. The lock's recorded `sha256` for the package (first 12 hex digits shown) is the link between the cached copy and the locked version. Nothing was inferred from a package name or publisher.
- **License identification:** reference texts MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, ISC, MPL-2.0, Zlib, Unlicense and OFL-1.1 were fetched from the SPDX license-list-data repository (2026-11-20). Each package license was normalised (copyright lines removed, lowercased, punctuation and whitespace collapsed to words) and compared word by word with the references; the closest reference is listed.
- **Match column:** `exact` = no differing words; `exact, title line differs` = only the heading differs or is absent (for example "The MIT License", or no heading at all); `exact, appendix placeholder kept` = Apache-2.0 plus its unfilled appendix line; `exact, list markers differ` = only bullet numbers differ; **`variant V1`** = BSD-3-Clause text with the same wording except (i) bullets instead of numbers, (ii) "Google LLC" or "Google Inc." in the non-endorsement clause where the SPDX text says "the copyright holder", and (iii) "copyright owner" for "copyright holder" in the disclaimer (10 differing words in every case, as computed on 2026-11-20 by the method above). **V1 is a textual variant of BSD-3-Clause, so the exact SPDX id is an interpretation of a near-exact match, not an exact match.**
- **Scope:** `runtime closure` = reachable from `apps/astro_mobile` through the declared dependency graph (`fvm dart pub deps --json`, read-only, 2026-11-20): 49 packages (44 hosted, 5 sdk) after ZOD-FND-003 (`apps/astro_mobile` now depends on `ephemeris_swiss`, whose build-hook packages `hooks`, `code_assets`, `native_toolchain_c`, `record_use` and their dependencies `file`, `glob`, `platform`, `process`, `pub_semver`, `yaml`, `ffi` joined the closure; the closure is computed from `directDependencies` only). The graph includes `flutter_test` because `flutter_riverpod` declares it as a dependency; **whether it is compiled into a build is `Unverified`** (tree shaking). `dev/test/tool only` = not in that closure. Whether tool-only packages fall under the AGPL's Corresponding Source is an **open question** (decision record).
- **Reading the Scope column:** `crypto` is a root `direct dev` dependency of the workspace but is in the app's runtime closure because `uuid` (a runtime dependency of `riverpod`) depends on it; the Lock kind column describes the root workspace, the Scope column the app's graph.
- **Caveat on all rows:** a package's `LICENSE` file is the license it states for itself. It says nothing about code inside it that came from elsewhere, and this audit did not read package source.

## 2. Dart and Flutter packages (all 119 lock entries)

| Package | Version | Source | Lock kind | Scope | License (as read) | Match | Copyright line (first, as read) | Verification source | Date |
|---|---|---|---|---|---|---|---|---|---|
| _fe_analyzer_shared | 111.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2019, the Dart project authors. | pub-cache LICENSE; lock sha256 `1c5591cc6f2…` | 2026-11-20 |
| analyzer | 14.7.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013, the Dart project authors. | pub-cache LICENSE; lock sha256 `6c39bd5486a…` | 2026-11-20 |
| ansi_styles | 0.3.2+1 | hosted | transitive | dev/test/tool only | Apache-2.0 | exact, appendix placeholder kept | Copyright 2020 Invertase Limited | pub-cache LICENSE; lock sha256 `9c656cc12b3…` | 2026-11-20 |
| archive | 4.7.1 | hosted | transitive | dev/test/tool only | MIT | exact, title line differs | Copyright (c) 2013-2021 Brendan Duncan. | pub-cache LICENSE; lock sha256 `2fda90592c0…` | 2026-11-20 |
| args | 2.7.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013, the Dart project authors.  | pub-cache LICENSE; lock sha256 `d0481093c50b…` | 2026-11-20 |
| async | 2.13.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `e2eb0491ba5d…` | 2026-11-20 |
| boolean_selector | 2.1.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2016, the Dart project authors. | pub-cache LICENSE; lock sha256 `8aab1771e12…` | 2026-11-20 |
| characters | 1.4.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2019, the Dart project authors.  | pub-cache LICENSE; lock sha256 `faf38497bda5…` | 2026-11-20 |
| charcode | 1.4.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. All rights reserved. | pub-cache LICENSE; lock sha256 `fb0f1107cac1…` | 2026-11-20 |
| checked_yaml | 2.0.4 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2019, the Dart project authors. All rights reserved. | pub-cache LICENSE; lock sha256 `959525d3162…` | 2026-11-20 |
| cli_config | 0.2.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2023, the Dart project authors. | pub-cache LICENSE; lock sha256 `ac20a183a070…` | 2026-11-20 |
| cli_launcher | 0.3.4+1 | hosted | transitive | dev/test/tool only | MIT | exact, title line differs | Copyright 2022 Gabriel Terwesten | pub-cache LICENSE; lock sha256 `ff37bcc6d5fa…` | 2026-11-20 |
| cli_util | 0.6.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `89b8801ba49…` | 2026-11-20 |
| clock | 1.1.3 | hosted | transitive | runtime closure | Apache-2.0 | exact | none in file | pub-cache LICENSE; lock sha256 `e51d50bca321…` | 2026-11-20 |
| code_assets | 2.2.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2025, the Dart project authors. | pub-cache LICENSE; lock sha256 `1ef22a0be3af…` | 2026-11-20 |
| collection | 1.19.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `2f5709ae4d3…` | 2026-11-20 |
| conventional_commit | 0.6.1+1 | hosted | transitive | dev/test/tool only | Apache-2.0 | exact, appendix placeholder kept | Copyright 2020 Invertase Limited | pub-cache LICENSE; lock sha256 `c40b1b449ce2…` | 2026-11-20 |
| convert | 3.1.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors. | pub-cache LICENSE; lock sha256 `b30acd594403…` | 2026-11-20 |
| coverage | 1.16.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `ff89e37c1935…` | 2026-11-20 |
| crypto | 3.0.8 | hosted | direct dev | runtime closure | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors. | pub-cache LICENSE; lock sha256 `e3626ae62703…` | 2026-11-20 |
| cupertino_ui | 1.1.6 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `369e39a1c5c…` | 2026-11-20 |
| dart_style | 3.1.14 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `a0e4f65339b3…` | 2026-11-20 |
| fake_async | 1.3.3 | hosted | transitive | runtime closure | Apache-2.0 | exact | none in file | pub-cache LICENSE; lock sha256 `5368f224a74…` | 2026-11-20 |
| ffi | 2.2.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2019, the Dart project authors.  | pub-cache LICENSE; lock sha256 `6d7fd894312…` | 2026-11-20 |
| ffigen | 23.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1, plus one appended paragraph: "Code generated by FFIgen is owned by the owner of the input file used when generating it." | Copyright 2020, the Dart project authors. | pub-cache LICENSE; lock sha256 `6f55d99ac185…` | 2026-11-20 |
| file | 7.0.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors. All rights reserved. | pub-cache LICENSE; lock sha256 `a3b4f84adafe…` | 2026-11-20 |
| fixnum | 1.1.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `b6dc7065e46c…` | 2026-11-20 |
| flutter | 0.0.0 | sdk | transitive | runtime closure | BSD-3-Clause | exact modulo V1 differences | Copyright 2014 The Flutter Authors | `packages/flutter/LICENSE` (Flutter 3.50.0) | 2026-11-20 |
| flutter_driver | 0.0.0 | sdk | transitive | dev/test/tool only | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| flutter_lints | 6.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors. All rights reserved. | pub-cache LICENSE; lock sha256 `3105dc8492f…` | 2026-11-20 |
| flutter_localizations | 0.0.0 | sdk | transitive | runtime closure | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| flutter_riverpod | 3.5.0 | hosted | transitive | runtime closure | MIT | exact | Copyright (c) 2020 Remi Rousselet | pub-cache LICENSE; lock sha256 `2ae1a93a868…` | 2026-11-20 |
| flutter_test | 0.0.0 | sdk | transitive | runtime closure | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| flutter_web_plugins | 0.0.0 | sdk | transitive | runtime closure | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| frontend_server_client | 4.2.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2012, the Dart project authors. | pub-cache LICENSE; lock sha256 `2b56423afc7…` | 2026-11-20 |
| fuchsia_remote_debug_protocol | 0.0.0 | sdk | transitive | dev/test/tool only | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| glob | 2.2.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `218aeb56050…` | 2026-11-20 |
| go_router | 18.1.4 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `d4105f50c438…` | 2026-11-20 |
| graphs | 2.3.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors.  | pub-cache LICENSE; lock sha256 `741bbf84165…` | 2026-11-20 |
| hooks | 2.2.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2025, the Dart project authors. | pub-cache LICENSE; lock sha256 `eaac480a35ec…` | 2026-11-20 |
| http | 1.6.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `87721a4a50b…` | 2026-11-20 |
| http_multi_server | 3.2.3 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `361668bdd71…` | 2026-11-20 |
| http_parser | 4.1.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `178d74305e7…` | 2026-11-20 |
| image | 4.13.1 | hosted | direct dev | dev/test/tool only | MIT | exact, title line differs | Copyright (c) 2013-2022 Brendan Duncan. | pub-cache LICENSE; lock sha256 `bc13f61f0f5c…` | 2026-11-20 |
| integration_test | 0.0.0 | sdk | transitive | dev/test/tool only | Unverified | no license file of its own in the package; SDK repository root LICENSE is BSD-3-Clause (interpretation: likely the covering text) | - | package directory has no LICENSE; SDK root `LICENSE` read | 2026-11-20 |
| intl | 0.20.3 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013, the Dart project authors. | pub-cache LICENSE; lock sha256 `1ca20c894b1…` | 2026-11-20 |
| io | 1.1.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors.  | pub-cache LICENSE; lock sha256 `2635216ca6a…` | 2026-11-20 |
| jni | 1.2.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2022, the Dart project authors. | pub-cache LICENSE; lock sha256 `19764f78f6b9…` | 2026-11-20 |
| jni_flutter | 1.1.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2026, the Dart project authors. | pub-cache LICENSE; lock sha256 `586594ad345b…` | 2026-11-20 |
| jni_util | 1.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2026, the Dart project authors. | pub-cache LICENSE; lock sha256 `1ba86da04a5f…` | 2026-11-20 |
| json_annotation | 4.12.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors. All rights reserved. | pub-cache LICENSE; lock sha256 `2a743920d81…` | 2026-11-20 |
| leak_tracker | 11.0.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2022, the Dart project authors. | pub-cache LICENSE; lock sha256 `33e2e26bdd8…` | 2026-11-20 |
| leak_tracker_flutter_testing | 3.0.10 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2022, the Dart project authors. | pub-cache LICENSE; lock sha256 `1dbc140bb5a…` | 2026-11-20 |
| leak_tracker_testing | 3.0.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2022, the Dart project authors. | pub-cache LICENSE; lock sha256 `8d5a2d49f4a…` | 2026-11-20 |
| lints | 6.1.0 | hosted | direct dev | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2021, the Dart project authors. | pub-cache LICENSE; lock sha256 `12f842a4795…` | 2026-11-20 |
| listen | 1.0.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `47501a08016…` | 2026-11-20 |
| logging | 1.3.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013, the Dart project authors.  | pub-cache LICENSE; lock sha256 `c8245ada5f17…` | 2026-11-20 |
| matcher | 0.12.20 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `31bd099b47c…` | 2026-11-20 |
| material_color_utilities | 0.13.0 | hosted | transitive | runtime closure | Apache-2.0 | exact, appendix placeholder kept | Copyright 2021 Google LLC | pub-cache LICENSE; lock sha256 `9c337007e82…` | 2026-11-20 |
| material_ui | 1.11.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `474c135fd46…` | 2026-11-20 |
| melos | 8.10.1 | hosted | direct dev | dev/test/tool only | Apache-2.0 | exact, appendix placeholder kept | Copyright 2020 Invertase Limited | pub-cache LICENSE; lock sha256 `d0d9f8b8d566…` | 2026-11-20 |
| meta | 1.19.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2016, the Dart project authors. | pub-cache LICENSE; lock sha256 `307249ce4ff…` | 2026-11-20 |
| mime | 2.1.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `bd47de35f07e…` | 2026-11-20 |
| mustache_template | 2.0.6 | hosted | transitive | dev/test/tool only | BSD-2-Clause | exact, list markers differ | Copyright (c) 2013, Greg Lowe | pub-cache LICENSE; lock sha256 `17a8de90725…` | 2026-11-20 |
| native_toolchain_c | 0.19.6 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2023, the Dart project authors. | pub-cache LICENSE; lock sha256 `120b6fc66acd…` | 2026-11-20 |
| node_preamble | 2.0.2 | hosted | transitive | dev/test/tool only | MIT + BSD-3-Clause-style (two texts in one file) | read: two texts | Copyright (c) 2015 Michael Bullington | pub-cache LICENSE; lock sha256 `6e7eac89047…` | 2026-11-20 |
| objective_c | 9.6.4 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2024, the Dart project authors. | pub-cache LICENSE; lock sha256 `c965d264fd4b…` | 2026-11-20 |
| package_config | 3.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2019, the Dart project authors.  | pub-cache LICENSE; lock sha256 `ffcf4cf3d6c0…` | 2026-11-20 |
| path | 1.9.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `75cca69d149…` | 2026-11-20 |
| path_provider | 2.1.6 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `a7f4874f9871…` | 2026-11-20 |
| path_provider_android | 2.3.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `69cbd515a62b…` | 2026-11-20 |
| path_provider_foundation | 2.6.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `2a376b7d6392…` | 2026-11-20 |
| path_provider_linux | 2.2.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `58c2005f1473…` | 2026-11-20 |
| path_provider_platform_interface | 2.1.3 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `484838772624…` | 2026-11-20 |
| path_provider_windows | 2.3.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors. All rights reserved. | pub-cache LICENSE; lock sha256 `bd6f00dbd873…` | 2026-11-20 |
| petitparser | 7.1.0 | hosted | transitive | dev/test/tool only | MIT | exact, title line differs | Copyright (c) 2006-2026 Lukas Renggli. | pub-cache LICENSE; lock sha256 `2f1564aadb1…` | 2026-11-20 |
| platform | 3.1.6 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors. All rights reserved. | pub-cache LICENSE; lock sha256 `5d6b1b0036a…` | 2026-11-20 |
| plugin_platform_interface | 2.1.8 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors. All rights reserved. | pub-cache LICENSE; lock sha256 `4820fbfdb947…` | 2026-11-20 |
| pool | 1.5.3 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `4177f68c237…` | 2026-11-20 |
| posix | 6.5.4 | hosted | transitive | dev/test/tool only | MIT | exact | Copyright (c) 2020 Brett Sutton | pub-cache LICENSE; lock sha256 `613646d0769…` | 2026-11-20 |
| process | 5.0.6 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013, the Dart project authors. | pub-cache LICENSE; lock sha256 `4242ba3508d…` | 2026-11-20 |
| prompts | 2.0.0 | hosted | transitive | dev/test/tool only | MIT | exact | Copyright (c) 2018 Tobe O | pub-cache LICENSE; lock sha256 `3773b845e85…` | 2026-11-20 |
| pub_semver | 2.2.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `261236774e8…` | 2026-11-20 |
| pub_updater | 0.6.0 | hosted | transitive | dev/test/tool only | MIT | exact | Copyright (c) 2021 Very Good Ventures | pub-cache LICENSE; lock sha256 `3aadeb8c68d…` | 2026-11-20 |
| pubspec_parse | 1.7.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2018, the Dart project authors. | pub-cache LICENSE; lock sha256 `9ac81c01ffd…` | 2026-11-20 |
| quiver | 3.2.2 | hosted | transitive | dev/test/tool only | Apache-2.0 | exact | none in file | pub-cache LICENSE; lock sha256 `ea0b925899e6…` | 2026-11-20 |
| record_use | 1.1.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2024, the Dart project authors. | pub-cache LICENSE; lock sha256 `1cb8564af8d4…` | 2026-11-20 |
| riverpod | 3.5.0 | hosted | transitive | runtime closure | MIT | exact | Copyright (c) 2020 Remi Rousselet | pub-cache LICENSE; lock sha256 `24cbce92e87…` | 2026-11-20 |
| shelf | 1.4.3 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `e75e9cf311d7…` | 2026-11-20 |
| shelf_packages_handler | 3.0.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2016, the Dart project authors. | pub-cache LICENSE; lock sha256 `89f967eca29…` | 2026-11-20 |
| shelf_static | 1.2.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors. | pub-cache LICENSE; lock sha256 `480504af9e5…` | 2026-11-20 |
| shelf_web_socket | 3.0.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `3632775c8e9…` | 2026-11-20 |
| sky_engine | 0.0.0 | sdk | transitive | runtime closure | Unverified (aggregate of third-party licenses, see section 4) | aggregate file | (many) | `bin/cache/pkg/sky_engine/license` | 2026-11-20 |
| source_map_stack_trace | 2.1.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors. | pub-cache LICENSE; lock sha256 `c0713a43e323…` | 2026-11-20 |
| source_maps | 0.10.14 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `14c29458476…` | 2026-11-20 |
| source_span | 1.10.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `56a02f1f4cd…` | 2026-11-20 |
| stack_trace | 1.12.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors. | pub-cache LICENSE; lock sha256 `277654b3034…` | 2026-11-20 |
| state_notifier | 1.0.0 | hosted | transitive | runtime closure | MIT | exact | Copyright (c) 2020 Remi Rousselet | pub-cache LICENSE; lock sha256 `b8677376aa54…` | 2026-11-20 |
| stream_channel | 2.1.4 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `969e04c80b8…` | 2026-11-20 |
| string_scanner | 1.4.1 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `921cd31725b…` | 2026-11-20 |
| sync_http | 0.3.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors. | pub-cache LICENSE; lock sha256 `7f0cd72eca0…` | 2026-11-20 |
| term_glyph | 1.2.2 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2017, the Dart project authors.  | pub-cache LICENSE; lock sha256 `7f554798625…` | 2026-11-20 |
| test | 1.32.0 | hosted | direct dev | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `de5d145b0aff…` | 2026-11-20 |
| test_api | 0.7.14 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2018, the Dart project authors.  | pub-cache LICENSE; lock sha256 `0a10344e901…` | 2026-11-20 |
| test_core | 0.6.20 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2018, the Dart project authors.  | pub-cache LICENSE; lock sha256 `80f3fb49087…` | 2026-11-20 |
| typed_data | 1.4.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors.  | pub-cache LICENSE; lock sha256 `f9049c039ebf…` | 2026-11-20 |
| uuid | 4.6.0 | hosted | transitive | runtime closure | MIT | exact, no title line in the file | Copyright (c) 2021 Yulian Kuncheff | pub-cache LICENSE; lock sha256 `9b129329f58…` | 2026-11-20 |
| vector_math | 2.4.4 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors | pub-cache LICENSE; lock sha256 `fa49e1674cb8…` | 2026-11-20 |
| vm_service | 15.4.0 | hosted | transitive | runtime closure | BSD-3-Clause | variant V1 | Copyright 2015, the Dart project authors. | pub-cache LICENSE; lock sha256 `89b11d62e10…` | 2026-11-20 |
| watcher | 1.2.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2014, the Dart project authors.  | pub-cache LICENSE; lock sha256 `1398c9f081a…` | 2026-11-20 |
| web | 1.1.2 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2023, the Dart project authors. | pub-cache LICENSE; lock sha256 `e119e82ac479…` | 2026-11-20 |
| web_socket | 1.0.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2024, the Dart project authors.  | pub-cache LICENSE; lock sha256 `34d64019aa8…` | 2026-11-20 |
| web_socket_channel | 3.0.3 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2016, the Dart project authors.  | pub-cache LICENSE; lock sha256 `d645757fb0f4…` | 2026-11-20 |
| webdriver | 3.2.0 | hosted | transitive | dev/test/tool only | Apache-2.0 | exact, appendix placeholder kept | Copyright 2013 Google LLC | pub-cache LICENSE; lock sha256 `28b82ec894f…` | 2026-11-20 |
| webkit_inspection_protocol | 1.2.1 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013, Google Inc. | pub-cache LICENSE; lock sha256 `87d3f2333bb…` | 2026-11-20 |
| xdg_directories | 1.1.0 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2013 The Flutter Authors. All rights reserved. | pub-cache LICENSE; lock sha256 `7a3f37b05d98…` | 2026-11-20 |
| xml | 7.1.0 | hosted | direct dev | dev/test/tool only | MIT | exact, title line differs | Copyright (c) 2006-2026 Lukas Renggli. | pub-cache LICENSE; lock sha256 `0fe8cc98946…` | 2026-11-20 |
| yaml | 3.1.4 | hosted | direct dev | runtime closure | MIT | exact, title line differs | Copyright (c) 2014, the Dart project authors.; second line: Copyright (c) 2006, Kirill Simonov. | pub-cache LICENSE; lock sha256 `f67cdd8e07d3…` | 2026-11-20 |
| yaml_edit | 2.2.4 | hosted | transitive | dev/test/tool only | BSD-3-Clause | variant V1 | Copyright 2020, the Dart project authors. | pub-cache LICENSE; lock sha256 `07c9e63ba42…` | 2026-11-20 |

**Summary of section 2 (100 lock entries):** BSD-3-Clause 71 (70 hosted as variant V1, plus `flutter`); MIT 13; Apache-2.0 7; BSD-2-Clause 1; `node_preamble` 1 (two texts in one file: MIT by its author and a BSD-3-Clause-style text by the Dart project authors; which part each covers is not stated, so both are recorded); **`Unverified` 7** (six SDK packages with no license file of their own: `flutter_driver`, `flutter_localizations`, `flutter_test`, `flutter_web_plugins`, `fuchsia_remote_debug_protocol`, `integration_test`; and `sky_engine`, whose file is an aggregate of third-party licenses, section 4). Interpretation for the six: the Flutter SDK repository `LICENSE` (BSD-3-Clause, read) is the likely covering text, but no file inside those packages says so.

## 3. Project members (project-authored, not in the lock)

`zodiann_workspace` (root), `apps/astro_mobile`, `packages/astro_core`, `packages/ephemeris_swiss`, `packages/ephemeris_astronomy`, `packages/gann_core`, `packages/feature_wheel`, `packages/feature_square`, `packages/shared_ui`, `packages/shared_storage`, `packages/shared_export_xlsx` (11). All have `publish_to: none`. Project-authored: group (g), AGPL-3.0-only.

## 4. SDKs, engine, platform, native and tooling

| Component | What it is here | License (as read) | Verification source | Date | Status |
|---|---|---|---|---|---|
| Flutter SDK 3.50.0 (framework and tools) | pinned by `.fvmrc` | BSD-3-Clause (V1 wording, "The Flutter Authors") | `LICENSE` at the SDK root and `packages/flutter/LICENSE` (identical, sha256 `a3a9fd82f800…`) | 2026-11-20 | read |
| Dart SDK 3.14.0 | compiler, VM, core libraries | BSD-3-Clause (V1 wording, "the Dart project authors") | `bin/cache/dart-sdk/LICENSE` (sha256 `2cfa3ee8e751…`) | 2026-11-20 | read |
| Flutter engine third-party components | libraries compiled into every Flutter build (graphics, text, fonts and others) | **Unverified** individually. The SDK ships one aggregate file of 1,331,982 bytes with many separate license texts, including the FreeType Project license text, which contains a clause about combining with GPLv2 software | `bin/cache/pkg/sky_engine/license` (sha256 `0d5050142d6b…`) | 2026-11-20 | `Unverified`; verify per build (ZOD-ABT-007, ZOD-REL-002) |
| Flutter embedder, Android embedding, AndroidX and Kotlin runtime libraries | linked into the Android build | `Unverified` (not read) | none | - | `Unverified` |
| Android build tooling: Android Gradle Plugin 9.3.1, Kotlin Gradle plugin 2.4.20, Flutter plugin loader 1.0.0, Gradle 9.5.0 (downloaded at build) | `android/settings.gradle.kts`, `gradle-wrapper.properties` | `Unverified` (not read) | the tracked Gradle files only name them | 2026-11-20 | `Unverified` |
| Android SDK and platform | `compileSdk` from Flutter | `Unverified` (not read) | none | - | `Unverified` |
| iOS build (Xcode project, Swift and system frameworks) | `apps/astro_mobile/ios`, no `Podfile`, no CocoaPods | system components; the Xcode license was not read; Apple's own terms are an **open** store question | none | - | `Unverified` |
| Native plugins in hosted packages | any `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `src/` or `ffi/` directory in the 92 cached packages that were in the lock on 2026-11-20 | none found | directory check of the cached copies | 2026-11-20 | checked |
| Native plugins in the 19 packages added by ZOD-FND-003 | the same directory check | `jni` 1.2.1 (`android/`, `linux/`, `windows/`, `src/`), `jni_flutter` 1.1.0 (`android/`), `objective_c` 9.6.4 (`src/`): all three are `dev/test/tool only` (pulled in by the integration-test helper `path_provider`, a dev dependency of `astro_mobile`); their native code was not read | directory check of the cached copies | 2026-11-20 | checked; code `Unverified` |
| Swiss Ephemeris source | **vendored by ZOD-FND-003 (2026-11-20), unmodified:** tag `v2.10.3bfinal`, commit `f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0`, nine library sources, headers and the upstream licence and copyright files under `native/swisseph/upstream/`, the data files `sepl_18.se1` and `semo_18.se1` under `packages/ephemeris_swiss/assets/ephe/` (spike subset, 1800 to 2400); per-file upstream git blob ids and SHA-256 in `native/swisseph/MANIFEST.json`, origin and omissions in `native/swisseph/VENDORED.md`, checked on every test run by `test/architecture/swisseph_vendored_test.dart`. Upstream `LICENSE.TXT` is a symlink to `LICENSE`, vendored as a 7-byte file. Built for Android only (the iOS half is pending). | the vendor's notice, read 2026-11-20, names "GNU Affero General Public License (AGPL)" with **no version number** and a Professional License option, requires its copyright and notice kept on all copies, and forbids using the authors' or Astrodienst's names to promote software that uses it | FND-010 sources S1 (astro.com, general information) and S4 (the repository `LICENSE`, sha256 `b6345743292c…`) | 2026-11-20 | files verified byte for byte against the upstream tree; licence status stays `Unverified` for the open questions: AGPL version wording (Q5) and the data-file license (Q2) |
| Swiss Ephemeris data files `.se1` (reserved row) | not in the repository | whether the AGPL grant covers them is open question Q2 | FND-010 record | 2026-11-19 | `Unverified` |
| astronomy-engine (reserved row) | not a dependency (ZOD-EPH-004 spike); `native/astronomy_c` holds only a README | MIT per the FND-010 record (its README read 2026-11-19) | FND-010 source S11 | 2026-11-19 | not in repo |
| drift (reserved row) | not a dependency yet (ZOD-FND-006) | not read | none | - | `Unverified` |
| Tooling not distributed: FVM, headless Chrome (used by `tool/wheel`), Python (`design-reference/.../getfonts.py`) | developer tools | `Unverified` (not read) | none | - | `Unverified`; status under the Corresponding Source is an open question |

## 5. Fonts

| Family | Files | License | Copyright (as read in `OFL.txt`) | Reserved Font Name | Verification | Date |
|---|---|---|---|---|---|---|
| IBM Plex Sans | 4 TTF in `packages/shared_ui/assets/fonts/ibm-plex-sans/` | SIL OFL 1.1 | Copyright © 2017 IBM Corp. | "Plex" | `OFL.txt` in the folder; SHA-256 of the TTFs match `SOURCES.md` | 2026-11-20 |
| IBM Plex Sans Hebrew | 4 TTF in `.../ibm-plex-sans-hebrew/` | SIL OFL 1.1 | Copyright © 2017 IBM Corp. | "Plex" | same | 2026-11-20 |
| Noto Sans Symbols | 1 TTF in `.../noto-sans-symbols/` | SIL OFL 1.1 | Copyright 2022 The Noto Project Authors | named in the OFL file | same | 2026-11-20 |
| Noto Sans Symbols 2 | 1 TTF in `.../noto-sans-symbols-2/` | SIL OFL 1.1 | Copyright 2022 The Noto Project Authors | named in the OFL file | same | 2026-11-20 |
| Noto Sans | 1 TTF in `.../noto-sans/` | SIL OFL 1.1 | Copyright 2022 The Noto Project Authors | named in the OFL file | same | 2026-11-20 |
| Reference copies (IBM Plex Sans, Plex Sans Hebrew, Noto Sans Symbols and Symbols 2) | 30 woff2 files and `fonts.css` in `design-reference/zodiann/assets/fonts/` | **no license text stored next to them**; the script that fetched them (`_source/render/getfonts.py`) takes them from the Google Fonts CSS API, and the same families are OFL in the bundled folders above (interpretation: same license) | provenance from `getfonts.py` and `fonts.css`; not shipped by any `pubspec.yaml` | 2026-11-20 | **Finding F1** below |

Eleven of eleven TTF files match the SHA-256 values in `packages/shared_ui/assets/fonts/SOURCES.md` (checked 2026-11-20). The five fonts are unmodified copies of official releases and stay under the OFL; the AGPL is not applied to them. OFL condition 5 requires the Font Software to be distributed entirely under the OFL and under no other license; the fonts are therefore not relicensed. Whether OFL fonts inside an AGPL application raise a compatibility question is an **open legal question**.

## 6. Project-owned asset groups and the owner's decision

Decision (D1, 2026-11-20): **AGPL-3.0 for (a)–(e) and (g)**; **(f), the name "Zodiann", is a trademark matter handled separately**, with no trademark statement (D6). Provenance is the **owner's statement** (the owner created the logo, icons, design materials, specifications and translations); the repository itself documents none of it. Counts are tracked files on 2026-11-20 (801 tracked in all).

| Group | What | Files (tracked) | License | Notes |
|---|---|---|---|---|
| (a) | logo set, launcher icons, platform icon and launch-image files: `packages/shared_ui/assets/logo`, `assets/app-logo.png`, `design-reference/zodiann/assets/zodiann-logo*`, iOS `AppIcon.appiconset` and `LaunchImage.imageset`, Android `res/` | 44 images | AGPL-3.0 (project license: AGPL-3.0-only) | owner-created (statement) |
| (b) | 33 SVG icons (`design-reference/zodiann/assets/icons`), the generated Dart drawing code (`packages/shared_ui/lib/src/icons/zodiann_icons.g.dart` and its two companions) and the generator (`tool/icons`) | 33 SVG + 3 Dart + tool files | AGPL-3.0 | generated code follows its source |
| (c) | design reference: screens, responsive mockups, the HTML kit (`_source/kit.css`, `kit.js`, `render/*`) and write-ups (`MASTER.md`, `README.md`, `DESIGN_DECISIONS.md`), excluding the icons, fonts and logos listed elsewhere | 66 | AGPL-3.0 | the kit describes itself as disposable rendering helpers |
| (d) | specification files: `assets/zodiann-specification.md` and the PDF | 2 | AGPL-3.0 | |
| (e) | test fixture PNGs and data under `packages/*/test/fixtures`; rendered from the kit or the designer images | 44 | AGPL-3.0 | follow (c) |
| (f) | the name "Zodiann" | - | not a copyright-license grant; no trademark statement (D6) | handled separately |
| (g) | all other project-authored files: Dart source, ARB translations (including the Hebrew text), `tool/` scripts, `docs/`, tests, task files, plans, PROGRESS | the remainder (about 564 of 801) | AGPL-3.0 | |

## 7. Third-party material inside the project's tree (carved out of the AGPL grant)

- `packages/shared_ui/assets/fonts/**` (17 files: 11 TTF, 5 `OFL.txt`, `SOURCES.md`): OFL-1.1, section 5. (`SOURCES.md` is project-authored documentation.)
- `design-reference/zodiann/assets/fonts/**` (31 files): third-party fonts under the OFL by interpretation, section 5, Finding F1.
- `pubspec.lock` entries (section 2) are not vendored; they are fetched at build time and keep their licenses.
- No other third-party file was found in groups (a)–(g): `design-reference/` and `tool/` were searched for license, SPDX and `@license` markers (none) and the group contents were read by path; this is a search, not proof that no third-party material exists. The owner states they created the rest.

## 8. Findings and open items (detail in the decision record)

- **F1 (finding, not fixed here):** the 30 woff2 reference fonts and `fonts.css` under `design-reference/zodiann/assets/fonts/` have no license text beside them, while the OFL asks for its text to accompany copies (interpretation of the OFL; not verified against a lawyer). The same families' `OFL.txt` files are in `packages/shared_ui/assets/fonts/`. Options for the owner (not decided): add the texts, or remove the copies from the repository. This task changes no asset file.
- **F2:** the Swiss Ephemeris vendor notice names no AGPL version (Q5) and forbids promotional use of the authors' names.
- `Unverified` entries: 7 in section 2, and the engine components, Android and iOS build, tooling and reserved rows in section 4.

**Standing process note:** a dependency or asset added later must be added to this file, and [ZOD-ABT-007](../development/about/ZOD-ABT-007-build-the-open-source-licenses-list.md) follows it. A staleness guard (a check that fails when `pubspec.lock` changes without an update here) is a follow-up proposal for ZOD-FND-004 or ZOD-ABT-007, not part of this task.
