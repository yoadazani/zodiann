/*
 * ZOD-EPH-004 Task 3 Step 1b: the Moon's position series and its exact
 * analytic time derivative. Project-authored (AGPL-3.0-only like the rest of
 * the project), and kept apart from the unmodified upstream source in
 * `upstream/`.
 *
 * Upstream's own position code is `CalcMoon` (astronomy.c). This file holds a
 * value path that reproduces it, and the derivative of that same series with
 * respect to time. The derivation, every omitted term and its size are in
 * docs/spikes/ZOD-EPH-004-moon-derivative.md. No finite difference is used
 * anywhere in this file, and upstream's Astronomy_GeoMoonState (a central
 * difference) is never called.
 *
 * This header is included by the shim translation unit after
 * `upstream/astronomy.c` (it needs that file's PI2, ARC and
 * EARTH_EQUATORIAL_RADIUS_AU).
 */
#ifndef ZODIANN_MOON_RATE_H
#define ZODIANN_MOON_RATE_H

/*
 * The Moon in the ecliptic of the MEAN equinox of date ("ECM"), as upstream's
 * CalcMoon returns it, with its rates.
 */
typedef struct {
    double lon;    /* radians, in [0, 2 pi) */
    double lat;    /* radians */
    double dist;   /* AU */
    double dlon;   /* radians per Julian century of TT */
    double dlat;   /* radians per Julian century of TT */
    double ddist;  /* AU per Julian century of TT */
} zodiann_moon_series_t;

#endif /* ZODIANN_MOON_RATE_H */
