import 'package:astro_core/astro_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single injection point for the planet-position source (ARCH-4).
///
/// A source (Swiss Ephemeris, astronomy-engine, or a test fake) is bound with
/// one override in `appOverrides` (`lib/src/di/app_overrides.dart`). No
/// adapter exists yet, so reading this provider unbound fails loudly: an
/// unbound source must never produce positions.
///
/// **App-level placeholder, not a public contract.** Feature packages must
/// never import the app layer, so this provider is not their provider
/// contract and is deliberately not exported. The first task that consumes
/// `EphemerisPort` from a feature package decides where the
/// feature-accessible contract lives and how `appOverrides` binds it.
final Provider<EphemerisPort> ephemerisPortProvider = Provider<EphemerisPort>(
  (ref) => throw StateError(
    'No EphemerisPort is bound. Override ephemerisPortProvider in '
    'appOverrides (lib/src/di/app_overrides.dart).',
  ),
);
