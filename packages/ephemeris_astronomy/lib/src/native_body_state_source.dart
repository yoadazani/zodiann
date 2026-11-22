import 'dart:ffi';

import 'package:astro_core/astro_core.dart';
import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import 'body_state.dart';
import 'ffi/astronomy_bindings.g.dart' as native;

/// The value every double of the call buffer holds before the shim runs, so a
/// test can tell a written element from an untouched one.
const double _sentinel = 1234.5;

/// The native [BodyStateSource]: astronomy-engine through the flat C shim
/// (ZOD-EPH-004, decision D2).
///
/// Importing this file loads `libastronomy`, which the build hook produces for
/// Android only, so import it from device code and never from host tests. The
/// pure types are in `package:ephemeris_astronomy/ephemeris_astronomy.dart`.
final class NativeBodyStateSource implements BodyStateSource {
  const NativeBodyStateSource();

  /// Throws [ArgumentError] if [utc] is not UTC or if [body] is [Body.node]
  /// (the node is formula-based and is never a native body). Throws
  /// [StateError] with the library's status code if the shim reports an error.
  @override
  BodyState bodyState(Body body, DateTime utc) {
    final id = _shimId(body);
    final result = _call(id, _utDays(utc), guardDoubles: 0);
    if (result.status != 0) {
      throw StateError('astronomy-engine status ${result.status}');
    }
    return BodyState.fromBuffer(result.buffer);
  }

  /// Test hook: runs the production call path once and returns the shim's
  /// status and the whole buffer, which holds [bodyStateLength] +
  /// [guardDoubles] doubles, **all pre-filled with the sentinel 1234.5**
  /// before the call. A test can then check that every element the shim must
  /// write was written, and that the guard elements after them are untouched
  /// (a guard of four doubles detects only an overrun of four doubles or
  /// fewer). [shimIdOverride] replaces the table id so an invalid id can be
  /// tried.
  @visibleForTesting
  ({int status, List<double> buffer}) rawBufferForTesting(
    Body body,
    DateTime utc, {
    int guardDoubles = 0,
    int? shimIdOverride,
  }) {
    final id = shimIdOverride ?? _shimId(body);
    return _call(id, _utDays(utc), guardDoubles: guardDoubles);
  }

  /// Test hook (D12): the UT days and the TT days the production path assigns
  /// to [utc]. `bodyState` and this hook derive the UT days through the same
  /// private method and the shim converts through one helper, so the TT
  /// returned here is the one `bodyState` uses. Returns exactly
  /// [timeStateLength] doubles (plus [guardDoubles] sentinel-filled ones): the
  /// UT days since J2000, then the TT days since J2000.
  @visibleForTesting
  List<double> timeForTesting(DateTime utc, {int guardDoubles = 0}) {
    final utDays = _utDays(utc);
    return _callHook(
      timeStateLength + guardDoubles,
      (out) => native.zodiann_test_time_for_ut(utDays, out),
    );
  }

  /// The one place a UTC [DateTime] becomes the UT days passed to the shim.
  static double _utDays(DateTime utc) => daysSinceJ2000(utc);

  /// Test hook (Task 3 Step 1b): the project-authored Moon series against
  /// upstream's own `CalcMoon` at [centuriesTt] Julian centuries of TT since
  /// J2000. Returns exactly [moonSeriesLength] doubles (plus [guardDoubles]
  /// more, all pre-filled with the sentinel 1234.5, for a bounds check):
  /// our lon, lat, dist (radians, radians, AU); our analytic rates per TT
  /// century (radians, radians, AU); upstream lon, lat, dist.
  @visibleForTesting
  List<double> moonSeriesForTesting(
    double centuriesTt, {
    int guardDoubles = 0,
  }) => _callHook(
    moonSeriesLength + guardDoubles,
    (out) => native.zodiann_test_moon_series(centuriesTt, out),
  );

  /// Test hook (Task 3 Step 1b): the Moon's state built by the production
  /// path at [utDays] days since J2000 UT. Returns exactly [moonStateLength]
  /// doubles (plus [guardDoubles] sentinel-filled ones): ECM position (3),
  /// ECM velocity (3), ECT position (3), ECT velocity (3), velocities in AU
  /// per day.
  @visibleForTesting
  List<double> moonStateForTesting(double utDays, {int guardDoubles = 0}) =>
      _callHook(
        moonStateLength + guardDoubles,
        (out) => native.zodiann_test_moon_state(utDays, out),
      );

  /// Runs a test-only shim function on a buffer of [total] doubles, all
  /// pre-filled with the sentinel, and returns the whole buffer. Throws
  /// [StateError] if the function reports an error.
  static List<double> _callHook(
    int total,
    int Function(Pointer<Double> out) call,
  ) {
    final pointer = calloc<Double>(total);
    try {
      for (var i = 0; i < total; i++) {
        pointer[i] = _sentinel;
      }
      final status = call(pointer);
      if (status != 0) {
        throw StateError('astronomy-engine status $status');
      }
      return [for (var i = 0; i < total; i++) pointer[i]];
    } finally {
      calloc.free(pointer);
    }
  }

  static int _shimId(Body body) {
    final id = shimBodyIds[body];
    if (id == null) {
      throw ArgumentError.value(body, 'body', 'is not a native body');
    }
    return id;
  }

  /// The one place that allocates the buffer and calls the shim; the
  /// production path and the test hook both go through it.
  static ({int status, List<double> buffer}) _call(
    int shimId,
    double utDays, {
    required int guardDoubles,
  }) {
    final total = bodyStateLength + guardDoubles;
    final pointer = calloc<Double>(total);
    try {
      for (var i = 0; i < total; i++) {
        pointer[i] = _sentinel;
      }
      final status = native.zodiann_body_state(shimId, utDays, pointer);
      return (
        status: status,
        buffer: [for (var i = 0; i < total; i++) pointer[i]],
      );
    } finally {
      calloc.free(pointer);
    }
  }
}
