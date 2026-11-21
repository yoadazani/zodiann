/*
 * ZOD-EPH-004 Task 3 Step 1b: see zodiann_moon_rate.h.
 *
 * Included by zodiann_astronomy_shim.c AFTER the unmodified upstream
 * `upstream/astronomy.c`, in the same translation unit. It uses that file's
 * PI2, ARC, EARTH_EQUATORIAL_RADIUS_AU, e_tilt, obl_ecl2equ_vec, nutation and
 * RotateEquatorialToEcliptic. Nothing here edits upstream.
 *
 * Mathematics: see docs/spikes/ZOD-EPH-004-moon-derivative.md, section 2. In
 * short, every quantity of upstream's CalcMoon is a closed-form function of T
 * (Julian centuries of TT since J2000): sines and cosines of arguments that
 * are polynomials in T, products, and one reciprocal. The value path below
 * mirrors CalcMoon statement for statement (same expressions, same order of
 * accumulation, so the values agree with upstream to rounding), and the rate
 * path differentiates each statement exactly. A dot (d...) is d/dT per
 * century.
 */
#include "zodiann_moon_rate.h"
#include "zodiann_moon_terms.h"

/* One of the four fundamental arguments (L, LS, F, D), upstream's index I - 1. */
#define ZMOON_ARG_COUNT 4

typedef struct {
    double t;                           /* centuries of TT since J2000 */
    /* Long-periodic corrections (arcseconds) and their rates. */
    double dl0, dl, dls, df, dd, dgam;
    double dl0d, dld, dlsd, dfd, ddd, dgamd;
    /* Mean longitude of the Moon (L0), radians, and its rate. */
    double l0, l0d;
    /* The four arguments and their rates, radians and radians per century. */
    double arg[ZMOON_ARG_COUNT];
    double argd[ZMOON_ARG_COUNT];
    /* alpha = FAC' / FAC for each argument (the scale factor's log rate). */
    double alpha[ZMOON_ARG_COUNT];
    /* CO(j, i) and SI(j, i) of upstream, j in -6..6 stored at j + 6. */
    double co[13][ZMOON_ARG_COUNT];
    double si[13][ZMOON_ARG_COUNT];
    /* Accumulators and their rates. */
    double dlam, ds, gam1c, sinpi, n;
    double dlamd, dsd, gam1cd, sinpid, nd;
} zodiann_moon_ctx;

#define ZMOON_CO(c, j, i) ((c)->co[(j) + 6][(i)])
#define ZMOON_SI(c, j, i) ((c)->si[(j) + 6][(i)])

static double zodiann_moon_frac(double x)
{
    return x - floor(x);
}

/* upstream's Sine(a + b T): sin of (a + b T) revolutions, and its rate. */
static void zodiann_moon_sine(double a, double b, double t, double *value, double *rate)
{
    double phase = PI2 * (a + b * t);
    *value = sin(phase);
    *rate = PI2 * b * cos(phase);
}

/* upstream's LongPeriodic. */
static void zodiann_moon_long_periodic(zodiann_moon_ctx *c)
{
    double S1, S2, S3, S4, S5, S6, S7;
    double R1, R2, R3, R4, R5, R6, R7;
    double G1, G2, G3, H1, H2, H3;
    const double T = c->t;

    zodiann_moon_sine(0.19833, 0.05611, T, &S1, &R1);
    zodiann_moon_sine(0.27869, 0.04508, T, &S2, &R2);
    zodiann_moon_sine(0.16827, -0.36903, T, &S3, &R3);
    zodiann_moon_sine(0.34734, -5.37261, T, &S4, &R4);
    zodiann_moon_sine(0.10498, -5.37899, T, &S5, &R5);
    zodiann_moon_sine(0.42681, -0.41855, T, &S6, &R6);
    zodiann_moon_sine(0.14943, -5.37511, T, &S7, &R7);

    c->dl0 = 0.84*S1+0.31*S2+14.27*S3+ 7.26*S4+ 0.28*S5+0.24*S6;
    c->dl  = 2.94*S1+0.31*S2+14.27*S3+ 9.34*S4+ 1.12*S5+0.83*S6;
    c->dls =-6.40*S1                                   -1.89*S6;
    c->df  = 0.21*S1+0.31*S2+14.27*S3-88.70*S4-15.30*S5+0.24*S6-1.86*S7;
    c->dd  = c->dl0 - c->dls;

    c->dl0d = 0.84*R1+0.31*R2+14.27*R3+ 7.26*R4+ 0.28*R5+0.24*R6;
    c->dld  = 2.94*R1+0.31*R2+14.27*R3+ 9.34*R4+ 1.12*R5+0.83*R6;
    c->dlsd =-6.40*R1                                   -1.89*R6;
    c->dfd  = 0.21*R1+0.31*R2+14.27*R3-88.70*R4-15.30*R5+0.24*R6-1.86*R7;
    c->ddd  = c->dl0d - c->dlsd;

    zodiann_moon_sine(0.59734, -5.37261, T, &G1, &H1);
    zodiann_moon_sine(0.35498, -5.37899, T, &G2, &H2);
    zodiann_moon_sine(0.39943, -5.37511, T, &G3, &H3);
    c->dgam  = -3332E-9 * G1 - 539E-9 * G2 - 64E-9 * G3;
    c->dgamd = -3332E-9 * H1 - 539E-9 * H2 - 64E-9 * H3;
}

