/*
 * ZOD-EPH-004: the flat C interface between Dart and astronomy-engine.
 *
 * Project-authored (AGPL-3.0-only like the rest of the project). It never
 * edits the vendored upstream source under `upstream/`; the shim includes it.
 * Plain int and double arguments only, so the generated FFI bindings carry no
 * struct by value.
 */
#ifndef ZODIANN_ASTRONOMY_SHIM_H
#define ZODIANN_ASTRONOMY_SHIM_H

#ifdef __cplusplus
extern "C" {
#endif

/* The caller owns a buffer of exactly this many doubles for
 * zodiann_body_state. Dart mirrors it as `bodyStateLength`. */
#define ZODIANN_BODY_STATE_LENGTH 8

/* The shim body ids: sun 0, moon 1, mercury 2, venus 3, mars 4, jupiter 5,
 * saturn 6, uranus 7, neptune 8, pluto 9. */
#define ZODIANN_BODY_COUNT 10

/*
 * The geocentric state of one body at the UT instant `ut_days` (days since
 * J2000, 2000-01-01T12:00 UT), in the true ecliptic of date.
 *
 *   out[0]    apparent ecliptic longitude, degrees in [0, 360)
 *   out[1..3] geocentric position, AU
 *   out[4..6] geocentric velocity, AU per day
 *   out[7]    a longitude in degrees from an independent library path
 *             (the Sun only: Astronomy_SunPosition); NaN for every other body
 *
 * Returns 0 on success, otherwise an astro_status_t code (an invalid `body`
 * or a NULL `out` or a non-finite `ut_days` gives ASTRO_INVALID_PARAMETER). `out` is written only when
 * the return value is 0: on any other return nothing in it is touched.
 */
int zodiann_body_state(int body, double ut_days, double* out);

#ifdef __cplusplus
}
#endif

#endif /* ZODIANN_ASTRONOMY_SHIM_H */
