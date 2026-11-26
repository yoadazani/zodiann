# Vendored Swiss Ephemeris

Added by ZOD-FND-003 (2026-11-20). Everything under `upstream/` and the two `.se1` data files under `packages/ephemeris_swiss/assets/ephe/` are **byte-for-byte copies** of the upstream files. Nothing in them was edited, reformatted or re-line-ended. `test/architecture/swisseph_vendored_test.dart` checks every file against `MANIFEST.json` on each test run.

## Origin

| | |
|---|---|
| Repository | https://github.com/aloistr/swisseph (Astrodienst AG) |
| Tag | `v2.10.3bfinal` (published 2026-08-02) |
| Commit | `f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0` |
| Retrieved | 2026-11-20, from the git blob of each file (`gh api repos/aloistr/swisseph/git/blobs/<sha>`), not from a working tree |
| License | AGPL-3.0 or the Swiss Ephemeris Professional License; the owner's choice is the AGPL path (`docs/decisions/ZOD-FND-010-swiss-ephemeris-license.md`, applied in ZOD-FND-015). The upstream `LICENSE`, `agpl-3.0.txt` and `readme.md` are vendored unchanged. The vendor's notice names no AGPL version (open question Q5) and the data-file position is open (Q2). |

## What is vendored

- `upstream/`: the nine library sources named by the upstream `Makefile` (`SWEOBJ = swedate swehouse swejpl swemmoon swemplan sweph swephlib swecl swehel`), their headers (`swedate.h swehouse.h swejpl.h swemptab.h swenut2000a.h sweodef.h sweph.h swephexp.h swephlib.h swedll.h`), and `LICENSE`, `LICENSE.TXT`, `agpl-3.0.txt`, `readme.md`, `Makefile`, `seleapsec.txt`.
- `packages/ephemeris_swiss/assets/ephe/sepl_18.se1` (planets) and `semo_18.se1` (Moon): the pair ZOD-FND-011 chose (nominally 1800 to 2400; ZOD-EPH-002 measured 1800-01-03 to 2400-01-06 for all ten bodies). The data files live in the package because Flutter bundles only assets declared inside a package (decision D2 of the plan).
- **Upstream `LICENSE.TXT` is a symlink** (git mode `120000`) whose target is `LICENSE`. It is vendored as a regular 7-byte file containing the text `LICENSE`; its git blob id equals the upstream blob id. Its SHA-256 differs from `LICENSE`'s, so the manifest lists both.

## Not vendored (not modified, simply not copied)

`swetest.c`, `swemini.c`, `swevents.c`, `swevents.h`, `sweephe4.c`, `sweephe4.h`, `swephgen4.c`, `obama.c`, `swein600.jpg`, upstream's `.gitattributes`, the directories `doc/`, `bin/`, `contrib/`, `setest/`, `windows/`, and every other file in `ephe/`.

## Project-authored files, not vendored

`zodiann_swiss_lock.c` and `zodiann_swiss_lock.h` sit beside `upstream/` (ZOD-EPH-002). They are not upstream files, are not in `MANIFEST.json`, and change nothing under `upstream/`. The build compiles them with the library and `-DTLSOFF`, an upstream switch (`sweodef.h`) that makes the library state shared by all threads.

## Why `.gitattributes` has two `-text` lines

Local trees and the Windows CI runner use `core.autocrlf=true`, which would check LF files out as CRLF and break the byte comparison. The root `.gitattributes` marks only `native/swisseph/upstream/**` and `packages/ephemeris_swiss/assets/ephe/**` as `-text`. The plan-authored files in `native/swisseph/` (this file, `README.md`, `MANIFEST.json`) are outside it.

## How "unchanged" was proved

1. The upstream tree at the commit above was read with `gh api repos/aloistr/swisseph/git/trees/f4dcd18e8005dde95fd8a8d2312ed12f9accd1b0` (and its `ephe` subtree); each file was fetched by blob id.
2. After `git add`, `git rev-parse :<path>` (the staged blob id) was compared with the upstream blob id for all 27 vendored files: **27 compared, 0 mismatches** (2026-11-20).
3. `git ls-files --eol` shows `attr/-text` on every vendored file. **`upstream/swedll.h` is genuinely CRLF upstream** (`i/crlf w/crlf`); it stays CRLF, which is why the attribute is required and not optional. The other text files are LF.
4. `test/architecture/swisseph_vendored_test.dart` recomputes each file's git blob id and SHA-256 from the bytes on disk and compares them with `MANIFEST.json`; it also confirms the licence files are present and that `LICENSE` has SHA-256 `b6345743292c…` (the value ZOD-FND-015 recorded in the inventory).
5. A Windows-style checkout (`git clone -c core.autocrlf=true`) was tested after the commit (Task 1, Step 7): see the result recorded in the ZOD-FND-003 findings.
