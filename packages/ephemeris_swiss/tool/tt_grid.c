/*
 * ZOD-EPH-002: prints, for each UT Julian day given on the command line, the
 * delta T in seconds that the vendored Swiss Ephemeris applies to it with the
 * packaged data files (the same call swe_calc_ut makes), one per line with 12
 * decimals. The first argument is the data directory. Host tool only, never
 * part of the app; tool/fetch_horizons_tt_reference.dart compiles it against
 * the unmodified upstream sources and runs it. It exits non-zero on any
 * library warning.
 */
#include <stdio.h>
#include <stdlib.h>

#include "swephexp.h"

int main(int argc, char **argv) {
  char serr[AS_MAXCH];
  int i;
  if (argc < 3) {
    fprintf(stderr, "usage: tt_grid <data directory> <jd ut>...\n");
    return 2;
  }
  swe_set_ephe_path(argv[1]);
  for (i = 2; i < argc; ++i) {
    double jd_ut = strtod(argv[i], NULL);
    double delta_t;
    serr[0] = '\0';
    delta_t = swe_deltat_ex(jd_ut, SEFLG_SWIEPH, serr);
    if (serr[0] != '\0') {
      fprintf(stderr, "%s: %s\n", argv[i], serr);
      return 1;
    }
    printf("%.12f\n", delta_t * 86400.0);
  }
  swe_close();
  return 0;
}