/* upstream's AddThe: a complex product. */
static void zodiann_moon_add_the(double c1, double s1, double c2, double s2, double *c, double *s)
{
    *c = c1*c2 - s1*s2;
    *s = s1*c2 + c1*s2;
}

/* upstream's Init. */
static void zodiann_moon_init(zodiann_moon_ctx *c)
{
    const double T = c->t;
    const double T2 = T * T;
    int i, j, max;
    double fac, facd, arg;

    c->dlam = 0.0;
    c->ds = 0.0;
    c->gam1c = 0.0;
    c->sinpi = 3422.7000;
    c->dlamd = 0.0;
    c->dsd = 0.0;
    c->gam1cd = 0.0;
    c->sinpid = 0.0;
    zodiann_moon_long_periodic(c);

    c->l0 = PI2*zodiann_moon_frac(0.60643382+1336.85522467*T-0.00000313*T2) + c->dl0/ARC;
    c->arg[0] = PI2*zodiann_moon_frac(0.37489701+1325.55240982*T+0.00002565*T2) + c->dl /ARC;  /* L  */
    c->arg[1] = PI2*zodiann_moon_frac(0.99312619+  99.99735956*T-0.00000044*T2) + c->dls/ARC;  /* LS */
    c->arg[2] = PI2*zodiann_moon_frac(0.25909118+1342.22782980*T-0.00000892*T2) + c->df /ARC;  /* F  */
    c->arg[3] = PI2*zodiann_moon_frac(0.82736186+1236.85308708*T-0.00000397*T2) + c->dd /ARC;  /* D  */

    /* d/dT of 2 pi Frac(a + b T + c T^2) is 2 pi (b + 2 c T): Frac only adds a
     * constant between its jumps, and every use is periodic in the angle. */
    c->l0d = PI2*(1336.85522467 - 2.0*0.00000313*T) + c->dl0d/ARC;
    c->argd[0] = PI2*(1325.55240982 + 2.0*0.00002565*T) + c->dld /ARC;
    c->argd[1] = PI2*(  99.99735956 - 2.0*0.00000044*T) + c->dlsd/ARC;
    c->argd[2] = PI2*(1342.22782980 - 2.0*0.00000892*T) + c->dfd /ARC;
    c->argd[3] = PI2*(1236.85308708 - 2.0*0.00000397*T) + c->ddd /ARC;

    for (i = 0; i < ZMOON_ARG_COUNT; ++i)
    {
        arg = c->arg[i];
        switch (i)
        {
            case 0:  max = 4; fac = 1.000002208;                       facd = 0.0;                  break;
            case 1:  max = 3; fac = 0.997504612-0.002495388*T;         facd = -0.002495388;         break;
            case 2:  max = 4; fac = 1.000002708+139.978*c->dgam;       facd = 139.978*c->dgamd;     break;
            default: max = 6; fac = 1.0;                               facd = 0.0;                  break;
        }
        c->alpha[i] = facd / fac;
        ZMOON_CO(c, 0, i) = 1.0;
        ZMOON_CO(c, 1, i) = cos(arg)*fac;
        ZMOON_SI(c, 0, i) = 0.0;
        ZMOON_SI(c, 1, i) = sin(arg)*fac;
        for (j = 2; j <= max; ++j)
            zodiann_moon_add_the(
                ZMOON_CO(c, j-1, i), ZMOON_SI(c, j-1, i),
                ZMOON_CO(c, 1, i), ZMOON_SI(c, 1, i),
                &ZMOON_CO(c, j, i), &ZMOON_SI(c, j, i));
        for (j = 1; j <= max; ++j)
        {
            ZMOON_CO(c, -j, i) =  ZMOON_CO(c, j, i);
            ZMOON_SI(c, -j, i) = -ZMOON_SI(c, j, i);
        }
    }
}

