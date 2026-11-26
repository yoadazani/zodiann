/*
 * SPDX-License-Identifier: AGPL-3.0-only
 *
 * ZOD-EPH-002: serialized access to one shared Swiss Ephemeris state.
 *
 * The library keeps global state (the ephemeris path, open files, cached
 * positions). Built with TLSOFF, that state is one for the whole process, so
 * a path set once applies to every thread, and calls must not interleave.
 *
 * The mutex is not recursive: a function here never calls another function
 * here. Upstream functions call each other freely (swe_set_ephe_path calls
 * swe_calc internally); that is safe because the inner call is the unlocked
 * upstream symbol, already running under this thread's lock.
 */
#ifndef TLSOFF
#error "build with -DTLSOFF: the lock assumes one shared library state"
#endif

#include <pthread.h>

#include "swephexp.h"
#include "zodiann_swiss_lock.h"

static pthread_mutex_t zodiann_swiss_mutex = PTHREAD_MUTEX_INITIALIZER;

void zodiann_swiss_version(char *out) {
  pthread_mutex_lock(&zodiann_swiss_mutex);
  swe_version(out);
  pthread_mutex_unlock(&zodiann_swiss_mutex);
}

void zodiann_swiss_set_ephe_path(const char *path) {
  pthread_mutex_lock(&zodiann_swiss_mutex);
  swe_set_ephe_path(path);
  pthread_mutex_unlock(&zodiann_swiss_mutex);
}

void zodiann_swiss_close(void) {
  pthread_mutex_lock(&zodiann_swiss_mutex);
  swe_close();
  pthread_mutex_unlock(&zodiann_swiss_mutex);
}

int zodiann_swiss_calc_ut(double tjd_ut, int ipl, int iflag, double *xx,
                          char *serr) {
  int returned;
  pthread_mutex_lock(&zodiann_swiss_mutex);
  returned = swe_calc_ut(tjd_ut, ipl, iflag, xx, serr);
  pthread_mutex_unlock(&zodiann_swiss_mutex);
  return returned;
}

int zodiann_swiss_calc_tt(double tjd_tt, int ipl, int iflag, double *xx,
                          char *serr) {
  int returned;
  pthread_mutex_lock(&zodiann_swiss_mutex);
  returned = swe_calc(tjd_tt, ipl, iflag, xx, serr);
  pthread_mutex_unlock(&zodiann_swiss_mutex);
  return returned;
}
