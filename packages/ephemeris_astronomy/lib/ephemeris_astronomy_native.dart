/// The native astronomy-engine binding (ZOD-EPH-004). Importing this library
/// loads `libastronomy`, which the build hook produces for Android only:
/// import it from device code, never from host tests. The pure types are in
/// `package:ephemeris_astronomy/ephemeris_astronomy.dart`.
library;

export 'src/native_body_state_source.dart';
