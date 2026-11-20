import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ffi/swisseph_bindings.g.dart' as native;
import 'swiss_calc.dart';

/// A thin wrapper over the native Swiss Ephemeris library (ZOD-FND-003 spike).
///
/// It exists to prove the binding. It is **not** the `EphemerisPort` adapter
/// (ZOD-EPH-002). The library keeps global state (the ephemeris path and open
/// file handles), so calls from several isolates or threads must not
/// interleave; this wrapper does nothing to serialize them.
///
/// Importing this file loads `libswisseph`, which the build hook produces for
/// Android only, so import it from device code and never from host tests.
final class SwissEphemerisBinding {
  SwissEphemerisBinding();

  /// The library's version string (`swe_version`), for example `2.10.03`.
  String version() {
    final buffer = calloc<Char>(256);
    try {
      native.swe_version(buffer);
      return buffer.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  /// Points the library at the directory that holds the `.se1` data files
  /// (`swe_set_ephe_path`). It must be a real file-system path.
  void setEphePath(String directory) {
    final path = directory.toNativeUtf8(allocator: calloc);
    try {
      native.swe_set_ephe_path(path.cast<Char>());
    } finally {
      calloc.free(path);
    }
  }

  /// Longitude and longitude speed of [body] at the UTC instant [utc]
  /// (`swe_calc_ut`).
  ///
  /// A missing or out-of-range data file is **not** an error for the library:
  /// it falls back to the built-in Moshier ephemeris, sets the Moshier flag
  /// and writes a warning to `serr`. This method returns that result, so
  /// callers must check [SwissCalcResult.usedSwissEphemerisFiles]. A negative
  /// return value is the library's error and throws [StateError] with its
  /// text. Throws [ArgumentError] if [utc] is not UTC.
  SwissCalcResult calcUt(
    DateTime utc,
    int body, {
    int flags = seflgSwieph | seflgSpeed,
  }) {
    final julianDay = julianDayUt(utc);
    final xx = calloc<Double>(6);
    final serr = calloc<Char>(256);
    try {
      final returned = native.swe_calc_ut(julianDay, body, flags, xx, serr);
      final error = serr.cast<Utf8>().toDartString();
      if (returned < 0) {
        throw StateError('swe_calc_ut failed: $error');
      }
      return SwissCalcResult(
        longitude: xx[0],
        speed: xx[3],
        returnFlags: returned,
        error: error,
      );
    } finally {
      calloc.free(xx);
      calloc.free(serr);
    }
  }

  /// Closes the library's open files (`swe_close`).
  void close() => native.swe_close();
}
