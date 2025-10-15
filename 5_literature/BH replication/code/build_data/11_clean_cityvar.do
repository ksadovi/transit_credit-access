* Combines county- and pref-level data

use "$data/temp_outputs/prefabove_selected_variables_wide", clear
gen source = "prefabove"
sort city_cn 
append using "$data/temp_outputs/clevel_selected_variables_wide"
replace source = "clevel" if mi(source)
local vars *20*

/* 	For duplicates, collect the correct one in the last entry, _n==_N */

gen conflicts = ""

foreach var of varlist `vars' {

	bysort city_cn : replace `var' = `var'[1] if mi(`var')
	bysort city_cn : replace conflicts = conflicts + " `var'" if `var' != `var'[1] & !mi(`var') & !mi(`var'[1]) & _n==_N & _N==2
	bysort city_cn : replace `var' = . if `var' != `var'[1] & !mi(`var') & !mi(`var'[1]) & _n==_N & _N==2
	
}
list city_cn conflicts if conflicts!=""
drop if conflicts!="" & source=="clevel" // for two cities with conflicts, prefabove it correct
drop conflicts

bysort city_cn : replace source = "both" if _N==2
bysort city_cn : keep if _n==_N // keep only the last entry

save "$data/temp_outputs/build_database_output/city_variables", replace


