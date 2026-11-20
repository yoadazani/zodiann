# ZOD-FND-015: applying the AGPL decision to the repository

> **Status: owner decisions recorded 2026-11-20; legal and technical questions below remain OPEN.** **This is not legal advice.** Nothing here says the project is legally compliant or has been cleared by anyone. A `LICENSE` file does not establish compliance. Facts, technical interpretations and open questions are labelled separately.

## 1. Purpose

ZOD-FND-010 recorded the owner's choice of **Option A, AGPL, for now** for Swiss Ephemeris ([`ZOD-FND-010-swiss-ephemeris-license.md`](ZOD-FND-010-swiss-ephemeris-license.md)). This record applies that choice to the repository: the license text and notices, what the license is and is not applied to, the source-availability and release-tag policy ([`docs/licensing/source-availability-policy.md`](../licensing/source-availability-policy.md)) and the inventory ([`docs/licensing/third-party-inventory.md`](../licensing/third-party-inventory.md)). It does **not** decide the distribution channel (ZOD-REL-003), vendor Swiss Ephemeris (ZOD-FND-003), build the About screen (ZOD-ABT-007), or contact Astrodienst.

## 2. Owner decisions (2026-11-20)

| Id | Decision |
|---|---|
| D1 | **AGPL-3.0** applies to the project-authored groups (a)–(e) and (g): logo, launcher and platform icons; SVG icons and generated icon code; design reference, mockups, kit and documentation; specification files; test fixtures; all other project-authored files. **Not** applied to third-party assets or dependencies, which keep their own licenses and notices. Group (f), the name "Zodiann", is handled separately as a trademark matter. |
| D1 provenance | **Owner statement:** the owner created all of the project's logo, icons, design materials, specifications and translations. The repository documents none of this and it was not independently verified. |
| D2 | **`AGPL-3.0-only`** for Zodiann's own code and assets. This is the owner's choice; it does **not** mean Astrodienst's own terms are clarified (question Q5). |
| D3 | Copyright line: `Copyright (C) 2026 Yoad Azani`. |
| D6 | No trademark statement is added. |
| Identities | Both existing Git author identities belong to the owner; no other contributor is known. |
| AI co-authorship | Recorded as an **open legal question**; it does not change the AGPL-3.0 direction and does not block implementation. |
| `gh` | Read-only `gh` queries on this repository are authorized. |
| D4, D5 | Per-file license headers and an inventory staleness guard are **not** in this task (follow-up proposals; the AGPL's own instructions suggest a notice in each source file, which this task does not add). |

## 3. Sources read

| Source | URL or path | Date | Supports |
|---|---|---|---|
| GNU AGPL v3 text | https://www.gnu.org/licenses/agpl-3.0.txt (`curl`, sha256 `0d96a4ff68ad6d4b6f1f30f713b18d5184912ba8dd389f86aa7710db079abcb0`, 661 lines, ASCII) | 2026-11-20 | `LICENSE`; sections 0, 1, 4, 5, 6, 7, 8, 10, 12, 13 and the "How to Apply" notice |
| Swiss Ephemeris general information | https://www.astro.com/swisseph/swephinfo_e.htm | 2026-11-20 | the vendor's dual-license notice |
| Swiss Ephemeris `LICENSE` and `readme.md` | https://raw.githubusercontent.com/aloistr/swisseph/master/ (FND-010 source S4) | 2026-11-20 | the vendor's notice as shipped with the source |
| Dart pubspec reference | https://dart.dev/tools/pub/pubspec | 2026-11-20 | no `license` field exists in the pubspec format (the only "license" mentions are the site's own) |
| SPDX license texts | https://raw.githubusercontent.com/spdx/license-list-data/main/text/ | 2026-11-20 | reference texts for the inventory |
| Repository, lock file, pub cache, Flutter 3.50.0 and Dart 3.14.0 SDK files, `git`, `gh repo view` (public, no license) | local and `gh` read-only | 2026-11-20 | inventory and repository state |
| ZOD-FND-010 record | [`ZOD-FND-010-swiss-ephemeris-license.md`](ZOD-FND-010-swiss-ephemeris-license.md) | 2026-11-19 | sources S1 to S15 and questions Q1 to Q4 |

## 4. Confirmed facts (read in the sources above)

1. **No license today.** Before this task the repository had no root or package `LICENSE`, `COPYING` or `NOTICE`, and no SPDX or copyright header in tracked Dart source. GitHub reported it public with no license. Every `pubspec.yaml` has `publish_to: none`, and the pubspec format has no license field.
2. **Vendor notice (S1, S4).** Swiss Ephemeris is offered under a dual system: the "GNU Affero General Public License (AGPL)" or the Swiss Ephemeris Professional License. The notice gives **no AGPL version number** and no "only" or "or later" wording; it links the AGPL v3 text. The choice "must be made before the software developer distributes software containing parts of Swiss Ephemeris to others". Choosing the AGPL "includes the obligation to place his or her whole software project under the AGPL or a compatible license". The notice requires "the copyright notices and this notice be preserved on all copies" and forbids using the authors' or Astrodienst's names to promote software that uses it.
3. **AGPL text, as read.** The license is version 3 (section 0). "Convey" excludes mere network interaction without a copy (0). "Corresponding Source" for object code means the source needed to generate, install, run and modify the work, including scripts that control those activities, and excludes System Libraries and "general-purpose tools or generally available free programs which are used unmodified ... but which are not part of the work" (1). Verbatim copies must keep copyright and license notices and give recipients a copy of the license (4). Conveying object code requires the Corresponding Source by one of the routes in 6(a) to (e). 6(a) is a physical medium with the source, 6(b) a written offer valid at least three years and as long as spare parts or support are offered for the physical product, 6(c) occasional noncommercial only, **6(d) offering access from a designated place with equivalent access to the source "through the same place at no further charge", the source possibly on another server with clear directions next to the object code, and "you remain obligated to ensure that it is available for as long as needed to satisfy these requirements"**, 6(e) peer-to-peer. "Installation Information" is required only for a "User Product" conveyed in a transaction transferring possession of that product (6). Additional terms may decline trademark rights (7(e)), limit publicity use of names (7(d)) and require preserved notices (7(b)), under the conditions of section 7. Non-permissive additional terms are further restrictions (7, 10). Violating the license terminates the violator's rights, reinstatement is possible (8). Each recipient automatically receives a license and the licensor may not impose further restrictions (10). Obligations that conflict with the license do not excuse compliance, and if both cannot be met the work may not be conveyed (12). Section 13 applies to a modified version that users interact with remotely over a network; Zodiann has no server today.
4. **"Appropriate Legal Notices" (0).** An interactive user interface "displays Appropriate Legal Notices" if it has a prominent feature that shows a copyright notice, says there is no warranty, says licensees may convey the work under the license, and says how to view a copy of it.
5. **Fonts.** The five bundled font families are under SIL OFL 1.1 (each folder has its `OFL.txt`) and match their recorded SHA-256 values (11 of 11). The OFL text (read in the shipped `OFL.txt`) says the Font Software may be bundled and redistributed with any software if each copy carries the copyright notice and the license, may not be sold by itself, and "must be distributed entirely under this license, and must not be distributed under any other license" (condition 5). The fonts are therefore kept under the OFL and are not relicensed to AGPL.
6. **Dependencies.** All 92 hosted lock entries have a license file in the locked version's cached copy: 70 BSD-3-Clause-family, 13 MIT, 7 Apache-2.0, 1 BSD-2-Clause, and `node_preamble` with two texts (92). Across all 100 lock entries the BSD-3-Clause count is 71 because it includes the SDK package `flutter`. Details and the exact matching rule are in the inventory. Seven of the 100 lock entries are `Unverified`: six SDK packages with no license file of their own, and `sky_engine`, whose file is an aggregate of third-party licenses.
7. **Commits.** 319 commits have two author identities (both the owner's, per the owner); 273 carry an AI co-author trailer (counted with `git log --all` on 2026-11-20).

## 5. Technical interpretations (readings, not legal conclusions)

- **I-1.** The vendor most plausibly means AGPL v3 (it links v3). `AGPL-3.0-only` is the narrower claim the evidence supports, and a copyright holder can probably widen it later but not narrow what has been handed out. *Falsified if* Astrodienst states a different version intent (Q5).
- **I-2.** MIT, BSD-2/3 and Apache-2.0 components can accompany an AGPL project when their notices are kept; they are not relicensed by the root `LICENSE`. This record and the notices say so. *Falsified if* a lawyer finds a conflict for a specific license (Apache-2.0 patent terms, for example, are not analysed here).
- **I-3.** For a downloadable app, route 6(d) (a designated place) is the closest fit; 6(a) to (c) concern physical products or occasional noncommercial use. The policy therefore names a designated place and a retention rule rather than a fixed period, because 6(d) sets none (it says "as long as needed").
- **I-4.** The Flutter SDK, Dart SDK, Melos, FVM, Chrome and Python are "general-purpose tools or generally available free programs used unmodified", so they are probably outside the Corresponding Source. The Flutter framework and engine are compiled into the app and are probably within "libraries ... specifically designed to require", which would put their source in scope. Neither reading was checked with a lawyer (open, Q-L3).
- **I-5.** The "Installation Information" duty applies to physical consumer products conveyed with the software, not to downloaded apps. Platform signing rules that stop recipients from installing modified builds (for example on iOS) are a separate question (Q-L2).
- **I-6.** Because the vendor says the AGPL covers the "whole software project", an asset that ships in the app but is left outside the AGPL grant could matter. D1 puts every project-authored group under the AGPL; the only shipped non-AGPL items are third-party (fonts, dependencies, engine), whose compatibility is the open question Q-L1.
- **I-7.** The 30 woff2 reference fonts and `fonts.css` in `design-reference/` have no license text beside them; the OFL asks for its text to accompany copies. The same families' `OFL.txt` files are in `packages/shared_ui/assets/fonts/`. *Finding F1*; this task adds nothing there (owner choice later: add the texts or remove the copies).
- **I-8.** The About screen (ZOD-ABT-001/007) is the natural place to satisfy "Appropriate Legal Notices" (fact 4), together with the source location; a hand-off, not part of this task.

## 6. Open questions (none is answered here; the executor sends none)

**For Astrodienst (drafted, never sent; the owner may send them):**

- **Q2 (from FND-010).** Are the `.se1` ephemeris data files in the vendor's repository licensed under the same AGPL grant as the C source for a Free Edition user, and may they be bundled in an app package handed to others? (Section 8 of the FND-010 record, as drafted there.)
- **Q4 (from FND-010).** If builds are released under the AGPL now and the Professional License is bought later, are the earlier AGPL releases still validly licensed? (As drafted there.)
- **Q5 (new).** The Swiss Ephemeris notice names the "GNU Affero General Public License (AGPL)" without a version number. Which AGPL version or versions does the grant mean: version 3 only, or version 3 or any later version? We plan to license our own code under `AGPL-3.0-only`; is that consistent with your grant?

**Stays with ZOD-REL-003:** Q3, whether an AGPL app can go to the Apple App Store or Google Play and whether Astrodienst accepts it.

**For a lawyer (or Astrodienst where it concerns their wording):**

- **Q-L1.** Whether non-AGPL third-party material that ships in the app (OFL fonts, permissively licensed dependencies, the engine's bundled components) is consistent with Astrodienst's "whole software project under the AGPL or a compatible license" wording and with the AGPL, including the FreeType Project license text with its GPLv2 combination clause inside the engine's license aggregate.
- **Q-L2.** Whether Apple's and Google's terms, including signing and installation restrictions, are compatible with AGPL distribution (ZOD-REL-003).
- **Q-L3.** Whether the Corresponding Source must include build tooling and the source of third-party libraries compiled into the app (interpretation I-4).
- **Q-L4 (AI co-authorship).** How the AI co-author trailers on 273 commits bear on who holds the copyright to license. **Open; does not block this task** (owner direction).
- **Q-L5.** Whether the owner's statement that they created all design materials, specifications and translations is enough provenance for the AGPL grant to those groups.
- **Q-L6.** Whether the woff2 reference fonts without a license text next to them (F1) need action.

**Technical, unverified:** the Flutter engine's bundled components, the Android build libraries and Gradle, Kotlin and AGP, the iOS system frameworks, and the six SDK packages without a license file are `Unverified` (inventory). Whether `flutter_test` and test-only packages are compiled into a build (the declared graph includes `flutter_test` through `flutter_riverpod`) is `Unverified` until a build exists.

## 7. What this record does not establish

It does not say the project is compliant with the AGPL, with Astrodienst's terms, with any dependency's license or with any store's terms. It does not say the AGPL version Astrodienst means. It does not decide the distribution channel or the final licensing path (ZOD-REL-003 reconfirms them; the README says "for now"). It does not replace a lawyer for the open questions.
