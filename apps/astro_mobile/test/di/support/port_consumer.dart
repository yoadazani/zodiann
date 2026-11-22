// ZOD-EPH-004 Task 7: a consumer written against `EphemerisPort` only. This
// library imports nothing from `ephemeris_astronomy` (the swap test scans it to
// prove that), so it stands for feature code that must not know which source
// is bound (ARCH-4).
import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Sun's longitude and longitude speed at [utc] from whatever source the
/// container binds to [ephemerisPortProvider].
({double longitude, double speed}) sunFrom(
  ProviderContainer container,
  DateTime utc,
) {
  final result = container.read(ephemerisPortProvider).position(Body.sun, utc);
  if (result is EphemerisSuccess) {
    return (longitude: result.position.longitude, speed: result.position.speed);
  }
  throw StateError('no position: $result');
}
