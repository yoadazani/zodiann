import 'swiss_calc.dart';
import 'swiss_calculation_source.dart';
import 'swiss_ephemeris_binding.dart';

/// The native [SwissCalculationSource]: the locked Swiss Ephemeris calls
/// through [SwissEphemerisBinding]. The data path must have been set (once, for
/// the whole process) with [SwissEphemerisBinding.setEphePath]; this class
/// never sets it.
///
/// Importing this file loads `libswisseph`, which the build hook produces for
/// Android only. The pure types are in
/// `package:ephemeris_swiss/ephemeris_swiss.dart`.
final class NativeSwissCalculationSource implements SwissCalculationSource {
  NativeSwissCalculationSource(this._binding);

  final SwissEphemerisBinding _binding;

  @override
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags}) =>
      _orNull(() => _binding.calcUt(utc, body, flags: flags));

  @override
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags}) =>
      _orNull(() => _binding.calcTt(tjdTt, body, flags: flags));

  /// The binding reports the library's own error as a [StateError]; for a
  /// position source that is "cannot calculate".
  static SwissCalcResult? _orNull(SwissCalcResult Function() call) {
    try {
      return call();
    } on StateError {
      return null;
    }
  }
}
