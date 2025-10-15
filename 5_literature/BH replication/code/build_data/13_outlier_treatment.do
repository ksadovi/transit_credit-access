// Drop outliers for the outcomes (variables stored in $var_prefix)

/* KEY VARIABLE DEFINITIONS:

	- x_obs_`var' : =1 if growth outlier (sustained change or jump occurs)
	- j_obs_`var' : =1 if jump 
	- s_obs_`var' : =1 if sustained change (this current routine only flags 
						the beginning of a sustained change)
	- x_`var' : =1 if the city experiences a growth outlier
	- j_`var' : =1 if the city experiences a jump
	- s_`var' : =1 if the city experiences a sustained change
*/

global outcomes = "avgnworkers_ppl_wc"

*-- Transfer variable selection from master_hsr and reformat outcome list --*
local t = log(2) // threshold for a jump
local y1 = 2007
local y2 = 2016
	
foreach var of global outcomes {
	use "$data/city_database_long", clear
/*	local y1 = 2007
	if ("`var'"!="railpaxtfc_ppl_wc") local y2 = 2016 
		else local y2 = 2014 */
	
	keep if inrange(year,`y1',`y2')
	keep cityid year `var'
	
	* Version in logs
	gen log_`var' = log(`var')
	local label_`var' : variable label `var'
	
	* Non-missing obs only
	keep if !mi(log_`var') 
	
	* Change in the variable rel to prev and next available periods (missing in the first/last non-missing obs for a city)
	gen d_`var' = log_`var'-log_`var'[_n-1] if cityid[_n-1]==cityid
	gen d_p1_`var' = log_`var'[_n+1]-log_`var' if cityid[_n+1]==cityid
	
	* Any big change relative to the previous observation:
	gen byte x_obs_`var' = abs(d_`var')>`t' & !mi(d_`var')
	
	* One-off jump: a big change followed by a reverse change of the magnitude of [3/4,4/3] of this change
	gen byte j_obs_`var' = x_obs_`var' & !mi(d_p1_`var') & sign(d_`var')!=sign(d_p1_`var') & inrange(abs(d_p1_`var'),(3/4)*abs(d_`var'),(4/3)*abs(d_`var'))
	
	* Sustained change: a big change that is not a one-off jump if the previous observation is not also a big change (as in the case of a reversal of a jump)
	bys cityid: gen byte s_obs_`var' = x_obs_`var' & !j_obs_`var' & (x_obs_`var'[_n-1]!=1)
	
	* Jumps for a prefecture in any year?
	foreach jtype in x j s {
		egen byte `jtype'_`var' = sum(`jtype'_obs_`var'), by(cityid)
	}
	
	* Now keep 2007, 2016 values + growth rate which removes sustained changes
	keep if year==`y1' | year==`y2'
	bys cityid : keep if _N==2 // only cities with non-missing values in both
	drop *_obs_* d_`var' d_p1_`var'
	reshape wide `var' log_`var', i(cityid) j(year)
	gen dlog_`var' = log_`var'`y2'-log_`var'`y1' if s_`var'==0
	replace dlog_`var' = .s if s_`var'>0
	
	label variable `var'`y1' "`label_`var'', `y1'"
	label variable `var'`y2' "`label_`var'', `y2'"
	label variable log_`var'`y1' "Log `label_`var'', `y1'"
	label variable log_`var'`y2' "Log `label_`var'', `y2'"
	label variable dlog_`var' "Growth rate `label_`var'', `y1'--`y2'"
	
	tempfile c_`var'
	save "`c_`var''"
	local filelist `"`filelist' `c_`var''"'
}

clear
foreach file of local filelist {
	if (_N==0) use "`file'"
		else merge 1:1 cityid using "`file'", nogen
}
save "$data/outcomes_`y1'_`y2'", replace
