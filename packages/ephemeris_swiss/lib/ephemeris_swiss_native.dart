/// The native Swiss Ephemeris binding and calculation source. The first
/// native call loads `libswisseph`, which the build hook produces for Android
/// only: host code may compile this import (the app's wiring does), but a
/// native call fails there. The pure types are in
/// `package:ephemeris_swiss/ephemeris_swiss.dart`.
library;

export 'src/native_swiss_calculation_source.dart';
export 'src/swiss_ephemeris_binding.dart';
