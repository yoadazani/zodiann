/*
 * ZOD-EPH-004 D12 spike tooling (not part of any build): prints Swiss
 * Ephemeris's delta T, in seconds, for each Julian day (UT) given as a
 * command-line argument, from swe_deltat_ex(jd_ut, SEFLG_SWIEPH, serr) with
 * the ephemeris files set (the tidal acceleration, and so delta T, depends on
 * the ephemeris in use; plain swe_deltat depends on the last ephemeris call).
 *
 *   gcc -O1 -I<swisseph/upstream> -o swiss_delta_t swiss_delta_t.c \
 *       <swisseph/upstream>/{swedate,swehouse,swejpl,swemmoon,swemplan,sweph,swephlib,swecl,swehel}.c -lm
 *   ./swiss_delta_t <ephe path> 2451545.0 2488069.5
 *
 * The Swiss Ephemeris sources are the vendored AGPL-3.0 files already in the
 * repository (native/swisseph/upstream); this helper only links against them
 * in a scratch build and distributes nothing.
 */
#include <stdio.h>
#include <stdlib.h>

#include "swephexp.h"

int main(int argc, char** argv)
{
    char serr[AS_MAXCH];
    int i;
    if (argc < 3)
    {
        fprintf(stderr, "usage: swiss_delta_t <ephe path> <jd_ut>...\n");
        return 2;
    }
    swe_set_ephe_path(argv[1]);
    for (i = 2; i < argc; ++i)
    {
        double jd = strtod(argv[i], NULL);
        double dt = swe_deltat_ex(jd, SEFLG_SWIEPH, serr);
        printf("%.9f %.6f\n", jd, dt * 86400.0);
    }
    swe_close();
    return 0;
}
