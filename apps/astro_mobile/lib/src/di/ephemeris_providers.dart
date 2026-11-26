import 'package:astro_core/astro_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ephemeris/ephemeris_status.dart';

/// The app's single injection point for the planet-position source (ARCH-4).
///
/// `bootstrapOverrides` (`lib/src/bootstrap.dart`) binds it at startup, once
/// the source has been chosen (`ephemeris_wiring.dart`, ZOD-EPH-002). Reading
/// it unbound fails loudly: an unbound source must never produce positions.
///
/// **App-level placeholder, not a public contract.** Feature packages must
/// never import the app layer, so this provider is not their provider
/// contract and is deliberately not exported. The first task that consumes
/// `EphemerisPort` from a feature package decides where the
/// feature-accessible contract lives and how the app binds it.
final Provider<EphemerisPort> ephemerisPortProvider = Provider<EphemerisPort>(
  (ref) => throw StateError(
    'No EphemerisPort is bound. bootstrapOverrides (lib/src/bootstrap.dart) '
    'binds ephemerisPortProvider.',
  ),
);

/// Which source is behind [ephemerisPortProvider], and what it can report
/// about an instant. Bound together with the port.
final Provider<EphemerisStatus> ephemerisStatusProvider =
    Provider<EphemerisStatus>(
      (ref) => throw StateError(
        'No ephemeris status is bound. bootstrapOverrides '
        '(lib/src/bootstrap.dart) binds ephemerisStatusProvider.',
      ),
    );
