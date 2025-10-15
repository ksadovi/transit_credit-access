* Import prefecture-level outcomes from the Yearbooks

clear all
set more off
set graphics off

* read file
import delimited using "${data}/temp_outputs/all_variables_prefabove_wide.csv", clear encoding("utf-8")
* rename some strings that refer to the same thing in different years according to the documentation
cleanchars, in("_rgn") out("_wc") vname
cleanchars, in("_city") out("_duc") vname
cleanchars, in("_noc") out("_duc") vname
cleanchars, in("parkgreenland") out("pubgreenland") vname
cleanchars, in("yrendurbpavedroad") out("yrendpavedroad") vname
cleanchars, in("pavedroadareapc") out("urbroadareapc") vname
cleanchars, in("rgdp") out("gdp") vname
cleanchars, in("yrendregpop") out("yrendtotpop") vname
cleanchars, in("yrendempinunits") out("empinunits") vname
cleanchars, in("totadmreglandarea") out("landarea") vname


* change the years from the publication year to the year of the variables

forval pub_year = 2000/2017 {
	local var_year = `pub_year' - 1 	
	cleanchars, in("`pub_year'") out("`var_year'") vname
}


*************************************
*                                   *
* construct variables for prefabove *
*                                   *
*************************************

quietly {

	**********************************
	*              GDP               *
	**********************************
	preserve
	keep city_cn gdp_cny* gdppc_cny* 

	reshape long gdp_cny_wc gdp_cny_duc gdppc_cny_wc gdppc_cny_duc, i(city_cn) j(year)

	tempfile gdp 
	save `gdp', replace
	restore


	***********************************
	* government revenue and spending *
	***********************************

	preserve
	keep city_cn gov*

	* in year 2000, the table didn't specify if the data is for whole city or districts under city
	* the information could've been in the yearbook (but lost during digitization)
	* but the year before and after all reported districts under city gov budget only, 
	* so I think it's safe to assume that the 2001 data is for districts under city
	rename govexpenditure_cny2000 govexpenditure_cny_duc2000
	rename govrevenue_cny2000 govrevenue_cny_duc2000

	reshape long govexpenditure_cny_duc govrevenue_cny_duc ///
				 govexpenditure_cny_wc  govrevenue_cny_wc  ///
			, i(city_cn) j(year)


	tempfile gov_budget
	save `gov_budget', replace

	restore


	**********************************
	*           population           *
	**********************************
	preserve 
	keep city_cn yrendtotpop* annualavgpop*


	reshape long yrendtotpop_ppl_wc yrendtotpop_ppl_duc ///
				 annualavgpop_ppl_duc annualavgpop_ppl_wc, ///
				 i(city_cn) j(year)

	tempfile pop 
	save `pop', replace
	restore



	**********************************
	*              wage              *
	**********************************

	preserve

	keep city_cn *wage*
	reshape long totwageworkers_cny_duc totwageworkers_cny_wc ///
				 avgwageworkers_cny_wc avgwageworkers_cny_duc, ///
				 i(city_cn) j(year)

	tempfile wage
	save `wage', replace

	restore

	**********************************
	*           employment           *
	**********************************
	preserve
	keep city_cn *empinunits* avgnworkers*

	reshape long empinunits_ppl_wc empinunits_ppl_duc avgnworkers_ppl_wc avgnworkers_ppl_duc, i(city_cn) j(year)

	tempfile emp 
	save `emp', replace 
	restore


	**********************************
	*   passenger/freight traffic    *
	**********************************

	preserve
	keep city_cn  *tfc* 
	drop *duc*

	reshape long pubtrstpaxtfc_rid ///
				 airfrttfc_ton_wc   airpaxtfc_ppl_wc   ///
				 railfrttfc_ton_wc  railpaxtfc_ppl_wc  ///
				 roadfrttfc_ton_wc  roadpaxtfc_ppl_wc  ///
				 waterfrttfc_ton_wc waterpaxtfc_ppl_wc ///
				 totfrttfc_ton_wc   totpaxtfc_ppl_wc,  ///
				 i(city_cn) j(year)

	tempfile traffic 
	save `traffic', replace 
	restore


	**********************************
	*       number of cinemas        *
	**********************************

	preserve
	keep city_cn  *cinema* 

	reshape long ncinema_unit_wc ncinema_unit_duc , i(city_cn) j(year)
		 
	tempfile cinema 
	save `cinema', replace 
	restore 


	**********************************
	*         green land             *
	**********************************

	preserve
	keep city_cn *green* 
	drop *builtup*

	reshape long builtupareagreenarea_ha_duc  ///
				 greenlandpc_m2pc_duc pubgreenland_ha_duc ///
				 urbgreenland_ha_duc, i(city_cn) j(year)

	tempfile green 
	save `green', replace 
	restore 


	**********************************
	*         land area              *
	**********************************

	preserve
	keep city_cn  *land* 
	drop *green* *arable* *resland* *const*

	reshape long landarea_km2_duc landarea_km2_wc, i(city_cn) j(year)
	
	tempfile land
	save `land', replace 
	restore 


	**********************************
	*           road area            *
	**********************************

	preserve
	keep city_cn  *road* 
	drop *tfc*

	* in year 2012 - 2015, year end urban paved road area was reported twice in separate tables
	* so we get two variables (_x _y) in each year holding the same values
	* therefore we drop one of them
	drop *_y 
	forval yr = 2011/2014 {
		rename yrendpavedroad_m2_duc`yr'_x yrendpavedroad_m2_duc`yr'
	}
	
	* in 2000, the area (wc or duc) was not specified,
	* but from context, it should be duc
	rename urbroadareapc_m22000 urbroadareapc_m2_duc2000
	rename yrendpavedroad_m22000 yrendpavedroad_m2_duc2000

	reshape long yrendpavedroad_m2_duc urbroadareapc_m2_duc, i(city_cn) j(year)
		 
	tempfile road 
	save `road', replace 
	restore 




	**********************************
	*      employment by sector      *
	**********************************

	preserve
	keep city_cn *emp*
	drop *empinunits*

	* these two are what i assumed based on the fact that 
	* they have very similar wordings and are reported in continuous 
	* but disjoint blocks of years 
	* so assumed that they are the same variable that are called a slightly 
	* different name before and after a certain year
	cleanchars, in("urbpriselfemp") out("priselfemp") vname
	cleanchars, in("fininsemp") out("finemp") vname


	reshape long priemp_ppl_duc priemp_ppl_wc  /// primary sector employment
				 secemp_ppl_duc secemp_ppl_wc  /// secondary sector employment
				 teremp_ppl_duc teremp_ppl_wc  /// tertiary sector employment
				 priselfemp_ppl_duc priselfemp_ppl_wc  /// private and self employed 
				 constemp_ppl_duc constemp_ppl_wc  /// construction employment
				 mfgemp_ppl_duc mfgemp_ppl_wc  /// manufacturing employment
				 miningemp_ppl_duc miningemp_ppl_wc  /// mining employment
				 wholesaleretailemp_ppl_duc wholesaleretailemp_ppl_wc /// wholesale and retail employment
				 accomncateremp_ppl_duc accomncateremp_ppl_wc ///accommodation and catering employment 
				 eduemp_ppl_duc eduemp_ppl_wc  /// education employment
				 lsencmlemp_ppl_duc lsencmlemp_ppl_wc  /// leasing and commercial services employment
				 itemp_ppl_duc itemp_ppl_wc  /// IT employment 
				 utilitiesemp_ppl_duc utilitiesemp_ppl_wc /// utilities employment
				 realestateemp_ppl_duc realestateemp_ppl_wc /// real estate employment 
				 finemp_ppl_duc finemp_ppl_wc  /// financial industry employment 
				 ressernothemp_ppl_duc ressernothemp_ppl_wc /// resident services and other services employment
				 , i(city_cn) j(year)

	* drop some variables that we didn't want and didn't include in reshaping 
	drop *20* *19*

	tempfile emp_sec 
	save `emp_sec', replace 
	restore, not

**********************************
*     combine and save           *
**********************************
	* merge back in the other tempfiles (except for the last one) generated earlier
	foreach filename in gdp pop wage gov_budget emp traffic cinema green land road {
		merge 1:1 city_cn year using ``filename'', nogen
	}

* reshape to wide form
	unab all_varnames: _all
	local exclude city_cn year 
	local vars_to_reshape: list all_varnames - exclude 
	di "`vars_to_reshape'"
	
	reshape wide `vars_to_reshape', i(city_cn) j(year)
}
save "${data}/temp_outputs/prefabove_selected_variables_wide.dta", replace
