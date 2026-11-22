#include <stdio.h>
#include <math.h>
#include "astronomy.h"
#include "swephexp.h"
int main(int c,char**v){swe_set_ephe_path(v[1]);double mx=0;
 for(double ut=-36000;ut<36000;ut+=7.31){astro_time_t t=Astronomy_TimeFromDays(ut);double a[6],b[6];char e[256];
  swe_calc(t.tt+2451545.0,1,SEFLG_SWIEPH|SEFLG_SPEED,a,e);swe_calc(t.tt+2451545.0,1,SEFLG_SWIEPH|SEFLG_SPEED|SEFLG_NOGDEFL,b,e);
  double d=fabs(a[3]-b[3]);if(d>mx)mx=d;}
 printf("Moon: max |default - NOGDEFL| speed over 1900-2100 sampled every 7.31 d: %.3e\n",mx);return 0;}
