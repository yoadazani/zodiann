/// Pure-Dart pieces of the Swiss Ephemeris source: the `EphemerisPort` adapter
/// over an injected calculation source, the Julian day, the body and flag
/// constants, and the result type. Nothing here imports `dart:ffi`, so host
/// tests never touch the native library.
library;

export 'src/swiss_calc.dart';
export 'src/swiss_calculation_source.dart';
export 'src/swiss_ephemeris.dart';
