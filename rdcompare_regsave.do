*****RDCOMPARE USING REG SAVE (ADVANCED), we can include more than one outcome variable
set more off, permanently 
clear all
set seed 123

* Program for comparing RD
capture program drop rdcompare
program rdcompare, eclass
    version 16
    syntax varlist(numeric), mediana(varname numeric)
	tokenize `varlist'
	sum `mediana', detail
	rdrobust `varlist' if `mediana' > `r(p50)'  &  `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
	local bw=e(h_l)
	tempvar touse1
	gen `touse1'=e(sample)
	matrix treat11 = e(b)
	matrix treat1 = treat11[1,3]
	sum `mediana', detail
	rdrobust `varlist' if `mediana' <= `r(p50)'  &  `mediana'!=., c(0) p(1) vce(hc1) covs($covars) all
	tempvar touse2
	gen `touse2'=e(sample)
	matrix treat22 = e(b)
	matrix treat2 = treat22[1,3]
	matrix diff = treat2 - treat1
	tempvar touse
	gen `touse'=`touse1'==1 | `touse2'==1
	ereturn post diff, esample(`touse') depname(`1')
end

* Program for formatting
capture program drop rdcompareformat
program rdcompareformat, eclass
    version 16
    syntax varlist(numeric), mediana(varname numeric)
tempfile regs
local replace replace
foreach k in $lista {
local label_`k': var lab `k'
quietly sum `mediana', detail
rdrobust `k' `varlist' if `mediana' > `r(p50)' & `mediana'!=., c(0) p(1) vce(hc1) covs($covars)  all
local bw=e(h_l)
regsave using "`regs'", t p addlabel(dep,`k',col,"(1)",Ancho_banda,`bw') `replace'
local replace append
quietly sum `mediana', detail
rdrobust `k' `varlist' if `mediana' <= `r(p50)' & `mediana'!=., c(0) p(1) vce(hc1) covs($covars)  all
local bw=e(h_l)
regsave using "`regs'", t p addlabel(dep,`k',col,"(2)",Ancho_banda,`bw') `replace'
bootstrap, reps(2): rdcompare `k' `varlist', mediana(`mediana')
regsave using "`regs'", t p addlabel(dep,`k',col,"(2)-(1)",Ancho_banda,`bw') `replace'
tempfile mytable
local replace replace
preserve
use "`regs'", clear
replace var="Robust" if var=="c1"
keep if var=="Robust"
regsave_tbl using "`mytable'" if dep=="`k'" & col=="(1)", name(col1) asterisk(10 5 1) parentheses(stderr) format(%9.3fc) `replace'
local replace append
regsave_tbl using "`mytable'" if dep=="`k'" & col=="(2)", name(col2) asterisk(10 5 1) parentheses(stderr) format(%9.3fc) `replace'
regsave_tbl using "`mytable'" if dep=="`k'" & col=="(2)-(1)", name(col3) asterisk(10 5 1) parentheses(stderr) format(%9.3fc) `replace'
use "`mytable'", clear
drop if strpos(var,"tstat") | strpos(var,"pval") | strpos(var,"dep") | var=="col"
replace var = subinstr(var,"Robust_coef","`k'",1)
replace var = "" if strpos(var,"_stderr")
replace var="Bandwidth" if var=="Ancho_banda"
replace var="Observations" if var=="N"
tempfile b`k'
save `b`k''
restore
}
clear
foreach k in $lista {
append using `b`k''
replace var="`label_`k''" if var=="`k'"
}
label var col1 "Below p(50)"
label var col2 "Above p(50)"
label var col3 "Difference"
label var var "Outcomes"
cou 
local N1 = `r(N)'+1
set obs `N1'
gen id=_n
replace col1="(1)" in `N1'
replace col2="(2)" in `N1'
replace col3="(2)-(1)" in `N1'
replace id=0.5 if id==`N1'
sort id
drop id 
end

local running "margin"
local mediana "termssenate"
global lista "vote lnp" // we can include more than one outcome
global covars "termshouse"

use https://github.com/rdpackages/rdrobust/raw/master/stata/rdrobust_senate.dta, clear
gen lnp=ln(population)
lab var lnp "log Population"
rdcompareformat `running', mediana(`mediana')
export excel using "C:\Users\Dell\Downloads\resultados_rdcompare.xlsx", cell(A2) firstrow(varl)
