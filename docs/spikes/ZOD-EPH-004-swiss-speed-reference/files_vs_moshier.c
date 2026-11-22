/* Scratch: Swiss data-file speed against Swiss's built-in Moshier speed at the
 * same TT, daily 1900-2099, per body. No adapter value is used. */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "astronomy.h"
#include "swephexp.h"
static double jd_from_ymd(int y, int m, int d){int a=(14-m)/12,yy=y+4800-a,mm=m+12*a-3;return d+(153*mm+2)/5+365.0*yy+yy/4-yy/100+yy/400-32045-0.5;}
static int cmpd(const void*a,const void*b){double x=*(double*)a,y=*(double*)b;return x<y?-1:x>y;}
int main(int argc,char**argv){
  const char* nm[10]={"sun","moon","mercury","venus","mars","jupiter","saturn","uranus","neptune","pluto"};
  double j0=jd_from_ymd(1900,1,1), j1=jd_from_ymd(2099,12,31); int n=(int)(j1-j0)+1,i,b;
  swe_set_ephe_path(argv[1]);
  double* d=malloc(sizeof(double)*n);
  for(b=0;b<10;b++){
    int o1=0,o2=0,o3=0,o5=0; double mx=0; double at=0; int fb=0;
    for(i=0;i<n;i++){
      double ut=(j0+i)-2451545.0; astro_time_t t=Astronomy_TimeFromDays(ut); double jd=t.tt+2451545.0;
      double xf[6],xm[6]; char e1[256]="",e2[256]="";
      int r1=swe_calc(jd,b,SEFLG_SWIEPH|SEFLG_SPEED,xf,e1);
      int r2=swe_calc(jd,b,SEFLG_MOSEPH|SEFLG_SPEED,xm,e2);
      if(r1<0||r2<0||(r1&SEFLG_MOSEPH)){fb++;d[i]=0;continue;}
      double df=fabs(xf[3]-xm[3]); d[i]=df;
      if(df>mx){mx=df;at=ut;}
      if(df>1e-4)o1++; if(df>2e-4)o2++; if(df>3e-4)o3++; if(df>5e-4)o5++;
    }
    qsort(d,n,sizeof(double),cmpd);
    printf("%-8s fallback %d | |files-moshier| p50 %.2e p99 %.2e p99.9 %.2e p99.99 %.2e max %.2e (ut %.1f) | >1e-4:%d >2e-4:%d >3e-4:%d >5e-4:%d\n",nm[b],fb,d[n/2],d[n*99/100],d[n*999/1000],d[n*9999/10000],mx,at,o1,o2,o3,o5);
  }
  return 0;}
