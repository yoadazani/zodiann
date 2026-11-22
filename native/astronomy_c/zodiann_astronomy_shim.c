/*
 * ZOD-EPH-004: see zodiann_astronomy_shim.h.
 *
 * One translation unit: it includes the unmodified upstream astronomy.c (the
 * file is not edited; the manifest guard and the Moon value-regression test
 * make a version change fail loudly). It then includes zodiann_moon_rate.c, the
 * project-authored Moon series and its exact analytic derivative.
 *
 * Velocity (decision D1, with the owner-approved retarded-instant refinement
 * of 2026-11-22, variant V2): for the Sun and the planets it is the library's
 * own barycentric velocity of the body at the light-time-retarded instant
 * t - tau, scaled by (1 - dtau/dt), minus the Earth's velocity at t
 * (Astronomy_BaryState, analytic VSOP derivatives, and for Pluto the library's
 * gravity-simulation state), rotated into the true ecliptic of date. Nothing
 * here differences positions. The Moon's velocity is project-authored code,
 * never Astronomy_GeoMoonState.
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
 * The one UTC-to-TT conversion of the shim (ZOD-EPH-004 D12). Every entry point,
 * the test hook zodiann_test_time_for_ut included, converts through this
 * function, so the hook reports exactly the TT the production path uses; a
 * host guard requires that it is the only caller of Astronomy_TimeFromDays and
 * that nothing edits the time afterwards. Defined before its first use, with no
 * separate prototype (the guard counts definitions).
 */
static astro_time_t zodiann_time_from_ut(double ut_days)
{
    return Astronomy_TimeFromDays(ut_days);
}

/*
 * The Moon: the longitude is upstream's Astronomy_EclipticGeoMoon (ECT, upstream
 * code, unchanged); the position and velocity are the project-authored Moon
 * series and its analytic derivative, in ECT (zodiann_moon_rate.c). Writes out
 * only on success.
 */
static int zodiann_moon_body_state(double ut_days, double* out)
{
    astro_time_t t = zodiann_time_from_ut(ut_days);
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
    astro_time_t t, t_retarded;
    astro_vector_t geo, geo_geometric, r, vel_eqj, v;
    double dist, taudot, rhat_x, rhat_y, rhat_z;
    astro_state_vector_t body_state, earth_state;
    astro_rotation_t rot;
    int i;

    if (out == NULL || body < 0 || body >= ZODIANN_BODY_COUNT || !isfinite(ut_days))
        return ASTRO_INVALID_PARAMETER;

    /* The Moon returns here, before any Astronomy_BaryState call: its velocity
     * is project-authored and never comes from upstream's GeoMoonState. */
    if (body == ZODIANN_BODY_MOON)
        return zodiann_moon_body_state(ut_days, out);

    t = zodiann_time_from_ut(ut_days);

    /* Apparent geocentric position (light time and aberration), EQJ. */
    geo = Astronomy_GeoVector(kShimBodies[body], t, ABERRATION);
    if (geo.status != ASTRO_SUCCESS)
        return geo.status;

    /* The light-time retardation (owner-approved refinement, 2026-11-22,
     * variant V2). GeoVector without aberration is the retarded geometric
     * vector; tau is its light time. The body is seen where it was at t - tau,
     * so its velocity is taken there, and the geometric part of the apparent
     * position moves as d/dt [x_body(t - tau) - x_earth(t)]
     *   = v_body(t - tau) (1 - dtau/dt) - v_earth(t),
     * with dtau/dt = rhat . (v_body(t - tau) - v_earth(t)) / (c + rhat .
     * v_body(t - tau)). The retarded time is built through the single
     * conversion helper (not Astronomy_AddDays); BaryState is analytic. The
     * derivatives of the aberration correction and of the frame rotation stay
     * omitted (docs/spikes/ZOD-EPH-004-retarded-velocity.md). */
    geo_geometric = Astronomy_GeoVector(kShimBodies[body], t, NO_ABERRATION);
    if (geo_geometric.status != ASTRO_SUCCESS)
        return geo_geometric.status;
    dist = sqrt(geo_geometric.x * geo_geometric.x +
                geo_geometric.y * geo_geometric.y +
                geo_geometric.z * geo_geometric.z);
    t_retarded = zodiann_time_from_ut(ut_days - dist / C_AUDAY);

    /* Velocity of the body at t - tau and of the Earth at t, barycentric EQJ,
     * AU per day. */
    body_state = Astronomy_BaryState(kShimBodies[body], t_retarded);
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

    rhat_x = geo_geometric.x / dist;
    rhat_y = geo_geometric.y / dist;
    rhat_z = geo_geometric.z / dist;
    taudot = (rhat_x * (body_state.vx - earth_state.vx) +
              rhat_y * (body_state.vy - earth_state.vy) +
              rhat_z * (body_state.vz - earth_state.vz)) /
             (C_AUDAY + (rhat_x * body_state.vx + rhat_y * body_state.vy +
                         rhat_z * body_state.vz));

    vel_eqj.status = ASTRO_SUCCESS;
    vel_eqj.x = body_state.vx * (1.0 - taudot) - earth_state.vx;
    vel_eqj.y = body_state.vy * (1.0 - taudot) - earth_state.vy;
    vel_eqj.z = body_state.vz * (1.0 - taudot) - earth_state.vz;
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
    t = zodiann_time_from_ut(ut_days);
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

/* Test-only (D12): the time the production path assigns to `ut_days`, through
 * the same helper. out[0] the UT days since J2000, out[1] the TT days since
 * J2000. Writes nothing unless it returns 0. */
int zodiann_test_time_for_ut(double ut_days, double* out)
{
    astro_time_t t;

    if (out == NULL || !isfinite(ut_days))
        return ASTRO_INVALID_PARAMETER;
    t = zodiann_time_from_ut(ut_days);
    out[0] = t.ut;
    out[1] = t.tt;
    return 0;
}