/*
 * upstream's Term(p, q, r, s): the product over the four arguments of
 * z_k^{n_k}, with z_k = FAC_k e^{i ARG_k} (the conjugate for a negative n_k),
 * as x + i y. Also returns its rate (xd + i yd):
 *   w' = w * sum_k ( |n_k| alpha_k + i n_k ARG_k' ).
 */
static void zodiann_moon_term(const zodiann_moon_ctx *c, int p, int q, int r, int s,
                              double *x, double *y, double *xd, double *yd)
{
    const int n[ZMOON_ARG_COUNT] = { p, q, r, s };
    double sum_re = 0.0, sum_im = 0.0;
    int k;

    *x = 1.0;
    *y = 0.0;
    for (k = 0; k < ZMOON_ARG_COUNT; ++k)
    {
        if (n[k] != 0)
        {
            zodiann_moon_add_the(*x, *y, ZMOON_CO(c, n[k], k), ZMOON_SI(c, n[k], k), x, y);
            sum_re += (double)(n[k] < 0 ? -n[k] : n[k]) * c->alpha[k];
            sum_im += (double)n[k] * c->argd[k];
        }
    }
    *xd = (*x) * sum_re - (*y) * sum_im;
    *yd = (*y) * sum_re + (*x) * sum_im;
}

/* upstream's CalcMoon, with rates. T is centuries of TT since J2000. */
static void zodiann_moon_series(double centuries_tt, zodiann_moon_series_t *out)
{
    zodiann_moon_ctx ctx;
    zodiann_moon_ctx *c = &ctx;
    double x, y, xd, yd;
    double planetary, planetaryd;
    double S, Sd, G, Gd, H, Hd, lat_seconds, lat_secondsd;
    double lonarg, lonargd;
    int i;

    c->t = centuries_tt;
    zodiann_moon_init(c);

    /* upstream's 104 AddSol(...) calls, in source order (generated table). */
    for (i = 0; i < ZODIANN_MOON_TERM_COUNT; ++i)
    {
        const zodiann_moon_term_t *m = &kZodiannMoonTerms[i];
        zodiann_moon_term(c, m->p, m->q, m->r, m->s, &x, &y, &xd, &yd);
        c->dlam   += m->coeffl*y;   c->dlamd   += m->coeffl*yd;
        c->ds     += m->coeffs*y;   c->dsd     += m->coeffs*yd;
        c->gam1c  += m->coeffg*x;   c->gam1cd  += m->coeffg*xd;
        c->sinpi  += m->coeffp*x;   c->sinpid  += m->coeffp*xd;
    }

    /* upstream's SolarN: 10 ADDN(...) terms (generated table). */
    c->n = 0.0;
    c->nd = 0.0;
    for (i = 0; i < ZODIANN_MOON_N_TERM_COUNT; ++i)
    {
        const zodiann_moon_n_term_t *m = &kZodiannMoonNTerms[i];
        zodiann_moon_term(c, m->p, m->q, m->r, m->s, &x, &y, &xd, &yd);
        c->n  += m->coeffn*y;
        c->nd += m->coeffn*yd;
    }

    /* upstream's Planetary: eleven sines added to DLAM. */
    {
        const double T = c->t;
        double P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11;
        double Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11;
        zodiann_moon_sine(0.7736,  -62.5512, T, &P1, &Q1);
        zodiann_moon_sine(0.0466, -125.1025, T, &P2, &Q2);
        zodiann_moon_sine(0.5785,  -25.1042, T, &P3, &Q3);
        zodiann_moon_sine(0.4591, +1335.8075, T, &P4, &Q4);
        zodiann_moon_sine(0.3130,  -91.5680, T, &P5, &Q5);
        zodiann_moon_sine(0.1480, +1331.2898, T, &P6, &Q6);
        zodiann_moon_sine(0.5918, +1056.5859, T, &P7, &Q7);
        zodiann_moon_sine(0.5784, +1322.8595, T, &P8, &Q8);
        zodiann_moon_sine(0.2275,   -5.7374, T, &P9, &Q9);
        zodiann_moon_sine(0.2965,   +2.6929, T, &P10, &Q10);
        zodiann_moon_sine(0.3132,   +6.3368, T, &P11, &Q11);
        planetary =
            +0.82*P1+0.31*P2
            +0.35*P3+0.66*P4
            +0.64*P5+1.14*P6
            +0.21*P7+0.44*P8
            +0.24*P9+0.28*P10
            +0.33*P11;
        planetaryd =
            +0.82*Q1+0.31*Q2
            +0.35*Q3+0.66*Q4
            +0.64*Q5+1.14*Q6
            +0.21*Q7+0.44*Q8
            +0.24*Q9+0.28*Q10
            +0.33*Q11;
        c->dlam  += planetary;
        c->dlamd += planetaryd;
    }

    /* upstream's final assembly. */
    S  = c->arg[2] + c->ds/ARC;            /* F + DS/ARC */
    Sd = c->argd[2] + c->dsd/ARC;
    G  = 1.000002708 + 139.978*c->dgam;
    Gd = 139.978*c->dgamd;
    H  = 18518.511 + 1.189 + c->gam1c;
    Hd = c->gam1cd;
    lat_seconds  = G*H*sin(S) - 6.24*sin(3*S) + c->n;
    lat_secondsd = Gd*H*sin(S) + G*Hd*sin(S) + G*H*cos(S)*Sd
                   - 6.24*3.0*cos(3*S)*Sd + c->nd;

    lonarg  = c->l0 + c->dlam/ARC;
    lonargd = c->l0d + c->dlamd/ARC;

    out->lon   = PI2 * zodiann_moon_frac(lonarg / PI2);
    out->lat   = lat_seconds * (DEG2RAD / 3600.0);
    out->dist  = (ARC * EARTH_EQUATORIAL_RADIUS_AU) / (0.999953253 * c->sinpi);
    out->dlon  = lonargd;
    out->dlat  = lat_secondsd * (DEG2RAD / 3600.0);
    out->ddist = -out->dist * c->sinpid / c->sinpi;
}

