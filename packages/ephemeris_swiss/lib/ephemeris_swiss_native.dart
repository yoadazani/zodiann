/// The native Swiss Ephemeris binding (ZOD-FND-003 spike). Importing this
/// library loads `libswisseph`, which the build hook produces for Android
/// only: import it from device code, never from host tests. The pure types
/// are in `package:ephemeris_swiss/ephemeris_swiss.dart`.
library;

export 'src/swiss_ephemeris_binding.dart';
