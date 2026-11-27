/*
 * ZOD-TST-001: the Swiss Ephemeris lunar node reference. Prints first
 * "version <library version>", then for each TT Julian day given on the command
 * line one line:
 *
 *   <mean node> <returned flags> <mean node J2000> <true node>
 *
 * where the first two are SE_MEAN_NODE with SEFLG_SWIEPH | SEFLG_SPEED |
 * SEFLG_NONUT (the mean equinox of date, the frame of the app's formula), and
 * the last two are controls: the same body on the J2000 equinox, and
 * SE_TRUE_NODE with the default flags. Longitudes are in degrees, nine
 * decimals. The first argument is the data directory. Host tool only, never part
 * of the app; tool/horizons/swiss_host.dart compiles it against the unmodified
 * upstream sources and runs it. It exits non-zero on any library error or
 * warning.
 */
#include <stdio.h>
#include <stdlib.h>

#include "swephexp.h"

/* The longitude of [body], or exits. Returns the flags the library used. */
static int longitude_of(double jd_tt, int body, int flags, double *longitude) {
  double position[6];
  char serr[AS_MAXCH];
  int returned;
  serr[0] = '\0';
  returned = swe_calc(jd_tt, body, flags, position, serr);
  if (returned < 0 || serr[0] != '\0') {
    fprintf(stderr, "JD %.9f body %d: %s\n", jd_tt, body, serr);
    exit(1);
  }
  *longitude = position[0];
  return returned;
}

int main(int argc, char **argv) {
  const int mean_flags = SEFLG_SWIEPH | SEFLG_SPEED | SEFLG_NONUT;
  char version[AS_MAXCH];
  int i;
  if (argc < 3) {
    fprintf(stderr, "usage: node_grid <data directory> <jd tt>...\n");
    return 2;
  }
  swe_set_ephe_path(argv[1]);
  printf("version %s\n", swe_version(version));
  for (i = 2; i < argc; ++i) {
    double jd_tt = strtod(argv[i], NULL);
    double mean, j2000, true_node;
    int returned = longitude_of(jd_tt, SE_MEAN_NODE, mean_flags, &mean);
    longitude_of(jd_tt, SE_MEAN_NODE, mean_flags | SEFLG_J2000, &j2000);
    longitude_of(jd_tt, SE_TRUE_NODE, SEFLG_SWIEPH | SEFLG_SPEED, &true_node);
    printf("%.9f %d %.9f %.9f\n", mean, returned, j2000, true_node);
  }
  swe_close();
  return 0;
}
