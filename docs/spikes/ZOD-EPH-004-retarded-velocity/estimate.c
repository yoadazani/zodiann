/*
 * Scratch estimate (not in the repository): would taking the body's velocity
 * at the light-time-retarded instant fix the Mercury (and Venus) speed
 * difference against Swiss? Variants, all from library vectors, no finite
 * differences of positions:
 *   V0 current: v = v_body(t) - v_earth(t)
 *   V1: v_body(t-tau) - v_earth(t)
 *   V2: v_body(t-tau)(1-taudot) - v_earth(t)   (exact derivative of the
 *       retarded geometric position)
 *   V3: v_body(t-tau) - v_earth(t-tau)         (the literal D7 wording)
 * r is always the shim's apparent position (GeoVector with aberration).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "astronomy.h"
#include "swephexp.h"

#define NV 4
static astro_body_t body_id;
static int swiss_id;

static double jd_from_ymd(int y, int m, int d)
{
    int a = (14 - m) / 12, yy = y + 4800 - a, mm = m + 12 * a - 3;
    return d + (153 * mm + 2) / 5 + 365.0 * yy + yy / 4 - yy / 100 + yy / 400 - 32045 - 0.5;
}

static void rotv(astro_rotation_t rot, double x, double y, double z, astro_time_t t, double* o)
{
    astro_vector_t v;
    v.status = ASTRO_SUCCESS; v.x = x; v.y = y; v.z = z; v.t = t;
    v = Astronomy_RotateVector(rot, v);
    o[0] = v.x; o[1] = v.y; o[2] = v.z;
}

/* Speeds (deg/day) of the four variants at ut_days; tt_out gets the TT days. */
static int speeds(double ut_days, double* sp, double* tt_out)
{
    astro_time_t t = Astronomy_TimeFromDays(ut_days);
    astro_vector_t geo = Astronomy_GeoVector(body_id, t, ABERRATION);
    astro_rotation_t rot = Astronomy_Rotation_EQJ_ECT(&t);
    astro_state_vector_t b0 = Astronomy_BaryState(body_id, t);
    astro_state_vector_t e0 = Astronomy_BaryState(BODY_EARTH, t);
    double r[3], dist, tau, c = C_AUDAY;
    astro_time_t tr;
    astro_state_vector_t b1, e1;
    double rx, ry, rz, rh[3], vb[3], ve[3], v[3], taudot, vbr_dot;
    int k;
    if (geo.status || b0.status || e0.status || rot.status) return 1;
    rotv(rot, geo.x, geo.y, geo.z, t, r);
    /* retardation from the geometric (unaberrated) distance */
    {
        astro_vector_t g = Astronomy_GeoVector(body_id, t, NO_ABERRATION);
        dist = sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
    }
    tau = dist / c;
    tr = Astronomy_AddDays(t, -tau);
    b1 = Astronomy_BaryState(body_id, tr);
    e1 = Astronomy_BaryState(BODY_EARTH, tr);
    if (b1.status || e1.status) return 1;
    *tt_out = t.tt;

    for (k = 0; k < NV; ++k) {
        double bx, by, bz, ex, ey, ez;
        if (k == 0) { bx = b0.vx; by = b0.vy; bz = b0.vz; ex = e0.vx; ey = e0.vy; ez = e0.vz; }
        else if (k == 1) { bx = b1.vx; by = b1.vy; bz = b1.vz; ex = e0.vx; ey = e0.vy; ez = e0.vz; }
        else if (k == 2) {
            /* geometric retarded unit vector in EQJ (unaberrated GeoVector is
               the retarded geometric vector) */
            astro_vector_t g = Astronomy_GeoVector(body_id, t, NO_ABERRATION);
            double gd = sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
            rx = g.x / gd; ry = g.y / gd; rz = g.z / gd;
            vbr_dot = rx * b1.vx + ry * b1.vy + rz * b1.vz;
            taudot = (rx * (b1.vx - e0.vx) + ry * (b1.vy - e0.vy) + rz * (b1.vz - e0.vz)) / (c + vbr_dot);
            bx = b1.vx * (1 - taudot); by = b1.vy * (1 - taudot); bz = b1.vz * (1 - taudot);
            ex = e0.vx; ey = e0.vy; ez = e0.vz;
            (void)rh;
        }
        else { bx = b1.vx; by = b1.vy; bz = b1.vz; ex = e1.vx; ey = e1.vy; ez = e1.vz; }
        rotv(rot, bx - ex, by - ey, bz - ez, t, v);
        (void)vb; (void)ve;
        sp[k] = (r[0] * v[1] - r[1] * v[0]) / (r[0] * r[0] + r[1] * r[1]) * (180.0 / 3.14159265358979323846);
    }
    return 0;
}

static double swiss_speed(double tt_days, char* err)
{
    double xx[6];
    int rc = swe_calc(tt_days + 2451545.0, swiss_id, SEFLG_SWIEPH | SEFLG_SPEED, xx, err);
    if (rc < 0 || (rc & SEFLG_MOSEPH)) { fprintf(stderr, "swiss fallback/err: %s\n", err); exit(3); }
    return xx[3];
}

static double swiss_at(double ut_days)
{
    astro_time_t t = Astronomy_TimeFromDays(ut_days);
    char err[256] = "";
    return swiss_speed(t.tt, err);
}

