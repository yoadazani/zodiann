/*
 * ZOD-EPH-004: see zodiann_astronomy_shim.h.
 *
 * One translation unit: it includes the unmodified upstream astronomy.c (the
 * file is not edited; the manifest guard and the Moon value-regression test
 * make a version change fail loudly). It then includes zodiann_moon_rate.c, the
 * project-authored Moon series and its exact analytic derivative.
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
#include "zodiann_moon_rate.c"

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

/*
 * The Moon: the longitude is upstream's Astronomy_EclipticGeoMoon (ECT, upstream
 * code, unchanged); the position and velocity are the project-authored Moon
 * series and its analytic derivative, in ECT (zodiann_moon_rate.c). Writes out
 * only on success.
 */
static int zodiann_moon_body_state(double ut_days, double* out)
{
    astro_time_t t = Astronomy_TimeFromDays(ut_days);
    astro_spherical_t sphere = Astronomy_EclipticGeoMoon(t);
    double r_ecm[3], v_ecm[3], r_ect[3], v_ect[3];
    int i;

    if (sphere.status != ASTRO_SUCCESS)
        return sphere.status;
    zodiann_moon_state(t, r_ecm, v_ecm, r_ect, v_ect);
    out[0] = zodiann_degrees_in_circle(sphere.lon);
    for (i = 0; i < 3; ++i)
    {
        out[1 + i] = r_ect[i];
        out[4 + i] = v_ect[i];
    }
    out[7] = NAN;
    return 0;
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

    /* The Moon returns here, before any Astronomy_BaryState call: its velocity
     * is project-authored and never comes from upstream's GeoMoonState. */
    if (body == ZODIANN_BODY_MOON)
        return zodiann_moon_body_state(ut_days, out);

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

/* Test-only (Task 3 Step 1b): the series value path against upstream's own
 * CalcMoon, with the analytic rates. Layout: ours lon, lat, dist (rad, rad,
 * AU), our rates per TT century (rad, rad, AU), upstream lon, lat, dist. */
int zodiann_test_moon_series(double centuries_tt, double* out)
{
    zodiann_moon_series_t ours;
    double lon, lat, dist;

    if (out == NULL || !isfinite(centuries_tt))
        return ASTRO_INVALID_PARAMETER;
    zodiann_moon_series(centuries_tt, &ours);
    CalcMoon(centuries_tt, &lon, &lat, &dist);
    out[0] = ours.lon;
    out[1] = ours.lat;
    out[2] = ours.dist;
    out[3] = ours.dlon;
    out[4] = ours.dlat;
    out[5] = ours.ddist;
    out[6] = lon;
    out[7] = lat;
    out[8] = dist;
    return 0;
}

/* Test-only (Task 3 Step 1b): the Moon's state, ECM position (3), ECM
 * velocity (3), ECT position (3), ECT velocity (3), velocities in AU per day. */
int zodiann_test_moon_state(double ut_days, double* out)
{
    astro_time_t t;
    double r_ecm[3], v_ecm[3], r_ect[3], v_ect[3];
    int i;

    if (out == NULL || !isfinite(ut_days))
        return ASTRO_INVALID_PARAMETER;
    t = Astronomy_TimeFromDays(ut_days);
    zodiann_moon_state(t, r_ecm, v_ecm, r_ect, v_ect);
    for (i = 0; i < 3; ++i)
    {
        out[0 + i] = r_ecm[i];
        out[3 + i] = v_ecm[i];
        out[6 + i] = r_ect[i];
        out[9 + i] = v_ect[i];
    }
    return 0;
}
