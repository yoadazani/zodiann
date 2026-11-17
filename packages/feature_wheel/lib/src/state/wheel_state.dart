import 'package:astro_core/astro_core.dart' show normalizeDegrees;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The zodiac wheel screen's state (ZOD-WHL-001).
///
/// Only the longitude under the fixed pointer today; WHL-009/010/014 extend
/// it (time, drag mode) and keep it the screen's one provider (ARCH-3).
@immutable
final class WheelState {
  /// A state with the pointer at [pointerLongitude] degrees.
  const WheelState({this.pointerLongitude = 0})
    // A debug assert: release relies on `setPointerLongitude` normalising.
    : assert(pointerLongitude >= 0 && pointerLongitude < 360);

  /// The ecliptic longitude under the fixed pointer, in `[0, 360)`.
  final double pointerLongitude;

  @override
  bool operator ==(Object other) =>
      other is WheelState && other.pointerLongitude == pointerLongitude;

  @override
  int get hashCode => pointerLongitude.hashCode;
}

/// Holds the [WheelState] and changes it.
class WheelController extends Notifier<WheelState> {
  @override
  WheelState build() => const WheelState();

  /// Puts [longitude] under the pointer, normalised into `[0, 360)`.
  ///
  /// Throws [ArgumentError] for NaN or infinity (the state stays unchanged).
  void setPointerLongitude(double longitude) {
    final next = WheelState(pointerLongitude: normalizeDegrees(longitude));
    if (next != state) state = next;
  }
}

/// The wheel screen's one provider; every derived value is a pure function of
/// its state (ARCH-3).
final NotifierProvider<WheelController, WheelState> wheelStateProvider =
    NotifierProvider<WheelController, WheelState>(WheelController.new);
