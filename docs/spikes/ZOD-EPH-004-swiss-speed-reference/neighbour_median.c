/* Scratch: statistic m(t) = |s(t) - median{s(t-2d), s(t-1d), s(t+1d), s(t+2d)}|
 * of Swiss's own speed values (TT-consistent daily samples), per body. */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "astronomy.h"
#include "swephexp.h"
static double jd_from_ymd(int y,int m,int d){int a=(14-m)/12,yy=y+4800-a,mm=m+12*a-3;return d+(153*mm+2)/5+365.0*yy+yy/4-yy/100+yy/400-32045-0.5;}
static int cmpd(const void*a,const void*b){double x=*(double*)a,y=*(double*)b;return x<y?-1:x>y;}
static double med4(double a,double b,double c,double d){double v[4]={a,b,c,d};qsort(v,4,sizeof(double),cmpd);return (v[1]+v[2])/2;}
int main(int argc,char**argv){
  const char* nm[10]={"sun","moon","mercury","venus","mars","jupiter","saturn","uranus","neptune","pluto"};
  double j0=jd_from_ymd(1900,1,1),j1=jd_from_ymd(2099,12,31);int n=(int)(j1-j0)+1,i,b;
  swe_set_ephe_path(argv[1]);
  double* s=malloc(sizeof(double)*n),*m=malloc(sizeof(double)*n);
  for(b=2;b<10;b++){
    for(i=0;i<n;i++){double ut=(j0+i)-2451545.0;astro_time_t t=Astronomy_TimeFromDays(ut);double xx[6];char e[256]="";swe_calc(t.tt+2451545.0,b,SEFLG_SWIEPH|SEFLG_SPEED,xx,e);s[i]=xx[3];}
    int c1=0,c2=0,c3=0,c4=0,c5=0;double mx=0;int at=0;int cnt=0;double* mm=malloc(sizeof(double)*n);
    for(i=2;i<n-2;i++){double q=fabs(s[i]-med4(s[i-2],s[i-1],s[i+1],s[i+2]));mm[cnt++]=q;if(q>mx){mx=q;at=i;}
      if(q>3e-5)c1++;if(q>1e-4)c2++;if(q>2e-4)c3++;if(q>3e-4)c4++;if(q>1e-3)c5++;}
    qsort(mm,cnt,sizeof(double),cmpd);
    printf("%-8s m(t): p50 %.1e p99 %.1e p99.9 %.1e p99.99 %.1e max %.1e (day %d => ut %.1f) | >3e-5:%d >1e-4:%d >2e-4:%d >3e-4:%d >1e-3:%d\n",nm[b],mm[cnt/2],mm[cnt*99/100],mm[cnt*999/1000],mm[cnt*9999/10000],mx,at,(j0+at)-2451545.0,c1,c2,c3,c4,c5);
    free(mm);
  }
  return 0;}