/*
 * The Moon's geocentric state, built exactly from the series and its rates in
 * ECM, then rotated to ECT by the same fixed chain `Astronomy_EclipticGeoMoon`
 * applies to the position, applied here to the position and to the velocity
 * alike. Velocities are AU per day (the rate per century divided by 36525).
 *
 * The rotation is fixed at the instant: the rate of change of the nutation and
 * obliquity (about 5e-5 degrees per day at most) is not included (documented).
 */
static void zodiann_moon_state(astro_time_t time, double r_ecm[3], double v_ecm[3],
                               double r_ect[3], double v_ect[3])
{
    zodiann_moon_series_t m;
    double cl, sl, cb, sb, speed_scale;
    double radial[3], d_lat[3], d_lon[3];
    earth_tilt_t et;
    double eqm[3], eqd[3];
    astro_ecliptic_t ecl;
    int i;

    zodiann_moon_series(time.tt / 36525.0, &m);

    cl = cos(m.lon);
    sl = sin(m.lon);
    cb = cos(m.lat);
    sb = sin(m.lat);

    radial[0] = cb*cl;       radial[1] = cb*sl;       radial[2] = sb;
    d_lat[0]  = -sb*cl;      d_lat[1]  = -sb*sl;      d_lat[2]  = cb;
    d_lon[0]  = -cb*sl;      d_lon[1]  = cb*cl;       d_lon[2]  = 0.0;

    speed_scale = 1.0 / 36525.0;
    for (i = 0; i < 3; ++i)
    {
        r_ecm[i] = m.dist * radial[i];
        v_ecm[i] = speed_scale * (m.ddist*radial[i] + m.dist*m.dlat*d_lat[i] + m.dist*m.dlon*d_lon[i]);
    }

    /* The chain of Astronomy_EclipticGeoMoon: ECM -> EQM (mean obliquity) ->
     * EQD (nutation) -> ECT (true obliquity). All three steps are linear. */
    et = e_tilt(&time);
    obl_ecl2equ_vec(et.mobl, time, r_ecm, eqm);
    nutation(eqm, &time, FROM_2000, eqd);
    ecl = RotateEquatorialToEcliptic(eqd, DEG2RAD * et.tobl, time);
    r_ect[0] = ecl.vec.x;  r_ect[1] = ecl.vec.y;  r_ect[2] = ecl.vec.z;

    obl_ecl2equ_vec(et.mobl, time, v_ecm, eqm);
    nutation(eqm, &time, FROM_2000, eqd);
    ecl = RotateEquatorialToEcliptic(eqd, DEG2RAD * et.tobl, time);
    v_ect[0] = ecl.vec.x;  v_ect[1] = ecl.vec.y;  v_ect[2] = ecl.vec.z;
}
