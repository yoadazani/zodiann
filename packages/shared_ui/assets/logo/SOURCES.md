# Bundled logo marks (ZOD-FND-008)

Each file is copied byte-for-byte from `design-reference/zodiann/assets/` (the 1024 px PNG renders of the SVG marks, MASTER §11). They are never redrawn or recoloured. `test/logo/logo_assets_test.dart` checks each file against its source and against the SHA-256 below.

| File | Source | SHA-256 |
|---|---|---|
| `zodiann-logo-on-dark.png` | `design-reference/zodiann/assets/zodiann-logo-on-dark.png` | `63c5ecf135bbc072e6c762a00a0fa27525e832e0f1237aa7ca8e3a715aafc694` |
| `zodiann-logo-on-light.png` | `design-reference/zodiann/assets/zodiann-logo-on-light.png` | `293b2a9c8758eee78589c8128077acef53a9bbbc10f47e54c1ddf41ff6991f8d` |

Use `ZodiannLogo`; never name these files elsewhere (`test/architecture/logo_size_guard_test.dart`).
