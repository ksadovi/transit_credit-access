* Import county-level outcomes from the Yearbooks

clear all
set more off
set graphics off

* read file
import delimited using "${data}/temp_outputs/all_variables_clevel_wide.csv", clear encoding("utf-8")
cleanchars, in("rgdp") out("gdp") vname
cleanchars, in("yrendregpop") out("yrendtotpop") vname

* change the years from the publication year to the year of the variables
quietly{
	forval pub_year = 2000/2017 {
		local var_year = `pub_year' - 1 	
		cleanchars, in("`pub_year'") out("`var_year'") vname
	}
}

**********************************
*                                *
* construct variables for clevel *
*                                *
**********************************

quietly{
	**********************************
	*              GDP               *
	**********************************

	preserve
	keep city_cn gdp_cny* 

	reshape long gdp_cny, i(city_cn) j(year)

	tempfile gdp 
	save `gdp', replace

	restore

	***********************************
	* government revenue and spending *
	***********************************

	preserve
	keep city_cn gov*
	reshape long govexpenditure_cny govrevenue_cny, i(city_cn) j(year)

	tempfile gov_budget
	save `gov_budget', replace

	restore


	**********************************
	*           population           *
	**********************************
	preserve 
	keep city_cn yrend*pop*

	* looking at the documentations, 
	* year yrendregpop_ppl in 2016 and 2017 is the same variable as 
	* yrendtotpop_ppl in previous years

	reshape long yrendtotpop_ppl, i(city_cn) j(year)

	tempfile pop 
	save `pop', replace
	restore

	**********************************
	*           employment           *
	**********************************
	preserve
	keep city_cn *yrendempinunits* *urbavgnworkers*

	reshape long yrendempinunits_ppl urbavgnworkers_ppl, i(city_cn) j(year)

	tempfile emp 
	save `emp', replace 
	restore

	**********************************
	*              wage              *
	**********************************

	preserve
	keep city_cn *totwageworkers* *avgwage*
	reshape long urbtotwageworkers_cny avgwage_cny, i(city_cn) j(year)
	restore, not

**********************************
*     combine and save           *
**********************************
	* merge back in the other variables generated earlier
	foreach filename in gdp pop emp gov_budget {
		merge 1:1 city_cn year using ``filename'', nogen
	}
	
	* rename some variables to their corresponding names in the prefabove dataset
	local var_set1 gdp_cny gdp_cny_duc
	local var_set2 urbavgnworkers_ppl avgnworkers_ppl_duc
	local var_set3 yrendempinunits_ppl empinunits_ppl_duc
	local var_set4 urbtotwageworkers_cny totwageworkers_cny_duc
	local var_set5 govrevenue_cny govrevenue_cny_duc
	local var_set6 govexpenditure_cny govexpenditure_cny_duc
	local var_set7 yrendtotpop_ppl yrendtotpop_ppl_duc
	* it's not clear that avgwage_cny matches avgwage_cny in prefabove
	local var_set8 avgwage_cny avgwage_cny_cty
				  
	forval i = 1/8 {
		local old: word 1 of `var_set`i''
		di "`old'"
		local new: word 2 of `var_set`i''
		di "`new'"
		rename `old' `new'
		label variable `new' clevel_`old'
	
	}

* reshape to wide form
	unab all_varnames: _all
	local exclude city_cn year 
	local vars_to_reshape: list all_varnames - exclude 
	di "`vars_to_reshape'"
	
	reshape wide `vars_to_reshape', i(city_cn) j(year)
}
save "${data}/temp_outputs/clevel_selected_variables_wide.dta", replace

