*** RDCOMPARE USING ESTTAB (BASIC)
set more off, permanently 
clear all
set seed 123

capture program drop rdcompare
program rdcompare, eclass
    version 16
    syntax varlist(numeric), mediana(varname numeric)
	 sum `mediana',d
	 rdrobust `varlist'  if  `mediana' > `r(p50)' & `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
	matrix treat1 = e(b)
	tempvar touse1
	gen `touse1'=e(sample)
	sum `mediana'	  ,d
	 rdrobust `varlist'  if  `mediana' <= `r(p50)' & `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
	matrix treat2 = e(b)
	tempvar touse2
	gen `touse2'=e(sample)
	matrix diff = treat2 - treat1
	tempvar touse
	gen `touse'=`touse1'==1 | `touse2'==1
	ereturn post diff, esample(`touse') depname(`1')
end


local outcome "vote"
local running "margin"
local mediana "termssenate"
global covars "termshouse"

estimates clear 
use https://github.com/rdpackages/rdrobust/raw/master/stata/rdrobust_senate.dta, clear
quietly sum `mediana' ,d 
rdrobust `outcome' `running'  if  `mediana'>`r(p50)' &  `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
estadd scalar bw e(h_l), replace
estimates store est1
quietly sum `mediana'   ,d
rdrobust `outcome' `running'  if  `mediana'<=`r(p50)' &  `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
estadd scalar bw e(h_l), replace
estimates store est2
bootstrap, reps(2): rdcompare  `outcome' `running', mediana(`mediana')
estimates store est3
esttab est1 est2 est3 , se keep(Robust) coef(Robust "Dem vote share in next election")
