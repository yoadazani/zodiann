import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ffi/swisseph_bindings.g.dart' as native;
import 'swiss_calc.dart';

/// A thin wrapper over the native Swiss Ephemeris library (ZOD-FND-003). It is
/// **not** the `EphemerisPort` adapter.
///
/// Every call goes through the project's locked functions
/// (native/swisseph/zodiann_swiss_lock.c) over **one library state shared by
/// every thread** (ZOD-EPH-002): calls from several isolates are serialized,
/// [setEphePath] is called once and applies to every isolate, and [close]
/// likewise affects every isolate.
///
/// The first call loads `libswisseph`, which the build hook produces for
/// Android only, so a call fails on the host.
final class SwissEphemerisBinding {
  SwissEphemerisBinding();

  /// The library's version string (`swe_version`), for example `2.10.03`.
  String version() {
    final buffer = calloc<Char>(256);
    try {
      native.zodiann_swiss_version(buffer);
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
      native.zodiann_swiss_set_ephe_path(path.cast<Char>());
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
      final returned = native.zodiann_swiss_calc_ut(
        julianDay,
        body,
        flags,
        xx,
        serr,
      );
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

  /// Longitude and longitude speed of [body] at the TT Julian day
  /// [tjdTt] (`swe_calc`, whose time argument is TT), with no UT-to-TT
  /// conversion by Swiss Ephemeris: the caller supplies the TT. Use
  /// [julianDayTt] (the function in `swiss_calc.dart`) to build it from days
  /// of TT since J2000 (ZOD-EPH-004 D12-O1).
  ///
  /// The same warnings apply as for [calcUt]: check
  /// [SwissCalcResult.usedSwissEphemerisFiles]. A negative return value is
  /// the library's error and throws [StateError] with its text.
  SwissCalcResult calcTt(
    double tjdTt,
    int body, {
    int flags = seflgSwieph | seflgSpeed,
  }) {
    final xx = calloc<Double>(6);
    final serr = calloc<Char>(256);
    try {
      final returned = native.zodiann_swiss_calc_tt(
        tjdTt,
        body,
        flags,
        xx,
        serr,
      );
      final error = serr.cast<Utf8>().toDartString();
      if (returned < 0) {
        throw StateError('swe_calc failed: $error');
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

  /// Closes the library's open files (`swe_close`), for every isolate.
  void close() => native.zodiann_swiss_close();
}
