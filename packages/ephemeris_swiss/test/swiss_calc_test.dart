import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:test/test.dart';

void main() {
  group('julianDayUt', () {
    test('J2000 noon is 2451545.0', () {
      expect(julianDayUt(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
    });

    test('the Unix epoch is 2440587.5', () {
      expect(julianDayUt(DateTime.utc(1970)), 2440587.5);
    });

    test('six hours are a quarter of a day', () {
      expect(
        julianDayUt(DateTime.utc(2000, 1, 1, 18)) -
            julianDayUt(DateTime.utc(2000, 1, 1, 12)),
        0.25,
      );
    });

    test('2026-11-20 00:00 UT is 2461364.5 (9820 days after J2000 noon, less half a day)', () {
      expect(julianDayUt(DateTime.utc(2026, 11, 20)), 2461364.5);
    });

    test('a local DateTime is rejected', () {
      expect(() => julianDayUt(DateTime(2000)), throwsArgumentError);
    });
  });

  group('constants (swephexp.h)', () {
    test('body and flag values match the header', () {
      expect(seSun, 0);
      expect(seMoon, 1);
      expect(seflgSwieph, 2);
      expect(seflgMoseph, 4);
      expect(seflgSpeed, 256);
    });
  });

  group('SwissCalcResult.usedSwissEphemerisFiles', () {
    SwissCalcResult result(int flags, [String error = '']) => SwissCalcResult(
      longitude: 0,
      speed: 0,
      returnFlags: flags,
      error: error,
    );

    test('true for the Swiss Ephemeris flag with no error', () {
      expect(result(seflgSwieph | seflgSpeed).usedSwissEphemerisFiles, isTrue);
    });

    test('false for the Moshier flag', () {
      expect(result(seflgMoseph | seflgSpeed).usedSwissEphemerisFiles, isFalse);
    });

    test('false when the library reported a warning', () {
      expect(
        result(
          seflgSwieph | seflgSpeed,
          'file not found',
        ).usedSwissEphemerisFiles,
        isFalse,
      );
    });
  });
}
