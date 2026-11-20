# native/swisseph

Swiss Ephemeris C source code, built into the app through the Flutter build toolchain (ARCH-6) and consumed by `packages/ephemeris_swiss` via FFI.

- `upstream/`: the vendored, **unmodified** upstream source and licence files (tag `v2.10.3bfinal`), added by **ZOD-FND-003**. Origin, omissions and the proof that nothing changed are in [`VENDORED.md`](VENDORED.md); `MANIFEST.json` lists every file's upstream git blob id and SHA-256 and is checked on every test run.
- The ephemeris **data files** are not here: they live at `packages/ephemeris_swiss/assets/ephe/`, because Flutter bundles only assets declared inside a package (spike subset `sepl_18.se1` and `semo_18.se1`, 1800 to 2400; the real coverage range is **ZOD-FND-011**).
- The build hook is `packages/ephemeris_swiss/hook/build.dart` (Android only so far; the iOS half of ZOD-FND-003 is pending).

The licensing decision is **ZOD-FND-010** (AGPL path), applied in **ZOD-FND-015**.
