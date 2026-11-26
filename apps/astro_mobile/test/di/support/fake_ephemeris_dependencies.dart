// Test only (ZOD-EPH-002): startup dependencies that count their calls and can
// be told to fail, so startup is tested on the host without native code or the
// real file installer. They provide calculation sources, never a port.
import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/di/ephemeris_wiring.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';

/// The longitude the fake primary source reports for every physical body.
const double fakeSwissLongitude = 11;

/// The longitude the fake backup source reports for every physical body.
const double fakeBackupLongitude = 22;

final class _SwissSource implements SwissCalculationSource {
  static const _result = SwissCalcResult(
    longitude: fakeSwissLongitude,
    speed: 1,
    returnFlags: swissAdapterFlags,
    error: '',
  );

  @override
  SwissCalcResult? calcUt(DateTime utc, int body, {required int flags}) =>
      _result;

  @override
  SwissCalcResult? calcTt(double tjdTt, int body, {required int flags}) =>
      _result;
}

final class _BackupSource implements BodyStateSource {
  @override
  BodyState bodyState(Body body, DateTime utc) => const BodyState(
    longitude: fakeBackupLongitude,
    x: 1,
    y: 0,
    z: 0,
    vx: 0,
    vy: 0.01,
    vz: 0,
  );
}

/// By default neither library "loads", so nothing else is called.
final class FakeEphemerisDependencies {
  FakeEphemerisDependencies({
    this.swiss = false,
    this.backup = false,
    this.directory = '/fake/ephe',
    this.swissProbeError,
    this.prepareError,
    this.openSwissError,
    this.backupProbeError,
    this.openBackupError,
  });

  final bool swiss;
  final bool backup;

  /// What preparing the data returns.
  final String? directory;

  /// Thrown by the matching call when set.
  final Object? swissProbeError;
  final Object? prepareError;
  final Object? openSwissError;
  final Object? backupProbeError;
  final Object? openBackupError;

  int swissProbes = 0;
  int preparations = 0;
  int backupProbes = 0;
  int backupOpens = 0;
  final openedDirectories = <String>[];

  T _answer<T>(Object? error, T value) {
    if (error != null) throw error;
    return value;
  }

  EphemerisDependencies get dependencies => EphemerisDependencies(
    swissLoads: () {
      swissProbes++;
      return _answer(swissProbeError, swiss);
    },
    prepareSwissData: () async {
      preparations++;
      return _answer(prepareError, directory);
    },
    openSwissSource: (directory) {
      openedDirectories.add(directory);
      return _answer(openSwissError, _SwissSource());
    },
    backupLoads: () {
      backupProbes++;
      return _answer(backupProbeError, backup);
    },
    openBackupSource: () {
      backupOpens++;
      return _answer(openBackupError, _BackupSource());
    },
  );
}
