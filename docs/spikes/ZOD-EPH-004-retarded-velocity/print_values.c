#define main est_main
#include "estimate.c"
#undef main
#include <stdint.h>
/* usage: est2 <ephe> body us_since_J2000 ... : prints body us V0 V2 (deg/day) */
int main(int argc, char** argv)
{
    int i;
    swe_set_ephe_path(argv[1]);
    for (i = 2; i + 1 < argc; i += 2) {
        const char* n = argv[i];
        int64_t us = strtoll(argv[i + 1], NULL, 10);
        double sp[NV], tt, ut = (double)us / 86400000000.0;
        if (!strcmp(n, "mercury")) { body_id = BODY_MERCURY; }
        else if (!strcmp(n, "venus")) { body_id = BODY_VENUS; }
        else if (!strcmp(n, "mars")) { body_id = BODY_MARS; }
        else if (!strcmp(n, "jupiter")) { body_id = BODY_JUPITER; }
        else if (!strcmp(n, "saturn")) { body_id = BODY_SATURN; }
        else if (!strcmp(n, "uranus")) { body_id = BODY_URANUS; }
        else if (!strcmp(n, "neptune")) { body_id = BODY_NEPTUNE; }
        else if (!strcmp(n, "pluto")) { body_id = BODY_PLUTO; }
        else { body_id = BODY_SUN; }
        if (speeds(ut, sp, &tt)) return 1;
        printf("%s %lld %.17g %.17g\n", n, (long long)us, sp[0], sp[2]);
    }
    return 0;
}
