/// The native Swiss Ephemeris binding and calculation source. Importing this
/// library loads `libswisseph`, which the build hook produces for Android
/// only: import it from device code, never from host tests. The pure types are
/// in `package:ephemeris_swiss/ephemeris_swiss.dart`.
library;

export 'src/native_swiss_calculation_source.dart';
export 'src/swiss_ephemeris_binding.dart';
