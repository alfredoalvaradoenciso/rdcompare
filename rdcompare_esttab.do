*** RDCOMPARE USING ESTTAB (BASIC)

use https://github.com/rdpackages/rdrobust/raw/master/stata/rdrobust_senate.dta, clear
capture program drop mydisp
program mydisp, eclass
	matrix betass=e(b)
    matrix colnames betass = "Dem vote share in next election"
    mat list betass
    ereturn repost b = betass, rename
	end
quietly sum termssenate ,d 
rdrobust  vote	margin  if  termssenate>`r(p50)' &  termssenate!=., c(0) p(1) masspoints(off) vce(hc1) 
estadd scalar bw e(h_l), replace
mydisp
estimates store est1
quietly sum termssenate   ,d
rdrobust 	vote	margin  if  termssenate<`r(p50)', c(0) p(1) masspoints(off) vce(hc1) 
estadd scalar bw e(h_l), replace
mydisp
estimates store est2

capture program drop rdcompare
program rdcompare, eclass
    version 16
    syntax varlist(numeric), mediana(varname numeric)
	 sum `mediana',d
	 rdrobust `varlist'  if  `mediana' > `r(p50)'  & `mediana'!=., c(0) p(1) masspoints(off) vce(hc1) 
	matrix treat1 = e(b)
	tempvar touse1
	gen `touse1'=e(sample)
	sum `mediana'	  ,d
	 rdrobust `varlist'  if  `mediana' < `r(p50)', c(0) p(1) masspoints(off) vce(hc1)  
	matrix treat2 = e(b)
	tempvar touse2
	gen `touse2'=e(sample)
	matrix diff = treat2 - treat1
	tempvar touse
	gen `touse'=`touse1'==1 | `touse2'==1
	ereturn post diff, esample(`touse') depname(`1')
end
bootstrap, reps(10): rdcompare  vote  margin , mediana(termssenate)
mydisp
estimates store est3
esttab est1 est2 est3 
