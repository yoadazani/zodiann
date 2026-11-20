// ZOD-FND-003: hand-copied from
// packages/ephemeris_swiss/test/fixtures/reference_longitudes.json (JPL
// Horizons, quantity 31, geocentric, apparent, retrieved 2026-11-20).
// `test/reference_longitudes_match_test.dart` keeps this copy equal to the
// fixture. `utc` is an ISO-8601 string because DateTime is not const.

/// Tolerance in arcseconds (the T-EPH-1 bound).
const double toleranceArcseconds = 1.0;

const referenceLongitudes =
    <({String body, String utc, double longitudeDegrees})>[
      (body: 'sun', utc: '1900-06-15T06:00:00Z', longitudeDegrees: 83.6521158),
      (body: 'sun', utc: '2000-01-01T12:00:00Z', longitudeDegrees: 280.3689092),
      (body: 'sun', utc: '2026-11-20T00:00:00Z', longitudeDegrees: 237.6706436),
      (
        body: 'moon',
        utc: '1900-06-15T06:00:00Z',
        longitudeDegrees: 290.3111397,
      ),
      (body: 'moon', utc: '2000-01-01T12:00:00Z', longitudeDegrees: 223.323786),
      (
        body: 'moon',
        utc: '2026-11-20T00:00:00Z',
        longitudeDegrees: 356.7762899,
      ),
    ];
