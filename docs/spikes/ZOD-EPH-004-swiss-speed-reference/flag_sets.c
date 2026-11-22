#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "astronomy.h"
#include "swephexp.h"
int main(int argc,char**argv){
  swe_set_ephe_path(argv[1]);
  struct {const char*n;int f;} F[]={
    {"default",SEFLG_SWIEPH|SEFLG_SPEED},
    {"NOGDEFL",SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_NOGDEFL},
    {"NOABERR",SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_NOABERR},
    {"NONUT",SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_NONUT},
    {"TRUEPOS",SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_TRUEPOS},
    {"NOGDEFL+NOABERR(astrometric)",SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_NOGDEFL|SEFLG_NOABERR},
  };
  int nf=sizeof F/sizeof F[0];
  /* Uranus around 2075-01-01: day 27393.5 (UT days since J2000) hourly */
  printf("Uranus 2075-01-01, hourly from -8h to +10h (speed deg/day) by flag set\n");
  for(int k=0;k<nf;k++){
    printf("%-30s",F[k].n);
    for(int h=-8;h<=10;h+=2){
      double ut=27393.5+h/24.0; astro_time_t t=Astronomy_TimeFromDays(ut); double xx[6];char e[256]="";
      swe_calc(t.tt+2451545.0,7,F[k].f,xx,e); printf(" %.5f",xx[3]);
    }
    printf("\n");
  }
  printf("Uranus 1946-06-09 (ut -19564.5) hourly -8h..+10h\n");
  for(int k=0;k<nf;k++){
    printf("%-30s",F[k].n);
    for(int h=-8;h<=10;h+=2){
      double ut=-19564.5+h/24.0; astro_time_t t=Astronomy_TimeFromDays(ut); double xx[6];char e[256]="";
      swe_calc(t.tt+2451545.0,7,F[k].f,xx,e); printf(" %.5f",xx[3]);
    }
    printf("\n");
  }
  return 0;}
