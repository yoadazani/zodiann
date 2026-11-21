# native/astronomy_c

astronomy-engine C source code (MIT), built through the Flutter build toolchain (ARCH-6) and consumed by `packages/ephemeris_astronomy` via FFI as the backup position source and comparison oracle.

- `upstream/`: the vendored, unmodified upstream files (`astronomy.c`, `astronomy.h`, `LICENSE`). Origin, version and how "unchanged" is proved: [`VENDORED.md`](VENDORED.md). Guard: `test/architecture/astronomy_vendored_test.dart`.
- `MANIFEST.json`: the upstream tag, commit and each file's git blob id and SHA-256.
- Project-authored files (the shim, the Moon rate code and its generated term table) are added by later steps of ZOD-EPH-004 and are kept apart from `upstream/`.
