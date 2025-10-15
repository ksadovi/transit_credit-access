// Prepares a cleaned panel of city outcomes

use "$data/temp_outputs/build_database_output/city_variables", clear
merge m:1 city_cn using "$data/citycentroids", keepusing(cityid city_en province_cn province_en) 
keep if _m==3 
	// _m==2 are 30 cities for which there are no outcomes recorded ever
	// _m==1 are 420 outcome records (mostly county-level) which do not match to our prefectures
drop _m

order cityid city_cn city_en

reshape long ///
		gdp_cny_wc gdp_cny_duc 	gdppc_cny_wc gdppc_cny_duc ///
		govexpenditure_cny_duc 	govrevenue_cny_duc  ///
		govexpenditure_cny_wc  	govrevenue_cny_wc   ///
		yrendtotpop_ppl_wc 		yrendtotpop_ppl_duc  ///
		annualavgpop_ppl_duc 	annualavgpop_ppl_wc  ///
		totwageworkers_cny_duc 	totwageworkers_cny_wc ///
		avgwageworkers_cny_wc 	avgwageworkers_cny_duc ///
		empinunits_ppl_wc 		empinunits_ppl_duc  ///
		avgnworkers_ppl_wc 		avgnworkers_ppl_duc ///
		pubtrstpaxtfc_rid  ///
		airfrttfc_ton_wc   		airpaxtfc_ppl_wc    ///
		railfrttfc_ton_wc  		railpaxtfc_ppl_wc   ///
		roadfrttfc_ton_wc  		roadpaxtfc_ppl_wc   ///
		waterfrttfc_ton_wc 		waterpaxtfc_ppl_wc  ///
		totfrttfc_ton_wc   		totpaxtfc_ppl_wc	 ///	 
		ncinema_unit_wc 		ncinema_unit_duc ///
		builtupareagreenarea_ha_duc   ///
		greenlandpc_m2pc_duc 	pubgreenland_ha_duc /// 
		urbgreenland_ha_duc ///
		landarea_km2_duc 		landarea_km2_wc ///
		yrendpavedroad_m2_duc 	urbroadareapc_m2_duc ///
		priemp_ppl_duc 			priemp_ppl_wc  ///
		secemp_ppl_duc 			secemp_ppl_wc  ///
		teremp_ppl_duc			teremp_ppl_wc  ///
		priselfemp_ppl_duc 		priselfemp_ppl_wc   ///
		constemp_ppl_duc 		constemp_ppl_wc   ///
		mfgemp_ppl_duc 			mfgemp_ppl_wc  ///
		miningemp_ppl_duc 		miningemp_ppl_wc   ///
		wholesaleretailemp_ppl_duc  ///
		wholesaleretailemp_ppl_wc  ///
		accomncateremp_ppl_duc 	accomncateremp_ppl_wc ///
		eduemp_ppl_duc			eduemp_ppl_wc   ///
		lsencmlemp_ppl_duc 		lsencmlemp_ppl_wc   ///
		itemp_ppl_duc 			itemp_ppl_wc  ///
		utilitiesemp_ppl_duc 	utilitiesemp_ppl_wc   ///
		realestateemp_ppl_duc 	realestateemp_ppl_wc  ///
		ressernothemp_ppl_duc 	ressernothemp_ppl_wc  ///
		finemp_ppl_duc 			finemp_ppl_wc ///
		avgwage_cny_cty ///
		 , i(cityid) j(year)

*==========================================
* label variables
*==========================================

/* Labels: city info */
label variable cityid "unique city identifier from citycentroids.csv"
label variable year "year"
label variable city_cn "city Chinese name"
label variable city_en "city English name"
label variable province_cn "province Chinse name"
label variable province_en "province English name"

/* Labels: vars with both whole city and urban core */
foreach suf in "_wc" "_duc"{
	local lb= ""
	if ("`suf'"=="_duc") local lb= "(urban district)"
	
	la var accomncateremp_ppl`suf' "accommodation and catering employment `lb'"
	la var constemp_ppl`suf' "construction employment `lb'"
	la var eduemp_ppl`suf' "education employment `lb'"
	la var finemp_ppl`suf' "financial industry employment `lb'"
	la var itemp_ppl`suf' "IT employment `lb'"
	la var lsencmlemp_ppl`suf' "leasing and commercial services employment `lb'"
	la var mfgemp_ppl`suf' "manufacturing employment `lb'"
	la var miningemp_ppl`suf' "mining employment `lb'"
	la var priemp_ppl`suf' "primary sector employment `lb'"
	la var realestateemp_ppl`suf' "real estate employment `lb'"
	la var ressernothemp_ppl`suf' "resident services and other services employment `lb'"
	la var secemp_ppl`suf' "secondary sector employment `lb'"
	la var teremp_ppl`suf' "tertiary sector employment `lb'"
	la var priselfemp_ppl`suf' "private and self employed `lb'"
	la var utilitiesemp_ppl`suf' "utilities employment `lb'"
	la var wholesaleretailemp_ppl`suf' "wholesale and retail employment `lb'"
	la var gdppc_cny`suf' "GDP per capita in chinese yuan `lb'"
	la var gdp_cny`suf' "GDP in chinese yuan `lb'"
	la var annualavgpop_ppl`suf' "annual average population `lb'"
	la var yrendtotpop_ppl`suf' "total population at year end `lb'"
	la var avgwageworkers_cny`suf' "average wage of employed staff and workers in chinese yuan `lb'"
	la var totwageworkers_cny`suf' "total wage bill of employed staff and workers in chinese yuan `lb'"
	la var govexpenditure_cny`suf' "expenditure of local government in chinese yuan `lb'"
	la var govrevenue_cny`suf' "revenue of local government in chinese yuan `lb'"
	la var avgnworkers_ppl`suf' "average number of employed staff and workers `lb'"
	la var empinunits_ppl`suf' "persons employed in various units at year end `lb'"
	la var landarea_km2`suf' "landarea in square kilometers `lb'"
	la var ncinema_unit`suf' "number of theaters and movie theaters `lb'"
	
}

/* Labels: whole city only vars */
local lb "(whole city)"
la var airfrttfc_ton_wc "goods transported by air in tons `lb'"
la var airpaxtfc_ppl_wc "civil air passenger traffic `lb'"
la var roadfrttfc_ton_wc "road freight traffic by ton `lb'"
la var roadpaxtfc_ppl_wc "road passenger traffic `lb'"
la var waterfrttfc_ton_wc "goods transported by water in tons `lb'"
la var waterpaxtfc_ppl_wc "water passenger traffic `lb'"
la var railfrttfc_ton_wc "goods transported by rail in tons `lb'"
la var railpaxtfc_ppl_wc "railway passenger traffic `lb'"
la var totfrttfc_ton_wc "total goods transported in tons `lb'"
la var totpaxtfc_ppl_wc "total passenger traffic `lb'"

/* Labels: urban core only vars */
local lb "(urban core)"
la var pubgreenland_ha_duc "park or public green land area in hectares `lb'"
la var urbgreenland_ha_duc "area of urban green land in hectares `lb'"
la var builtupareagreenarea_ha_duc "green coverage area of built up area in hectares `lb'"
la var greenlandpc_m2pc_duc "area of green land per capita in square meters `lb'"
la var yrendpavedroad_m2_duc "area of paved roads at year end in square meters `lb'"
la var urbroadareapc_m2_duc "area of urban road per capita in square meters `lb'"

/* Labels: not in documentation */
la var pubtrstpaxtfc_rid "not in documentation"

save "$data/city_database_long", replace
