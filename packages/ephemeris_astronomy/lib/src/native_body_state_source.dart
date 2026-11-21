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
    final result = _call(id, daysSinceJ2000(utc), guardDoubles: 0);
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
    return _call(id, daysSinceJ2000(utc), guardDoubles: guardDoubles);
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
