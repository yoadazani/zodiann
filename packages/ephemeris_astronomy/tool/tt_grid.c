/*
 * ZOD-EPH-004 D12: prints, for each UT-days value given as a command-line
 * argument, the UT days and the TT days that the vendored astronomy-engine
 * assigns to it (Astronomy_TimeFromDays), each with 17 significant digits so
 * that the doubles round-trip. Host tool only, never part of the app:
 *
 *   gcc -O0 -ffp-contract=off -o tt_grid tt_grid.c -lm
 *   ./tt_grid 0 36525.5
 *
 * It includes the same unmodified upstream file the shim includes, and calls
 * the same function the shim's single conversion helper calls. The device test
 * pins the result against the device's own hook (zodiann_test_time_for_ut).
 */
#include <stdio.h>
#include <stdlib.h>

#include "../../../native/astronomy_c/upstream/astronomy.c"

int main(int argc, char** argv)
{
    int i;
    for (i = 1; i < argc; ++i)
    {
        double ut_days = strtod(argv[i], NULL);
        astro_time_t t = Astronomy_TimeFromDays(ut_days);
        printf("%.17g %.17g\n", t.ut, t.tt);
    }
    return 0;
}
