# Source availability and release-tag policy

> **Not legal advice. No compliance or clearance claim.** This is the project's own working policy, written on 2026-11-20 (ZOD-FND-015) to follow the AGPL path chosen in ZOD-FND-010 and applied in [`docs/decisions/ZOD-FND-015-agpl-application.md`](../decisions/ZOD-FND-015-agpl-application.md). It reflects the AGPL v3 text as read on 2026-11-20 and the owner's decisions. It does not say that following it satisfies the AGPL, Astrodienst's terms or any store's terms. The open questions are in the decision record, section 6.

**Scope:** every build of Zodiann that is given to anyone (for example a package for a friend). It does **not** cover store submission (ZOD-REL-003 decides the distribution channel and reconfirms the licensing path first). The AGPL path is "for now".

## 1. The rule: one build, one public tag

1. Every distributed build corresponds to **exactly one public annotated Git tag** of https://github.com/yoadazani/zodiann, created on a commit that is on `main`.
2. A tag is **never moved, deleted or reused for a different source state** once a build from it has left the owner's machine. A fix gets a new tag.
3. Several binaries (Android, iOS, ABI splits, formats) may share one tag **only if** each is built from that tag's clean checkout with the toolchain versions recorded for that tag. A rebuild whose source or build inputs differ gets a new tag.
4. **A build with no tag is not distributed.**
5. Tags are created by the owner; automation or an assistant does not tag without the owner's instruction.
6. **Tag name:** `apps/astro_mobile/pubspec.yaml` has no `version:` today, so the name is the owner's decision until one exists. When the app has a version `X.Y.Z+N`, the tag may carry the build number (written `vX.Y.Z-bN` if `+` is a problem) when the build number changes with the source or build inputs. Setting the version belongs to ZOD-REL-002 or the owner, not to this policy.

7. **What counts as "distributed":** any build given to a person other than the owner, including testers and test-distribution services. A build that only runs on the owner's own devices is not distributed under this policy; if unsure, tag it.
8. **Mistaken or early tags:** a tag created before any build exists, or by mistake, may be deleted or moved **only while no build made from it has left the owner's machine**. Once one has, rule 2 applies.
9. **Protecting tags (recommendation, owner's choice):** enable tag protection or a ruleset on the repository so tags cannot be force-moved or deleted by accident, and keep a second copy of each released tag's source (the source archive attached to the Release, or a mirror), because the repository host is a single point of failure.

## 2. Where the source is

- **Designated place:** the tag page `https://github.com/yoadazani/zodiann/tree/<tag>` (and the repository's archive of that tag). This is the "designated place" idea of AGPL section 6(d) (offering the source from the same kind of place, at no charge, with clear directions next to the build).
- **Directions with every build:** each hand-off (message, release note, file name) states the tag and the URL above, so the recipient does not have to look for it.
- **Release-assets option (a policy option, not a decision about a channel):** attach the build to a GitHub Release created from the same tag, so the build and its source reference sit together. Releases are created by the owner.
- **A public repository alone is not treated as enough.** What the policy relies on is the tag, the directions given with the build, and the retention rule below.

## 3. Retention

AGPL section 6(d), as read, requires the source to remain available "for as long as needed to satisfy these requirements" and sets no fixed period; the three-year period belongs to the written offer for physical products in 6(b). So this policy sets none by assumption either:

- **Until the owner decides a period,** the repository and every tag that a build was made from stay public for as long as anyone who received a build from them may still be using it.
- **Floor until decided:** never before every recipient has confirmed they no longer use the build or have been told in writing that the source will no longer be offered.
- **Retention period: owner decision, not yet made.** Record it here when decided.

If the repository is renamed, made private or deleted, or a tag is moved, that is a breach of this policy. Recovery: restore public access (or republish the repository and tags at a stated place), tell every recipient of the affected builds where the source now is, and record what happened in `docs/PROGRESS.md`.

## 4. What the tag must contain

As read in the AGPL text (section 1, "Corresponding Source": the source needed to generate, install, run and modify the work, including scripts that control those activities, excluding System Libraries and general-purpose tools used unmodified), the tag must carry:

- the source, assets and generated files of the project;
- the build scripts and configuration needed to build: `pubspec.lock`, `.fvmrc`, the Melos configuration in the root `pubspec.yaml`, `apps/astro_mobile/android` and `ios` project files, `native/` sources (once Swiss Ephemeris is vendored), and the generators in `tool/` used for committed generated files;
- `LICENSE`, `THIRD_PARTY_NOTICES.md` and `docs/licensing/third-party-inventory.md` as they stand at that tag;
- a record of the toolchain used (Flutter SDK from `.fvmrc`, the Dart SDK it bundles, Gradle wrapper and plugin versions, Xcode version) in the release note, including inputs fetched at build time that the repository does not pin (the Gradle distribution download, pub packages beyond the hash in `pubspec.lock`, Flutter engine artifacts). Rebuild reproducibility is only partly covered by this record; that limit is stated, not hidden.

**Open, not decided here** (decision record, section 6): whether the source of third-party libraries compiled into the app (the Flutter framework and engine, pub packages pinned by `pubspec.lock`) must also be offered, and whether the tools used unmodified (Flutter SDK, Melos, FVM, Chrome, Python) are outside the Corresponding Source (questions Q-L3, interpretation I-4); platform signing or installation limits on recipients (Q-L2); signing keys are not treated as part of the source (interpretation I-5, since the "Installation Information" duty read in section 6 concerns physical consumer products).

## 5. Per-release checklist

1. The tag exists, is annotated, is on `main` and is public.
2. The build was made from a clean checkout of that tag (no local changes), with the toolchain recorded for that tag.
3. `THIRD_PARTY_NOTICES.md` and the inventory at that tag match `pubspec.lock` (compare the lock's packages with the inventory; the inventory's standing process note applies).
4. The hand-off to the recipient names the tag and the URL (section 2) and says the project is licensed `AGPL-3.0-only` with third-party components under their own licenses.
5. The recipient is not asked to accept any further restriction (AGPL section 10).
6. **Swiss Ephemeris:** present only after ZOD-FND-003 vendored it with its original license and copyright files unchanged. At the time of the first such release, record that the data-file license (Astrodienst Q2) and the AGPL version wording (Q5) are still open unless answered.
7. No store submission under this policy; ZOD-REL-003 decides the channel and reconfirms the path.
8. The version shown in the app, once one exists, is traceable to the tag.

## 6. Hand-offs to other tasks (notes only; no scope or criteria of those tasks are edited here)

- **ZOD-ABT-001 / ZOD-ABT-007:** the About screen is the natural place for the license notice, the "no warranty" statement, how to read the license, and the source location (AGPL section 0, "Appropriate Legal Notices", as read; interpretation I-8), and for the Swiss Ephemeris chip text (ABT-007 already carries a note).
- **ZOD-REL-002:** the build pipeline and the app version that names the tag; ZOD-REL-003 reconfirms the licensing path against the channel.
- **ZOD-FND-004 (CI):** may later add a check that the inventory matches `pubspec.lock`; not part of this task.
