// ZOD-EPH-002: what the app reports about the active source. The time basis and
// the delta T data status describe the primary source only; both come from the
// pure functions in astro_core, never from an adapter's type.
import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/ephemeris/ephemeris_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the primary source', () {
    const status = EphemerisStatus(ActiveEphemerisSource.primary);

    for (final (utc, basis, data) in [
      (
        DateTime.utc(1971, 12, 31),
        ReportedTimeBasis.historicalDeltaT,
        DeltaTStatus.observed,
      ),
      (
        DateTime.utc(2000),
        ReportedTimeBasis.publishedLeapSeconds,
        DeltaTStatus.observed,
      ),
      (
        DateTime.utc(2027, 6, 28),
        ReportedTimeBasis.assumedContinuousUtc,
        DeltaTStatus.estimated,
      ),
      (
        DateTime.utc(2030),
        ReportedTimeBasis.assumedContinuousUtc,
        DeltaTStatus.forecast,
      ),
    ]) {
      test('at $utc', () {
        expect(status.timeBasisAt(utc), basis);
        expect(status.dataStatusAt(utc), data);
      });
    }
  });

  test('the backup uses its own delta T and reports no data status', () {
    const status = EphemerisStatus(ActiveEphemerisSource.backup);

    expect(
      status.timeBasisAt(DateTime.utc(2030)),
      ReportedTimeBasis.backupOwnDeltaT,
    );
    expect(status.dataStatusAt(DateTime.utc(2030)), isNull);
  });

  test('with no source there is nothing to report', () {
    const status = EphemerisStatus(ActiveEphemerisSource.none);

    expect(status.timeBasisAt(DateTime.utc(2000)), isNull);
    expect(status.dataStatusAt(DateTime.utc(2000)), isNull);
  });

  test('a non-UTC instant is rejected for every source', () {
    for (final source in ActiveEphemerisSource.values) {
      final status = EphemerisStatus(source);

      expect(() => status.timeBasisAt(DateTime(2000)), throwsArgumentError);
      expect(() => status.dataStatusAt(DateTime(2000)), throwsArgumentError);
    }
  });
}
