# native/swisseph

Swiss Ephemeris C source code, built into the app through the Flutter build toolchain (ARCH-6) and consumed by `packages/ephemeris_swiss` via FFI.

- `upstream/`: the vendored, **unmodified** upstream source and licence files (tag `v2.10.3bfinal`), added by **ZOD-FND-003**. Origin, omissions and the proof that nothing changed are in [`VENDORED.md`](VENDORED.md); `MANIFEST.json` lists every file's upstream git blob id and SHA-256 and is checked on every test run.
- `zodiann_swiss_lock.c` and `zodiann_swiss_lock.h`: **project-authored** (AGPL-3.0-only, **ZOD-EPH-002**), beside `upstream/`, never inside it. They are the only way Dart calls the library: one mutex around every call. The library is compiled with `-DTLSOFF`, so it has one state shared by every thread (the data path is set once); the lock refuses to compile without it.
- The ephemeris **data files** are not here: they live at `packages/ephemeris_swiss/assets/ephe/`, because Flutter bundles only assets declared inside a package (`sepl_18.se1` and `semo_18.se1`, chosen by **ZOD-FND-011**; **ZOD-EPH-002** measured their coverage of all ten bodies as 1800-01-03 to 2400-01-06).
- The build hook is `packages/ephemeris_swiss/hook/build.dart` (Android only so far; the iOS half of ZOD-FND-003 is pending, and an iOS target must compile the lock with `-DTLSOFF` too).

The licensing decision is **ZOD-FND-010** (AGPL path), applied in **ZOD-FND-015**.
