/*
 * ZOD-EPH-004: see zodiann_astronomy_shim.h.
 *
 * One translation unit: it includes the unmodified upstream astronomy.c (the
 * file is not edited; the manifest guard and the Moon value-regression test
 * make a version change fail loudly). The Moon branch is added in Task 3,
 * Step 1b; until then it returns ASTRO_INVALID_BODY and writes nothing.
 *
 * Velocity (decision D1): for the Sun and the planets it is the library's own
 * barycentric velocity of the body minus the Earth's (Astronomy_BaryState,
 * analytic VSOP derivatives, and for Pluto the library's gravity-simulation
 * state), rotated into the true ecliptic of date. Nothing here differences
 * positions. The Moon's velocity will be project-authored code, never
 * Astronomy_GeoMoonState.
 */
#include <math.h>

#include "zodiann_astronomy_shim.h"
#include "upstream/astronomy.c"

#define ZODIANN_BODY_MOON 1

static const astro_body_t kShimBodies[ZODIANN_BODY_COUNT] = {
    BODY_SUN,    BODY_MOON,   BODY_MERCURY, BODY_VENUS,  BODY_MARS,
    BODY_JUPITER, BODY_SATURN, BODY_URANUS,  BODY_NEPTUNE, BODY_PLUTO,
};

static double zodiann_degrees_in_circle(double degrees)
{
    degrees = fmod(degrees, 360.0);
    if (degrees < 0.0)
        degrees += 360.0;
    if (degrees >= 360.0)
        degrees = 0.0;
    return degrees;
}

int zodiann_body_state(int body, double ut_days, double* out)
{
    double s[ZODIANN_BODY_STATE_LENGTH];
    astro_time_t t;
    astro_vector_t geo, r, vel_eqj, v;
    astro_state_vector_t body_state, earth_state;
    astro_rotation_t rot;
    int i;

    if (out == NULL || body < 0 || body >= ZODIANN_BODY_COUNT || !isfinite(ut_days))
        return ASTRO_INVALID_PARAMETER;

    /* The Moon branch is added in Task 3, Step 1b. Nothing is written. */
    if (body == ZODIANN_BODY_MOON)
        return ASTRO_INVALID_BODY;

    t = Astronomy_TimeFromDays(ut_days);

    /* Apparent geocentric position (light time and aberration), EQJ. */
    geo = Astronomy_GeoVector(kShimBodies[body], t, ABERRATION);
    if (geo.status != ASTRO_SUCCESS)
        return geo.status;

    /* Velocity of the body and of the Earth, barycentric EQJ, AU per day. */
    body_state = Astronomy_BaryState(kShimBodies[body], t);
    if (body_state.status != ASTRO_SUCCESS)
        return body_state.status;
    earth_state = Astronomy_BaryState(BODY_EARTH, t);
    if (earth_state.status != ASTRO_SUCCESS)
        return earth_state.status;

    rot = Astronomy_Rotation_EQJ_ECT(&t);
    if (rot.status != ASTRO_SUCCESS)
        return rot.status;

    r = Astronomy_RotateVector(rot, geo);
    if (r.status != ASTRO_SUCCESS)
        return r.status;

    vel_eqj.status = ASTRO_SUCCESS;
    vel_eqj.x = body_state.vx - earth_state.vx;
    vel_eqj.y = body_state.vy - earth_state.vy;
    vel_eqj.z = body_state.vz - earth_state.vz;
    vel_eqj.t = t;
    v = Astronomy_RotateVector(rot, vel_eqj);
    if (v.status != ASTRO_SUCCESS)
        return v.status;

    s[0] = zodiann_degrees_in_circle(atan2(r.y, r.x) * (180.0 / PI));
    s[1] = r.x;
    s[2] = r.y;
    s[3] = r.z;
    s[4] = v.x;
    s[5] = v.y;
    s[6] = v.z;
    s[7] = NAN;

    if (body == 0) {
        /* The Sun: an independent longitude, from the library's own SunPosition. */
        astro_ecliptic_t sun = Astronomy_SunPosition(t);
        if (sun.status != ASTRO_SUCCESS)
            return sun.status;
        s[7] = sun.elon;
    }

    for (i = 0; i < ZODIANN_BODY_STATE_LENGTH; ++i)
        out[i] = s[i];
    return 0;
}