typedef struct { double max, sum; int n, over; double at; } Acc;
static void add(Acc* a, double d, double at, double bound)
{
    d = fabs(d); a->n++; a->sum += d;
    if (d > a->max) { a->max = d; a->at = at; }
    if (d > bound) a->over++;
}

static int cmpd(const void* a, const void* b) { double x = *(double*)a, y = *(double*)b; return x < y ? -1 : x > y; }

int main(int argc, char** argv)
{
    const char* names[NV] = {"V0 current", "V1 body(t-tau)-earth(t)", "V2 exact retarded derivative", "V3 body,earth both at t-tau"};
    double bound;
    double j0 = jd_from_ymd(1900, 1, 1), j1 = jd_from_ymd(2099, 12, 31);
    int n = (int)(j1 - j0) + 1, i, k;
    Acc daily[NV], formal[NV];
    double* diffs[NV];
    char err[256] = "";
    FILE* f;
    double ut, sp[NV], tt, sw, prevneg = 0;
    double prev_sw = 0, prev_ut = 0;
    int have_prev = 0, stations = 0;
    if (argc < 4) { fprintf(stderr, "usage: est mercury|venus <ephe> <ref_ut.txt>\n"); return 2; }
    if (!strcmp(argv[1], "mercury")) { body_id = BODY_MERCURY; swiss_id = 2; bound = 0.0012; }
    else if (!strcmp(argv[1], "sun")) { body_id = BODY_SUN; swiss_id = 0; bound = 0.0003; }
    else if (!strcmp(argv[1], "mars")) { body_id = BODY_MARS; swiss_id = 4; bound = 0.0003; }
    else if (!strcmp(argv[1], "jupiter")) { body_id = BODY_JUPITER; swiss_id = 5; bound = 0.0003; }
    else if (!strcmp(argv[1], "saturn")) { body_id = BODY_SATURN; swiss_id = 6; bound = 0.0003; }
    else if (!strcmp(argv[1], "uranus")) { body_id = BODY_URANUS; swiss_id = 7; bound = 0.0003; }
    else if (!strcmp(argv[1], "neptune")) { body_id = BODY_NEPTUNE; swiss_id = 8; bound = 0.0003; }
    else if (!strcmp(argv[1], "pluto")) { body_id = BODY_PLUTO; swiss_id = 9; bound = 0.0003; }
    else { body_id = BODY_VENUS; swiss_id = 3; bound = 0.00045; }
    swe_set_ephe_path(argv[2]);
    memset(daily, 0, sizeof daily); memset(formal, 0, sizeof formal);
    for (k = 0; k < NV; ++k) diffs[k] = malloc(sizeof(double) * n);

    /* daily scan; also collect Swiss sign changes for the station set */
    double* st_lo = malloc(sizeof(double) * 4000); double* st_hi = malloc(sizeof(double) * 4000);
    for (i = 0; i < n; ++i) {
        ut = (j0 + i) - 2451545.0;
        if (speeds(ut, sp, &tt)) { fprintf(stderr, "lib fail %d\n", i); return 1; }
        sw = swiss_speed(tt, err);
        for (k = 0; k < NV; ++k) { add(&daily[k], sp[k] - sw, ut, bound); diffs[k][i] = fabs(sp[k] - sw); }
        if (have_prev && ((prev_sw < 0) != (sw < 0))) { st_lo[stations] = prev_ut; st_hi[stations] = ut; stations++; }
        prev_sw = sw; prev_ut = ut; have_prev = 1;
    }
    /* formal-equivalent set: 53 reference instants + station +- {0,1,5,20} days (as the test) */
    f = fopen(argv[3], "r");
    while (fscanf(f, "%lf", &ut) == 1) {
        speeds(ut, sp, &tt); sw = swiss_at(ut);
        for (k = 0; k < NV; ++k) add(&formal[k], sp[k] - sw, ut, bound);
    }
    fclose(f);
    for (i = 0; i < stations; ++i) {
        double lo = st_lo[i], hi = st_hi[i], mid;
        int it; int neg_lo = swiss_at(lo) < 0;
        for (it = 0; it < 12; ++it) { mid = (lo + hi) / 2; if ((swiss_at(mid) < 0) == neg_lo) lo = mid; else hi = mid; }
        mid = (lo + hi) / 2;
        const double offs[7] = {0, 1, -1, 5, -5, 20, -20};
        for (int o = 0; o < 7; ++o) {
            double u = mid + offs[o];
            if (speeds(u, sp, &tt)) continue;
            sw = swiss_at(u);
            for (k = 0; k < NV; ++k) add(&formal[k], sp[k] - sw, u, bound);
        }
    }
    printf("%s: %d daily samples, %d Swiss stations, bound %.5f\n", argv[1], n, stations, bound);
    for (k = 0; k < NV; ++k) {
        qsort(diffs[k], n, sizeof(double), cmpd);
        printf("%-30s daily: max %.6f (ut %.1f) mean %.6f p99 %.6f p99.9 %.6f over-bound %d | formal-set: max %.6f (ut %.4f) mean %.6f over %d of %d\n",
               names[k], daily[k].max, daily[k].at, daily[k].sum / daily[k].n, diffs[k][n * 99 / 100], diffs[k][n * 999 / 1000], daily[k].over,
               formal[k].max, formal[k].at, formal[k].sum / formal[k].n, formal[k].over, formal[k].n);
    }
    return 0;
}
