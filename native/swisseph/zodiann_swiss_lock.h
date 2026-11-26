/*
 * SPDX-License-Identifier: AGPL-3.0-only
 *
 * ZOD-EPH-002: the only way Dart calls Swiss Ephemeris.
 *
 * Project-authored (AGPL-3.0-only like the rest of the project). It never
 * edits the vendored upstream source under `upstream/`. The library is built
 * with TLSOFF, so it has one state shared by every thread, and each function
 * here runs under one lock. Plain int, double and char arguments only, and no
 * system header, so the generated FFI bindings need no sysroot.
 */
#ifndef ZODIANN_SWISS_LOCK_H
#define ZODIANN_SWISS_LOCK_H

#ifdef __cplusplus
extern "C" {
#endif

/* swe_version. `out` holds at least 256 bytes. */
void zodiann_swiss_version(char *out);

/* swe_set_ephe_path. Applies to every thread. */
void zodiann_swiss_set_ephe_path(const char *path);

/* swe_close. Affects every thread. */
void zodiann_swiss_close(void);

/* swe_calc_ut. `xx` holds 6 doubles, `serr` at least 256 bytes. */
int zodiann_swiss_calc_ut(double tjd_ut, int ipl, int iflag, double *xx,
                          char *serr);

/* swe_calc, whose time argument is TT. Buffers as above. */
int zodiann_swiss_calc_tt(double tjd_tt, int ipl, int iflag, double *xx,
                          char *serr);

#ifdef __cplusplus
}
#endif

#endif /* ZODIANN_SWISS_LOCK_H */
